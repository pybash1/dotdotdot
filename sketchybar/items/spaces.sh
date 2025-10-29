#!/bin/bash

# Create workspace items for all workspaces at startup
for sid in $(aerospace list-workspaces --all | sort -n); do
    sketchybar --add item space.$sid left \
        --subscribe space.$sid aerospace_workspace_change space_windows_change \
        --set space.$sid \
        background.color=$BAR_COLOR                \
        icon="$sid" \
        label.font="sketchybar-app-font:Regular:16.0" \
        label.padding_right=10                      \
        label.y_offset=-1                          \
        click_script="aerospace workspace $sid" \
        script="$PLUGIN_DIR/space_windows.sh $sid"
done

sketchybar --add item space_separator left                             \
           --set space_separator icon="􀆊"                                \
                                 icon.color=$ACCENT_COLOR \
                                 icon.padding_left=0                   \
                                 label.drawing=off                     \
                                 background.drawing=off                \
                                 background.color=$BAR_COLOR                \
                                 script="$PLUGIN_DIR/space_windows.sh" \
           --subscribe space_separator space_windows_change aerospace_workspace_change                           
