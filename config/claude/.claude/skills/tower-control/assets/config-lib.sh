# shellcheck shell=bash
# À sourcer depuis un script bash, après avoir posé REPO (chemin du dépôt qui porte les issues) :
#   REPO=…; source "$(dirname "$0")/config-lib.sh"
# Charge .claude/tower-control/config.sh puis lot-<login GitHub>.sh, pose GH_LOGIN, LOT, CONFIG et les
# tableaux REPO_PATH, REPO_BASE, REPO_BOOTSTRAP, REPO_CHECK, REPO_PROD_START, GRAPPES, ISSUES. Voir config.example.sh.
# Sourcé au niveau du script, pas dans une fonction : un `declare -A` d'un fichier sourcé dans une fonction y resterait local.
[ "${BASH_VERSINFO[0]:-0}" -ge 4 ] || { echo "bash 4 requis (tableaux associatifs) ; /bin/bash du Mac est en 3.2, utiliser /usr/bin/env bash" >&2; exit 2; }
: "${REPO:?REPO doit être posé avant de sourcer config-lib.sh}"
CONFIG="$REPO/.claude/tower-control/config.sh"
test -f "$CONFIG" || { echo "config absente : $CONFIG" >&2; exit 2; }
declare -A REPO_PATH=() REPO_BASE=() REPO_BOOTSTRAP=() REPO_CHECK=() REPO_PROD_START=() GRAPPES=() ISSUES=()
# shellcheck source=/dev/null
source "$CONFIG"
GH_LOGIN=$(gh api user -q .login) && test -n "$GH_LOGIN" || { echo "login GitHub introuvable : gh auth status" >&2; exit 2; }
LOT="$REPO/.claude/tower-control/lot-$GH_LOGIN.sh"
if [ -f "$LOT" ]; then
  unset GRAPPES
  declare -A GRAPPES=()
  # shellcheck source=/dev/null
  source "$LOT"
elif [ ${#GRAPPES[@]} -gt 0 ]; then
  echo "attention : pas de $LOT, grappes lues dans $CONFIG ; à deux, ce sont peut-être celles de l'autre" >&2
fi

# Une grappe : "<branche>" en dépôt unique, "<dépôt> <branche>" en méta-dépôt. Clé de repli `_` pour le dépôt unique.
tc_repo_of() { case "$1" in *" "*) echo "${1%% *}" ;; *) echo "" ;; esac; }
tc_branch_of() { echo "${1##* }"; }
tc_path_of() { local r=$1; test -n "$r" && echo "${REPO_PATH[$r]:?dépôt inconnu dans REPO_PATH : $r}" || echo "$REPO"; }
tc_base_of() { local r=${1:-_}; echo "${REPO_BASE[$r]:-${BASE_BRANCH:-main}}"; }
tc_bootstrap_of() { local r=${1:-_}; echo "${REPO_BOOTSTRAP[$r]:-${BOOTSTRAP:-true}}"; }
tc_check_of() { local r=${1:-_}; echo "${REPO_CHECK[$r]:-true}"; }
tc_prod_start_of() { local r=${1:-_}; echo "${REPO_PROD_START[$r]:-${PROD_START:-}}"; }
