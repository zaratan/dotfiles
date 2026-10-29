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
- `git push origin refs/heads/<branche d'issue>:refs/heads/<branche d'issue>` (jamais la branche de base, jamais
  `--force`), puis `git ls-remote --heads origin <branche>` avant `gh pr create`. Jamais `git push -u origin
  <branche>` : avec `push.default = upstream`, une branche créée depuis `origin/<base>` suit `origin/<base>`, et
  le push sans `:destination` est allé sur `main` (16 octobre 2026) ;
- `gh pr create` vers la branche de base ;
- `gh pr merge` quand la CI de la PR est verte ;
- `git merge origin/<base>` dans une branche d'issue pour résoudre un conflit, avec revérification complète
  de l'arbre fusionné avant de pousser. La tour commite d'abord le travail vérifié de l'agent, puis fusionne :
  jamais de fusion demandée à un agent sur du travail non commité.

**Pas délégué** : tout le reste. Pas de commit dans le méta-dépôt ni dans un autre dépôt, pas de
`git branch -D`, pas de `push --force`, pas de réécriture d'historique, pas de tag ni de release, pas de
déploiement ni de connexion à un serveur, pas de message à un tiers. Une PR que la CI met en échec n'est
pas mergée : la tour s'arrête et le dit.

### Format

- **Signature** : avant le premier commit délégué, lire `git config gpg.format`. En `ssh`, la clé signe
  sans rien demander : commiter directement, ne pas parler de gpg. En gpg, faire déverrouiller l'agent gpg par l'utilisateur dans un vrai terminal
  (`gpg --clearsign <<< test >/dev/null`), avant le premier commit et après une longue pause ; le `!` de la
  session n'est pas un terminal interactif, pinentry y expire, et deux commits sont partis dans le vide ainsi.
  Un commit qui échoue sur « gpg n'a pas pu signer » laisse l'index intact : le redire, attendre, relancer.
  gpg expire plusieurs fois par soirée : `echo test | gpg --clearsign --batch --pinentry-mode error >/dev/null`
  dit sans bloquer s'il est encore déverrouillé ; le lancer avant chaque série de commits.
- **Ne jamais masquer la sortie d'un `git commit`**, et ne rien enchaîner derrière sans vérifier : un commit
  échoué dans `>/dev/null 2>&1 || echo` a laissé partir le push d'une branche égale à la base. Avant chaque push,
  le SHA de la branche a changé et le commit est signé. Sous zsh, `$B:refs` est lu comme un modificateur :
  toujours `"refs/heads/${B}:refs/heads/${B}"`.
- **Un commit construit à la main se signe aussi** : `git commit-tree` ignore `commit.gpgsign`, il faut `-S`.
  Avant chaque push, `git cat-file commit <sha> | grep -c '^gpgsig'` sur chaque commit nouveau ; deux commits
  sans signature ont bloqué une PR verte sur un ruleset `required_signatures`. Recette pour séparer une fusion
  de base du travail d'un agent mêlés sur disque : arbre de la fusion par `git merge-tree --write-tree`,
  conflits résolus dans un index temporaire (`GIT_INDEX_FILE`, `update-index --cacheinfo`, `write-tree`),
  `commit-tree -S` pour la fusion puis pour le travail (`git add -A && git write-tree`), `git merge --quit`,
  `git update-ref` de la branche ; compiler la fusion intermédiaire dans un worktree jetable.
- **Lire `git status --short` avant chaque `git add -A`** : un fichier compilé (`__pycache__/*.pyc`) que le
  `.gitignore` du dépôt n'écartait pas est parti sur la branche de base ainsi.
