# dotfiles

macOS shell setup with zsh, neovim, and Ghostty.

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

### Tools Installed
- neovim
- zsh-autosuggestions
- zsh-syntax-highlighting
- fzf
- eza
- nvm
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
