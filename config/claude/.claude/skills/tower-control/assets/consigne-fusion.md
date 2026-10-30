# Gabarit de consigne de fusion

Pour l'agent qui connaît un des deux côtés. Avant : le travail de l'agent est commité (par la tour sous
délégation, sinon par l'utilisateur) et la tour a lancé `git merge origin/<base>` dans le worktree. L'agent
résout sans git ; la tour commite la fusion. Assemblée par `consigne.sh <dépôt> <fichier> --retouche`.

```
## Fusion #<N> ← <base>

`git merge origin/<base>` est lancé dans `<worktree>` et s'arrête sur <n> fichiers en conflit : <liste>.
L'autre côté vient de <PR ou issue>, compte rendu `<chemin>` : <ce qu'il change, deux phrases>.

Résous chaque fichier sans aucune commande git (ni `add`, ni `checkout`, ni `merge --continue`) : garde les
deux comportements quand ils s'ajoutent ; quand ils se contredisent, arrête-toi et pose la question.
<« Décidé : … » pour ce qui est tranché d'avance.>
Si une migration vient de chaque côté, recrée la tienne (horodatage neuf, identifiants lus après les
migrations de la base) et vérifie `up`, `down`, `up` avec le compte des lignes.
Puis `build`, les migrations, et les vérifications du projet sur l'arbre fusionné : <commandes>.
Écris `## Fusion` dans `<chemin absolu du compte rendu>` : fichiers résolus et comment, vérifications avec
chiffres, ce qui attend une décision. Puis arrête-toi : la tour commite.
```
