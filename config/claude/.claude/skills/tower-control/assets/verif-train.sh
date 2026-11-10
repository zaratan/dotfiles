#!/usr/bin/env bash
# verif-train.sh <dépôt des issues> <dépôt du code | _> <worktree> <train, convoi ou SHA> [--tout | spec e2e…] : vérifie
# une tête en local (references/trains.md) dans un worktree de vérification détaché, par les étapes VERIF / REPO_VERIF
# du config.sh, journaux dans $JOURNAUX. Long (install, base, e2e) : en arrière-plan. Sortie : 0 vert, 1 rouge,
# 2 configuration, 3 refus, 4 panne (fetch, checkout).
set -uo pipefail

REPO=${1:?usage: verif-train.sh <dépôt des issues> <dépôt du code | _> <worktree> <réf> [--tout | spec e2e…]}
DEPOT=${2:?dépôt du code manquant (_ en dépôt unique)}; NOM=${3:?worktree manquant}; REF=${4:?réf manquante}
TOUT=0; SPECS=()
for a in "${@:5}"; do
  case "$a" in --tout) TOUT=1 ;; -*) echo "option inconnue : $a" >&2; exit 2 ;; *) SPECS+=("$a") ;; esac
done
[ "$TOUT" = 0 ] || [ ${#SPECS[@]} = 0 ] || { echo "--tout ou des specs, pas les deux" >&2; exit 2; }
# shellcheck source=../../tc-commun/config-lib.sh
source "$(dirname "$0")/../../tc-commun/config-lib.sh"
: "${WORKTREES_DIR:?}"
refuse() { echo "REFUSÉ : $*"; exit 3; }

r=$DEPOT; [ "$r" != _ ] || r=""
code=$(tc_path_of "$r"); base=$(tc_base_of "$r")
etapes=$(tc_verif_of "$r")
[ -n "$etapes" ] || { echo "aucune étape : VERIF ou REPO_VERIF[$DEPOT] dans $CONFIG (config.example.sh)" >&2; exit 2; }
[[ $NOM == verif-* ]] || refuse "un worktree de vérification se nomme verif-<k>, pas $NOM"
WT="$WORKTREES_DIR/$NOM"
if [ ! -d "$WT" ]; then
  echo "worktree absent : $WT. Le créer et l'amorcer, une fois par lot :"
  echo "  git -C $code worktree add --detach $WT $base"
  echo "  cd $WT && $(tc_bootstrap_of "$r")"
  exit 2
fi
g() { git -C "$WT" "$@"; }
[ "$(g rev-parse --path-format=absolute --git-common-dir)" = "$(git -C "$code" rev-parse --path-format=absolute --git-common-dir)" ] \
  || refuse "$WT n'est pas un worktree de $code"

gitdir=$(g rev-parse --absolute-git-dir)
verrou="$gitdir/verif-train.lock"
mkdir "$verrou" 2>/dev/null || refuse "une vérification tourne déjà dans $WT (sinon : rmdir $verrou)"
etape=""
arreter() { [ -z "$etape" ] || kill -TERM -- "-$etape" 2>/dev/null; exit 143; }
trap 'rmdir "$verrou"' EXIT
trap arreter INT TERM
branche=$(g symbolic-ref --short -q HEAD) && refuse "$WT porte la branche $branche : un worktree de vérification reste détaché"
for etat in MERGE_HEAD rebase-merge rebase-apply CHERRY_PICK_HEAD REVERT_HEAD BISECT_LOG; do
  [ ! -e "$gitdir/$etat" ] || refuse "opération en cours dans $WT ($etat)"
done
g fetch -q origin || { echo "PANNE : fetch"; exit 4; }
[ -z "$(g rev-list -1 HEAD --not --remotes)" ] || refuse "HEAD de $WT porte des commits absents d'origin"

if sha=$(g rev-parse --verify -q "refs/remotes/origin/$REF^{commit}"); then :
elif [[ $REF =~ ^[0-9a-f]{7,40}$ ]] && sha=$(g rev-parse --verify -q "$REF^{commit}") \
  && [ -z "$(g rev-list -1 "$sha" --not --remotes)" ]; then :
else refuse "réf absente d'origin : $REF"
fi
court=$(g rev-parse --short=8 "$sha")
if ! g checkout -q -f --detach "$sha" || ! g clean -fdq; then echo "PANNE : checkout"; exit 4; fi
(cd "$WT" && eval "$(tc_check_of "$r")") || { echo "amorçage incomplet : $(tc_check_of "$r")"; exit 2; }
JOURNAUX=${JOURNAUX:-$(mktemp -d)}; mkdir -p "$JOURNAUX"
PASSE=${VERIF_PASSE:-'[1-9][0-9]* passed'}
sans_e2e=" sans e2e"
set -m
echo "tête $court ($REF), journaux dans $JOURNAUX"

while IFS= read -r -u 3 ligne; do
  [ -n "${ligne// }" ] || continue
  nom=${ligne%%:*}; cmd=${ligne#*:}; cmd=${cmd# }
  if [ "$nom" = e2e ]; then
    if [ ${#SPECS[@]} -gt 0 ]; then cmd+=$(printf ' %q' "${SPECS[@]}")
    elif [ "$TOUT" = 0 ]; then echo "e2e non jouée (ni spec ni --tout)"; continue
    fi
    sans_e2e=""
  fi
  journal="$JOURNAUX/$NOM-$nom.log"; debut=$SECONDS; motif=""; compte=""
  (cd "$WT" && eval "$cmd") </dev/null >"$journal" 2>&1 &
  etape=$!; wait "$etape"; sortie=$?; etape=""
  duree=$((SECONDS - debut))
  case "$nom" in
    test*|e2e*)
      compte=$(grep -oE -- "$PASSE" "$journal" | tail -1)
      [ -n "$compte" ] || motif="aucun « $PASSE »"
      ! grep -qE '[1-9][0-9]* failed' "$journal" || motif="des tests en échec" ;;
  esac
  if [ "$sortie" != 0 ] || [ -n "$motif" ]; then
    echo "$nom KO en ${duree} s (sortie $sortie${motif:+, $motif}) : $journal"
    tail -20 "$journal"
    echo "ROUGE $court ($REF) à l'étape $nom"
    exit 1
  fi
  echo "$nom OK en ${duree} s${compte:+ ($compte)}"
done 3<<< "$etapes"
echo "VERT $court ($REF)$sans_e2e"
