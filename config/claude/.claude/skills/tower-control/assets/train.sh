#!/usr/bin/env bash
# train.sh <dépôt des issues> <grappe> <issue> <train> <titre> [--dry-run] : sous /tc-delegate, porte une issue vérifiée
# par la tour dans son train (references/trains.md) : commit, push sans hook par pousser.sh, PR vers le train, merge,
# ligne dans lot-<n>/trains.md, issue en Review. Chaque étape déjà faite est sautée : on relance après un échec.
set -euo pipefail

REPO=${1:?usage: train.sh <dépôt des issues> <grappe> <issue> <train/<lot>-<grappe>> <titre> [--dry-run]}
GRAPPE=${2:?grappe manquante}; N=${3:?issue manquante}; TRAIN=${4:?train manquant}; TITRE=${5:?titre manquant}
DRY=0
for opt in "${@:6}"; do
  case "$opt" in --dry-run) DRY=1 ;; *) echo "option inconnue : $opt" >&2; exit 2 ;; esac
done
ASSETS=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../tc-commun/config-lib.sh
source "$ASSETS/../../tc-commun/config-lib.sh"
: "${WORKTREES_DIR:?}" "${PROJECT_OWNER:?}" "${PROJECT_NUMBER:?}"
refuse() { echo "REFUSÉ : $*"; exit 3; }

