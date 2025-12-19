#!/bin/bash

# ==============================================================================
# Clipboard Monitor for macOS
# Automatically saves clipboard content to a file when it ends with a specific 
# marker. Designed specifically for macOS using pbpaste.
# ==============================================================================

# --- Configuration Variables (Edit these) ---
MARKER="%FOR OBSIDIANMD%"
TARGET_FILE="$HOME/core/floating.md"
MODE="append"          # Options: "append" or "overwrite"
INTERVAL=0.5           # Check interval in seconds (0.5 to 2.0 recommended)
KEEP_LAST=true         # true: don't save the same content repeatedly
DEBUG=true             # true: print log messages to terminal
# --------------------------------------------

# Internal state
LAST_CLIP_HASH=""

# --- Cleanup on Exit ---
cleanup() {
    echo -e "\n[INFO] Monitor stopped. Exiting cleanly..."
    exit 0
}
# Trap Ctrl-C (SIGINT) and termination (SIGTERM)
trap cleanup SIGINT SIGTERM

# --- Save Content Logic ---
save_content() {
    local content="$1"
    local dir
    dir=$(dirname "$TARGET_FILE")

    # Ensure target directory exists
    if [ ! -d "$dir" ]; then
        if ! mkdir -p "$dir"; then
            echo "[ERROR] Could not create directory: $dir" >&2
            return 1
        fi
    fi

    if [ "$MODE" = "overwrite" ]; then
        # Atomic overwrite: write to temp file then move
        local tmp_file="${TARGET_FILE}.tmp"
        printf "%s" "$content" > "$tmp_file" && mv "$tmp_file" "$TARGET_FILE"
    else
        # Append: Add a newline between entries if the file isn't empty
        if [[ -s "$TARGET_FILE" ]]; then
            printf "\n%s" "$content" >> "$TARGET_FILE"
        else
            printf "%s" "$content" >> "$TARGET_FILE"
        fi
    fi

    if [ "$DEBUG" = true ]; then
        echo "[$(date '+%H:%M:%S')] SAVED: Content ending with '$MARKER'"
    fi
}

# --- Main Loop ---
main() {
    # Check if we are on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        echo "[ERROR] This script is optimized for macOS. (Detected: $OSTYPE)"
        exit 1
    fi

    # Verify pbpaste is available
    if ! command -v pbpaste >/dev/null 2>&1; then
        echo "[ERROR] 'pbpaste' utility not found. This is standard on macOS."
        exit 1
    fi

    echo "--------------------------------------------------------"
    echo " Clipboard Monitor Started (macOS)"
    echo " Marker:      '$MARKER'"
    echo " Target File: $TARGET_FILE"
    echo " Mode:        $MODE"
    echo " Press Ctrl-C to stop."
    echo "--------------------------------------------------------"

    while true; do
        # pbpaste gets the current clipboard content
        current_clip=$(pbpaste)

        # Skip if clipboard is empty
        if [[ -n "$current_clip" ]]; then
            
            # Check if the content ends with the exact marker string
            # Using [[ string == *suffix ]] for pattern matching
            if [[ "$current_clip" == *"$MARKER" ]]; then
                
                # Check for changes to avoid duplicate saves
                if [ "$KEEP_LAST" = true ]; then
                    # Generate an MD5 hash of the content for comparison
                    current_hash=$(echo -n "$current_clip" | md5)
                    
                    if [ "$current_hash" != "$LAST_CLIP_HASH" ]; then
                        # Strip the marker from the end of the content
                        cleaned_clip="${current_clip%"$MARKER"}"
                        save_content "$cleaned_clip"
                        LAST_CLIP_HASH="$current_hash"
                    fi
                else
                    # Strip the marker from the end of the content
                    cleaned_clip="${current_clip%"$MARKER"}"
                    save_content "$cleaned_clip"
                fi
            fi
        fi

        sleep "$INTERVAL"
    done
}

main
