#!/usr/bin/env bash
# board.sh lire <dépôt des issues>            : le board en Markdown, par colonne, avec assignés, points, priorité.
# board.sh assigner <dépôt des issues> <N>    : s'assigne l'issue, relit, se retire si quelqu'un d'autre y est.
# Deux pièges silencieux de gh : sans --limit la lecture s'arrête à 30 items, et `.assignees` est absent quand personne
# n'est assigné. L'assignation n'est pas un verrou : deux tours qui lisent en même temps s'assignent toutes les deux.
set -euo pipefail

CMD=${1:?usage: board.sh lire <dépôt> | assigner <dépôt> <N>}
REPO=${2:?dépôt des issues manquant}
# shellcheck source=../../tc-commun/config-lib.sh
source "$(dirname "$0")/../../tc-commun/config-lib.sh"
: "${ISSUES_REPO:?}" "${PROJECT_OWNER:?}" "${PROJECT_NUMBER:?}"

case "$CMD" in
  lire)
    gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --limit 500 --format json \
      | jq -r --arg me "$GH_LOGIN" '
        def ordre: {"Backlog":0,"À faire":1,"En cours":2,"Bloqué":3,"Review":4,"Fait":5};
        [.items[] | select(.content.number != null) | select((.status // "") != "Fait")]
        | sort_by((ordre[.status // ""] // 9), (.["priorité"] // "P9"), .content.number)
        | "| Colonne | Issue | Prio | Pts | Assignés | Titre |", "|---|---|---|---|---|---|",
          (.[] | "| \(.status // "(sans statut)") | #\(.content.number) | \(.["priorité"] // "") | \(.points // "") | \(((.assignees // []) | join(", ")) | if . == "" then "personne" elif . == $me then "moi" else . end) | \(.title[0:70]) |")' ;;
  assigner)
    N=${3:?"numéro d'issue manquant"}
    gh issue edit "$N" --repo "$ISSUES_REPO" --add-assignee @me >/dev/null
    sleep 1
    who=$(gh issue view "$N" --repo "$ISSUES_REPO" --json assignees -q '[.assignees[].login] | join(" ")')
    case " $who " in
      " $GH_LOGIN ") echo "#$N assignée à $GH_LOGIN, seul" ;;
      *" $GH_LOGIN "*) gh issue edit "$N" --repo "$ISSUES_REPO" --remove-assignee @me >/dev/null
                       echo "#$N CO-ASSIGNÉE ($who) : retiré, ne pas lancer, le dire à l'utilisateur"; exit 3 ;;
      *) echo "#$N : l'assignation n'a pas pris (assignés : ${who:-personne}), ne pas lancer"; exit 4 ;;
    esac ;;
  *) echo "commande inconnue : $CMD" >&2; exit 2 ;;
esac
