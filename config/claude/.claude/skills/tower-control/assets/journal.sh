#!/usr/bin/env bash
# journal.sh <dépôt des issues> <n> : la table Issue | Pts | PR | Merge | État du lot <n> (label `lot: <n>`) et sa ligne
# d'ordres de grandeur, en Markdown, pour la section du journal (tc-lot/assets/journal-lot.md). Lecture seule.
set -euo pipefail

REPO=${1:?usage: journal.sh <dépôt des issues> <numéro de lot>}
LOT_N=${2:?numéro de lot manquant}
# shellcheck source=config-lib.sh
source "$(dirname "$0")/config-lib.sh"
: "${ISSUES_REPO:?}" "${PROJECT_OWNER:?}" "${PROJECT_NUMBER:?}"

issues=$(gh issue list --repo "$ISSUES_REPO" --state all --label "lot: $LOT_N" --limit 200 --json number,title,state)
count=$(echo "$issues" | jq length)
[ "$count" -gt 0 ] || { echo "aucune issue avec le label « lot: $LOT_N » dans $ISSUES_REPO" >&2; exit 1; }
items=$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --limit 500 --format json)

rows=""; pr_total=0
for n in $(echo "$issues" | jq -r '.[].number'); do
  title=$(echo "$issues" | jq -r --argjson n "$n" '.[] | select(.number == $n) | .title' | cut -c1-60)
  state=$(echo "$issues" | jq -r --argjson n "$n" '.[] | select(.number == $n) | .state')
  pts=$(echo "$items" | jq -r --argjson n "$n" '.items[] | select(.content.number == $n) | .points // ""' | head -1)
  prs=$(gh issue view "$n" --repo "$ISSUES_REPO" --json closedByPullRequestsReferences \
    | jq -r '.closedByPullRequestsReferences[]? | "\(.repository.owner.login)/\(.repository.name) \(.number)"')
  pr_cells=""; merge_cells=""; merged_at=""
  while read -r prrepo prnum; do
    [ -n "$prnum" ] || continue
    pr=$(gh pr view "$prnum" --repo "$prrepo" --json mergedAt,mergeCommit)
    at=$(echo "$pr" | jq -r '.mergedAt // ""'); sha=$(echo "$pr" | jq -r '.mergeCommit.oid // "" | .[0:7]')
    pr_cells="${pr_cells:+$pr_cells, }#$prnum"; merge_cells="${merge_cells:+$merge_cells, }${sha:+\`$sha\`}"
    pr_total=$((pr_total + 1))
    if [ -n "$at" ] && { [ -z "$merged_at" ] || [[ "$at" > "$merged_at" ]]; }; then merged_at=$at; fi
  done <<< "$prs"
  if [ "$state" = CLOSED ]; then etat="Fait, lot: $LOT_N"; else etat="Ouverte"; fi
  rows+="${merged_at:-9999}	| #$n $title | $pts | $pr_cells | $merge_cells | $etat |
"
done

echo "| Issue | Pts | PR | Merge | État |"
echo "|---|---|---|---|---|"
printf '%s' "$rows" | sort | cut -f2-

total_pts=$(echo "$items" | jq -r --argjson ns "$(echo "$issues" | jq -c '[.[].number]')" '[.items[] | select(.content.number as $n | $ns | index($n)) | .points // 0] | add // 0')
first=$(printf '%s' "$rows" | sort | head -1 | cut -f1); last=$(printf '%s' "$rows" | sort | /usr/bin/grep -v '^9999' | tail -1 | cut -f1)
echo
echo "**Ordres de grandeur.** <forme du projet> · $count issues · $total_pts pts · $pr_total PR · <agents max> agents · merges de ${first:0:16} à ${last:0:16} · <retouches>/<comptes rendus> retouches · <min/issue> · <questions>"
