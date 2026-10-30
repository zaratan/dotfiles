#!/usr/bin/env bash
# retard.sh <worktree> <base> : ce que la branche porte, son retard sur la base, et la prédiction de la fusion, sans
# toucher aux branches ni à l'index. Le travail non commité compte : l'arbre prédit vient d'un index temporaire
# (`git write-tree` seul lirait l'index, et la prédiction d'avant Review ne verrait jamais le diff de l'agent).
# Lecture seule, hors le `git fetch`.
set -euo pipefail

WT=${1:?usage: retard.sh <worktree> <base, ex. origin/main>}; BASE=${2:?base manquante, ex. origin/main}
test -d "$WT/.git" || test -f "$WT/.git" || { echo "pas un worktree git : $WT" >&2; exit 2; }
g() { git -C "$WT" "$@"; }

case "$BASE" in origin/*) g fetch -q origin ;; esac
g rev-parse --verify --quiet "$BASE" >/dev/null || { echo "base introuvable : $BASE" >&2; exit 2; }
branche=$(g rev-parse --abbrev-ref HEAD)
mb=$(g merge-base HEAD "$BASE")
read -r derriere devant <<< "$(g rev-list --left-right --count "$BASE...HEAD")"
dirty=$(g status --short | wc -l | tr -d ' ')

echo "## $branche contre $BASE"
echo "$devant commit(s) devant, $derriere derrière ; $dirty fichier(s) non commité(s) inclus dans la prédiction."
echo
echo "### Fichiers de la branche (depuis la base de fusion, jamais \`git diff $BASE\` à deux voies)"
g diff --stat "$mb" HEAD | tail -n 20
echo
echo "### Fusion prédite"
idx=$(mktemp); trap 'rm -f "$idx"' EXIT
GIT_INDEX_FILE=$idx g read-tree HEAD
GIT_INDEX_FILE=$idx g add -A
tree=$(GIT_INDEX_FILE=$idx g write-tree)
tmp=$(g commit-tree "$tree" -p HEAD -m "prédiction")
if out=$(g merge-tree --write-tree --name-only "$BASE" "$tmp" 2>&1); then
  echo "sans conflit textuel (un conflit sémantique reste possible : jouer la fusion dans un worktree jetable quand des fichiers sont partagés)"
else
  echo "CONFLIT sur :"
  echo "$out" | tail -n +2 | sed '/^$/q' | sed '/^$/d;s/^/  /'
  echo "$out" | sed '1,/^$/d' | sed 's/^/    /'
  exit 1
fi
