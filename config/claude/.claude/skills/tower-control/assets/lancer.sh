#!/usr/bin/env bash
# Crée un worktree herdr par grappe, l'amorce, lie la mémoire et y démarre un agent Claude.
# Configuration lue dans <dépôt>/.claude/tower-control/config.sh — voir l'exemple en bas.
set -euo pipefail

REPO="${1:?usage: lancer.sh <chemin du dépôt>}"
CONFIG="$REPO/.claude/tower-control/config.sh"
test -f "$CONFIG" || { echo "config absente : $CONFIG" >&2; exit 2; }
# shellcheck source=/dev/null
source "$CONFIG"

test "${HERDR_ENV:-}" = 1 || { echo "pas dans herdr" >&2; exit 2; }
: "${WORKTREES_DIR:?}" "${MODEL:=claude-opus-5-5}" "${BOOTSTRAP:=true}"
declare -p GRAPPES >/dev/null 2>&1 || { echo "GRAPPES manquant dans $CONFIG" >&2; exit 2; }

MEMORY="$HOME/.claude/projects/$(echo "$REPO" | tr '/' '-')/memory"
DENY="Bash(git add*) Bash(git commit*) Bash(git push*) Bash(git stash*) Bash(git switch*) Bash(git checkout*) Bash(git reset*) Bash(git rebase*) Bash(git merge*) Bash(rm -rf*)"

for name in "${!GRAPPES[@]}"; do
  branch="${GRAPPES[$name]}"
  path="$WORKTREES_DIR/$name"
  echo "== $name → $path ($branch)"

  created=$(herdr worktree create --workspace "$HERDR_WORKSPACE_ID" --branch "$branch" \
    --base main --path "$path" --label "$name" --no-focus)
  pane=$(echo "$created" | jq -r '.result.root_pane.pane_id // .result.root_pane // empty')
  if [ -z "$pane" ]; then echo "pane introuvable dans :" >&2; echo "$created" >&2; exit 1; fi
  echo "   pane $pane"

  key=$(echo "$path" | tr '/' '-')
  mkdir -p "$HOME/.claude/projects/$key"
  ln -sfn "$MEMORY" "$HOME/.claude/projects/$key/memory"

  marker="AMORCE-OK-$RANDOM"
  herdr pane run "$pane" "$BOOTSTRAP && echo $marker" >/dev/null
  herdr pane wait-output "$pane" --match "$marker" --timeout 300000 >/dev/null
  echo "   amorcé"

  herdr agent start "$name" --kind claude --pane "$pane" --timeout 60000 -- \
    --model "$MODEL" --permission-mode auto --disallowedTools "$DENY" >/dev/null
  echo "   agent $name prêt"

  terminal=$(herdr pane split --pane "$pane" --direction right --cwd "$path" --no-focus | jq -r '.result.pane.pane_id')
  echo "   terminal $terminal à droite"
done

# Exemple de .claude/tower-control/config.sh :
#
#   WORKTREES_DIR="$HOME/Projects/monprojet-wt"
#   BOOTSTRAP='ln -s "/chemin/partage" external_doc && ln -s "$HOME/Projects/monprojet/reference" reference && pnpm install --frozen-lockfile'
#   declare -A GRAPPES=([p0-controle]="p0/4-couleur" [p0-photos]="p0/5-credit")
