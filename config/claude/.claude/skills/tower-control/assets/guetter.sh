#!/bin/bash
# guetter.sh <agent> <fichier attendu> : rend la main si l'agent pose une question,
# ou s'il est arrêté sans tâche de fond 3 minutes de suite avec le fichier présent, ou 6 minutes sans lui.
a=$1; f=$2; idle=0
while true; do
  st=$(herdr agent get "$a" | jq -r '.result.agent.agent_status')
  if [ "$st" = blocked ]; then echo "$a QUESTION"; exit 0; fi
  sh=$(herdr agent read "$a" --source visible 2>/dev/null | /usr/bin/grep -c 'shell still running\|· [0-9]* shell')
  if [ "$st" != working ] && [ "$sh" = 0 ]; then idle=$((idle+1)); else idle=0; fi
  if [ -f "$f" ] && [ $idle -ge 3 ]; then echo "$a FINI $(basename "$f")"; exit 0; fi
  if [ $idle -ge 6 ]; then echo "$a ARRÊTÉ sans $(basename "$f")"; exit 0; fi
  sleep 60
done