[[ $TRAIN =~ ^train/([0-9]+)- ]] || refuse "un train se nomme train/<lot>-<grappe> : $TRAIN"
NUM_LOT=${BASH_REMATCH[1]}
spec=${GRAPPES[$GRAPPE]:?grappe inconnue dans $LOT : $GRAPPE}
r=$(tc_repo_of "$spec"); code=$(tc_path_of "$r"); base=$(tc_base_of "$r"); base=${base#origin/}
WT="$WORKTREES_DIR/$GRAPPE"
g() { git -C "$WT" "$@"; }

[ ${#TITRE} -le 100 ] || refuse "titre de ${#TITRE} caractères, 100 au plus"
BR=$(g symbolic-ref --short -q HEAD) || refuse "HEAD détaché dans $WT"
[ "$BR" != "$base" ] && [ "$BR" != "$TRAIN" ] || refuse "HEAD est sur $BR"
[ -z "${ISSUES[$GRAPPE]:-}" ] || [ "${ISSUES[$GRAPPE]}" = "$N" ] || echo "attention : ISSUES[$GRAPPE] vaut ${ISSUES[$GRAPPE]}, pas $N"
g fetch -q origin
g rev-parse --verify -q "refs/remotes/origin/$TRAIN" >/dev/null \
  || refuse "$TRAIN absent d'origin ; le créer : git -C $code push origin refs/remotes/origin/$base:refs/heads/$TRAIN"

interdit=${REFS_INTERDITES:-}
[ -n "$interdit" ] || [ -z "$r" ] || interdit=$(printf '%s' "${ISSUES_REPO#*/}" | sed -E 's/[][\\.*^$+?(){}|]/\\&/g')
if [ -n "$interdit" ]; then
  ! printf '%s\n' "$TITRE" | grep -qE -- "$interdit" || refuse "le titre contient une référence interdite ($interdit)"
  trouve=$(g diff "origin/$TRAIN" | grep -E '^\+' | grep -vE '^\+\+\+ ' | grep -E -- "$interdit" || true)
  trouve+=$(cd "$WT" && git ls-files -o --exclude-standard -z | xargs -0 -r grep -nE -- "$interdit" || true)
  [ -z "$trouve" ] || { echo "$trouve"; refuse "référence interdite ($interdit) dans le travail"; }
fi

slug=$(g remote get-url origin | sed -E 's#\.git$##; s#.*[:/]([^/]+/[^/]+)$#\1#')
pr=$(gh pr list --repo "$slug" --head "$BR" --base "$TRAIN" --state all --json number,state \
  -q '[.[] | select(.state != "CLOSED")][0] // empty | "\(.number) \(.state)"')
P=${pr%% *}; ETAT=${pr#* }
PAUSE=${TRAIN_PAUSE:-5}
dirty=$(g status --short); dernier=$(g log -1 --format=%s); devant=$(g rev-list -1 "origin/$TRAIN..HEAD")
if [ -z "$dirty" ] && [ -z "$devant" ]; then
  [ "$ETAT" = MERGED ] || refuse "rien à porter : $BR n'a ni travail ni commit au-delà de $TRAIN"
  echo "PR $P déjà mergée dans $TRAIN : reste la ligne et le board"
else
  g merge-base --is-ancestor "origin/$TRAIN" HEAD \
    || refuse "$BR ne contient pas la tête de $TRAIN : fusionner $TRAIN dans $BR, revérifier l'arbre fusionné, relancer"
  [ "$ETAT" != MERGED ] || { echo "PR $P déjà mergée : le travail neuf part dans une nouvelle PR"; P=""; ETAT=""; }
  if [ -n "$dirty" ]; then
    [ "$dernier" != "$TITRE" ] || refuse "arbre non commité, et le dernier commit porte déjà le titre « $TITRE »"
    echo "$dirty"
  else
    echo "commits déjà faits au-delà de $TRAIN : reprise"
  fi
fi
if [ "$DRY" = 1 ]; then
  echo "à faire : commit « $TITRE » si besoin, pousser.sh --no-verify, PR vers $TRAIN (${P:-nouvelle}), merge, Review de #$N"
  exit 0
fi

if [ "$ETAT" != MERGED ]; then
  if [ -n "$dirty" ]; then
    g add -A
    g commit -q -m "$TITRE"
    [ "$(g log -1 --format=%s)" = "$TITRE" ] || { echo "ÉCHEC : le commit n'a pas pris"; exit 1; }
  fi
  "$ASSETS/pousser.sh" "$WT" "origin/$TRAIN" --no-verify
  if [ -z "$P" ]; then
    url=$(gh pr create --repo "$slug" --base "$TRAIN" --head "$BR" --title "$TITRE" --body "" | tail -1)
    P=${url##*/}
  fi
  fusion=UNKNOWN
  for _ in 1 2 3 4 5 6 7 8 9 10 11 12; do
    fusion=$(gh pr view "$P" --repo "$slug" --json mergeable -q .mergeable)
    [ "$fusion" = UNKNOWN ] || break
    sleep "$PAUSE"
  done
  [ "$fusion" != UNKNOWN ] || { echo "ÉCHEC : GitHub ne dit pas si la PR $P fusionne ; relancer"; exit 1; }
  [ "$fusion" != CONFLICTING ] || refuse "PR $P en conflit avec $TRAIN : fusionner $TRAIN dans $BR, revérifier, relancer"
  sleep "$PAUSE"
  checks=$(gh pr view "$P" --repo "$slug" --json statusCheckRollup -q '.statusCheckRollup | length')
  [ "$checks" = 0 ] || refuse "PR $P a $checks checks : ce dépôt lance la CI vers les trains, ce que trains.md exclut. À revoir avec l'utilisateur ; rien n'est mergé"
  for _ in 1 2 3; do
    gh pr merge "$P" --repo "$slug" --merge --subject "Merge branch '$BR'" --body "" && break
    sleep "$PAUSE"
  done
  for _ in 1 2 3 4 5 6; do
    [ "$(gh pr view "$P" --repo "$slug" --json state -q .state)" = MERGED ] && break
    sleep "$PAUSE"
  done
  [ "$(gh pr view "$P" --repo "$slug" --json state -q .state)" = MERGED ] || { echo "ÉCHEC : PR $P non mergée"; exit 1; }
fi

journal="$REPO/.claude/tower-control/lot-$NUM_LOT/trains.md"
mkdir -p "$(dirname "$journal")"
[ -f "$journal" ] || printf '| Issue | Commit | Branche | PR | Train | Push |\n|---|---|---|---|---|---|\n' > "$journal"
grep -qF "| $BR | $P | $TRAIN |" "$journal" || echo "| #$N | $(g rev-parse --short=8 HEAD) | $BR | $P | $TRAIN | --no-verify |" >> "$journal"
python3 "$ASSETS/board-field.py" "$PROJECT_OWNER" "$PROJECT_NUMBER" Status Review "$N"
echo "#$N PR $P mergée dans $TRAIN. Issue suivante de la grappe :"
echo "  $ASSETS/branche-suivante.sh $WT <branche> origin/$TRAIN"
