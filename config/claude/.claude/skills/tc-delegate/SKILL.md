---
name: tc-delegate
description: "Déléguer à la tour de contrôle (tower-control), pour la session en cours seulement, les écritures git que l'utilisateur fait d'habitude : commiter, pousser la branche d'une issue, ouvrir la PR, la merger après sa CI. « on » ouvre la délégation, « off » la ferme. Invoqué par l'utilisateur uniquement."
argument-hint: "on | off"
disable-model-invocation: true
---

# Délégation à la tour

L'utilisateur s'absente (déplacement, réunion) et peut répondre aux questions, mais pas commiter. Ce skill
lève, **pour cette session seulement**, la règle « ne jamais écrire dans l'historique git sans demande
explicite » sur un périmètre précis. Aucun fichier n'est écrit : la délégation n'existe que dans la
conversation et meurt avec elle.

## `off`

La délégation est fermée à partir de ce message : plus aucun commit, push, PR ou merge. Finir l'action
en cours seulement si l'interrompre laisserait un état cassé (un push sans PR, par exemple), et le dire.
Faire le point : ce qui a été commité, poussé, ouvert, mergé pendant la délégation, avec les liens.

## `on` (ou sans argument)

Confirmer en une phrase ce qui est délégué et ce qui ne l'est pas, puis appliquer ceci.

**Délégué**, seulement pour les branches d'issue créées par la tour dans ses worktrees :
- `git add` et `git commit` du travail **vérifié par la tour** (compte rendu relu, vérifications relancées,
  décisions de l'agent posées à l'utilisateur et acceptées) ;
- `git push origin <branche d'issue>` (jamais la branche de base, jamais `--force`) ;
- `gh pr create` vers la branche de base ;
- `gh pr merge` quand la CI de la PR est verte ;
- `git merge origin/<base>` dans une branche d'issue pour résoudre un conflit, avec revérification complète
  de l'arbre fusionné avant de pousser.

**Pas délégué** : tout le reste. Pas de commit dans le méta-dépôt ni dans un autre dépôt, pas de
`git branch -D`, pas de `push --force`, pas de réécriture d'historique, pas de tag ni de release, pas de
déploiement ni de connexion à un serveur, pas de message à un tiers. Une PR que la CI met en échec n'est
pas mergée : la tour s'arrête et le dit.

### Format

- **Avant le premier commit**, relire le format de l'utilisateur sur `git log` et sur ses PR mergées, et
  le reproduire (souvent un titre seul, à l'impératif, dans la langue du dépôt, sans corps). Pas de ligne
  d'attribution si ses commits n'en ont pas.
- Corps de PR comme les siennes (souvent vide). Jamais de référence au méta-dépôt privé (`Closes …`,
  numéro d'issue, chemin de ses `docs/`) : la tour ferme l'issue à la main au merge.

### Merger

- Une PR à la fois. Attendre sa CI, merger avec la méthode de ses merges précédents (merge commit, squash),
  puis attendre que **toutes** les exécutions du commit de merge sur la branche de base soient terminées et
  vertes avant la PR suivante.
- Avant de proposer ou d'appliquer un ordre, comparer les horodatages des migrations des PR ouvertes : les
  instances refusent une migration plus ancienne que la dernière appliquée.
- PR empilée : viser la branche de la PR du dessous tant qu'elle n'est pas mergée ; après son merge, GitHub
  recible sur la base sans relancer la CI : fermer puis rouvrir la PR.
- Après chaque merge : fermer l'issue privée avec la PR et le commit, lui poser le label `lot: <n>`
  (voir tower-control), passer à l'issue suivante.

### Rendre compte

À chaque merge, une ligne à l'utilisateur (PR, commit de merge, CI de la base). À la fin ou sur `off`, le
tableau complet. Les décisions prises seul par un agent continuent d'être posées à l'utilisateur avant le
commit : la délégation porte sur les gestes git, pas sur les choix.
