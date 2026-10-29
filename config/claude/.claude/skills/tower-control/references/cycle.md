# Le cycle d'une issue

À lire une fois l'agent lancé (`references/lancer.md`). Les chemins `assets/…` sont
ceux du skill `tower-control`. Relire ce fichier après un résumé automatique du
contexte.

```
tour  : consigne commune + consigne issue → agent        board : (Backlog ou) À faire → En cours
agent : lit l'issue, code, teste, revue lead-engineer, compte rendu, s'arrête
tour  : attend en arrière-plan, lit le compte rendu, VÉRIFIE ELLE-MÊME,
        coche la Must-Have, résume à l'utilisateur        board : En cours → Review
user  : ouvre le sous-espace herdr, relit le diff, commite, ouvre la PR (Closes #N)
tour  : vérifie le lien PR → issue par `gh pr view <PR> --json closingIssuesReferences`,
        jamais par une regex sur le corps (GitHub accepte « Closes: #N », « fixes #N »…) ;
        si le lien manque au merge, c'est la tour qui ferme l'issue, avec un commentaire
tour  : s'il reste une issue dans la grappe, crée sa branche
        (`git switch -c <b> --no-track origin/<base>`) et envoie sa consigne
merge : ferme l'issue, le workflow du board la passe en Fait — la tour n'y touche pas
tour  : en lot, pose le label du lot sur l'issue fermée (voir /tc-lot)
```

## La Must-Have

La Must-Have de l'issue est le contrat entre la tour, l'agent et l'utilisateur. La
consigne la reprend comme Attendu ; le compte rendu de l'agent la reprend case par
case, avec la preuve. Après sa vérification indépendante, la tour coche sur l'issue ce
qu'elle a constaté elle-même, selon la recette de « Écrire sur GitHub » dans
`~/.claude/skills/backlog-setup/references/conventions.md` : un geste mécanique, sans
passe humanize ni accord, qu'elle dit dans son point à l'utilisateur. Ce que l'agent
affirme et que la tour n'a pas revu reste décoché.

L'issue passe en Review quand toutes les cases sont cochées, ou quand sa PR est mergée et que
ses cases ouvertes n'attendent plus que la QA ou une autre issue. « En cours » ne garde que ce
qu'un agent a entre les mains : cinq issues « En cours » dont deux seulement travaillées ont
fait demander à l'utilisateur ce qui se passait. Une case qui attend un tiers passe l'issue en
Bloqué. Abandonner une case est une
décision de l'utilisateur : la retirer de la Must-Have et l'écrire dans le How. Sur une
issue d'avant ce gabarit, sans Must-Have, la tour rédige l'Attendu de la consigne comme
avant, chiffré, et ne coche rien.

## Commit, PR, CI

Quand l'utilisateur s'absente, il peut taper `/tc-delegate on` : la tour fait alors elle-même les
lignes « user » (commit, PR, merge) selon tc-delegate, pour la session seulement. Sans cette commande,
une délégation ne se déduit jamais d'une conversation.

**Lire la CI soi-même** : celle de chaque PR jusqu'au bout (boucler tant qu'une tâche est
« pending » ; `gh pr checks --watch` rend la main au premier résultat) et celle de la
branche de base après chaque merge. Une tâche annulée par son délai n'est pas un test qui
échoue : lire l'étape avant de relancer, et proposer la cause et le correctif avec la
relance. Sur la branche de base, attendre que **toutes les exécutions du commit de merge**
soient terminées, jamais un nombre fixe de workflows : un filtre `paths:` en lance moins
quand la base de données n'est pas touchée, et une attente sur « trois » ne rend jamais la
main. Une PR empilée que GitHub recible sur la base après le merge de celle du dessous ne
relance pas sa CI : la fermer puis la rouvrir la déclenche, **à condition de laisser une pause
entre les deux** (un close/reopen à trois secondes d'écart n'a déclenché aucun run sur deux PR ;
45 s ont suffi). Quand la base n'a pas de déclencheur `push` (décision de coût de l'utilisateur),
le run d'après merge n'existe pas : **recibler chaque PR en attente sur la base courante** par
ce même close/reopen avant de la merger, pour que sa CI rejoue sur le merge réel. Le titre par
défaut d'un merge commit GitHub cite le numéro de PR et le propriétaire (« Merge pull request
#10 from owner/branche ») : si le dépôt du code interdit ces références, merger avec
`gh pr merge --merge --subject "Merge branch '<branche>'"`.

