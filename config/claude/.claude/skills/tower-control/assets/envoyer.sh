#!/usr/bin/env bash
# envoyer.sh <agent> <fichier> : envoie le fichier à l'agent herdr et vérifie qu'il l'a reçu (passe à `working`).
# Refuse un agent `blocked` (répondre d'abord). Si le texte n'est pas pris, ferme le panneau ou la boîte qui l'a avalé
# (« Teach auto mode », vue d'un shell de fond) par `esc` et renvoie une fois. Douze consignes ont été perdues ainsi,
# sans erreur de herdr. Rappelle de lancer le guet dans le même tour.
set -euo pipefail

a=${1:?usage: envoyer.sh <agent> <fichier>}; f=${2:?fichier manquant}
test -f "$f" || { echo "fichier absent : $f" >&2; exit 2; }

etat() { herdr agent get "$a" | jq -r '.result.agent.agent_status // empty'; }
ecran() { herdr agent read "$a" --source visible 2>/dev/null || true; }
attend_working() { for _ in 1 2 3 4 5 6 7 8; do [ "$(etat)" = working ] && return 0; sleep 2; done; return 1; }

st=$(etat) || { echo "$a INTROUVABLE (herdr agent get a échoué)"; exit 2; }
[ -n "$st" ] || { echo "$a INTROUVABLE (herdr agent get a échoué)"; exit 2; }
if [ "$st" = blocked ]; then
  echo "$a BLOQUÉ sur une question ou une permission : lire l'écran (herdr agent read $a --source visible), répondre, puis renvoyer."
  exit 3
fi

herdr agent prompt "$a" "$(command cat "$f")" >/dev/null
if attend_working; then echo "$a ENVOYÉ $(basename "$f") ; lancer le guet : guetter.sh $a <compte rendu>"; exit 0; fi

if ecran | grep -qE 'Teach auto mode|Esc/Enter/Space to close|Showing [0-9]+ lines'; then
  herdr agent send-keys "$a" esc >/dev/null
  sleep 1
  herdr agent prompt "$a" "$(command cat "$f")" >/dev/null
  if attend_working; then echo "$a ENVOYÉ $(basename "$f") après un esc (panneau ou boîte fermé) ; lancer le guet : guetter.sh $a <compte rendu>"; exit 0; fi
fi
echo "$a NON REÇU : état $(etat), dernière ligne : $(ecran | grep -v '^[[:space:]]*$' | tail -1)"
exit 4
