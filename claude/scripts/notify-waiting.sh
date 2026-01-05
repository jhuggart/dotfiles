#!/bin/sh
terminal-notifier -title '🔔 Claude Code' -message 'Claude is waiting...'
tmux set-option -wt "$TMUX_PANE" @claude-waiting 1
