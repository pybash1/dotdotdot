#!/bin/bash

sketchybar --add item audio_device right \
           --set audio_device update_freq=30 \
                              script="$PLUGIN_DIR/audio_device.sh" \
                              background.drawing=off \
                              label.drawing=off \
                              icon.padding_left=2 \
                              icon.padding_right=2 \
                              drawing=off \
           --subscribe audio_device system_woke volume_change