## Attendre

**Attendre sans surveiller, un guetteur par agent** : `assets/guetter.sh <agent>
<compte rendu attendu> [section]`, lancé en arrière-plan (`run_in_background`). Il rend la
main dès que l'agent est `blocked` (question ou demande de permission) ; quand le compte
rendu a été **modifié après le lancement du guet** (un ancien fichier ne compte pas) et que
l'agent est arrêté depuis trois minutes sans shell de fond, ou depuis dix minutes avec (un
agent laisse souvent un `next start` ouvert : un guet qui exigeait zéro shell a attendu sans
fin un compte rendu écrit depuis longtemps) ; ou après dix minutes d'arrêt sans compte rendu,
trente quand il reste des shells de fond (un agent qui attend une mesure de huit minutes a été
dit arrêté une minute avant son compte rendu). Le verdict « ARRÊTÉ » porte la dernière ligne
visible de l'agent : la lire avant de conclure.
Pour une retouche, passer la section attendue (`"## Retouche"`) plutôt qu'une boucle
`until grep` maison. Demander dans chaque consigne de fermer ses shells de fond avant
d'écrire le compte rendu. Le relancer après chaque réponse. La zone de saisie d'un agent
arrêté peut montrer une suggestion de prompt grisée de Claude Code : ce n'est pas un texte
de l'utilisateur, ne jamais la lui attribuer. Ne pas guetter seulement le fichier : trois agents sont
restés bloqués sur une question pendant que la tour attendait leur compte rendu. Ne pas
se fier à `herdr agent wait` seul : il rend « done » pendant que l'agent a des mesures en
arrière-plan. Ne pas partager une attente entre agents : la fin de l'un est passée
inaperçue.

## Vérifier

**Vérifier indépendamment, mais jamais en même temps que l'agent.** Attendre `done`
et un écran arrêté : deux générations dans le même `travail/` se marchent dessus et
fabriquent des écarts fantômes.

