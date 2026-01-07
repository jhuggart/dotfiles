# dotfiles

macOS shell setup with zsh, Ghostty, tmux, and vim.

## Quick Start

```bash
git clone https://github.com/jhuggart/dotfiles.git ~/code/dotfiles
cd ~/code/dotfiles
./setup.sh
```

## What's Included

### Zsh
- Custom prompt with git branch and colors
- Autosuggestions (ghost text from history)
- Syntax highlighting (green = valid, red = invalid)
- Fuzzy history search (`Ctrl+R`)
- Auto-cd, typo correction
- 50k shared history across terminals
- `eza` aliases: `ls` (icons), `ll` (detailed + git), `lt` (tree)
- `zoxide` smart directory jumping: `z foo` jumps to any directory containing "foo"
- Lazy-loaded NVM for faster shell startup

### Ghostty
- JetBrains Mono Nerd Font
- GruvboxDark theme
- Clean padding and block cursor

### Tmux

Prefix is `Ctrl+A` (not the default `Ctrl+B`).

| Keys | Action |
|------|--------|
| `Ctrl+A p` | Split pane horizontally |
| `Ctrl+A v` | Split pane vertically |
| `Ctrl+A x` | Kill pane (no confirm) |
| `Ctrl+A r` | Reload config |
| `Ctrl+A T` | Move window to first position |
| `Ctrl+A h/j/k/l` | Resize pane |
| `Ctrl+h/j/k/l` | Navigate panes (vim-aware) |
| `Ctrl+A I` | Install TPM plugins |
| `Ctrl+A U` | Update TPM plugins |

**Vim integration:** Pane navigation works seamlessly between tmux and vim splits using `Ctrl+h/j/k/l`.

**Session persistence:** Sessions are automatically saved and restored on restart via tmux-resurrect and tmux-continuum.

### Neovim

| Keys | Action |
|------|--------|
| `Ctrl+p` | Find files (telescope) |
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gr` | Find references |
| `gi` | Go to implementation |
| `K` | Hover documentation |
| `\rn` | Rename symbol |
| `\ca` | Code actions |
| `\fg` | Live grep (search in files) |
| `\fb` | List buffers |
| `Ctrl+h/j/k/l` | Navigate splits/tmux panes |

**Auto-completion:** Full LSP-powered completion with nvim-cmp. Use `Tab`/`S-Tab` to navigate, `Enter` to confirm, `Ctrl+Space` to trigger manually.

**LSP support:** Go (gopls) and TypeScript (typescript-language-server).

### Claude Code

**Slash commands:**
| Command | Action |
|---------|--------|
| `/cp` | Commit and push |
| `/cppr` | Commit, push, open PR, and watch GitHub Actions |
| `/merge` | Merge current branch's PR to main |

**Tmux window highlighting:**
- Yellow - Claude is waiting for input
- Green - Claude has finished
- Highlighting only appears on background windows and clears when focused

### Tools Installed
- neovim
- tmux (with TPM plugin manager)
- zsh-autosuggestions
- zsh-syntax-highlighting
- fzf
- eza
- zoxide
- nvm
- ripgrep
- go
- terminal-notifier
- JetBrainsMono Nerd Font

## Customization

**Change Ghostty theme:**
```bash
ghostty +list-themes  # see available themes
```
Then edit `ghostty/config` and change the `theme` line.

**Prompt colors** are in `.zshrc` using `%F{color}` format:
- `cyan` - directory
- `magenta` - git branch
- `green` - prompt arrow
