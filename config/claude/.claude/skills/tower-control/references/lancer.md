# Faire traiter une issue : préparer et lancer

À lire avant de lancer un agent, pour une issue seule comme pour les grappes d'un lot
(`/tc-lot`). Les chemins `assets/…` et `references/…` sont ceux du skill
`tower-control`. Relire ce fichier après un résumé automatique du contexte.

## Environnement

`test "$HERDR_ENV" = 1` : le lanceur et le guetteur passent par herdr. Relever
`git config push.default` : en `upstream`, un `git push origin <branche>` sans
`:destination` part vers l'amont de la branche, qui est la base quand elle a été créée
depuis `origin/<base>` sans `--no-track`.

Avec un méta-dépôt, deux conséquences de plus de `config.sh` :

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

## Le fichier des worktrees

**Les worktrees sont décrits dans `lot-<login>.sh`**, à côté de `config.sh`.
`config.sh` porte les faits du projet et se partage ; le fichier de lot porte
`GRAPPES` (une grappe : un worktree nommé et sa branche, `"<dépôt> <branche>"` en
méta-dépôt), c'est la tour qui l'écrit, et git l'ignore (`.claude/tower-control/lot-*.sh`
dans le `.gitignore` du dépôt des issues ; si la ligne manque, la proposer). Une issue
traitée hors lot y a sa grappe comme les autres : ajouter `GRAPPES[<nom>]="<branche>"`
**après** la ligne `declare -A GRAPPES=(…)` si elle existe (placée avant, elle est effacée),
sans toucher aux grappes d'un lot en vol ; les tableaux sont déclarés par `config-lib.sh`
avant la lecture du fichier (`config.example.sh` donne les deux formes). Lancer
`lancer.sh <chemin du dépôt des issues> <nom>`, qui ne démarre que celle-là.

