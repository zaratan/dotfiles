#!/usr/bin/env bash
# guet-qa.sh <dossier travail/> <lot> <signalements déjà vus> : rend la main dès que les suivis de QA du lot portent plus de lignes
# KO, « attente tour » ou bloquées que le compte donné (NEUF), sinon au bout de GUET_QA_MAX secondes, 2 400 par défaut (DÉLAI).
set -uo pipefail
T=${1:?usage: guet-qa.sh <dossier travail/> <lot> <signalements déjà vus>}; LOT=${2:?lot}; vu=${3:-0}
[ -d "$T" ] || { echo "dossier introuvable : $T" >&2; exit 2; }
[[ $vu =~ ^[0-9]+$ ]] || { echo "compte déjà vu non entier : $vu" >&2; exit 2; }
SIGNALEMENT='^[0-9]{2}:[0-9]{2} [|] *([^|]*[|] *(KO|bloqu)|attente tour)'
JOUEE='^[0-9]{2}:[0-9]{2} [|] *[^|]*[|] *(OK|KO|bloqu)'
compte() {
  local f n=0
  for f in "$T"/qa-"$LOT"-*-suivi.md; do [ -e "$f" ] && n=$((n + $(grep -cE "$SIGNALEMENT" "$f"))); done
  echo "$n"
}

fin=$((SECONDS + ${GUET_QA_MAX:-2400}))
while [ "$(compte)" -le "$vu" ] && [ "$SECONDS" -lt "$fin" ]; do sleep "${GUET_QA_PAS:-60}"; done

n=$(compte)
if [ "$n" -gt "$vu" ]; then echo "NEUF : $n signalements (vus : $vu)"; else echo "DÉLAI : $n signalements (vus : $vu)"; fi
aucun=1
for f in "$T"/qa-"$LOT"-*-suivi.md; do
  [ -e "$f" ] || continue; aucun=0
  echo "$(basename "$f") : $(grep -cE "$JOUEE" "$f") lignes jouées"
  grep -nE "$SIGNALEMENT" "$f" | cut -c1-400
done
[ "$aucun" = 0 ] || echo "aucun suivi qa-$LOT-*-suivi.md dans $T"
if [ -n "${TZ:-}" ] && [ -e "/usr/share/zoneinfo/$TZ" ]; then echo "Il est $(date '+%H h %M') ($TZ)."
else echo "Il est $(date '+%H h %M') à l'heure du serveur : fuseau de l'utilisateur absent ou inconnu (TZ=<zone> guet-qa.sh …)."; fi
