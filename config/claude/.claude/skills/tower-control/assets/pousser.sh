#!/usr/bin/env bash
# pousser.sh <worktree> <base> [--dry-run] : pousse la branche d'issue du worktree, sous /tc-delegate seulement.
# Avant : l'arbre affiché, HEAD différent de la base, chaque commit nouveau signé si le dépôt signe. Push par refspec
# explicite (jamais `-u`, jamais la base, jamais `--force`), puis la branche relue sur origin. Un commit échoué et
# masqué a déjà fait pousser une branche égale à la base ; `push.default = upstream` a déjà poussé sur `main`.
set -euo pipefail

WT=${1:?usage: pousser.sh <worktree> <base, ex. origin/main> [--dry-run]}; BASE=${2:?base manquante}; DRY=${3:-}
g() { git -C "$WT" "$@"; }

BR=$(g rev-parse --abbrev-ref HEAD)
base=${BASE#origin/}
[ "$BR" != "$base" ] && [ "$BR" != HEAD ] || { echo "REFUSÉ : HEAD est sur $BR"; exit 3; }
g fetch -q origin
echo "## $BR → origin/$BR"
dirty=$(g status --short); [ -z "$dirty" ] || { echo "Non commité (restera sur le poste) :"; echo "$dirty"; }
[ "$(g rev-parse HEAD)" != "$(g rev-parse "origin/$base")" ] || { echo "REFUSÉ : HEAD égale origin/$base, rien à pousser (commit échoué ?)"; exit 3; }
if [ "$(g config --get commit.gpgsign || true)" = true ]; then
  for sha in $(g rev-list "origin/$base..HEAD"); do
    [ "$(g cat-file commit "$sha" | grep -c '^gpgsig')" -ge 1 ] || { echo "REFUSÉ : $(g rev-parse --short "$sha") n'est pas signé"; exit 3; }
  done
fi
echo "$(g rev-list --count "origin/$base..HEAD") commit(s) à pousser, tête $(g rev-parse --short HEAD)"
if [ "$DRY" = "--dry-run" ]; then echo "git -C $WT push origin \"refs/heads/${BR}:refs/heads/${BR}\""; exit 0; fi
g push origin "refs/heads/${BR}:refs/heads/${BR}"
g ls-remote --exit-code --heads origin "$BR" >/dev/null || { echo "ÉCHEC : $BR absente d'origin après le push"; exit 1; }
echo "poussée ; gh pr create peut partir"
