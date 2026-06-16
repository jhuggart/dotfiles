export PATH="$HOME/go/bin:$HOME/.local/bin:$PATH"

# Auto-start tmux (disabled - use `tmux new-session -A -s main` to enter manually)
# if command -v tmux &> /dev/null && [[ -z "$TMUX" ]]; then
#   exec tmux new-session -A -s main
# fi

alias vim="nvim"
alias vi="nvim"

# oh-my-zsh setup
export ZSH="$HOME/.oh-my-zsh"
ZSH_THEME="refined"
DISABLE_UNTRACKED_FILES_DIRTY="true"
plugins=(git golang redis-cli docker docker-compose)
source $ZSH/oh-my-zsh.sh

# nvm setup
export NVM_DIR="$HOME/.nvm"
export BASH_ENV="$HOME/.bash_profile"  # For non-interactive bash (e.g., Claude Code)
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

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

# Tab: complete first; accept the autosuggestion only when there's genuinely
# nothing to complete. We read $compstate[nmatches] (the real match count) via a
# completion widget rather than checking whether $BUFFER changed — an ambiguous
# prefix (e.g. "ls Do" with Documents/ + Downloads/) shows a menu WITHOUT changing
# the buffer, and we must not clobber that menu with history ghost text.
# Must come after the fzf source so this binding wins over fzf-completion.
_tab_complete_count() { _main_complete; _tab_nmatches=$compstate[nmatches]; }
zle -C _tab-complete-count .expand-or-complete _tab_complete_count

_tab_or_autosuggest() {
  _tab_nmatches=0
  zle _tab-complete-count
  if (( _tab_nmatches == 0 )); then
    # nothing to complete -> accept the autosuggestion if one is showing
    [[ -n $POSTDISPLAY ]] && zle autosuggest-accept
  else
    # completion ran -> clear any now-stale ghost text so it doesn't linger
    # after the inserted text (e.g. "ls nvim/" with a leftover "im" suggestion)
    [[ -n $POSTDISPLAY ]] && zle autosuggest-clear
  fi
}
zle -N _tab_or_autosuggest
bindkey '\t' _tab_or_autosuggest

# zoxide (smart cd replacement)
command -v zoxide &> /dev/null && eval "$(zoxide init zsh)"

# mise (runtime version manager - reads .ruby-version/.tool-versions)
command -v mise &> /dev/null && eval "$(mise activate zsh)"

# ─────────────────────────────────────────────────────────────
# eza (modern ls replacement)
# ─────────────────────────────────────────────────────────────
if command -v eza &> /dev/null; then
  # NOTE: --icons must carry an explicit =auto. With a bare --icons, eza's zsh
  # completion treats the next word as --icons's WHEN argument and offers
  # "always/auto/automatic/never" instead of completing filenames.
  alias ls='eza --color=always --icons=auto'
  alias ll='eza -la --color=always --icons=auto --git'
  alias lt='eza --tree --level=2 --icons=auto'
fi

# ─────────────────────────────────────────────────────────────
# Local Configuration (secrets, machine-specific settings)
# ─────────────────────────────────────────────────────────────
if [[ -f ~/.env.local ]]; then
  if [[ "$(stat -f '%Lp' ~/.env.local)" == "600" ]]; then
    source ~/.env.local
  else
    echo "WARNING: ~/.env.local has insecure permissions (expected 600), skipping"
  fi
fi
[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local
# CF CLI completions
[[ -f "$HOME/.config/cf/completions/_cf.zsh" ]] && source "$HOME/.config/cf/completions/_cf.zsh"
