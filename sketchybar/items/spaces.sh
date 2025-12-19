#!/bin/bash

# Create workspace items for all workspaces at startup
workspace_ids=$(aerospace list-workspaces --all | sort -n)

args=()
while IFS= read -r sid; do
    args+=(--add item space.$sid left)
    args+=(--set space.$sid background.color=$BAR_COLOR)
    args+=(icon="$sid")
    args+=(label.font="sketchybar-app-font:Regular:16.0")
    args+=(label.padding_right=10)
    args+=(label.y_offset=-1)
    args+=(click_script="aerospace workspace $sid")
    args+=(script="$PLUGIN_DIR/space_windows.sh $sid")
done <<< "$workspace_ids"

args+=(--add item space_separator left)
args+=(--set space_separator icon="􀆊")
args+=(icon.color=$ACCENT_COLOR)
args+=(icon.padding_left=0)
args+=(label.drawing=off)
args+=(background.drawing=off)
args+=(background.color=$BAR_COLOR)
args+=(script="$PLUGIN_DIR/space_windows.sh")
args+=(--subscribe space_separator space_windows_change aerospace_workspace_change)

sketchybar "${args[@]}"
