#!/usr/bin/env bash
# demarrer-prod.sh <dépôt des issues> <grappe> [--print] : démarre l'app du worktree comme en production, au premier
# plan (la tour le lance en arrière-plan puis arrête par le port). Recette : REPO_PROD_START[<dépôt>] ou PROD_START.
set -euo pipefail

REPO="${1:?usage: demarrer-prod.sh <dépôt des issues> <grappe> [--print]}"
GRAPPE="${2:?usage: demarrer-prod.sh <dépôt des issues> <grappe> [--print]}"
# shellcheck source=config-lib.sh
source "$(dirname "$0")/config-lib.sh"

: "${WORKTREES_DIR:?}"
WT="$WORKTREES_DIR/$GRAPPE"
test -d "$WT" || { echo "worktree absent : $WT" >&2; exit 2; }

r=$(tc_repo_of "${GRAPPES[$GRAPPE]:-}")
cmd=$(tc_prod_start_of "$r")
test -n "$cmd" || { echo "aucune recette de démarrage pour ${r:-ce dépôt} dans $CONFIG" >&2; exit 2; }

if [ "${3:-}" = "--print" ]; then
  echo "cd $WT && $cmd"
  exit 0
fi
cd "$WT"
exec bash -c "$cmd"
