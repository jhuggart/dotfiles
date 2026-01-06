#!/bin/sh
terminal-notifier -title '✅ Claude Code' -message 'Done'

# Only highlight if this window is not currently active
current_window=$(tmux display-message -p '#{window_id}')
pane_window=$(tmux display-message -t "$TMUX_PANE" -p '#{window_id}')

if [ "$current_window" != "$pane_window" ]; then
  tmux set-option -wt "$TMUX_PANE" @claude-done 1
fi
