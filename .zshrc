export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

# Auto-start tmux
if command -v tmux &> /dev/null && [[ -z "$TMUX" ]]; then
  exec tmux new-session -A -s main
fi

alias vim="nvim"
alias vi="nvim"

# oh-my-zsh setup
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="refined"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git golang redis-cli docker docker-compose)
source $ZSH/oh-my-zsh.sh

# nvm setup (lazy-loaded for faster shell startup)
export NVM_DIR="$HOME/.nvm"
export BASH_ENV="$HOME/.bash_profile"  # For non-interactive bash (e.g., Claude Code)
lazy_load_nvm() {
  unset -f nvm node npm npx
  [ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
  [ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"
}
nvm() { lazy_load_nvm && nvm "$@"; }
node() { lazy_load_nvm && node "$@"; }
npm() { lazy_load_nvm && npm "$@"; }
npx() { lazy_load_nvm && npx "$@"; }

# ─────────────────────────────────────────────────────────────
# Navigation & Correction
# ─────────────────────────────────────────────────────────────
setopt AUTO_CD              # Type directory name to cd into it
setopt CORRECT              # Suggest corrections for commands
setopt CORRECT_ALL          # Suggest corrections for arguments too
SPROMPT='zsh: correct %F{red}%R%f to %F{green}%r%f? [y/n/a/e] '

# ─────────────────────────────────────────────────────────────
# History
# ─────────────────────────────────────────────────────────────
HISTFILE=~/.zsh_history
HISTSIZE=50000
SAVEHIST=50000
setopt SHARE_HISTORY        # Share history across terminals
setopt HIST_IGNORE_DUPS     # Don't save duplicate lines
setopt HIST_IGNORE_SPACE    # Don't save lines starting with space
setopt HIST_REDUCE_BLANKS   # Remove extra blanks
setopt INC_APPEND_HISTORY   # Add commands immediately

# ─────────────────────────────────────────────────────────────
# Tab Completion Styling
# ─────────────────────────────────────────────────────────────
zstyle ':completion:*' menu select                       # Arrow key menu
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'     # Case insensitive
zstyle ':completion:*' list-colors ${(s.:.)LS_COLORS}   # Colored completions
zstyle ':completion:*:descriptions' format '%F{yellow}── %d ──%f'

# ─────────────────────────────────────────────────────────────
# Plugins (via Homebrew)
# ─────────────────────────────────────────────────────────────
# Autosuggestions (ghost text from history)
[[ -f $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]] && \
  source $(brew --prefix)/share/zsh-autosuggestions/zsh-autosuggestions.zsh

# Syntax highlighting (green = valid, red = invalid)
[[ -f $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ]] && \
  source $(brew --prefix)/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fzf keybindings (ctrl+r for fuzzy history)
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# zoxide (smart cd replacement)
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# ─────────────────────────────────────────────────────────────
# eza (modern ls replacement)
# ─────────────────────────────────────────────────────────────
if command -v eza &> /dev/null; then
  alias ls='eza --color=always --icons'
  alias ll='eza -la --color=always --icons --git'
  alias lt='eza --tree --level=2 --icons'
fi

# ─────────────────────────────────────────────────────────────
# Local Configuration (secrets, machine-specific settings)
# ─────────────────────────────────────────────────────────────
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
