#!/usr/bin/env bash
# avancement.sh <dépôt des issues> [--board] : le tableau des agents du projet pour le point (tc-lot/assets/point.md).
# Agents herdr nommés `<dépôt>-<grappe>` par lancer.sh, ou dont le cwd est le dépôt ou un worktree ; la tour elle-même
# ($HERDR_PANE_ID) est exclue. Contexte % : fichier ~/.claude/tower-control/ctx/<session> écrit par la ligne d'état.
# « Depuis » : dernière écriture du transcript de l'agent. --board ajoute la colonne du board (une lecture, à la demande).
set -euo pipefail

REPO=${1:?usage: avancement.sh <dépôt des issues> [--board]}
BOARD=${2:-}
# shellcheck source=../../tc-commun/config-lib.sh
source "$(dirname "$0")/../../tc-commun/config-lib.sh"
command -v herdr >/dev/null || { echo "herdr absent du PATH" >&2; exit 2; }
list=$(herdr agent list) || { echo "herdr ne répond pas" >&2; exit 2; }

prefix="$(basename "$REPO" | tr '[:upper:]' '[:lower:]')-"
agents=$(echo "$list" | jq -c --arg p "$prefix" --arg r "$REPO/" --arg w "${WORKTREES_DIR:-/nonexistent}/" --arg me "${HERDR_PANE_ID:-}" '
  .result.agents[]
  | select(.pane_id != $me)
  | select(((.name // "") | startswith($p)) or ((.cwd + "/") | startswith($r)) or ((.cwd + "/") | startswith($w)))
  | {name: (.name // ""), status: .agent_status, cwd, session: (.agent_session.value // ""), title: (.terminal_title_stripped // "")}')
if [ -z "$agents" ]; then echo "Aucun agent herdr pour $(basename "$REPO") (nom préfixé $prefix, ou cwd sous $REPO)."; exit 0; fi

board_status() { echo ""; }
if [ "$BOARD" = "--board" ]; then
  : "${PROJECT_OWNER:?}" "${PROJECT_NUMBER:?}"
  items=$(gh project item-list "$PROJECT_NUMBER" --owner "$PROJECT_OWNER" --limit 500 --format json)
  board_status() { echo "$items" | jq -r --argjson n "${1:-0}" '.items[] | select(.content.number == $n) | .status // ""' | head -1; }
  echo "| Grappe | Issue | Board | État | Depuis | Contexte | Fait | ETA | Titre de l'agent |"
  echo "|---|---|---|---|---|---|---|---|---|"
else
  echo "| Grappe | Issue | État | Depuis | Contexte | Fait | ETA | Titre de l'agent |"
  echo "|---|---|---|---|---|---|---|---|"
fi

now=$(date +%s)
while IFS= read -r a; do
  name=$(echo "$a" | jq -r .name); status=$(echo "$a" | jq -r .status); cwd=$(echo "$a" | jq -r .cwd)
  session=$(echo "$a" | jq -r .session); title=$(echo "$a" | jq -r .title)
  grappe=${name#"$prefix"}; [ -n "$grappe" ] || grappe="(sans nom, $(basename "$cwd"))"
  issue=${ISSUES[$grappe]:-}
  ctx="?"; f="$HOME/.claude/tower-control/ctx/$session"; [ -n "$session" ] && [ -f "$f" ] && ctx="$(command cat "$f") %"
  depuis="?"
  t="$HOME/.claude/projects/$(echo "$cwd" | tr '/' '-')/$session.jsonl"
  if [ -n "$session" ] && [ -f "$t" ]; then
    age=$(( (now - $(date -r "$t" +%s)) / 60 ))
    if [ "$age" -ge 60 ]; then depuis="$((age / 60)) h $((age % 60)) min"; else depuis="$age min"; fi
  fi
  case "$status" in blocked) etat="question" ;; working) etat="travaille" ;; idle|done) etat="arrêté" ;; *) etat="$status" ;; esac
  if [ "$BOARD" = "--board" ]; then
    echo "| $grappe | ${issue:+#}$issue | $(board_status "$issue") | $etat | $depuis | $ctx | | | $title |"
  else
    echo "| $grappe | ${issue:+#}$issue | $etat | $depuis | $ctx | | | $title |"
  fi
done <<< "$agents"
