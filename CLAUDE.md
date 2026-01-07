# Dotfiles Project

macOS shell configuration with zsh, Ghostty, tmux, neovim, and Claude Code integration.

## Key Files to Update

When making changes, ensure these files stay in sync:

- **setup.sh** - Update when adding new dependencies, symlinks, or installation steps
- **README.md** - Update when adding new features, keybindings, or commands

## Structure

```
dotfiles/
├── .tmux.conf          # tmux configuration
├── .zshrc              # zsh configuration
├── ghostty/config      # Ghostty terminal config
├── nvim/               # Neovim configuration
├── claude/
│   ├── commands/       # Claude Code slash commands (auto-symlinked)
│   ├── scripts/        # Notification scripts for tmux highlighting
│   └── settings.json   # Claude Code settings template
└── setup.sh            # Installation script
```

## Claude Code Commands

Commands in `claude/commands/` are automatically symlinked to `~/.claude/commands/` by setup.sh.

## Tmux Window Highlighting

The notification scripts (`claude/scripts/`) set tmux user options (`@claude-waiting`, `@claude-done`) to highlight windows when Claude needs attention.
