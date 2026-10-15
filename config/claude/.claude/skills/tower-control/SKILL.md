---
name: tower-control
description: "Piloter en parallèle plusieurs sessions Claude (Opus) qui traitent chacune une issue GitHub dans son propre worktree git ouvert comme sous-espace herdr, pendant que la session courante joue la tour de contrôle : consignes, attente, vérification indépendante, compte rendu, questions centralisées, board GitHub Projects. À utiliser dès que l'utilisateur parle de dispatcher des issues, de lancer des claude dans des worktrees ou des sub-spaces herdr, de « faire travailler des agents issue par issue », de tower control, ou veut avancer un backlog GitHub à plusieurs agents — même s'il ne nomme pas le skill. Requiert herdr (HERDR_ENV=1), gh, et un GitHub Project."
---

# Tower control

La session courante ne code pas : elle **dispatche**. Chaque issue est traitée par
une session Claude dédiée, dans un worktree git qui est aussi un sous-espace herdr.
L'utilisateur relit et commite lui-même ; rien ne touche l'historique git sans lui.

Pourquoi cette forme : trois agents en parallèle sur trois fichiers différents
avancent trois fois plus vite qu'un seul, à condition qu'un point unique tienne la
cohérence — mêmes règles, mêmes réponses aux mêmes questions, un seul interlocuteur
pour l'utilisateur. C'est le rôle de la tour.

Lire `references/retours.md` avant de commencer : c'est le journal des itérations
précédentes, et la raison d'être de ce skill est de s'améliorer à chaque lot.

## 1. Préparer le lot

**Vérifier l'environnement** : `test "$HERDR_ENV" = 1`, `gh auth status` avec le
scope `project`, un board GitHub Projects avec les statuts Backlog → À faire →
En cours → Bloqué → Review → Fait, et le workflow « item closed → Fait » actif.

**Relever les alias du poste** (`type df du grep sed`) : une commande écrite dans une
consigne ou lancée par la tour tombe sur `duf`, `dust`, `ugrep` ; écrire `/bin/df`,
`/usr/bin/grep` quand c'est le cas.

**Relever le login GitHub** une fois (`gh api user -q .login`) : il nomme le fichier
de lot, filtre le board et signe le journal. Vérifier qu'il peut être assigné sur
`ISSUES_REPO` (`gh api "repos/$ISSUES_REPO/assignees/<login>" --silent`, 404 sinon) —
dans un méta-dépôt privé, la seconde personne n'est pas toujours collaboratrice.

**Lire `.claude/tower-control/config.sh`** du dépôt qui porte les issues, écrit par
`backlog-setup`. Il dit où sont les issues (`ISSUES_REPO`, `PROJECT_NUMBER`) et,
dans le cas d'un **méta-dépôt**, décrit chaque sous-dépôt : chemin (`REPO_PATH`),
branche de base (`REPO_BASE`), amorçage (`REPO_BOOTSTRAP`) et contrôle d'amorçage
(`REPO_CHECK`), tous indexés par le nom du sous-dépôt ; une grappe s'écrit alors
`"<dépôt> <branche>"`. Trois conséquences quand les dépôts diffèrent :

- toute commande `gh issue …` porte `--repo "$ISSUES_REPO"`, y compris dans les
  consignes envoyées aux agents : leur worktree est dans le dépôt du code, `gh` y
  résoudrait le mauvais dépôt ;
- **si le méta-dépôt est privé et inconnu du client** (le cas courant : c'est le
  dossier personnel du prestataire), rien de ce qui part dans le dépôt du code ne le
  cite — ni `Closes owner/meta#N`, ni un numéro d'issue, ni un chemin de ses
  `docs/` — dans le code, les runbooks, les commits ou les PR. La consigne projet
  le dit aux agents, la tour le vérifie (`git diff | grep`) avant de passer en
  Review, et c'est elle qui ferme l'issue quand elle constate le merge. Le
  `Closes owner/meta#N` ne se justifie que pour un méta-dépôt que le client voit ;
- partout où ce skill dit `main` ou `origin/main`, lire la branche de base du
  sous-dépôt concerné (`REPO_BASE[<dépôt>]`, ou `BASE_BRANCH` en dépôt unique) : les
  branches d'issue en partent, et le retard se mesure contre elle ;
