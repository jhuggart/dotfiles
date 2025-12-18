export PATH="$HOME/.local/bin:$PATH"

alias vim="nvim"
alias vi="nvim"

# nvm setup
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

# git completion
autoload -Uz compinit && compinit

# Git branch for prompt
autoload -Uz vcs_info
precmd() { vcs_info }
zstyle ':vcs_info:git:*' formats ' %F{magenta}(%b)%f'
setopt PROMPT_SUBST

# Prompt: directory (cyan) + git branch (magenta) + arrow (green)
PROMPT='%F{cyan}%~%f${vcs_info_msg_0_} %F{green}❯%f '

# Right prompt: timestamp
RPROMPT='%F{240}%*%f'

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

# ─────────────────────────────────────────────────────────────
# eza (modern ls replacement)
# ─────────────────────────────────────────────────────────────
if command -v eza &> /dev/null; then
  alias ls='eza --color=always --icons'
  alias ll='eza -la --color=always --icons --git'
  alias lt='eza --tree --level=2 --icons'
fi
