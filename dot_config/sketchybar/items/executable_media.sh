#!/bin/bash

sketchybar --add item media e \
           --set media label.color=$ACCENT_COLOR \
                       label.max_chars=20 \
                       icon.padding_left=10 \
                       label.padding_right=2 \
                       scroll_texts=on \
                       icon=􀑪             \
                       icon.color=$ACCENT_COLOR   \
                       background.drawing=off \
                       script="$CONFIG_DIR/plugins/media.sh" \
                       update_freq=5 \
           --subscribe media media_change
