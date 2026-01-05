#!/bin/bash
set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "════════════════════════════════════════════════════════════"
echo "  Dotfiles Setup"
echo "════════════════════════════════════════════════════════════"

# ─────────────────────────────────────────────────────────────
# Install Homebrew if not present
# ─────────────────────────────────────────────────────────────
if ! command -v brew &> /dev/null; then
  echo "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

  # Add brew to path for Apple Silicon
  if [[ $(uname -m) == "arm64" ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  fi
fi

# ─────────────────────────────────────────────────────────────
# Install oh-my-zsh if not present
# ─────────────────────────────────────────────────────────────
if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
  echo "Installing oh-my-zsh..."
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# ─────────────────────────────────────────────────────────────
# Install dependencies
# ─────────────────────────────────────────────────────────────
echo "Installing dependencies..."
brew install neovim
brew install tmux
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install fzf
brew install eza
brew install nvm
brew install ripgrep
brew install go
brew install zoxide
brew install terminal-notifier

# Install Node via nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$(brew --prefix)/opt/nvm/nvm.sh" ] && \. "$(brew --prefix)/opt/nvm/nvm.sh"
nvm install --lts
nvm use --lts

# Install language servers
go install golang.org/x/tools/gopls@latest
npm install -g typescript typescript-language-server

# Set up fzf key bindings
yes | $(brew --prefix)/opt/fzf/install --key-bindings --completion --no-bash --no-fish --no-update-rc

# Install TPM (tmux plugin manager)
if [[ ! -d "$HOME/.tmux/plugins/tpm" ]]; then
  echo "Installing TPM..."
  git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
fi

# Install tmux plugins via TPM
echo "Installing tmux plugins..."
~/.tmux/plugins/tpm/bin/install_plugins

# Install Nerd Font
echo "Installing Nerd Font..."
brew install --cask font-jetbrains-mono-nerd-font

# ─────────────────────────────────────────────────────────────
# Create symlinks
# ─────────────────────────────────────────────────────────────
echo "Creating symlinks..."

# Create symlink if it doesn't exist or points elsewhere
link_file() {
  local src="$1"
  local dest="$2"

  # Already correctly linked
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    echo "  $dest already linked"
    return
  fi

  # Backup if regular file exists
  if [[ -e "$dest" && ! -L "$dest" ]]; then
    echo "  Backing up $dest to $dest.backup"
    mv "$dest" "$dest.backup"
  elif [[ -L "$dest" ]]; then
    rm "$dest"
  fi

  ln -s "$src" "$dest"
  echo "  Linked $dest"
}

# zsh
link_file "$DOTFILES_DIR/.zshrc" ~/.zshrc

# tmux
link_file "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf

# ghostty
mkdir -p ~/.config/ghostty
link_file "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config

# neovim
mkdir -p ~/.config
link_file "$DOTFILES_DIR/nvim" ~/.config/nvim

# claude code scripts
mkdir -p ~/.claude/scripts
link_file "$DOTFILES_DIR/claude/scripts/notify-waiting.sh" ~/.claude/scripts/notify-waiting.sh
link_file "$DOTFILES_DIR/claude/scripts/notify-done.sh" ~/.claude/scripts/notify-done.sh

# claude code settings (merge hooks if settings.json exists)
if [[ ! -f ~/.claude/settings.json ]]; then
  cp "$DOTFILES_DIR/claude/settings.json" ~/.claude/settings.json
  echo "  Created ~/.claude/settings.json"
else
  echo "  ~/.claude/settings.json exists - please manually add hooks from $DOTFILES_DIR/claude/settings.json"
fi

# ─────────────────────────────────────────────────────────────
# Set zsh as default shell
# ─────────────────────────────────────────────────────────────
if [[ "$SHELL" != *"zsh"* ]]; then
  echo "Setting zsh as default shell..."
  chsh -s $(which zsh)
fi

echo ""
echo "════════════════════════════════════════════════════════════"
echo "  Done!"
echo "════════════════════════════════════════════════════════════"
echo ""
echo "  Next steps:"
echo "  1. Restart your terminal (or run: source ~/.zshrc)"
echo "  2. Set terminal font to 'JetBrainsMono Nerd Font'"
echo ""
echo "  Tips:"
echo "  - Ghostty themes: run 'ghostty +list-themes' to see options"
echo "  - Use 'z <partial-dir>' to jump to directories with zoxide"
echo ""
