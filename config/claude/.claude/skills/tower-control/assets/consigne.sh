#!/usr/bin/env bash
# consigne.sh <dépôt des issues> <fichier> [--retouche | --qa] [--lot <fragment>] [--out <dossier>]
# Assemble ce qu'un agent reçoit et l'écrit dans <dossier>/envoyee-<nom>.md (défaut : envoyees/ à côté du fichier),
# puis imprime le chemin. Issue : consigne commune du skill + consigne-projet.md + fragment de lot + consigne.
# Retouche, fusion, QA : le fichier seul. Le fragment « shells » s'ajoute dans tous les cas.
# Le modèle commun est toujours celui du skill : une copie par lot avait dérivé de 28 lignes en trois lots.
set -euo pipefail

REPO=${1:?usage: consigne.sh <dépôt des issues> <fichier> [--retouche | --qa] [--lot <fragment>] [--out <dossier>]}
FICHIER=${2:?fichier de consigne manquant}
shift 2
MODE=issue; LOTFRAG=""; OUT=""
while [ $# -gt 0 ]; do
  case "$1" in
    --retouche) MODE=retouche ;;
    --qa) MODE=qa ;;
    --lot) LOTFRAG=${2:?fragment manquant après --lot}; shift ;;
    --out) OUT=${2:?dossier manquant après --out}; shift ;;
    *) echo "option inconnue : $1" >&2; exit 2 ;;
  esac
  shift
done
test -f "$FICHIER" || { echo "fichier absent : $FICHIER" >&2; exit 2; }
[ -z "$LOTFRAG" ] || test -f "$LOTFRAG" || { echo "fragment absent : $LOTFRAG" >&2; exit 2; }

ASSETS=$(cd "$(dirname "$0")" && pwd)
TC="$REPO/.claude/tower-control"
CONFIG="$TC/config.sh"
test -f "$CONFIG" || { echo "config absente : $CONFIG" >&2; exit 2; }
# Lecture sans gh ni réseau : seule ISSUES_REPO sert ici, et la consigne se prépare aussi hors ligne.
ISSUES_REPO=$(REPO="$REPO" bash -c 'source "$1" >/dev/null 2>&1; printf %s "${ISSUES_REPO:-}"' _ "$CONFIG")
test -n "$ISSUES_REPO" || { echo "ISSUES_REPO absent de $CONFIG" >&2; exit 2; }

OUT=${OUT:-$(dirname "$FICHIER")/envoyees}
mkdir -p "$OUT"
DEST="$OUT/envoyee-$(basename "$FICHIER" .md).md"

projet() {
  local f="$TC/consigne-projet.md"
  test -f "$f" || { echo "consigne-projet.md absente : $f" >&2; exit 2; }
  sed '1{/^## Projet[[:space:]]*$/d;}' "$f"
}

{
  if [ "$MODE" = issue ]; then
    sed -e "s|<dépôt des issues>|$ISSUES_REPO|g" -e '/^<!-- Section fournie par le dépôt/,$d' "$ASSETS/consigne-commune.md"
    projet
    echo
    if [ -n "$LOTFRAG" ]; then command cat "$LOTFRAG"; echo; fi
    command cat "$ASSETS/consigne-shells.md"
    echo
    command cat "$FICHIER"
  else
    command cat "$FICHIER"
    echo
    command cat "$ASSETS/consigne-shells.md"
  fi
} > "$DEST"
echo "$DEST"
