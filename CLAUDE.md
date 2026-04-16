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
│   ├── skills/         # Claude Code skills (auto-symlinked, one dir per skill)
│   ├── scripts/        # Notification scripts for tmux highlighting
│   └── settings.json   # Claude Code settings template
└── setup.sh            # Installation script
```

## Claude Code Skills

Skills in `claude/skills/*/SKILL.md` are automatically symlinked to `~/.claude/skills/` by setup.sh.

## Tmux Window Highlighting

The notification scripts (`claude/scripts/`) set tmux user options (`@claude-waiting`, `@claude-done`) to highlight windows when Claude needs attention.

## Debugging & Investigation

- When investigating configuration issues, always trace the full config flow from source (config files, environment variables) through to usage. Don't assume defaults in code are actually used - verify that config values are being passed through.
- For latency/performance investigations, gather multiple data points before concluding root cause. Present findings as hypotheses to verify rather than definitive diagnoses.

## Git Workflow

- When working with worktrees, always confirm the worktree is created and switched to before making changes. Use `git worktree list` to verify.
- When building implementation plans, always include a fresh worktree creation as the first step to isolate changes from the main workspace.
- Write plans to .md files before executing, delete after entire plan has been completed and before final commit for that plan
