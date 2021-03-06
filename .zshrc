# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load.
# Look in ~/.oh-my-zsh/themes/
# Optionally, if you set this to "random", it'll load a random theme each
# time that oh-my-zsh is loaded.
ZSH_THEME="gallifrey"

# Uncomment the following line to use case-sensitive completion.
# CASE_SENSITIVE="true"

# Uncomment the following line to disable bi-weekly auto-update checks.
# DISABLE_AUTO_UPDATE="true"

# Uncomment the following line to change how often to auto-update (in days).
# export UPDATE_ZSH_DAYS=13

# Uncomment the following line to disable colors in ls.
# DISABLE_LS_COLORS="true"

# Uncomment the following line to disable auto-setting terminal title.
DISABLE_AUTO_TITLE="true"

# Uncomment the following line to enable command auto-correction.
# ENABLE_CORRECTION="true"

# Uncomment the following line to display red dots whilst waiting for completion.
# COMPLETION_WAITING_DOTS="true"

# Uncomment the following line if you want to disable marking untracked files
# under VCS as dirty. This makes repository status check for large repositories
# much, much faster.
# DISABLE_UNTRACKED_FILES_DIRTY="true"

# Uncomment the following line if you want to change the command execution time
# stamp shown in the history command output.
# The optional three formats: "mm/dd/yyyy"|"dd.mm.yyyy"|"yyyy-mm-dd"
# HIST_STAMPS="mm/dd/yyyy"

# Would you like to use another custom folder than $ZSH/custom?
# ZSH_CUSTOM=/path/to/new-custom-folder

# Which plugins would you like to load? (plugins can be found in ~/.oh-my-zsh/plugins/*)
# Custom plugins may be added to ~/.oh-my-zsh/custom/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git docker)

source $ZSH/oh-my-zsh.sh

# User configuration

export PATH="/usr/local/bin:${PATH}:/Users/jhuggart/.rvm/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:/usr/local/bin:/opt/X11/bin:/usr/local/git/bin:/Users/jhuggart/bin:/Applications/Postgres.app/Contents/Versions/9.3/bin:/Users/jhuggart/bin:/Applications/Postgres.app/Contents/Versions/9.3/bin:/Users/jhuggart/Library/Android/sdk/tools:/Users/jhuggart/Library/Android/sdk/platform-tools:Users/jhuggart/gradle-2.1.1/bin"

export ANDROID_HOME=/usr/local/opt/android-sdk
# export MANPATH="/usr/local/man:$MANPATH"

# You may need to manually set your language environment
# export LANG=en_US.UTF-8

# Preferred editor for local and remote sessions
# if [[ -n $SSH_CONNECTION ]]; then
#   export EDITOR='vim'
# else
#   export EDITOR='mvim'
# fi

# Compilation flags
# export ARCHFLAGS="-arch x86_64"

# ssh
# export SSH_KEY_PATH="~/.ssh/dsa_id"

# Set personal aliases, overriding those provided by oh-my-zsh libs,
# plugins, and themes. Aliases can be placed here, though oh-my-zsh
# users are encouraged to define aliases within the ZSH_CUSTOM folder.
# For a full list of active aliases, run `alias`.
#

alias rld='source ~/.zshrc'
alias pg='phonegap'
alias pgs='phonegap serve'
alias pra='phonegap run android'
alias prad='phonegap run android --device'

alias sd='docker-machine start default && eval "$(docker-machine env default)"'

alias fuck='eval $(thefuck $(fc -ln -1 | tail -n 1)); fc -R'

#teamocil autocomplete
compctl -g '~/.teamocil/*(:t:r)' teamocil
#
# Example aliases
# alias zshconfig="mate ~/.zshrc"
# alias ohmyzsh="mate ~/.oh-my-zsh"
alias tw="teamocil --here well"
#alias vim="mvim -v"

#ulimit -n 16384
#ulimit -u 2048

export PATH="$PATH:$HOME/.rvm/bin" # Add RVM to PATH for scripting

[ -s "/Users/jhuggart/.kre/kvm/kvm.sh" ] && . "/Users/jhuggart/.kre/kvm/kvm.sh" # Load kvm

#nvm
export NVM_DIR=~/.nvm
source $(brew --prefix nvm)/nvm.sh

#set docker env vars
#eval "$(docker-machine env default)"
