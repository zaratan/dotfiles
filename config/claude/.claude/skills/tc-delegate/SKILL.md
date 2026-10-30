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
- le push par `~/.claude/skills/tower-control/assets/pousser.sh <worktree> origin/<base>` : il refuse une tête
  égale à la base ou un commit non signé quand le dépôt signe, pousse par refspec explicite (jamais `-u`, jamais la
  base, jamais `--force` : avec `push.default = upstream`, un `push -u` d'une branche créée depuis `origin/<base>`
  est allé sur `main`), et relit la branche sur origin avant `gh pr create` ;
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
- **Ne jamais masquer la sortie d'un `git commit`**, ni rien enchaîner derrière sans vérifier : un commit
  échoué (gpg expiré, titre refusé par commitlint, souvent au-delà de 100 caractères : mesurer `${#M}` avant)
  caché dans `>/dev/null 2>&1 || echo` a laissé partir le push d'une branche égale à la base, deux fois. Avant
  chaque push : `git log -1` montre le nouveau commit, le SHA de la branche a changé, le commit est signé.
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

### Merger

- **Les PR s'ouvrent dès le push, leurs CI tournent en parallèle, seul le merge est sérialisé** (un
  verrou pris juste avant `gh pr merge`, relâché après). Une file où chaque PR attend la précédente de bout
  en bout coûte douze minutes par PR pour rien.
- **Avant tout merge dont la base a bougé depuis la CI de la PR** : fusionner la base dans la branche,
  jouer les migrations venues de la base (`pnpm db:migrate` ou l'équivalent, sinon la suite échoue sur sa
  mise en place), régénérer les relevés figés par un instantané (registre de textes), `build` (un paquet
  consommé par son `dist` reste celui d'avant la fusion et le lint du pre-commit refuse le commit), rejouer
  les gates et la suite e2e sur l'arbre fusionné, pousser, puis merger. Deux PR vertes se sont cassées l'une
  l'autre (un test e2e écrit sur un parcours à cinq étapes, mergé après la PR qui en ajoutait une sixième),
  la base est restée rouge cinquante minutes. Quand les fichiers de la PR sont disjoints de ce qui a été
  fusionné, le close/reopen de `cycle.md` (« Commit, PR, CI ») rejoue la CI sur la fusion réelle sans
  toucher la branche.
- **Migrations des branches ouvertes** : à chaque prédiction de fusion et avant de proposer un ordre de
  merge, comparer leurs horodatages et leurs identifiants de semence. Les instances refusent une migration
  plus ancienne que la dernière appliquée, et deux branches parties du même commit lisent le même « prochain
  identifiant libre ». À la fusion, l'agent recrée sa migration (horodatage neuf, identifiants lus après les
  migrations de la base) et la vérifie par `up`, `down`, `up` avec le compte des lignes.
- **Avant d'attendre une CI, lire `gh pr view <N> --json mergeable`** : une PR `CONFLICTING` n'a aucune CI,
  GitHub ne la lance pas et ne le dit pas (rollup vide, close/reopen sans effet) ; une PR poussée pendant que
  sa base était en conflit reste `UNKNOWN` même après le merge de sa base. Dans les deux cas : fusionner la
  base dans la branche, revérifier, pousser un commit neuf, qui relance la CI. `gh pr update-branch` n'est pas
  une voie de repli : il échoue dès qu'il y a conflit.
- **Le hook pre-push joue l'arbre de travail, pas le commit poussé** : quand le worktree est déjà passé à
  l'issue suivante, il rejoue les gates sur le travail en cours de l'agent et rougit. Pousser avec
  `--no-verify` quand le commit a ses gates et ses e2e, et l'écrire dans le journal.
- Une PR à la fois. Attendre sa CI, merger avec la méthode de ses merges précédents (merge commit, squash),
  puis attendre que **toutes** les exécutions du commit de merge sur la branche de base soient terminées et
  vertes avant la PR suivante. Cette attente ne vaut qu'entre deux merges : lancer un agent sur une branche
  partie de la base n'attend pas, le contenu est celui que la CI de la PR a déjà validé.
- PR empilée : viser la branche de la PR du dessous tant qu'elle n'est pas mergée ; après son merge, GitHub
  recible sur la base sans relancer la CI : close/reopen (`cycle.md`).
- Après chaque merge : fermer l'issue privée avec la PR et le commit, en lot, lui poser le label
  `lot: <n>` (voir tc-lot), passer à l'issue suivante.

### Rendre compte

À chaque merge, une ligne à l'utilisateur (PR, commit de merge, CI de la base). À la fin ou sur `off`, le
tableau complet. Les décisions prises seul par un agent continuent d'être posées à l'utilisateur avant le
commit : la délégation porte sur les gestes git, pas sur les choix.
