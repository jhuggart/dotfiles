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

# tmux
backup_if_exists ~/.tmux.conf
ln -s "$DOTFILES_DIR/.tmux.conf" ~/.tmux.conf
echo "  Linked .tmux.conf"

# ghostty
mkdir -p ~/.config/ghostty
backup_if_exists ~/.config/ghostty/config
ln -s "$DOTFILES_DIR/ghostty/config" ~/.config/ghostty/config
echo "  Linked ghostty/config"

# neovim
mkdir -p ~/.config
backup_if_exists ~/.config/nvim
ln -s "$DOTFILES_DIR/nvim" ~/.config/nvim
echo "  Linked nvim"

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
