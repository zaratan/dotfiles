#!/usr/bin/env bash
# branche-suivante.sh <worktree> <branche> <base> [--dry-run] : crée la branche de l'issue suivante dans le worktree,
# depuis la base distante fraîche, sans suivi d'amont. Écriture git : sur demande explicite de l'utilisateur ou sous
# /tc-delegate seulement. Refuse un arbre sale (`switch -c` l'emporterait en silence). Une branche créée avec un amont
# a déjà poussé sur `main` ; trois agents sont partis sur des branches jamais créées par une boucle zsh.
set -euo pipefail

WT=${1:?usage: branche-suivante.sh <worktree> <branche> <base> [--dry-run]}; BR=${2:?branche manquante}; BASE=${3:?base manquante}
DRY=${4:-}
g() { git -C "$WT" "$@"; }

base=${BASE#origin/}
dirty=$(g status --short)
if [ -n "$dirty" ]; then echo "REFUSÉ : arbre non commité dans $WT"; echo "$dirty"; exit 3; fi
if g show-ref --verify --quiet "refs/heads/$BR"; then echo "REFUSÉ : la branche $BR existe déjà"; exit 3; fi

if [ "$DRY" = "--dry-run" ]; then
  echo "git -C $WT fetch -q origin"
  echo "git -C $WT switch -c $BR --no-track origin/$base"
  exit 0
fi
g fetch -q origin
g switch -q -c "$BR" --no-track "origin/$base"
head=$(g rev-parse --abbrev-ref HEAD)
[ "$head" = "$BR" ] || { echo "ÉCHEC : HEAD est $head, pas $BR"; exit 1; }
if g rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; then echo "ÉCHEC : $BR suit un amont, un push nu irait dessus"; exit 1; fi
echo "$BR créée dans $WT depuis origin/$base ($(g rev-parse --short HEAD)), sans amont"
