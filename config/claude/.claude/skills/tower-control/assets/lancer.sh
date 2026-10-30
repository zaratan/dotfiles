#!/usr/bin/env bash
# lancer.sh <dépôt des issues> [grappe…] : crée un worktree herdr par grappe, l'amorce, lie la mémoire et y démarre
# un agent Claude. Sans grappe nommée, toutes celles du fichier de lot. Configuration : config.example.sh.
set -euo pipefail

REPO="${1:?usage: lancer.sh <chemin du dépôt qui porte les issues> [grappe…]}"
ONLY=("${@:2}")
# shellcheck source=config-lib.sh
source "$(dirname "$0")/config-lib.sh"

test "${HERDR_ENV:-}" = 1 || { echo "pas dans herdr" >&2; exit 2; }
: "${WORKTREES_DIR:?}" "${MODEL:=claude-opus-5-5}" "${BOOTSTRAP_TIMEOUT:=900000}"
[ ${#GRAPPES[@]} -gt 0 ] || { echo "GRAPPES manquant : l'écrire dans $LOT" >&2; exit 2; }

for name in "${!GRAPPES[@]}"; do
  r=$(tc_repo_of "${GRAPPES[$name]}"); code=$(tc_path_of "$r"); base=$(tc_base_of "$r")
  git -C "$code" rev-parse --verify --quiet "$base" >/dev/null \
    || { echo "grappe $name : branche de base introuvable dans $code : $base" >&2; exit 2; }
done

MEMORY="$HOME/.claude/projects/$(echo "$REPO" | tr '/' '-')/memory"
mkdir -p "$WORKTREES_DIR"
DENY="Bash(git add*) Bash(git commit*) Bash(git push*) Bash(git stash*) Bash(git switch*) Bash(git checkout*) Bash(git reset*) Bash(git rebase*) Bash(git merge*) Bash(git rm*) Bash(git mv*) Bash(git restore*) Bash(git clean*) Bash(git update-index*) Bash(rm -rf*)"

wanted() { [ ${#ONLY[@]} -eq 0 ] && return 0; local g; for g in "${ONLY[@]}"; do [ "$g" = "$1" ] && return 0; done; return 1; }
for name in "${!GRAPPES[@]}"; do
  wanted "$name" || continue
  r=$(tc_repo_of "${GRAPPES[$name]}")
  branch=$(tc_branch_of "${GRAPPES[$name]}")
  code=$(tc_path_of "$r"); base=$(tc_base_of "$r"); bootstrap=$(tc_bootstrap_of "$r"); check=$(tc_check_of "$r")
  path="$WORKTREES_DIR/$name"
  echo "== $name → $path ($branch depuis $base, dépôt ${r:-$(basename "$code")})"

  # herdr refuse --workspace et --cwd ensemble.
  if [ -n "$r" ]; then origin=(--cwd "$code"); else origin=(--workspace "$HERDR_WORKSPACE_ID"); fi
  created=$(herdr worktree create "${origin[@]}" \
    --branch "$branch" --base "$base" --path "$path" --label "$name" --no-focus)
  pane=$(echo "$created" | jq -r '.result.root_pane.pane_id // .result.root_pane // empty')
  # Une branche créée depuis origin/<base> suit origin/<base> : un `git push` nu irait sur la base.
  git -C "$path" branch --unset-upstream 2>/dev/null || true
  if [ -z "$pane" ]; then echo "pane introuvable dans :" >&2; echo "$created" >&2; exit 1; fi
  echo "   pane $pane"

  # La mémoire de Claude Code suit le chemin : un worktree part sans mémoire. En méta, l'agent démarre dans le méta et l'a déjà.
  if [ -z "$r" ]; then
    key=$(echo "$path" | tr '/' '-')
    mkdir -p "$HOME/.claude/projects/$key"
    ln -sfn "$MEMORY" "$HOME/.claude/projects/$key/memory"
  fi

  # wait-output lit aussi la commande tapée : le marqueur attendu ne doit pas y figurer en clair.
  seed=$RANDOM
  herdr pane run "$pane" "$bootstrap && echo AMORCE-\$(($seed*2))-FIN" >/dev/null
  herdr pane wait-output "$pane" --match "AMORCE-$((seed*2))-FIN" --timeout "$BOOTSTRAP_TIMEOUT" >/dev/null
  (cd "$path" && eval "$check") || { echo "amorçage douteux dans $path : « $check » a échoué" >&2; exit 1; }
  echo "   amorcé"

  if [ -n "$r" ]; then herdr pane run "$pane" "cd '$REPO'" >/dev/null; fi
  # Nom d'agent global à la machine, minuscules imposées par herdr ; `agent_pane_busy` juste après l'amorçage, d'où les essais.
  agent="$(basename "$REPO" | tr '[:upper:]' '[:lower:]')-$name"
  started=0
  for _ in 1 2 3 4 5; do
    if herdr agent start "$agent" --kind claude --pane "$pane" --timeout 60000 -- \
        --model "$MODEL" --permission-mode auto --disallowedTools "$DENY" >/dev/null; then started=1; break; fi
    sleep 3
  done
  if [ "$started" = 0 ]; then echo "agent $agent : démarrage refusé cinq fois, grappe $name laissée amorcée sans agent" >&2; continue; fi
  echo "   agent $agent prêt"

  terminal=$(herdr pane split --pane "$pane" --direction right --cwd "$path" --no-focus | jq -r '.result.pane.pane_id')
  echo "   terminal $terminal à droite"
done