- **Avant le premier commit**, relire le format de l'utilisateur sur `git log` et sur ses PR mergées, et
  le reproduire (souvent un titre seul, à l'impératif, dans la langue du dépôt, sans corps). Pas de ligne
  d'attribution si ses commits n'en ont pas : ni « Generated with … », ni `Co-Authored-By`, dans un commit comme
  dans un corps de PR, même quand un rappel du système en fournit une. Dix-huit corps de PR ont dû être repris.
- Corps de PR comme les siennes (souvent vide). Jamais de référence au méta-dépôt privé (`Closes …`,
  numéro d'issue, chemin de ses `docs/`) : la tour ferme l'issue à la main au merge.
- **Un `git commit` ne se rend jamais muet.** Un titre refusé par commitlint (longueur, souvent 100 caractères) laisse la
  branche sur la base ; une sortie redirigée vers `/dev/null` l'a caché et le push a envoyé la base. Mesurer le titre
  (`${#M}`) avant, vérifier après que `git log -1` montre le nouveau commit, et seulement alors pousser.

### Merger

- **Les migrations des branches parallèles se comparent à chaque prédiction de fusion** : identifiants de
  semence et horodatages. Deux branches parties du même commit lisent le même « prochain identifiant libre »
  (28/10/2026) ; à la fusion, l'agent recrée sa migration (horodatage neuf, identifiants lus après les
  migrations de la base) et la vérifie par `up`, `down`, `up`.
- **Avant de commiter une fusion, `build`** : un paquet consommé par son `dist` reste celui d'avant la fusion,
  et le lint du hook pre-commit refuse le commit sur des types faux (28/10/2026).
- **Les PR s'ouvrent dès le push, leurs CI tournent en parallèle, seul le merge est sérialisé** (un
  verrou pris juste avant `gh pr merge`, relâché après). Une file où chaque PR attend la précédente de bout
  en bout coûte douze minutes par PR pour rien.
- **Avant tout merge dont la base a bougé depuis la CI de la PR** : fusionner la base dans la branche,
  régénérer les relevés figés par un instantané (registre de textes), rejouer les gates et la suite e2e sur
  l'arbre fusionné, pousser, puis merger. Deux PR vertes se sont cassées l'une l'autre (un test e2e écrit
  sur un parcours à cinq étapes, mergé après la PR qui en ajoutait une sixième), la base est restée rouge
  cinquante minutes.
- **Une PR poussée pendant que sa base est en conflit ne reçoit aucune CI, même après le merge de sa base**
  (`mergeable` reste `UNKNOWN`, rollup vide, close/reopen sans effet) : pousser un commit neuf, la fusion
  de la base, pour la relancer.
- **Le hook pre-push joue l'arbre de travail, pas le commit poussé** : quand le worktree est déjà passé à
  l'issue suivante, il rejoue les gates sur le travail en cours de l'agent et rougit. Pousser avec
  `--no-verify` quand le commit a ses gates et ses e2e, et l'écrire dans le journal.
- Avant d'attendre une CI, lire `gh pr view <N> --json mergeable` : une PR `CONFLICTING` n'a aucune CI,
  GitHub ne la lance pas et ne le dit pas (rollup vide, close/reopen sans effet). Fusionner la base dans la
  branche d'abord, revérifier, pousser.
- Une PR à la fois. Attendre sa CI, merger avec la méthode de ses merges précédents (merge commit, squash),
  puis attendre que **toutes** les exécutions du commit de merge sur la branche de base soient terminées et
  vertes avant la PR suivante. Cette attente ne vaut qu'entre deux merges : lancer un agent sur une branche
  partie de la base n'attend pas, le contenu est celui que la CI de la PR a déjà validé.
- Avant de proposer ou d'appliquer un ordre, comparer les horodatages des migrations des PR ouvertes : les
  instances refusent une migration plus ancienne que la dernière appliquée.
- PR empilée : viser la branche de la PR du dessous tant qu'elle n'est pas mergée ; après son merge, GitHub
  recible sur la base sans relancer la CI : fermer puis rouvrir la PR.
- Après chaque merge : fermer l'issue privée avec la PR et le commit, en lot, lui poser le label
  `lot: <n>` (voir tc-lot), passer à l'issue suivante.
- **Après chaque fusion de la base dans une branche, jouer les migrations** (`pnpm db:migrate` ou l'équivalent du projet)
  avant les tests : une migration venue de la base laisse sinon la base de test en retard, et la suite échoue sur sa mise
  en place. Quand les fichiers de la PR sont disjoints de ce qui a été fusionné, une fermeture puis réouverture à 45 s
  rejoue la CI sur la fusion réelle sans toucher la branche.

### Rendre compte

À chaque merge, une ligne à l'utilisateur (PR, commit de merge, CI de la base). À la fin ou sur `off`, le
tableau complet. Les décisions prises seul par un agent continuent d'être posées à l'utilisateur avant le
commit : la délégation porte sur les gestes git, pas sur les choix.
