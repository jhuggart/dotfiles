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

**Vim integration:** Pane navigation works seamlessly between tmux and vim splits using `Ctrl+h/j/k/l`.

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

**LSP support:** Go (gopls) and TypeScript (typescript-language-server).

### Tools Installed
- neovim
- tmux
- zsh-autosuggestions
- zsh-syntax-highlighting
- fzf
- eza
- nvm
- ripgrep
- go
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
