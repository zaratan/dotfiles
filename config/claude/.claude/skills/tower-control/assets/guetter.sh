#!/bin/bash
# guetter.sh <agent> <fichier attendu> [section] : rend la main
#  - si l'agent pose une question (blocked) ;
#  - si le fichier est présent (et contient la section, pour une retouche : « ## Retouche ») et que l'agent
#    n'est plus en train de travailler depuis 3 minutes, sans shell de fond ;
#  - ou depuis 10 minutes, même s'il lui reste des shells de fond : un agent laisse souvent un next start
#    ou une pile ouverte, et l'attente ne doit pas en dépendre ;
#  - si l'agent est arrêté depuis 10 minutes sans le fichier, ou depuis 30 minutes quand il lui reste des shells
#    de fond : un agent qui attend une mesure de 8 min n'est pas arrêté, et son compte rendu arrive juste après.
# Le fichier ne compte que s'il a été modifié après le lancement du guet (un ancien compte rendu ne suffit pas).
# Le verdict ARRÊTÉ imprime la dernière ligne visible de l'agent, pour lire sans ouvrir le pane.
a=$1; f=$2; section=${3:-}; idle=0
start=$(date +%s)
fresh() {
  [ -f "$f" ] || return 1
  [ "$(stat -c %Y "$f")" -ge "$start" ] || return 1
  [ -z "$section" ] || /usr/bin/grep -q "^$section" "$f"
}
while true; do
  st=$(herdr agent get "$a" | jq -r '.result.agent.agent_status')
  if [ "$st" = blocked ]; then echo "$a QUESTION"; exit 0; fi
  sh=$(herdr agent read "$a" --source visible 2>/dev/null | /usr/bin/grep -c 'shell still running\|· [0-9]* shells\?\b')
  if [ "$st" != working ]; then idle=$((idle+1)); else idle=0; fi
  if fresh; then
    if [ $idle -ge 3 ] && [ "$sh" = 0 ]; then echo "$a FINI $(basename "$f")"; exit 0; fi
    if [ $idle -ge 10 ]; then echo "$a FINI $(basename "$f") (shells de fond encore ouverts)"; exit 0; fi
  elif [ $idle -ge 10 ] && { [ "$sh" = 0 ] || [ $idle -ge 30 ]; }; then
    last=$(herdr agent read "$a" --source visible 2>/dev/null | /usr/bin/grep -v '^[[:space:]]*$' | tail -1)
    echo "$a ARRÊTÉ sans $(basename "$f")${section:+ ($section)}${sh:+ ; shells de fond : $sh} ; dernière ligne : ${last}"; exit 0
  fi
  sleep 60
done
