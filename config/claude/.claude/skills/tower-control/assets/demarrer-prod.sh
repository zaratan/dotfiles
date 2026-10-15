#!/usr/bin/env bash
# Démarre l'app d'un worktree comme en production (build puis start), au premier plan : à lancer en arrière-plan
# par la tour pour revérifier un écran, puis arrêter par le port. La recette est propre au projet :
# REPO_PROD_START[<dépôt>] dans config.sh (ou PROD_START en dépôt unique), exécutée dans le worktree.
set -euo pipefail

REPO="${1:?usage: demarrer-prod.sh <dépôt des issues> <grappe> [--print]}"
GRAPPE="${2:?usage: demarrer-prod.sh <dépôt des issues> <grappe> [--print]}"
CONFIG="$REPO/.claude/tower-control/config.sh"
test -f "$CONFIG" || { echo "config absente : $CONFIG" >&2; exit 2; }
# shellcheck source=/dev/null
source "$CONFIG"
GH_LOGIN=$(gh api user -q .login)
LOT="$REPO/.claude/tower-control/lot-$GH_LOGIN.sh"
# shellcheck source=/dev/null
[ -f "$LOT" ] && source "$LOT"

: "${WORKTREES_DIR:?}"
WT="$WORKTREES_DIR/$GRAPPE"
test -d "$WT" || { echo "worktree absent : $WT" >&2; exit 2; }

spec="${GRAPPES[$GRAPPE]:-}"
case "$spec" in *" "*) r="${spec%% *}" ;; *) r="" ;; esac
if [ -n "$r" ]; then
  declare -p REPO_PROD_START >/dev/null 2>&1 || { echo "REPO_PROD_START absent de $CONFIG" >&2; exit 2; }
  cmd="${REPO_PROD_START[$r]:-}"
else
  cmd="${PROD_START:-}"
fi
test -n "$cmd" || { echo "aucune recette de démarrage pour ${r:-ce dépôt} dans $CONFIG" >&2; exit 2; }

if [ "${3:-}" = "--print" ]; then
  echo "cd $WT && $cmd"
  exit 0
fi
cd "$WT"
exec bash -c "$cmd"