- **`WORKTREES_DIR` est sous le méta-dépôt** (`<méta>/wt`, ignoré par son git) et
  **l'agent est lancé depuis la racine du méta**, pas depuis le worktree : son cwd
  est le méta, son worktree est `wt/<grappe>`. Raisons : les instructions et les
  docs du méta priment sur celles du sous-dépôt (qui sont celles du client, souvent
  périmées) ; une issue peut toucher plusieurs sous-dépôts (`wt/app` et `infra/`
  dans la même session) ; la mémoire est celle du méta sans lien à poser. Le
  `CLAUDE.md` du sous-dépôt se charge quand l'agent lit dedans, en second. Le
  `CLAUDE.md` du méta doit le dire explicitement : « en cas de conflit, ce fichier
  prime ». Toute commande de build ou de test se lance dans le worktree
  (`pnpm -C wt/<grappe> …`) ; la consigne de l'issue le rappelle avec le chemin.

**Les grappes sont dans `lot-<login>.sh`**, à côté de `config.sh`. `config.sh` porte
les faits du projet et se partage ; le fichier de lot porte `GRAPPES`, c'est la tour
qui l'écrit au groupement, et git l'ignore (`.claude/tower-control/lot-*.sh` dans le
`.gitignore` du dépôt des issues ; si la ligne manque, la proposer). Il peut aussi corriger un chemin de poste, élément par
élément (`REPO_PATH[app]=…`), ou faire partir les branches de `origin/<base>` plutôt que
de la branche locale (`REPO_BASE[app]="origin/develop"`, avec un `git fetch` avant de
lancer : la tour ne met pas à jour le `develop` local du client) ; un `declare -A REPO_PATH=(…)` y effacerait les autres
sous-dépôts. Au groupement, ne remplacer que la ligne `GRAPPES` : les autres lignes
du fichier sont propres au poste et durent d'un lot à l'autre. Si `config.sh` contient encore des `GRAPPES` (dépôt d'avant ce
découpage), le lanceur s'en sert faute de fichier de lot et prévient : proposer à
l'utilisateur de les déplacer, parce qu'à deux ce sont celles du premier qui a écrit.

**Le lot est ce qui est assigné au login courant dans la colonne « À faire ».** C'est
l'utilisateur qui trie ; la tour ne rediscute pas la sélection, elle lit chaque issue
retenue et passe au groupement. Lire le board avec une limite explicite
(`gh project item-list … --limit 500 --format json` ; sans elle la lecture s'arrête à
30 items, sans erreur) et avec `(.assignees // [])` : la clé est absente quand
personne n'est assigné.

- **assignée au login courant** : dans le lot ;
- **assignée à quelqu'un d'autre** : ignorée. La tour ne la groupe pas, ne la déplace
  pas sur le board, ne la ferme pas — dans toutes les colonnes et pendant tout le
  cycle ;
- **sans assigné** : la lister à l'utilisateur et attendre son accord avant
  `gh issue edit <N> --repo "$ISSUES_REPO" --add-assignee @me`. La répartition entre
  deux personnes n'est pas une décision de la tour. Même traitement pour une issue
  sans assigné déjà « En cours » ou en « Review » : un board d'avant l'assignation,
  ou un lot en vol ;
- **co-assignée dès la lecture** : la signaler, ne pas la lancer sans réponse.

L'assignation n'est pas un verrou : GitHub accepte plusieurs assignés, et deux tours
qui lisent le board en même temps s'assignent toutes les deux. Relire aussitôt
(`gh issue view <N> --repo "$ISSUES_REPO" --json assignees`) et vérifier que le
login y figure, seul. S'il n'y est pas, l'assignation n'a pas pris : ne pas lancer.
Si quelqu'un d'autre y figure, se retirer (`--remove-assignee @me`), ne pas lancer,
et le dire. Si les
deux tours se retirent, l'issue redevient libre et sera reproposée.

**Regarder ce que font les autres**, pour information : les issues « En cours » et
« Review » assignées à d'autres, et les PR ouvertes d'autres auteurs dans chaque
dépôt de code (`gh pr list --state open --limit 200 --json
number,author,headRefName,files` lancé depuis ce dépôt, en écartant celles dont
`.author.login` est le login courant). Un fichier commun avec une grappe se dit dans le point à
l'utilisateur ; ça ne bloque pas le lancement, ça se règle à la PR.

**Grouper les issues par fichiers touchés, pas par thème.** Deux issues qui
modifient le même fichier vont dans le même worktree, l'une après l'autre ; sinon le
second merge conflicte à coup sûr. Lire chaque issue, noter les fichiers probables,
former des grappes. Trois ou quatre worktrees est un bon nombre : au-delà, la tour
ne suit plus et la machine chauffe.

