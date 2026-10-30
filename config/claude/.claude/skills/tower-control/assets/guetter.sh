#!/usr/bin/env bash
# guetter.sh <agent> <compte rendu attendu> [section] : rend la main
#  - QUESTION : l'agent est `blocked` (question ou permission) ;
#  - FINI : le fichier a été écrit après le départ du guet (et contient la section, pour une retouche : « ## Retouche »),
#    et l'agent est arrêté depuis 3 minutes sans shell de fond, ou 10 minutes avec (un agent laisse souvent un serveur ouvert) ;
#  - ARRÊTÉ : arrêté depuis 10 minutes sans le fichier, ou 30 quand il reste des shells de fond (une mesure de 8 minutes
#    n'est pas un arrêt). Le verdict imprime la dernière ligne visible de l'agent.
a=${1:?usage: guetter.sh <agent> <fichier attendu> [section]}; f=${2:?fichier attendu}; section=${3:-}; idle=0
repere=$(mktemp); trap 'rm -f "$repere"' EXIT
fresh() {
  [ -f "$f" ] && [ "$f" -nt "$repere" ] || return 1
  [ -z "$section" ] || grep -q "^$section" "$f"
}
while true; do
  st=$(herdr agent get "$a" | jq -r '.result.agent.agent_status // empty') || st=""
  if [ -z "$st" ]; then echo "$a INTROUVABLE (herdr agent get a échoué)"; exit 2; fi
  if [ "$st" = blocked ]; then echo "$a QUESTION"; exit 0; fi
  sh=$(herdr agent read "$a" --source visible 2>/dev/null | grep -c 'shell still running\|· [0-9]* shells\?\b') || sh=0
  if [ "$st" != working ]; then idle=$((idle+1)); else idle=0; fi
  if fresh; then
    if [ "$idle" -ge 3 ] && [ "$sh" = 0 ]; then echo "$a FINI $(basename "$f")"; exit 0; fi
    if [ "$idle" -ge 10 ]; then echo "$a FINI $(basename "$f") (shells de fond encore ouverts)"; exit 0; fi
  elif [ "$idle" -ge 10 ] && { [ "$sh" = 0 ] || [ "$idle" -ge 30 ]; }; then
    last=$(herdr agent read "$a" --source visible 2>/dev/null | grep -v '^[[:space:]]*$' | tail -1)
    echo "$a ARRÊTÉ sans $(basename "$f")${section:+ ($section)} ; shells de fond : $sh ; dernière ligne : ${last}"; exit 0
  fi
  sleep 60
done
