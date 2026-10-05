#!/usr/bin/env bash
# Crée un worktree herdr par grappe, l'amorce, lie la mémoire et y démarre un agent Claude.
# Configuration lue dans <dépôt des issues>/.claude/tower-control/ : config.sh (partagé), puis
# lot-<login GitHub>.sh (les grappes de la personne qui lance) — voir les exemples en bas.
# Dépôt unique : une grappe = "<branche>". Méta-dépôt : une grappe = "<dépôt> <branche>",
# et chaque dépôt est décrit par REPO_PATH / REPO_BASE / REPO_BOOTSTRAP / REPO_CHECK.
set -euo pipefail

REPO="${1:?usage: lancer.sh <chemin du dépôt qui porte les issues> [grappe…]}"
ONLY=("${@:2}")   # sans argument : toutes les grappes ; sinon seulement celles nommées (relance partielle)
CONFIG="$REPO/.claude/tower-control/config.sh"
test -f "$CONFIG" || { echo "config absente : $CONFIG" >&2; exit 2; }
# shellcheck source=/dev/null
source "$CONFIG"

GH_LOGIN=$(gh api user -q .login) && test -n "$GH_LOGIN" || { echo "login GitHub introuvable : gh auth status" >&2; exit 2; }
LOT="$REPO/.claude/tower-control/lot-$GH_LOGIN.sh"
if [ -f "$LOT" ]; then
  # Sans ce unset, un lot écrit élément par élément hériterait des grappes restées dans config.sh.
  unset GRAPPES
  declare -A GRAPPES=()
  # shellcheck source=/dev/null
  source "$LOT"
elif declare -p GRAPPES >/dev/null 2>&1; then
  echo "attention : pas de $LOT, grappes lues dans $CONFIG — à deux, ce sont peut-être celles de l'autre" >&2
fi

test "${HERDR_ENV:-}" = 1 || { echo "pas dans herdr" >&2; exit 2; }
: "${WORKTREES_DIR:?}" "${MODEL:=claude-opus-5-5}" "${BOOTSTRAP_TIMEOUT:=900000}"
declare -p GRAPPES >/dev/null 2>&1 && [ ${#GRAPPES[@]} -gt 0 ] || { echo "GRAPPES manquant : l'écrire dans $LOT" >&2; exit 2; }
declare -p REPO_PATH >/dev/null 2>&1 || declare -A REPO_PATH=()
declare -p REPO_BASE >/dev/null 2>&1 || declare -A REPO_BASE=()
declare -p REPO_BOOTSTRAP >/dev/null 2>&1 || declare -A REPO_BOOTSTRAP=()
declare -p REPO_CHECK >/dev/null 2>&1 || declare -A REPO_CHECK=()

# Sans dépôt nommé dans la grappe, le code est le dépôt des issues lui-même.
repo_of() { case "$1" in *" "*) echo "${1%% *}" ;; *) echo "" ;; esac; }
branch_of() { echo "${1##* }"; }
path_of() { local r=$1; test -n "$r" && echo "${REPO_PATH[$r]:?dépôt inconnu dans REPO_PATH : $r}" || echo "$REPO"; }
base_of() { local r=${1:-_}; echo "${REPO_BASE[$r]:-${BASE_BRANCH:-main}}"; }
bootstrap_of() { local r=${1:-_}; echo "${REPO_BOOTSTRAP[$r]:-${BOOTSTRAP:-true}}"; }
check_of() { local r=${1:-_}; echo "${REPO_CHECK[$r]:-true}"; }

for name in "${!GRAPPES[@]}"; do
  r=$(repo_of "${GRAPPES[$name]}"); code=$(path_of "$r"); base=$(base_of "$r")
  git -C "$code" rev-parse --verify --quiet "$base" >/dev/null \
    || { echo "grappe $name : branche de base introuvable dans $code : $base" >&2; exit 2; }
done

# La mémoire suit le dépôt des issues : c'est lui qui porte les notes du projet.
MEMORY="$HOME/.claude/projects/$(echo "$REPO" | tr '/' '-')/memory"
mkdir -p "$WORKTREES_DIR"
DENY="Bash(git add*) Bash(git commit*) Bash(git push*) Bash(git stash*) Bash(git switch*) Bash(git checkout*) Bash(git reset*) Bash(git rebase*) Bash(git merge*) Bash(rm -rf*)"

