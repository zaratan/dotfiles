#!/usr/bin/env bash
# ranger.sh <dépôt des issues> <grappe> [--dry-run] : retire le worktree d'une grappe finie. Préconditions, chacune
# bloquante : PR de la branche mergée, `git status --short` vide, aucun fichier ignoré hors dossiers de build (un
# prototype n'a vécu que dans un `out/` sans commit ; une retouche non commitée a été perdue par un `--force`).
# Puis : `herdr workspace close`, `git worktree remove` sans `--force`, lien mémoire (dépôt unique), et la ligne du
# fichier de lot à retirer, imprimée, jamais éditée (sed -i diffère entre Mac et Linux). Rien d'autre : pas de `branch -D`.
set -euo pipefail

REPO=${1:?usage: ranger.sh <dépôt des issues> <grappe> [--dry-run]}; GRAPPE=${2:?grappe manquante}; DRY=${3:-}
# shellcheck source=../../tc-commun/config-lib.sh
source "$(dirname "$0")/../../tc-commun/config-lib.sh"
: "${WORKTREES_DIR:?}"
spec=${GRAPPES[$GRAPPE]:?grappe inconnue dans $LOT : $GRAPPE}
r=$(tc_repo_of "$spec"); branche=$(tc_branch_of "$spec"); code=$(tc_path_of "$r")
WT="$WORKTREES_DIR/$GRAPPE"
test -d "$WT" || { echo "worktree absent : $WT" >&2; exit 2; }
BUILD='^(node_modules|target|dist|\.next|\.turbo|__pycache__|\.venv|coverage|\.cache)(/|$)'

slug=$(git -C "$code" remote get-url origin | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#')
merged=$(gh pr list --repo "$slug" --head "$branche" --state merged --json number -q '.[].number' | head -1)
[ -n "$merged" ] || { echo "REFUSÉ : aucune PR mergée pour $branche"; exit 3; }
dirty=$(git -C "$WT" status --short); [ -z "$dirty" ] || { echo "REFUSÉ : fichiers non commités dans $WT"; echo "$dirty"; exit 3; }
ignored=$(git -C "$WT" status --short --ignored | awk '$1=="!!"{print $2}' | grep -vE "$BUILD" || true)
[ -z "$ignored" ] || { echo "REFUSÉ : fichiers ignorés qui ne sont pas du build (prototype ? sorties ?) :"; echo "$ignored"; echo "les mettre sur une branche ou les supprimer, puis relancer"; exit 3; }

ws=$(herdr worktree list | jq -r --arg p "$WT" '.. | objects | select((.path // "") == $p) | .workspace_id // empty' | head -1)
key="$HOME/.claude/projects/$(echo "$WT" | tr '/' '-')/memory"
echo "PR #$merged mergée, arbre propre. À faire :"
echo "  herdr workspace close ${ws:-<workspace introuvable : herdr worktree list>}"
echo "  git -C $code worktree remove $WT"
[ -n "$r" ] || echo "  rm $key"
echo "  retirer du fichier de lot : GRAPPES[$GRAPPE] et ISSUES[$GRAPPE]"
[ "$DRY" = "--dry-run" ] && exit 0
[ -n "$ws" ] && herdr workspace close "$ws" >/dev/null
git -C "$code" worktree remove "$WT"
[ -n "$r" ] || rm -f "$key"
echo "fait ; la ligne du fichier de lot reste à retirer à la main"
