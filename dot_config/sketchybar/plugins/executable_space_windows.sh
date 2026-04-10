#!/bin/bash

source "$CONFIG_DIR/colors.sh"

# Function to create a workspace item if it doesn't exist
create_workspace_item() {
    local workspace="$1"
    
    # Find the correct position to insert (after the last existing workspace)
    local existing_spaces=$(sketchybar --query bar | jq -r '.items[] | select(startswith("space.")) | .[6:]' 2>/dev/null | sort -n)
    local position_ref=""
    
    if [ -n "$existing_spaces" ]; then
        # Find the last workspace that's smaller than this one
        while IFS= read -r existing_space; do
            if [ "$existing_space" -lt "$workspace" ]; then
                position_ref="space.$existing_space"
            fi
        done <<< "$existing_spaces"
    fi
    
    if [ -n "$position_ref" ]; then
        sketchybar --add item space.$workspace left --position "$position_ref"
    else
        # Insert at the beginning (before space_separator or first)
        if sketchybar --query space_separator &>/dev/null; then
            sketchybar --add item space.$workspace left --position space_separator
        else
            sketchybar --add item space.$workspace left --position first
        fi
    fi
    
    sketchybar --set space.$workspace \
        background.color=$BAR_COLOR \
        icon="$workspace" \
        label.font="sketchybar-app-font:Regular:16.0" \
        label.padding_right=0 \
        label.y_offset=-1 \
        click_script="aerospace workspace $workspace" \
        script="$PLUGIN_DIR/space_windows.sh $workspace"
}

# Function to remove a workspace item
remove_workspace_item() {
    local workspace="$1"
    sketchybar --remove space.$workspace 2>/dev/null
}

# Function to check if workspace item exists
workspace_item_exists() {
    local workspace="$1"
    sketchybar --query space.$workspace &>/dev/null
}

# Function to update workspace appearance based on focus
update_workspace_appearance() {
    local workspace="$1"
    local focused_workspace="$2"
    
    if [ -z "$focused_workspace" ]; then
        focused_workspace=$(aerospace list-workspaces --focused)
    fi
    
    if [ "$workspace" = "$focused_workspace" ]; then
        sketchybar --set space.$workspace background.drawing=on \
                                         background.color=$ACCENT_COLOR \
                                         label.color=$BAR_COLOR \
                                         icon.color=$BAR_COLOR
    else
        sketchybar --set space.$workspace background.drawing=off \
                                         label.color=$ACCENT_COLOR \
                                         icon.color=$ACCENT_COLOR
    fi
}

# Function to update window icons for a workspace
update_workspace_windows() {
    local workspace="$1"
    local focused_workspace="$2"
    
    # Get apps in the workspace
    apps=$(aerospace list-windows --workspace "$workspace" --format "%{app-name}" 2>/dev/null)
    
    # Always ensure the workspace item exists
    if ! workspace_item_exists "$workspace"; then
        create_workspace_item "$workspace"
    fi
    
    if [ -n "$apps" ] && [ "$apps" != "" ]; then
        # Workspace has windows, update window icons
        icon_strip=""
        while IFS= read -r app; do
            if [ -n "$app" ]; then
                icon=$($CONFIG_DIR/plugins/icon_map_fn.sh "$app")
                icon_strip+="$icon"
            fi
        done <<< "$apps"
        sketchybar --set space.$workspace label="$icon_strip"
    else
        # Workspace is empty, clear the label but keep the item
        sketchybar --set space.$workspace label=""
    fi
    
    # Update appearance
    update_workspace_appearance "$workspace" "$focused_workspace"
}

# Handle different events and calls
# Handle different events and calls
if [ "$SENDER" = "aerospace_workspace_change" ]; then
    # Update all workspaces when workspace changes
    # Try to get focused workspace from env or query
    focused_workspace="$FOCUSED_WORKSPACE"
    if [ -z "$focused_workspace" ]; then
        focused_workspace=$(aerospace list-workspaces --focused)
    fi
    
    # Fast update using regex to reset all, then highlight focused
    sketchybar --set '/space\..*/' background.drawing=off \
                                 label.color=$ACCENT_COLOR \
                                 icon.color=$ACCENT_COLOR \
               --set "space.$focused_workspace" background.drawing=on \
                                                background.color=$ACCENT_COLOR \
                                                label.color=$BAR_COLOR \
                                                icon.color=$BAR_COLOR

elif [ "$SENDER" = "space_windows_change" ]; then
    # Update all workspaces when windows change
    
    # Source the icon map function to avoid N+1 process forks
    # We redirect output to null because the script executes itself at the end
    if [ -f "$CONFIG_DIR/plugins/icon_map_fn.sh" ]; then
        source "$CONFIG_DIR/plugins/icon_map_fn.sh" > /dev/null 2>&1
    fi

    # 1. Get focused workspace
    focused_workspace=$(aerospace list-workspaces --focused)
    
    # 2. Get all windows with their workspace in one call
    # Format: workspace|app-name
    windows_list=$(aerospace list-windows --all --format "%{workspace}|%{app-name}")
    
    # 3. Aggregate apps per workspace
    declare -A workspace_apps
    while IFS= read -r line; do
        if [ -n "$line" ]; then
            ws="${line%%|*}"
            app="${line#*|}"
            workspace_apps["$ws"]+="$app"$'\n'
        fi
    done <<< "$windows_list"
    
    # 4. Build sketchybar command
    args=()
    
    # Iterate over all workspaces
    for sid in $(aerospace list-workspaces --all); do
        apps="${workspace_apps[$sid]}"
        icon_strip=""
        
        if [ -n "$apps" ]; then
            while IFS= read -r app; do
                if [ -n "$app" ]; then
                    # Use the sourced function directly
                    if type icon_map >/dev/null 2>&1; then
                        icon_map "$app"
                        icon_strip+="$icon_result"
                    else
                        # Fallback if sourcing failed
                        icon=$($CONFIG_DIR/plugins/icon_map_fn.sh "$app")
                        icon_strip+="$icon"
                    fi
                fi
            done <<< "$apps"
        fi
        
        args+=(--set "space.$sid" label="$icon_strip")
        
        # Also ensure appearance is correct (redundant but safe)
        if [ "$sid" = "$focused_workspace" ]; then
            args+=(background.drawing=on background.color=$ACCENT_COLOR label.color=$BAR_COLOR icon.color=$BAR_COLOR)
        else
            args+=(background.drawing=off label.color=$ACCENT_COLOR icon.color=$ACCENT_COLOR)
        fi
    done
    
    sketchybar "${args[@]}"
else
    # Initial setup, manual call, or specific workspace update
    if [ -n "$1" ]; then
        # Called with specific workspace
        update_workspace_windows "$1"
    else
        # Called without parameters, update all
        focused_workspace=$(aerospace list-workspaces --focused)
        for sid in $(aerospace list-workspaces --all); do
            update_workspace_windows "$sid" "$focused_workspace"
        done
    fi
fi
