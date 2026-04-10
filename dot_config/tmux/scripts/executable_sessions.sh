#!/usr/bin/env bash
# Renders all tmux sessions in the left status bar.
# Current session: amber accent  ·  Others: muted gray
# Example output:  ❯ main  ·  dev  ·  work

current=$(tmux display-message -p '#S')
result=""

while IFS= read -r s; do
  if [[ "$s" == "$current" ]]; then
    result+="#[fg=#101010,bg=#ffc799,bold] ❯ ${s} #[fg=#a67c52,nobold]·#[default]"
  else
    result+="#[fg=#444444,bg=#ffc799] ${s} #[fg=#a67c52]·#[default]"
  fi
done < <(tmux list-sessions -F '#S' 2>/dev/null)

# Trim trailing separator
result="${result% #[fg=#a67c52]·#[default]}"
echo "$result "
