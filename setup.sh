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
# Install dependencies
# ─────────────────────────────────────────────────────────────
echo "Installing dependencies..."
brew install neovim
brew install zsh-autosuggestions
brew install zsh-syntax-highlighting
brew install fzf
brew install eza
brew install nvm

# Set up fzf key bindings
$(brew --prefix)/opt/fzf/install --key-bindings --completion --no-bash --no-fish --no-update-rc -y

# Install Nerd Font
echo "Installing Nerd Font..."
brew install --cask font-jetbrains-mono-nerd-font

# ─────────────────────────────────────────────────────────────
# Create symlinks
# ─────────────────────────────────────────────────────────────
echo "Creating symlinks..."

# Backup existing files
backup_if_exists() {
  if [[ -e "$1" && ! -L "$1" ]]; then
    echo "  Backing up $1 to $1.backup"
    mv "$1" "$1.backup"
  elif [[ -L "$1" ]]; then
    rm "$1"
  fi
}

# zsh
backup_if_exists ~/.zshrc
ln -s "$DOTFILES_DIR/.zshrc" ~/.zshrc
echo "  Linked .zshrc"

# ghostty
mkdir -p ~/.config/ghostty
backup_if_exists ~/.config/ghostty/config
ln -s "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
echo "  Linked ghostty/config"

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
echo "  Ghostty themes: run 'ghostty +list-themes' to see options"
echo ""
