# `path` sans doublons : les exports ci-dessous sont en prefixe:$PATH et
# s'empilaient à chaque évaluation du fichier (login -> tmux -> pane).
# zsh garde la première occurrence, donc l'ordre de priorité est préservé.
typeset -U path PATH

command -v gdircolors >/dev/null && eval "$(gdircolors ~/.dircolors.256dark)"
ZSH_DISABLE_COMPFIX=true
export ZSH=$HOME/.oh-my-zsh
ZSH_THEME="agnoster"

# Avant oh-my-zsh : son plugin tmux démarre le serveur pendant le source,
# et tmux dérive mode-keys/status-keys de $EDITOR à cet instant-là.
export EDITOR='nvim'

# prompt

plugins=(git brew bundler docker gem gh tmux npm macos rails z yarn docker-compose)
export RPS1='($(date -u "+%m/%d %H:%M:%S"))'
export ZSH_TMUX_AUTOSTART=true
export ZSH_TMUX_AUTOQUIT=false

# mise completions must be in fpath before oh-my-zsh runs compinit.
# mise n'est pas encore dans le PATH ici (construit plus bas), d'où le
# chemin explicite. Le fichier est régénéré si le binaire change.
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
# Pas de LC_ALL : il écrase toutes les catégories. LANG suffit pour la
# collation. LC_NUMERIC reste en C, sinon awk/bc/time sortent "3,50"
# et tout script qui parse un nombre casse. Le unset est nécessaire : un
# shell imbriqué hérite sinon du LC_ALL posé par une session plus ancienne.
unset LC_ALL
export LC_NUMERIC=C

export PATH="$HOME/.cargo/bin:$PATH"

[ -L ~/.fzf ] && source ~/.fzf

# Kubectl
if (( $+commands[kubectl] )); then
  # ~110 ms à générer : on met en cache, régénéré si le binaire change
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

# mise gère node/ruby/python et les outils globaux. Son hook recalcule le
# PATH à chaque prompt : plus de shims à régénérer après un gem install.
eval "$(mise activate zsh)"

# En fin de course : ce qui est défini ici doit gagner sur tous les
# export PATH ci-dessus (sinon les runtimes de mise passent devant).
if [ -e "$HOME/.zshrc.local" ]; then
  source "$HOME/.zshrc.local"
fi

# Must stay sourced last so it can hook everything defined above
[ -r /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh ] && \
  source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
