#!/bin/bash

get_media_info() {
    osascript -e '
        tell application "System Events"
            set spotify_running to (name of processes) contains "Spotify"
            set music_running to (name of processes) contains "Music"
        end tell

        if spotify_running then
            try
                tell application "Spotify"
                    if player state is playing then
                        return "playing|" & name of current track & " - " & artist of current track
                    end if
                end tell
            end try
        end if

        if music_running then
            try
                tell application "Music"
                    if player state is playing then
                        return "playing|" & name of current track & " - " & artist of current track
                    end if
                end tell
            end try
        end if

        return "stopped|"
    '
}

if [ -z "$INFO" ]; then
    MEDIA_INFO=$(get_media_info)
else
    STATE="$(echo "$INFO" | jq -r '.state')"
    if [ "$STATE" = "playing" ]; then
        MEDIA="$(echo "$INFO" | jq -r '.title + " - " + .artist')"
        MEDIA_INFO="playing|$MEDIA"
    else
        MEDIA_INFO="stopped|"
    fi
fi

STATE=$(echo "$MEDIA_INFO" | cut -d'|' -f1)
MEDIA=$(echo "$MEDIA_INFO" | cut -d'|' -f2)

if [ "$STATE" = "playing" ] && [ -n "$MEDIA" ]; then
    sketchybar --set $NAME label="$MEDIA" drawing=on
else
    sketchybar --set $NAME drawing=off
fi