wanted() { [ ${#ONLY[@]} -eq 0 ] && return 0; local g; for g in "${ONLY[@]}"; do [ "$g" = "$1" ] && return 0; done; return 1; }
for name in "${!GRAPPES[@]}"; do
  wanted "$name" || continue
  r=$(repo_of "${GRAPPES[$name]}")
  branch=$(branch_of "${GRAPPES[$name]}")
  code=$(path_of "$r"); base=$(base_of "$r"); bootstrap=$(bootstrap_of "$r"); check=$(check_of "$r")
  path="$WORKTREES_DIR/$name"
  echo "== $name → $path ($branch depuis $base, dépôt ${r:-$(basename "$code")})"

  # herdr refuse --workspace et --cwd ensemble : le sous-dépôt d'un méta-dépôt passe par --cwd.
  if [ -n "$r" ]; then origin=(--cwd "$code"); else origin=(--workspace "$HERDR_WORKSPACE_ID"); fi
  created=$(herdr worktree create "${origin[@]}" \
    --branch "$branch" --base "$base" --path "$path" --label "$name" --no-focus)
  pane=$(echo "$created" | jq -r '.result.root_pane.pane_id // .result.root_pane // empty')
  # Une branche créée depuis origin/<base> suit origin/<base> : un `git push` nu irait sur la base.
  git -C "$path" branch --unset-upstream 2>/dev/null || true
  if [ -z "$pane" ]; then echo "pane introuvable dans :" >&2; echo "$created" >&2; exit 1; fi
  echo "   pane $pane"

  # Dépôt unique : l'agent vit dans le worktree, qui n'a pas de mémoire → lien. Méta-dépôt : l'agent
  # est lancé depuis le méta (cwd = $REPO), sa mémoire est déjà la bonne.
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

  # Méta-dépôt : claude démarre à la racine du méta, pas dans le worktree, pour que ses instructions
  # et ses docs priment et qu'une issue puisse toucher plusieurs sous-dépôts.
  if [ -n "$r" ]; then herdr pane run "$pane" "cd '$REPO'" >/dev/null; fi
  herdr agent start "$name" --kind claude --pane "$pane" --timeout 60000 -- \
    --model "$MODEL" --permission-mode auto --disallowedTools "$DENY" >/dev/null
  echo "   agent $name prêt"

  terminal=$(herdr pane split --pane "$pane" --direction right --cwd "$path" --no-focus | jq -r '.result.pane.pane_id')
  echo "   terminal $terminal à droite"
done

# Exemple de .claude/tower-control/config.sh (dépôt unique) :
#
#   ISSUES_REPO="owner/monprojet"
#   PROJECT_NUMBER=1
#   WORKTREES_DIR="$HOME/Projects/monprojet-wt"
#   BASE_BRANCH="main"
#   BOOTSTRAP='pnpm install --frozen-lockfile'
#
# et son .claude/tower-control/lot-<login GitHub>.sh :
#
#   declare -A GRAPPES=([p0-controle]="p0/4-couleur" [p0-photos]="p0/5-credit")
#
# Méta-dépôt (les issues ici, le code dans des sous-dépôts, chacun avec sa branche et son amorçage) :
#
#   ISSUES_REPO="owner/meta"
#   PROJECT_NUMBER=2
#   WORKTREES_DIR="$HOME/Projects/meta/wt"   # sous le méta, pour hériter de son CLAUDE.md ; wt/ dans son .gitignore
#   declare -A REPO_PATH=([app]="$HOME/Projects/meta/app" [infra]="$HOME/Projects/meta/infra")
#   declare -A REPO_BASE=([app]="develop" [infra]="main")
#   declare -A REPO_BOOTSTRAP=([app]='pnpm install --frozen-lockfile' [infra]='true')
#   declare -A REPO_CHECK=([app]='test -d node_modules')
#
# et son lot-<login GitHub>.sh, qui peut corriger un chemin de poste élément par élément
# (un `declare -A REPO_PATH=(…)` y effacerait les autres sous-dépôts) :
#
#   declare -A GRAPPES=([irn]="app p0/2-echelle" [keys]="infra p1/62-cles")
#   REPO_PATH[app]="$HOME/code/app"
