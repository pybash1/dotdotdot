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
    
    sketchybar --subscribe space.$workspace aerospace_workspace_change space_windows_change \
        --set space.$workspace \
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
    local focused_workspace=$(aerospace list-workspaces --focused)
    
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
    update_workspace_appearance "$workspace"
}

# Handle different events and calls
if [ "$SENDER" = "aerospace_workspace_change" ]; then
    # Update all workspaces when workspace changes
    for sid in $(aerospace list-workspaces --all); do
        update_workspace_appearance "$sid"
        update_workspace_windows "$sid"
    done
elif [ "$SENDER" = "space_windows_change" ]; then
    # Update all workspaces when windows change
    for sid in $(aerospace list-workspaces --all); do
        update_workspace_windows "$sid"
    done
else
    # Initial setup, manual call, or specific workspace update
    if [ -n "$1" ]; then
        # Called with specific workspace
        update_workspace_windows "$1"
    else
        # Called without parameters, update all
        for sid in $(aerospace list-workspaces --all); do
            update_workspace_windows "$sid"
        done
    fi
fi