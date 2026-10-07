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

**Vérifier que le défaut peut encore arriver.** Pour chaque issue, écrire en une
phrase le scénario daté qui le déclenche dans l'état actuel du projet. Si on n'y
arrive pas, le dire à l'utilisateur avant de lancer, « jeter » en première option :
une issue codée et revue a déjà été jetée pour cette raison. Confronter aussi la piste
de l'issue à la doc du dépôt avant de la recopier dans une consigne.

**Si plusieurs agents mesurent sur la même machine**, poser un verrou commun avant de
lancer (`lockf`, une commande par verrou, règle écrite dans un `MESURES.md` du dossier
des worktrees, seuil d'espace disque avant tout balayage) ; voir `references/retours.md`.

**Trancher avant de lancer** ce que les issues laissent ouvert (« à trancher »). Un
agent bloqué sur une décision produit est un agent qui attend ; la tour prend la
décision avec l'utilisateur en amont et l'écrit dans la consigne.

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

Envoyer à chaque agent **la consigne commune et la consigne de l'issue en un seul
`agent prompt`** (les deux fichiers concaténés) : en deux envois, l'agent répond à la
première par « quelle issue ? » et la seconde reste derrière sa question.

Passer les issues lancées en « En cours » sur le board
(`gh project item-edit <n> --owner <o> --url <issue> --field Status --value "En cours"` :
la forme par URL et nom de champ évite les identifiants de nœuds).

## 3. Le cycle, issue par issue

```
tour  : consigne commune + consigne issue → agent        board : À faire → En cours
agent : lit l'issue, code, teste, revue lead-engineer, compte rendu, s'arrête
tour  : attend en arrière-plan, lit le compte rendu, VÉRIFIE ELLE-MÊME,
        résume à l'utilisateur                            board : En cours → Review
user  : ouvre le sous-espace herdr, relit le diff, commite, ouvre la PR (Closes #N)
tour  : vérifie le lien PR → issue par `gh pr view <PR> --json closingIssuesReferences`,
        jamais par une regex sur le corps (GitHub accepte « Closes: #N », « fixes #N »…)
tour  : crée la branche suivante depuis ce HEAD, envoie la consigne suivante
merge : ferme l'issue, le workflow du board la passe en Fait — la tour n'y touche pas
```

**Attendre sans surveiller** : `herdr agent wait <nom>` lancé en arrière-plan
(`run_in_background`) réveille la tour quand l'agent passe en `done` ou `blocked`.
Ne pas boucler sur `agent get`.
Quand l'agent lance des mesures longues en arrière-plan, `wait` rend « done » trop tôt :
demander que le compte rendu ne soit écrit qu'à la toute fin, et attendre ce fichier
(`until [ -f … ]; do sleep 120; done`) avant `agent wait`.

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
chose à dire.

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
l'utilisateur qui trie. `gh issue create` n'a pas de `--json` : prendre le numéro sur
l'URL imprimée.

**Quand la branche est en retard et partage des fichiers avec ce qui a été fusionné**,
ne pas se contenter de `merge-tree` : jouer la fusion dans un worktree jetable
(`git worktree add --detach` sur un `commit-tree` du résultat), install, build,
typecheck, tests, puis le retirer. Un rebase sans conflit a déjà cassé `tsc` deux fois.

**Une branche par issue, et d'où elle part.** Après le commit de l'utilisateur, la
tour crée la branche suivante dans le même worktree (`git switch -c` — c'est la tour
qui le fait, l'agent en est interdit). Elle part de **`origin/<branche de base>`
après un `fetch`**, pas du HEAD local : d'autres worktrees ont pu merger entre-temps, et une
branche partie du HEAD local ne « prend » jamais ces changements toute seule. Faire
`git branch --unset-upstream` aussitôt, sinon un `push` nu irait sur la branche de
base. On n'empile sur le HEAD local que si la PR précédente n'est pas encore mergée.

**Avant de passer en Review, mesurer le retard.** `git fetch` puis
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
- L'utilisateur ne répond pas dans les panes ; s'il l'a fait, vérifier l'état de
  l'agent avant d'envoyer quoi que ce soit, pour ne pas répondre deux fois. Un texte tapé
  sans être envoyé reste dans la zone de saisie : `send-keys enter` ne le soumet pas (il
  ne sert qu'aux dialogues), le prochain `agent prompt` l'envoie concaténé. Le lire comme
  la réponse de l'utilisateur et la consigner.
- Un agent qui pilote le navigateur a besoin que le site de sa pile (`localhost:<port
  dérivé>`) soit autorisé dans l'extension : le prévoir dans la consigne.

Un agent qui tourne en rond se voit au `agent read` : l'interrompre
(`agent send-keys <nom> esc`), reformuler, et ne pas dépasser deux relances sans en
parler à l'utilisateur.

## 5. Clore le lot

- Proposer l'ordre de merge qui minimise les conflits (les grappes qui partagent un
  fichier en dernier, l'une après l'autre).
- Une fois tout mergé : `herdr workspace close` des sous-espaces créés par la tour,
  `git worktree remove`, suppression des liens de mémoire.
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
  grandeur — sans nom de projet, sans numéro d'issue. Puis retoucher `SKILL.md` et
  `assets/` en conséquence. C'est cette étape qui fait que le lot suivant se passe
  mieux ; ne pas la sauter parce que le lot est fini.