**Quand la CI d'une PR dépasse une dizaine de minutes**, proposer au groupement de réunir
les petites issues d'une même grappe en une seule PR (une branche, un `Closes` par issue) :
chaque PR coûte une CI complète et une relecture. Trois issues d'un banc de mesure sont
passées ainsi en une PR, à la demande de l'utilisateur, sur une CI de quinze minutes.

**Contrôler la couverture** : chaque issue du lot est dans exactement une grappe (`comm` entre la
liste « À faire » assignée et la somme des grappes) ; une issue décidée et jamais lancée a été
retrouvée en fin de lot par la colonne du board.

**Ordonner chaque grappe** du plus simple au plus discutable, et mettre en dernier
ce qui finira « Bloqué » sur une décision externe.

**Relire chaque issue contre le code avant de grouper**, par des agents en lecture seule
(`Explore`, trois à cinq issues chacun, en parallèle) : reproductible encore ? fichiers
touchés ? choix laissés ouverts, avec recommandation ? doc du dépôt contredite ? Attendu
chiffré mesuré maintenant ? Le résultat va dans `lot-<n>/decisions.md` du dépôt des issues
(prémisses corrigées, groupement, décisions de l'utilisateur) : c'est de là que les
consignes se rédigent. Sur vingt issues, huit prémisses fausses ont été trouvées ainsi.

**Une issue qui change l'outillage de tous les worktrees** (pile de dev par worktree,
amorçage, scripts de test) **se lance seule, d'abord** ; les grappes partent du `develop`
qui la contient.

**Mesurer chaque chiffre de la consigne avec la commande qui servira à vérifier**, même
s'il vient de la doc du dépôt : une doc de mesures est périmée dès qu'une issue mergée
touche la même chaîne, et une consigne écrite dessus coûte une issue sans objet ou une
question d'agent.

**Vérifier que le défaut peut encore arriver.** Pour chaque issue, écrire en une
phrase le scénario daté qui le déclenche dans l'état actuel du projet. Si on n'y
arrive pas, le dire à l'utilisateur avant de lancer, « jeter » en première option :
une issue codée et revue a déjà été jetée pour cette raison. Confronter aussi la piste
de l'issue à la doc du dépôt avant de la recopier dans une consigne.

**Si plusieurs agents mesurent sur la même machine**, poser un verrou commun avant de
lancer (`lockf`, une commande par verrou, règle écrite dans un `MESURES.md` du dossier
des worktrees, seuil d'espace disque avant tout balayage) ; voir `references/retours.md`.
Toute compilation chronométrée ou partie de zéro passe sous le verrou, comme la mesure.
Le critère de calme d'avant mesure se mesure sur la machine au repos avant d'être écrit :
la charge moyenne d'un Mac vaut 5 à 6 à vide, et un agent qui l'attendait plus basse a
attendu sans fin ; la somme des `%CPU` des autres processus et un `pgrep` des outils
lourds conviennent.
Une série de mesures lancée par la tour elle-même se dimensionne au besoin (à quoi sert
chaque ligne, qui attend le verrou pendant ce temps) et se dit à l'utilisateur avec son
coût : un balayage exhaustif a bloqué trois agents une matinée pour un tableau que sept
lignes déjà mesurées suffisaient à remplir.

**Si une issue redistribue du code tiers** (binaire, paquet, image), la consigne demande
de vérifier d'abord les licences réellement embarquées (chaînes des bibliothèques, pas le
fichier de licences du paquet, qui peut mentir) et de s'arrêter si elles changent celle du
livrable : c'est une décision de l'utilisateur, et la tour revérifie elle-même.

**Trancher avant de lancer** ce que les issues laissent ouvert (« à trancher »). Un
agent bloqué sur une décision produit est un agent qui attend ; la tour prend la
décision avec l'utilisateur en amont et l'écrit dans la consigne. Poser d'abord les
**questions transverses** (une brique est-elle dans l'échéance, une séance est-elle datée,
une décision tient-elle encore) : sur un lot, douze d'entre elles ont décidé les deux tiers
des verdicts avant la première question d'issue. Les poser avec `AskUserQuestion` en forme
**positive** (« coche ce que tu veux appliquer »), quatre options au plus ; « coche ce que tu
refuses » n'est pas lisible. Une question de l'utilisateur arrivée après l'écriture d'une
consigne peut l'invalider (« et si la recette n'a pas de Front Door ? ») : lancer d'abord ce
qui n'en dépend pas, répondre, réécrire la consigne et l'issue, puis lancer.

