#!/bin/bash

# Some events send additional information specific to the event in the $INFO
# variable. E.g. the front_app_switched event sends the name of the newly
# focused application in the $INFO variable:

STATE_DIR="${TMPDIR:-/tmp}/sketchybar"
LAST_APP_FILE="$STATE_DIR/last_front_app"

if [ "$SENDER" = "front_app_switched" ]; then
  mkdir -p "$STATE_DIR"

  # Mission Control can transiently focus WindowManager; restore the previous app.
  case "$INFO" in
    "WindowManager"|"windowmanager")
      if [ -f "$LAST_APP_FILE" ]; then
        LAST_APP=$(cat "$LAST_APP_FILE")
        if [ -n "$LAST_APP" ]; then
          osascript -e "tell application \"$LAST_APP\" to activate" >/dev/null 2>&1
        fi
      fi
      exit 0
      ;;
  esac

  printf "%s" "$INFO" > "$LAST_APP_FILE"

  # Source the icon map function to avoid process fork
  # Redirect output to null because the script executes itself at the end
  if [ -f "$CONFIG_DIR/plugins/icon_map_fn.sh" ]; then
      source "$CONFIG_DIR/plugins/icon_map_fn.sh" > /dev/null 2>&1
  fi

  ICON=":default:"
  if type icon_map >/dev/null 2>&1; then
      icon_map "$INFO"
      ICON="$icon_result"
  else
      # Fallback
      ICON=$($CONFIG_DIR/plugins/icon_map_fn.sh "$INFO")
  fi

  sketchybar --set $NAME label="$INFO" icon="$ICON"
fi
