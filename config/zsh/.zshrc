typeset -U path PATH

command -v gdircolors >/dev/null && eval "$(gdircolors ~/.dircolors.256dark)"
ZSH_DISABLE_COMPFIX=true
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="agnoster"

# Before oh-my-zsh: its tmux plugin reads $EDITOR when starting the server
export EDITOR='nvim'

# prompt

plugins=(git brew bundler docker gem gh tmux npm macos rails z yarn docker-compose)
export RPS1='($(date -u "+%m/%d %H:%M:%S"))'
export ZSH_TMUX_AUTOSTART=true
export ZSH_TMUX_AUTOQUIT=false

# mise completions must be in fpath before oh-my-zsh runs compinit
_mise_bin="$HOME/.local/bin/mise"
_mise_comp="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/completions"
if [[ -x $_mise_bin ]]; then
  if [[ ! -s $_mise_comp/_mise || $_mise_bin -nt $_mise_comp/_mise ]]; then
    mkdir -p "$_mise_comp"
    "$_mise_bin" completion zsh > "$_mise_comp/_mise"
  fi
  fpath=("$_mise_comp" $fpath)
fi
unset _mise_bin _mise_comp

source $ZSH/oh-my-zsh.sh

if [ -e "$HOME/.aliases" ]; then
  source "$HOME/.aliases"
fi

# User configuration
#

export PATH="$HOME/bin:/opt/homebrew/sbin:/opt/homebrew/bin:/usr/local/bin:$PATH"
export PATH="/opt/homebrew/opt/coreutils/libexec/gnubin:$PATH"


#z

command -v direnv >/dev/null && eval "$(direnv hook zsh)"
[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ] && \
  source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
export ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=6'

export LANG=fr_FR.UTF-8
# No LC_ALL: it overrides LC_NUMERIC too, and awk/bc then print "3,50"
unset LC_ALL
export LC_NUMERIC=C

export PATH="$HOME/.cargo/bin:$PATH"

[ -L ~/.fzf ] && source ~/.fzf

# Kubectl
if (( $+commands[kubectl] )); then
  # ~110 ms to generate: cache it, regenerated when the binary changes
  _kubectl_comp="${ZSH_CACHE_DIR:-$HOME/.cache}/kubectl-completion.zsh"
  if [[ ! -s $_kubectl_comp || $commands[kubectl] -nt $_kubectl_comp ]]; then
    mkdir -p "${_kubectl_comp:h}"
    kubectl completion zsh > "$_kubectl_comp"
  fi
  source "$_kubectl_comp"
  unset _kubectl_comp
fi

# BAT
export BAT_THEME="Solarized (dark)"
export GPG_TTY=$(tty)
export PATH="/opt/homebrew/opt/rustup/bin:$PATH"
export PATH="/opt/homebrew/opt/postgresql@17/bin:$PATH"

# pnpm
export PNPM_HOME="$HOME/Library/pnpm"
export PATH="$PNPM_HOME:$PNPM_HOME/bin:$PATH"
# pnpm end

# Java
if [ -z "${JAVA_HOME:-}" ] && [ -x /usr/libexec/java_home ]; then
  _java_home="$(/usr/libexec/java_home -v 25 2>/dev/null)" && export JAVA_HOME="$_java_home"
  unset _java_home
fi
# Java end

export PATH="$HOME/.local/bin:$PATH"

eval "$(mise activate zsh)"

# Last: what is set here must win over the PATH exports above
if [ -e "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# Must stay sourced last so it can hook everything defined above
[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
