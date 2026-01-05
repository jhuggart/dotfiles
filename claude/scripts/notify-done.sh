#!/bin/sh
terminal-notifier -title '✅ Claude Code' -message 'Done'
tmux set-option -wt "$TMUX_PANE" @claude-done 1