Le fichier de lot peut aussi corriger un chemin de poste, élément par élément
(`REPO_PATH[app]=…`), ou faire partir les branches de `origin/<base>` plutôt que de
la branche locale (`REPO_BASE[app]="origin/develop"`, avec un `git fetch` avant de
lancer : la tour ne met pas à jour le `develop` local du client) ; un
`declare -A REPO_PATH=(…)` y effacerait les autres sous-dépôts. Au groupement d'un
lot, ne remplacer que la ligne `GRAPPES` : les autres lignes du fichier sont propres
au poste et durent d'un lot à l'autre. Si `config.sh` contient encore des `GRAPPES`
(dépôt d'avant ce découpage), le lanceur s'en sert faute de fichier de lot et
prévient : proposer à l'utilisateur de les déplacer, parce qu'à deux ce sont celles du
premier qui a écrit.

## Avant d'écrire la consigne

- L'issue est assignée au login courant, seul, relu après l'assignation (« Le board
  et l'assignation » du skill) ; sinon, ne pas lancer.
- Elle a été relue contre le code (« Trier et relire le backlog » du skill) ; sinon,
  le faire maintenant.
- **Premier lancement sur un projet** : relire le workflow du `CLAUDE.md` du dépôt. Écrit avant les skills,
  il demande souvent un mode plan relu par trois agents, des arrêts par sous-phase et un `git add` permis,
  ce qui contredit le cadre de la tour. Le réécrire avec l'utilisateur (session directe, agent de la tour,
  règles communes) et le faire commiter avant de créer les worktrees.
- **Si la doc des écrans est en retard sur le code**, lancer d'abord, seule, la PR qui la remet d'accord : les
  agents relisent cette doc avant de toucher un libellé et « corrigeraient » le code dans le mauvais sens.

**Regarder ce que font les autres**, pour information : les issues « En cours » et
« Review » assignées à d'autres, et les PR ouvertes d'autres auteurs dans chaque
dépôt de code (`gh pr list --state open --limit 200 --json
number,author,headRefName,files` lancé depuis ce dépôt, en écartant celles dont
`.author.login` est le login courant). Un fichier commun avec une grappe se dit dans le point à
l'utilisateur ; ça ne bloque pas le lancement, ça se règle à la PR.

**Mesurer chaque chiffre de la consigne avec la commande qui servira à vérifier**, même
s'il vient de la doc du dépôt : une doc de mesures est périmée dès qu'une issue mergée
touche la même chaîne, et une consigne écrite dessus coûte une issue sans objet ou une
question d'agent.

**Si plusieurs agents mesurent sur la même machine**, poser un verrou commun avant de
lancer (une commande par verrou, règle écrite dans un `MESURES.md` du dossier
des worktrees, seuil d'espace disque avant tout balayage).
Le verrou a deux niveaux : `lourd`, partagé (vidéos entières, construction de zéro, tests
lents, deux agents peuvent le tenir ensemble), et `chrono`, exclusif (un temps publié attend
que tout le lourd soit fini) ; un script Python `fcntl.flock` fait les deux et reste compatible
avec `lockf`. Toute compilation chronométrée ou partie de zéro passe sous le verrou, comme la
mesure. **Le réseau n'est jamais sous le verrou** : un téléchargement de 11 Go mis sous le
verrou par une consigne a bloqué les mesures 24 min sur un réseau d'hôtel.
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
décision avec l'utilisateur en amont, et l'écrit dans la consigne et dans le How de
l'issue. Une question de l'utilisateur arrivée après l'écriture d'une consigne peut
l'invalider (« et si la recette n'a pas de Front Door ? ») : lancer d'abord ce qui
n'en dépend pas, répondre, réécrire la consigne et l'issue, puis lancer.

## Préparer les consignes

Une consigne courte par issue sur le modèle de `assets/consigne-issue.md` (son Attendu reprend
la Must-Have), dans `lot-<n>/` du dépôt des issues. Ce que l'agent reçoit est assemblé par
`assets/consigne.sh <dépôt> <fichier> [--lot <fragment>]` : la consigne commune **du skill**
(règles, interdits, forme du compte rendu), `consigne-projet.md` du dépôt, le fragment de lot s'il
y en a un, le fragment « shells », puis la consigne. Jamais une copie de la consigne commune dans le
projet : une copie par lot avait pris 28 lignes de retard en trois lots. Le fichier assemblé reste
dans `envoyees/` : c'est la trace de ce que l'agent a lu. Montrer les consignes à l'utilisateur
avant tout lancement.

**Faire committer** ce qui doit être dans les worktrees (un `CLAUDE.md` retouché,
par exemple) : les branches partent de la branche de base commitée, pas de l'arbre
de travail. Avec un méta-dépôt, les règles du projet ne sont pas dans le worktree
(son `CLAUDE.md` est celui du client) : elles voyagent par la section « Projet » de
la consigne commune, `.claude/tower-control/consigne-projet.md` du méta-dépôt.

## Lancer

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
La sonde de port libre doit aussi interroger docker (`docker ps --format '{{.Ports}}'`) : `ss` ne voit pas
un port qu'un conteneur publie, et un worktree a reçu le PostgreSQL d'un autre, puis deux fois les mêmes
ports d'images.

**Relire les commentaires de l'issue juste avant de l'envoyer** (`gh issue view <N> --comments`),
pas seulement son corps au groupement : un commentaire de l'utilisateur posté entre-temps a
changé la règle d'une issue déjà lancée, et l'agent a dû refaire son passage.

Envoyer à chaque agent le fichier assemblé **en un seul envoi, par `assets/envoyer.sh <agent>
<envoyee>`** : en deux envois, l'agent répond au cadre par « quelle issue ? » et la consigne reste
derrière sa question. Le script vérifie que l'agent a bien pris le texte (« Attendre » de `cycle.md`).

Passer les issues lancées en « En cours » sur le board (« Poser un champ » du skill).