**Un lot peut ne pas contenir de code** : un audit du dépôt ou une relecture complète du
backlog se dispatche de la même façon, à des agents de lecture seule (une zone ou un groupe
d'issues chacun, format de constat imposé, chiffre mesuré par ligne), repris ensuite par
`SendMessage` pour rédiger les textes d'issues dans un dossier ; la tour les applique par
script après relecture de l'utilisateur, et aucun agent n'écrit sur GitHub. À la création, poser Statut
et Points avec l'id que `gh project item-add` rend : le listing du projet est en retard de plusieurs
minutes après des ajouts, et un workflow du board peut poser « À faire » par défaut. Quand le lot naît
d'un besoin utilisateur plutôt que d'un backlog, **interviewer d'abord** (`AskUserQuestion`, quatre
questions par tour, état mesuré de la commande en main), et donner la trame de décisions aux agents
comme contrainte. Les issues
« méta » (une brique à 13 points) deviennent des parentes GitHub avec des sous-issues
natives (`POST /repos/{o}/{r}/issues/{parent}/sub_issues`, id numérique de l'enfant) : la
parente reste en Backlog sans points ni assigné, la tour ne dispatche que les sous-issues.

**Préparer les consignes** : `assets/consigne-commune.md` (règles, interdits,
forme du compte rendu), complétée par la section propre au projet, plus une
consigne courte par issue sur le modèle de `assets/consigne-issue.md`. Les montrer à
l'utilisateur avant tout lancement.

**Faire committer** ce qui doit être dans les worktrees (un `CLAUDE.md` retouché,
par exemple) : les branches partent de la branche de base commitée, pas de l'arbre
de travail. Avec un méta-dépôt, les règles du projet ne sont pas dans le worktree
(son `CLAUDE.md` est celui du client) : elles voyagent par la section « Projet » de
la consigne commune, `.claude/tower-control/consigne-projet.md` du méta-dépôt.

## 2. Lancer

`assets/lancer.sh` crée les worktrees via herdr, les amorce, lie la mémoire, et
démarre un agent Claude par worktree. Les commandes herdr sont documentées avec leurs
pièges dans `references/herdr.md` — lire ce fichier plutôt que deviner la syntaxe.

Trois choses que le lanceur fait et qu'il ne faut pas retirer :

- **Lien de mémoire.** La mémoire de Claude Code est indexée sur le chemin du
  répertoire : un worktree démarre sans aucune mémoire. Le lanceur crée
  `~/.claude/projects/<clé-du-worktree>/memory → mémoire du projet principal`.
- **Outils interdits** via `--disallowedTools` : toute commande git qui écrit,
  `rm -rf`. Une règle textuelle peut être mal lue ; une interdiction d'outil, non.
- **Mode `auto`** : sans lui, chaque commande Bash non listée bloque l'agent et
  quelqu'un doit répondre.

L'amorçage d'un worktree qui dérive ses ports d'une table de noms de grappes met tout nom
nouveau sur le même port : deux worktrees ont voulu le même PostgreSQL. Dériver l'offset du
nom (checksum modulo) pour les noms hors table, et lire la sortie du pane quand l'amorçage
échoue avant de chercher ailleurs. **Sonder l'amorçage sur la machine qui lance**, pas sur
celle qui l'a écrit : un script écrit sur Mac a cassé trois fois sur un serveur EL (`sed -i ''`
que GNU sed lit comme un fichier, `lsof` absent, SELinux `Enforcing` qui refuse au conteneur
un bind-mount du worktree tant que le dossier n'a pas le label `container_file_t`). Le nom
d'agent herdr est global à la machine : le lanceur le préfixe par le dépôt des issues
(`<méta>-<grappe>`), et c'est ce nom que la tour emploie dans `agent prompt`, `agent get` et
le guetteur.

Envoyer à chaque agent **la consigne commune et la consigne de l'issue en un seul
`agent prompt`** (les deux fichiers concaténés) : en deux envois, l'agent répond à la
première par « quelle issue ? » et la seconde reste derrière sa question.

Passer les issues lancées en « En cours » sur le board
(`gh project item-edit <n> --owner <o> --url <issue> --field Status --value "En cours"` :
la forme par URL et nom de champ évite les identifiants de nœuds). **Pour plus d'une dizaine
de champs, `assets/board-field.py`** : la forme par URL relit tous les items du projet à
chaque appel et épuise le quota GraphQL en points (seize issues à quatre champs ont bloqué
GraphQL quarante-cinq minutes alors que `rate_limit` affichait 4 300 appels restants) ; le
script lit le projet une fois puis pose un champ par mutation.

## 3. Le cycle, issue par issue

```
tour  : consigne commune + consigne issue → agent        board : À faire → En cours
agent : lit l'issue, code, teste, revue lead-engineer, compte rendu, s'arrête
tour  : attend en arrière-plan, lit le compte rendu, VÉRIFIE ELLE-MÊME,
        résume à l'utilisateur                            board : En cours → Review
user  : ouvre le sous-espace herdr, relit le diff, commite, ouvre la PR (Closes #N)
tour  : vérifie le lien PR → issue par `gh pr view <PR> --json closingIssuesReferences`,
        jamais par une regex sur le corps (GitHub accepte « Closes: #N », « fixes #N »…) ;
        si le lien manque au merge, c'est la tour qui ferme l'issue, avec un commentaire
tour  : crée la branche suivante depuis ce HEAD, envoie la consigne suivante
merge : ferme l'issue, le workflow du board la passe en Fait — la tour n'y touche pas
tour  : pose le label du lot sur l'issue fermée (`lot: <n>`)
```

**Chaque issue fermée par un merge du lot porte le label `lot: <n>`**, `<n>` étant le numéro du
dossier `lot-<n>/`. On retrouve ainsi ce qu'un lot a livré (`gh issue list --repo "$ISSUES_REPO"
--state closed --label "lot: <n>"`). La tour le pose au moment où elle constate le merge, que
l'issue ait été fermée par `Closes` ou à la main :
`gh issue edit <N> --repo "$ISSUES_REPO" --add-label "lot: <n>"`. Au premier merge du lot, créer
le label s'il manque (`gh label create "lot: <n>" --repo "$ISSUES_REPO" --color 5319e7`). Le label
reste dans le dépôt des issues : il n'existe ni sur la PR ni dans le dépôt du code. Une issue
jetée, découpée ou fermée sans merge ne le reçoit pas. À la clôture, comparer la liste du label
avec le tableau des merges du journal.

Quand l'utilisateur s'absente, il peut taper `/tc-delegate on` : la tour fait alors elle-même les
lignes « user » (commit, PR, merge) selon ce skill, pour la session seulement. Sans cette commande,
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

**Attendre sans surveiller, un guetteur par agent** : `assets/guetter.sh <agent>
<compte rendu attendu> [section]`, lancé en arrière-plan (`run_in_background`). Il rend la
main dès que l'agent est `blocked` (question ou demande de permission) ; quand le compte
rendu a été **modifié après le lancement du guet** (un ancien fichier ne compte pas) et que
l'agent est arrêté depuis trois minutes sans shell de fond, ou depuis dix minutes avec (un
agent laisse souvent un `next start` ouvert : un guet qui exigeait zéro shell a attendu sans
fin un compte rendu écrit depuis longtemps) ; ou après dix minutes d'arrêt sans compte rendu.
Pour une retouche, passer la section attendue (`"## Retouche"`) plutôt qu'une boucle
`until grep` maison. Demander dans chaque consigne de fermer ses shells de fond avant
d'écrire le compte rendu. Le relancer après chaque réponse. La zone de saisie d'un agent
arrêté peut montrer une suggestion de prompt grisée de Claude Code : ce n'est pas un texte
de l'utilisateur, ne jamais la lui attribuer. Ne pas guetter seulement le fichier : trois agents sont
restés bloqués sur une question pendant que la tour attendait leur compte rendu. Ne pas
se fier à `herdr agent wait` seul : il rend « done » pendant que l'agent a des mesures en
arrière-plan. Ne pas partager une attente entre agents : la fin de l'un est passée
inaperçue.

**Vérifier indépendamment, mais jamais en même temps que l'agent.** Attendre `done`
et un écran arrêté : deux générations dans le même `travail/` se marchent dessus et
fabriquent des écarts fantômes.

**Mesurer la sortie de succès de chaque commande de vérification avant de l'écrire
dans une consigne** (« doit être muet » était faux pour un script qui imprime une ligne
de succès : trois agents sur trois l'ont signalé). Dans un worktree à ports dérivés, les
tests de base passent par le wrapper du projet, pas par le CLI brut.

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
à chaque vérification. Arrêter ensuite l'app par son port. **Les scripts et captures de la
tour vont dans son scratchpad, jamais dans le cwd d'un worktree** : un outil qui écrit un
chemin relatif (capture d'écran, rapport de test) laisse sinon un fichier non suivi que l'agent
trouve et signale, ou qui part dans un commit.

**Résumer court** : ce qui est fait, les chiffres vérifiés, ce qui reste ouvert. Le
compte rendu complet est dans `travail/rapport-<N>.md` ou lisible par
`herdr agent read`. **Les décisions que l'agent a prises seul ne vont pas dans le
résumé : elles se posent en questions directes** (AskUserQuestion, une à la fois,
avec le texte avant et après), avant de dire « prêt à commiter ». Un utilisateur qui
traite plusieurs sujets fusionne sans relire ce qu'un résumé lui signale en prose.

**Chaque « hors périmètre repéré » finit quelque part, avant le résumé** : écrire la
table point → destination, avec trois destinations possibles : traité (retouche par le
même agent si le fichier est dans sa branche, ou bloc « reliquats » dans la consigne
suivante de la même grappe), attaché à une issue existante (commentaire avec
fichier:ligne), ou nouvelle issue. Jamais seulement listé. **Une issue créée en chemin
va dans la colonne Backlog, explicitement** (`item-add` laisse le statut vide) : c'est
l'utilisateur qui trie. Elle suit toute la convention du dépôt, posée dans le même script
que la création : relire d'abord une issue existante (étiquettes de type et de
complexité, pied de texte, jalon), et proposer points et priorité avec le texte. Onze
issues créées sans eux ont été relevées deux fois par l'utilisateur. `gh issue create`
n'a pas de `--json` : prendre le numéro sur l'URL imprimée. Avant d'attacher un point à
une issue existante, relire ce qu'elle produit : la tour a annoncé des extraits vidéo
d'une issue qui ne sort que des tableaux.

**Quand la branche est en retard et partage des fichiers avec ce qui a été fusionné**,
ne pas se contenter de `merge-tree` : jouer la fusion dans un worktree jetable, puis
install, build, typecheck, tests, et le retirer. Branche commitée : `merge-tree
--write-tree` + `commit-tree` + `git worktree add --detach`. Travail non commité :
`git worktree add --detach` sur `origin/<base>`, `git diff HEAD` appliqué par
`git apply --3way`, copie des fichiers non suivis — **jamais `git add -N` ni `git reset`**
dans le worktree de l'agent, ce sont des écritures d'index et l'arbre obtenu est faux. Un
rebase sans conflit a déjà cassé `tsc` deux fois, et un `merge-tree` propre a caché un
conflit sémantique (un test qui compte des fichiers qu'une autre branche ajoute).

**Tout geste git d'écriture de la tour passe par `git -C <chemin absolu>`**, jamais par un
`cd <worktree> &&` en tête de chaîne : une fois, le `cd` n'a pas pris dans le shell de l'outil,
`git add` a échoué sur un chemin inexistant et un `push` a visé le dépôt des issues, refusé
parce que la référence n'existait pas. Rien d'écrit, par chance.

**Une branche par issue, et d'où elle part.** Après le commit de l'utilisateur, la
tour crée la branche suivante dans le même worktree (`git switch -c` — c'est la tour
qui le fait, l'agent en est interdit). Elle part de **`origin/<branche de base>`
après un `fetch`**, pas du HEAD local : d'autres worktrees ont pu merger entre-temps, et une
branche partie du HEAD local ne « prend » jamais ces changements toute seule. Faire
`git branch --unset-upstream` aussitôt, sinon un `push` nu irait sur la branche de
base. On n'empile sur le HEAD local que si la PR précédente n'est pas encore mergée.
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
vert : `check` complet avant de pousser, et la tour revérifie après.

## 4. Les questions

Les agents posent leurs questions par AskUserQuestion ; herdr les montre `blocked`.
**Tout passe par la tour**, pour trois raisons : la même question revient dans
plusieurs agents et doit recevoir la même réponse ; une bonne part a déjà sa réponse
dans les docs du dépôt ; chaque réponse de l'utilisateur doit être rangée là où
elle survivra.

Règles :

- Lire le contexte (`herdr agent read`) avant de répondre.
- **Une demande de permission bloque l'agent comme une question.** La lire avant de
  répondre ; refuser un `rm` dont le chemin dépend d'une variable qui peut être vide, et
  demander `"${VAR:?}"/…` à la place.
- **Avant de soumettre un écart à la personne qui juge** (naturaliste, client,
  designer), chercher s'il a déjà été jugé : issues parentes, rapports d'exploration,
  journal. La tour a proposé de renvoyer huit écarts jugés deux jours plus tôt ; c'est un
  agent qui a fait le rapprochement.
- La tour répond seule **uniquement** quand la réponse existe déjà : dans CLAUDE.md,
  la documentation du dépôt, l'issue, ou une décision que l'utilisateur a prise plus
  tôt dans le lot. Elle cite alors la source à l'agent et liste la réponse dans le
  résumé.
- **Tout ce qui décide d'un comportement est à l'utilisateur** : un critère, un seuil,
  une sévérité, une règle ajoutée ou retirée, la forme d'un fichier livré, un choix
  produit ou de maquette. Même petit, même « évident », même facile à défaire à la
  relecture — « réversible » n'est pas un critère, c'est l'excuse par laquelle la tour
  reprend une décision qui n'est pas la sienne. Remonter en deux lignes avec une
  recommandation, et laisser l'agent attendre : un agent qui attend dix minutes coûte
  moins qu'une décision prise à la place de l'utilisateur.
- Ranger la réponse : décision produit → docs du dépôt (questions ouvertes, écarts),
  règle de travail → CLAUDE.md, seulement ce qui reste flou → mémoire.
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

## 5. Clore le lot

- Proposer l'ordre de merge qui minimise les conflits (les grappes qui partagent un
  fichier en dernier, l'une après l'autre). **Comparer d'abord les horodatages des
  migrations des PR ouvertes** : si la branche de base se déploie à chaque merge et que les
  instances refusent une migration plus ancienne que la dernière appliquée, l'ordre des
  migrations impose l'ordre des merges. Le dire à l'utilisateur dès que deux PR en portent.
- **Passe de QA de fin de lot**, une fois tout mergé et avant de dire le lot livrable. Les tests
  de chaque PR ne voient pas une régression qui naît de la somme des merges, ni celle d'une
  zone qu'aucune issue n'a touchée : un import XLS qui n'écrivait plus aucune réponse, cassé
  par un changement de droits ailleurs, est parti ainsi chez les clients. On vérifie dans le
  navigateur, sur le dernier commit de la base, que tout ce que le lot a livré marche encore,
  ainsi que les chemins d'or de l'application.
  - **Le cahier** a deux parties :
    - les **chemins d'or**, dans `.claude/tower-control/chemins-d-or.md` du dépôt des issues
      (versionné, commun aux lots). C'est le parcours de chaque fonction principale de
      l'application, de bout en bout, avec le compte, où cliquer, ce qui doit apparaître et
      la donnée à constater. S'il manque, la tour le rédige depuis les runbooks produit et le
      fait valider par l'utilisateur avant la première passe. Quand un agent de lecture le
      rédige, lui demander d'emblée **les variantes de chaque écran, les profils, les états
      forcés et une section de contrôles transverses** (santé, en-têtes, 404, erreurs de
      l'API, accessibilité de base) : une première passe « parcours de référence seulement »
      a été jugée trop mince et refaite ; la seconde a doublé le fichier ;
    - **une ligne par issue du label `lot: <n>`**, tirée de la section « Vérifier sur une
      instance » de son runbook ou de l'Attendu de sa consigne.
  - **Une ligne vaut par son résultat**, pas par l'absence d'erreur : réponses écrites et
    comptées, score affiché avec sa valeur, mail arrivé dans la boîte de test.
  - **Les agents** : deux ou trois agents de QA, un par zone du cahier. Chacun a son worktree
    temporaire `wt/qa-<k>` sur `origin/<base>` (grappes `qa-<k>` dans le fichier de lot, branche
    locale `qa/lot-<n>-<k>` jamais poussée), sa pile locale et l'app en mode production. Il
    utilise le Chromium headless du projet, avec un onglet par compte. Consigne :
    `assets/consigne-qa.md`, seule, sans la consigne commune. Ils ne corrigent rien.
  - **Suivi en direct** : chaque agent ajoute une ligne à `travail/qa-<n>-<k>-suivi.md` par ligne
    jouée, avec le détail de chaque KO. La tour lit ces fichiers pendant la passe (un point toutes
    les 15 minutes si l'utilisateur le demande). Elle n'attend pas le rapport final pour agir sur un
    KO : rejouer, ouvrir l'issue, et lancer le correctif dans une grappe neuve partie de
    `origin/<base>`, en suivant le cycle normal (consigne, vérification, décisions posées,
    PR). Elle redirige l'agent si une ligne dépend d'un défaut déjà connu. Elle réordonne les
    lignes d'un agent quand une autre passe d'abord (correctif mergé, donnée prête). Une ligne KO
    se rejoue après le merge de son correctif.
  - **Contournements partagés** : `travail/qa-<n>-contournements.md`, commun aux agents. Chacun y
    ajoute ce qui servirait aux autres (sélecteur, double facteur, préparation de donnée,
    libellé réel), et le relit avant chaque ligne. La tour y relaie ce qu'elle voit dans un fichier
    de suivi et que les autres n'ont pas encore écrit. Après la passe, ces contournements vont dans
    `chemins-d-or.md` (section 0) ou dans les seeds.
  - **États hors écran** : une ligne qui exige un état que l'app refuse de fabriquer (transition
    interdite, doublon, dates passées) se signale « attente tour » dans le suivi. La tour prépare
    cet état elle-même sur la pile locale de l'agent, au besoin en contournant les protections de
    l'app (jamais ailleurs que sur une pile locale), puis dit à l'agent ce qu'elle a fait et
    l'ajoute aux seeds à prévoir. Le garde-fou d'un agent a déjà refusé cette préparation, et la
    ligne est restée bloquée toute une passe. Un état fabriqué ainsi n'est pas une donnée normale :
    un écart vu dessus se rejoue sur des données faites par l'écran avant d'être compté comme KO.
  - **Chaque KO**, la tour le rejoue elle-même avant d'en parler. Puis elle le classe :
    régression du lot (à dire tout de suite, avec la recommandation de ne pas livrer avant
    le correctif) ou défaut préexistant. Le classement se **date par `git log -- <fichiers de
    la cause>` entre la base du lot et la tête**, pas par la seule lecture de la cause : sur
    une passe, les quatre KO étaient antérieurs au lot, et le dire a changé la décision
    (corriger tout de suite ou trier). Dans les deux cas, une issue va au Backlog, et
    l'utilisateur trie ; un correctif décidé passe par le cycle normal dans un worktree
    libéré, avec un agent qui a déjà le cadre.
  - **Après la passe**, le jour même : réécrire `chemins-d-or.md` avec les apprentissages des
    agents (libellés réels, `h2` contre `h3`, montants à figer, codes HTTP), qui se perdent
    sinon. Réunir
    leurs « seeds à ajouter » en une issue au Backlog, pour qu'une passe parte un jour d'une
    base remise à zéro sans préparation à la main. Y ajouter
    un chemin d'or pour chaque fonction livrée par le lot qui en mérite un, après accord de
    l'utilisateur. Puis ranger les worktrees `qa-<k>` comme les autres. Comme ils n'ont pas de
    PR, la condition se réduit à un `git status --short` vide.
- Une fois tout mergé : `herdr workspace close` des sous-espaces créés par la tour,
  `git worktree remove` (jamais `--force` ; avant chacun, la PR de la branche est mergée et
  `git status --short` du worktree est vide), suppression des liens de mémoire.
  **Rien d'autre** : pas de `git branch -D` sur les branches mergées, c'est une écriture git
  qui appartient à l'utilisateur.
- **Libérer ce que l'utilisateur abandonne** : une issue encore assignée au login
  courant qui sort du lot sans suite reste invisible pour l'autre tour. Proposer
  `--remove-assignee @me` ; une issue en Review reste à son auteur jusqu'au merge.
- **Écrire le journal du lot dans le dépôt**, `.claude/tower-control/journal.md` :
  issues traitées, décisions prises par l'utilisateur, prémisses corrigées, ce qui
  reste à faire. C'est du projet, ça reste dans le projet. Le journal est commun :
  chaque lot y est une section ajoutée en fin de fichier, titrée avec sa date et le
  login. Deux clôtures en parallèle conflictent à cet endroit sans la ligne
  `.claude/tower-control/journal.md merge=union` du `.gitattributes` ; si elle
  manque, la proposer.
- **Remonter dans `references/retours.md` du skill** ce qui vaut pour tout projet :
  ce qui a coincé et la règle qui en sort, ce qui a bien marché, les ordres de
  grandeur — sans nom de projet ni numéro d'issue, titre de section compris.
- **Puis confronter le skill aux leçons du lot** : pour chaque leçon, l'endroit de
  `SKILL.md`, `assets/` ou `references/herdr.md` qui la contredit ou l'omet. Proposer
  les retouches à l'utilisateur (AskUserQuestion en forme positive, une recommandation
  par retouche) et les appliquer après son accord. Deux lots ont rempli `retours.md`
  sans toucher au skill, qui disait encore l'inverse sur l'attente ; l'utilisateur a dû
  le demander. C'est cette étape qui fait que le lot suivant se passe mieux ; ne pas la
  sauter parce que le lot est fini.
