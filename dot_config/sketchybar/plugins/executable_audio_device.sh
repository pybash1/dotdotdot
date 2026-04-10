#!/bin/sh

# Show an icon only when the default output device is a wireless headset/earbuds.
DEVICE_AND_TRANSPORT=$(system_profiler SPAudioDataType 2>/dev/null | awk '
  /^[[:space:]]+[[:graph:]].*:$/ {
    current_device=$0
    gsub(/^[[:space:]]+/, "", current_device)
    sub(/:$/, "", current_device)
  }
  /Default Output Device: Yes/ { in_default_output=1 }
  in_default_output && /Transport:/ {
    transport=$0
    gsub(/^[[:space:]]+/, "", transport)
    print current_device "|" transport
    exit
  }
')

DEFAULT_DEVICE=$(printf "%s" "$DEVICE_AND_TRANSPORT" | awk -F'|' '{print $1}' | tr '[:upper:]' '[:lower:]')
TRANSPORT_INFO=$(printf "%s" "$DEVICE_AND_TRANSPORT" | awk -F'|' '{print $2}' | tr '[:upper:]' '[:lower:]')

DEVICE_KIND=""
IS_WIRELESS=0

case "$DEFAULT_DEVICE" in
  *airpods*max*|*headphone*|*headphones*|*headset*|*wh-*|*qc*|*bose*|*sony*)
    DEVICE_KIND="headphones"
    ;;
  *airpods*|*earbud*|*earbuds*|*buds*)
    DEVICE_KIND="earbuds"
    ;;
esac

case "$TRANSPORT_INFO" in
  *bluetooth*|*wireless*)
    IS_WIRELESS=1
    ;;
esac

if [ -n "$DEVICE_KIND" ] && [ "$IS_WIRELESS" -eq 1 ]; then
  if [ "$DEVICE_KIND" = "earbuds" ]; then
    ICON="􀪷"
  else
    ICON="􀪹"
  fi

  sketchybar --set "$NAME" drawing=on icon="$ICON" icon.font="SF Pro:Regular:14.0" label=""
else
  sketchybar --set "$NAME" drawing=off
fi
