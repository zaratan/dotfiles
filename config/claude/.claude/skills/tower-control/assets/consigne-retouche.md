# Gabarit de consigne de retouche

Pour un agent qui a déjà reçu le cadre : courte, sans la consigne commune. Chaque point vient d'un passage
que la tour a relu dans le code, pas seulement d'un compte rendu ou d'une revue : trois retouches fausses
sont parties en un lot (valeurs « déjà rendues » qui ne l'étaient pas, attribut dit inutile qui servait à un
lint). Une retouche de la tour est une proposition : l'agent qui a le code sous les yeux peut la refuser et
le dire. Assemblée par `consigne.sh <dépôt> <fichier> --retouche`.

```
## Retouche #<N>

Le cadre reçu au début tient. <Origine : ta revue, ma vérification, une décision de l'utilisateur.>

1. `<fichier:ligne>` : <ce qu'il faut changer et pourquoi, une phrase>. <« Décidé : … » s'il y a une décision.>
2. …

Ne touche à rien d'autre. Rejoue <les vérifications légères, et celles que ces lignes peuvent changer>.
Ajoute une section `## Retouche` à `<chemin absolu du compte rendu>` : ce qui a changé (le diff s'il fait
moins de 30 lignes), les vérifications relancées avec leurs chiffres, ce que tu as refusé d'appliquer et
pourquoi. Puis arrête-toi.
```
