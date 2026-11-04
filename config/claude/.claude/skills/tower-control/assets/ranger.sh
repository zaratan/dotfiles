#!/usr/bin/env bash
# ranger.sh <dépôt des issues> <grappe> [--dry-run] [--sans-pr] : retire le worktree d'une grappe finie. Préconditions,
# chacune bloquante : PR de la branche mergée (sauf `--sans-pr` : grappe de QA ou jetable, qui n'a pas de PR), `git status
# --short` vide, aucun fichier ignoré hors dossiers de build ni hors `RANGER_IGNORE` du config.sh (un prototype n'a vécu
# que dans un `out/` sans commit ; une retouche non commitée a été perdue par un `--force`). Puis : `herdr workspace close`,
# `git worktree remove` sans `--force`, lien mémoire (dépôt unique), et la ligne du fichier de lot à retirer, imprimée,
# jamais éditée (sed -i diffère entre Mac et Linux). Rien d'autre : pas de `branch -D`.
set -euo pipefail

REPO=${1:?usage: ranger.sh <dépôt des issues> <grappe> [--dry-run] [--sans-pr]}; GRAPPE=${2:?grappe manquante}
DRY=0; SANS_PR=0
for opt in "${@:3}"; do
  case "$opt" in --dry-run) DRY=1 ;; --sans-pr) SANS_PR=1 ;; *) echo "option inconnue : $opt" >&2; exit 2 ;; esac
done
# shellcheck source=../../tc-commun/config-lib.sh
source "$(dirname "$0")/../../tc-commun/config-lib.sh"
: "${WORKTREES_DIR:?}"
spec=${GRAPPES[$GRAPPE]:?grappe inconnue dans $LOT : $GRAPPE}
r=$(tc_repo_of "$spec"); branche=$(tc_branch_of "$spec"); code=$(tc_path_of "$r")
WT="$WORKTREES_DIR/$GRAPPE"
test -d "$WT" || { echo "worktree absent : $WT" >&2; exit 2; }
# Un composant de chemin, où qu'il soit : dans un monorepo, apps/api/node_modules/ et packages/x/dist/ sont du build.
BUILD='(^|/)(node_modules|target|dist|\.next|\.turbo|__pycache__|\.venv|coverage|\.cache|\.husky/_)(/|$)|(\.tsbuildinfo|next-env\.d\.ts)$'
[ -z "${RANGER_IGNORE:-}" ] || BUILD="$BUILD|$RANGER_IGNORE"

if [ "$SANS_PR" = 1 ]; then
  merged=""
else
  slug=$(git -C "$code" remote get-url origin | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#')
  merged=$(gh pr list --repo "$slug" --head "$branche" --state merged --json number -q '.[].number' | head -1)
  [ -n "$merged" ] || { echo "REFUSÉ : aucune PR mergée pour $branche (grappe de QA ou jetable : --sans-pr)"; exit 3; }
fi
dirty=$(git -C "$WT" status --short); [ -z "$dirty" ] || { echo "REFUSÉ : fichiers non commités dans $WT"; echo "$dirty"; exit 3; }
ignored=$(git -C "$WT" status --short --ignored=matching | awk '$1=="!!"{print $2}' | grep -vE "$BUILD" || true)
[ -z "$ignored" ] || { echo "REFUSÉ : fichiers ignorés qui ne sont pas du build (prototype ? sorties ? à lister dans RANGER_IGNORE du config.sh ?) :"; echo "$ignored"; echo "les mettre sur une branche ou les supprimer, puis relancer"; exit 3; }

# Le worktree est listé par le dépôt du code (`--cwd`, un méta-dépôt n'en sait rien) ; sinon par le nom de l'agent, global à la machine (lancer.sh).
ws=$(herdr worktree list --cwd "$code" | jq -r --arg p "$WT" '.result.worktrees[]? | select((.path // "") == $p) | .open_workspace_id // empty' | head -1)
agent="$(basename "$REPO" | tr '[:upper:]' '[:lower:]')-$GRAPPE"
[ -n "$ws" ] || ws=$(herdr agent get "$agent" 2>/dev/null | jq -r '.result.agent.workspace_id // empty')
key="$HOME/.claude/projects/$(echo "$WT" | tr '/' '-')/memory"
if [ -n "$merged" ]; then echo "PR #$merged mergée, arbre propre. À faire :"; else echo "sans PR (--sans-pr), arbre propre. À faire :"; fi
echo "  herdr workspace close ${ws:-<workspace introuvable : herdr worktree list --cwd $code, herdr agent get $agent>}"
echo "  git -C $code worktree remove $WT"
[ -n "$r" ] || echo "  rm $key"
echo "  retirer du fichier de lot : GRAPPES[$GRAPPE] et ISSUES[$GRAPPE]"
[ "$DRY" = 1 ] && exit 0
[ -n "$ws" ] && herdr workspace close "$ws" >/dev/null
git -C "$code" worktree remove "$WT"
[ -n "$r" ] || rm -f "$key"
echo "fait ; la ligne du fichier de lot reste à retirer à la main"
