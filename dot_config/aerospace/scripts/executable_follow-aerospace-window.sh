#!/usr/bin/env bash

set -u

# Target app bundle ID.
TARGET_BUNDLE_ID="com.voiceos.app"
INTERVAL_SECONDS="${AEROSPACE_FOLLOW_INTERVAL_SECONDS:-1}"

while true; do
  focused_workspace="$(aerospace list-workspaces --focused 2>/dev/null | head -n 1)"

  if [[ -n "${focused_workspace}" ]]; then
    # list-windows --all includes visible and non-visible windows.
    window_id="$(
      aerospace list-windows --monitor all --format '%{window-id}|%{app-bundle-id}' 2>/dev/null \
        | awk -F'|' -v target="${TARGET_BUNDLE_ID}" '$2 == target { print $1; exit }'
    )"

    if [[ -n "${window_id}" ]]; then
      aerospace move-node-to-workspace --window-id "${window_id}" "${focused_workspace}" --fail-if-noop >/dev/null 2>&1
    fi
  fi

  sleep "${INTERVAL_SECONDS}"
done