**Mesurer la sortie de succès de chaque commande de vérification avant de l'écrire
dans une consigne** (« doit être muet » était faux pour un script qui imprime une ligne
de succès : trois agents sur trois l'ont signalé). Dans un worktree à ports dérivés, les
tests de base passent par le wrapper du projet, pas par le CLI brut.

**Relire le diff pour ce que le poste local ne voit pas** : un import ou une aide qui ne sert qu'à un test réservé à
un système (`#[cfg(unix)]`), inutilisé ailleurs et refusé par `-D warnings` ; une égalité exacte sur la sortie
d'erreur, qu'un runner virtualisé salit de ses propres messages. Deux PR ont cassé en CI ainsi, vertes sur le Mac.

**Vérifier indépendamment.** Le compte rendu de l'agent est une affirmation. Avant
de résumer à l'utilisateur, relancer soi-même dans le worktree les vérifications
que le projet définit (`pnpm run check`, référence de non-régression, contrôle des
données) et comparer aux chiffres annoncés. Un écart entre les deux est la première
chose à dire. **Exception, quand ces vérifications sont longues** (plus d'une dizaine de
minutes par issue) **et que la CI de la PR les relance** : la tour ne refait que ce que la
CI ne voit pas, soit les tests locaux sur des données absentes de la CI, le diff
(commentaires, fichiers non suivis), et un temps annoncé quand il compte, remesuré au
calme. Sur un projet vidéo, la relance de `check`, des tests lents et de la référence
coûtait 15 à 20 min de verrou par issue, pour des tests que l'agent venait de lancer et
que la CI relançait sur trois systèmes. Avec des tests rapides, la vérification complète
reste la règle.

Pour revoir un écran, démarrer l'app du worktree comme en production avec
`assets/demarrer-prod.sh <dépôt des issues> <grappe>`, en arrière-plan. Le script lit la
recette du projet dans `config.sh` (`REPO_PROD_START[<dépôt>]`, ou `PROD_START` en dépôt
unique) ; si elle manque, l'écrire une fois avec l'utilisateur plutôt que la refaire à la main
à chaque vérification. Arrêter ensuite l'app par son port.

**Résumer court** : ce qui est fait, les chiffres vérifiés, les cases cochées, ce qui
reste ouvert. Le compte rendu complet est dans `travail/rapport-<N>.md` ou lisible par
`herdr agent read`. **Les décisions que l'agent a prises seul ne vont pas dans le
résumé : elles se posent en questions directes** (AskUserQuestion, une à la fois,
avec le texte avant et après), avant de dire « prêt à commiter ». Un utilisateur qui
traite plusieurs sujets fusionne sans relire ce qu'un résumé lui signale en prose.

**Une retouche que la tour tire d'un compte rendu ou d'une revue se vérifie dans le code avant l'envoi** : lire le
passage cité. Trois retouches fausses sont parties ainsi en un lot (des valeurs « déjà rendues » qui ne l'étaient pas,
un attribut dit inutile qui servait à un lint, un chemin de cache dont la forme changeait la version de l'entrée) ;
les agents les ont arrêtées. Au merge d'une issue, proposer de retirer sa planche lourde (vidéos, images).

**Chaque « hors périmètre repéré » finit quelque part, avant le résumé** : écrire la
table point → destination, avec trois destinations possibles : traité (retouche par le
même agent si le fichier est dans sa branche, ou bloc « reliquats » dans la consigne
suivante de la même grappe), attaché à une issue existante (commentaire avec
fichier:ligne), ou nouvelle issue. Jamais seulement listé. Une issue créée en chemin
et un commentaire suivent « Écrire sur GitHub » du skill. Avant d'attacher un point à
une issue existante, relire ce qu'elle produit : la tour a annoncé des extraits vidéo
d'une issue qui ne sort que des tableaux.

## Branches et retard

**Quand la branche est en retard et partage des fichiers avec ce qui a été fusionné**,
ne pas se contenter de `merge-tree` : jouer la fusion dans un worktree jetable, puis
install, build, typecheck, tests, et le retirer. Branche commitée : `merge-tree
--write-tree` + `commit-tree` + `git worktree add --detach`. Travail non commité :
`git worktree add --detach` sur `origin/<base>`, `git diff HEAD` appliqué par
`git apply --3way`, copie des fichiers non suivis — **jamais `git add -N` ni `git reset`**
dans le worktree de l'agent, ce sont des écritures d'index et l'arbre obtenu est faux. Un
rebase sans conflit a déjà cassé `tsc` deux fois, et un `merge-tree` propre a caché un
conflit sémantique (un test qui compte des fichiers qu'une autre branche ajoute).

**Une branche par issue, et d'où elle part.** Après le commit de l'utilisateur, la
tour crée la branche suivante dans le même worktree (`git switch -c <b> --no-track origin/<base>` —
c'est la tour qui le fait, l'agent en est interdit ; sans `--no-track`, la branche suit la base et un
push sans refspec explicite y part). Elle part de **`origin/<branche de base>`
après un `fetch`**, pas du HEAD local : d'autres worktrees ont pu merger entre-temps, et une
branche partie du HEAD local ne « prend » jamais ces changements toute seule. Faire
`git branch --unset-upstream` aussitôt, sinon un `push` nu irait sur la branche de
base. **Avant d'envoyer la consigne, `git rev-parse --abbrev-ref HEAD` du worktree doit
rendre la branche qu'elle nomme** : une boucle zsh `for s in "wt branche"; do set -- $s` ne
découpe pas la chaîne, aucune branche n'a été créée, et trois agents sont partis sur des branches
déjà mergées. Créer les branches en lignes explicites, une par worktree. On n'empile sur le HEAD local que si la PR précédente n'est pas encore mergée.
Jamais `git pull` sur la branche de base, même en avance rapide : `fetch`, puis
`origin/<base>` ou `git show`, suffisent à la tour.

**Avant de passer en Review, mesurer le retard.** Jamais `git diff origin/<base>` à deux
voies pour lire une branche : ce qui a été fusionné entre-temps y apparaît comme un retrait,
et la tour a annoncé un retrait qui n'existait pas ; lire `git diff $(git merge-base HEAD
origin/<base>) HEAD`. Puis `git fetch` et
`git rev-list --left-right --count origin/<base>...HEAD`, et prédire le rebase sans
toucher aux branches : `tree=$(git write-tree); tmp=$(git commit-tree $tree -p HEAD
-m x); git merge-tree --write-tree origin/<base> $tmp` (un commit sans référence
n'est pas de l'historique). Le point à l'utilisateur dit « N commits derrière, rebase sans
conflit » ou nomme les fichiers en conflit. Le rebase lui-même est une écriture git :
il se fait sur sa demande explicite, ou par lui. Un rebase sans conflit n'est pas un rebase
vert : `check` complet avant de pousser, et la tour revérifie après. **La prédiction se refait
juste avant le merge**, sur l'`origin/<base>` du moment : un `merge-tree` propre à l'ouverture
de la PR a été suivi de trois merges, et la PR était sale sur cinq fichiers à son tour. Dès
qu'elle est sale, lancer la fusion dans le worktree de l'agent (sous délégation, `git merge
origin/<base>` ; sinon la demander) et le laisser résoudre.

## Les questions des agents

Les agents posent leurs questions par AskUserQuestion ; herdr les montre `blocked`.
**Tout passe par la tour**, pour trois raisons : la même question revient dans
plusieurs agents et doit recevoir la même réponse ; une bonne part a déjà sa réponse
dans les docs du dépôt ; chaque réponse de l'utilisateur doit être rangée là où
elle survivra.

Les règles de décision (ce que la tour tranche seule, ce qui remonte à l'utilisateur,
où ranger la réponse) sont dans « Les questions » du skill. En plus, pour les agents :

- Lire le contexte (`herdr agent read`) avant de répondre.
- **Une demande de permission bloque l'agent comme une question.** La lire avant de
  répondre ; refuser un `rm` dont le chemin dépend d'une variable qui peut être vide, et
  demander `"${VAR:?}"/…` à la place.
- La tour qui répond seule cite la source à l'agent et liste la réponse dans le
  résumé. Une décision qui remonte à l'utilisateur laisse l'agent attendre : un agent
  qui attend dix minutes coûte moins qu'une décision prise à la place de l'utilisateur.
- L'utilisateur ne répond pas dans les panes, et **un texte non envoyé dans la zone de
  saisie d'un agent n'est jamais de lui** : c'est une suggestion automatique de Claude
  Code (« Compte rendu lu, je commite. », « aligne aussi … »). Ne pas l'interpréter, ne pas
  le consigner, ne pas poser de question dessus ; `agent prompt` le remplace. `send-keys
  enter` ne sert qu'aux dialogues (`AskUserQuestion`).
- Un agent qui pilote le navigateur a besoin que le site de sa pile (`localhost:<port
  dérivé>`) soit autorisé dans l'extension : le prévoir dans la consigne.

Un agent qui tourne en rond se voit au `agent read` : l'interrompre
(`agent send-keys <nom> esc`), reformuler, et ne pas dépasser deux relances sans en
parler à l'utilisateur.

## Ranger un worktree

Une fois la PR mergée et la grappe sans issue suivante : `herdr workspace close` du
sous-espace créé par la tour, `git worktree remove` (jamais `--force` ; avant chacun,
la PR de la branche est mergée et `git status --short` du worktree est vide),
suppression du lien de mémoire, et retrait de sa grappe du fichier de lot.
**Avant de retirer un worktree, chercher le travail qui n'existe nulle part ailleurs** : un
`status` vide ne voit pas les dossiers ignorés (`out/`, `target/`), et un prototype d'exploration
n'a vécu que là, sans aucun commit. Lister ce qui n'est ni sorties ni build
(`find <wt>/out -maxdepth 2`), le dire à l'utilisateur, proposer de le mettre sur une branche,
et garder le worktree tant qu'il n'a pas répondu.
**Rien d'autre** : pas de `git branch -D` sur les branches mergées, c'est une écriture git
qui appartient à l'utilisateur.
