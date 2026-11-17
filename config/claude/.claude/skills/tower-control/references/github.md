# Le board, le backlog et GitHub

À lire avant de lire le board, de relire une issue ou d'écrire sur GitHub, et après un résumé
automatique du contexte. Les chemins `assets/…` sont ceux du skill `tower-control`.

## Méta-dépôt et dépôt public

Quand le dépôt des issues n'est pas celui du code :

- toute commande `gh issue …` porte `--repo "$ISSUES_REPO"`, y compris dans les
  consignes envoyées aux agents : leur worktree est dans le dépôt du code, `gh` y
  résoudrait le mauvais dépôt ;
- **si le méta-dépôt est privé et inconnu du client** (le cas courant : c'est le
  dossier personnel du prestataire), rien de ce qui part dans le dépôt du code ne le
  cite — ni `Closes owner/meta#N`, ni un numéro d'issue, ni un chemin de ses
  `docs/` — dans le code, les runbooks, les commits ou les PR. La consigne projet
  le dit aux agents, la tour le vérifie (`git diff | grep`, et `git log` des branches et de
  la base avant la première PR) avant de passer en Review, et c'est elle qui ferme l'issue
  quand elle constate le merge. Le
  `Closes owner/meta#N` ne se justifie que pour un méta-dépôt que le client voit.

**Si le dépôt des issues est public**, tout `.claude/tower-control/` s'ignore dès le
départ (journal, consignes, décisions sont le dossier personnel de la tour), ou il
vit dans un méta-dépôt privé : l'utilisateur a dû sortir le dossier du suivi après
neuf lots, et le rebase qui a suivi a buté sur un fichier non suivi puis effacé onze
fichiers du disque à l'`--abort`.

## Le board et l'assignation

Lire le board par `assets/board.sh lire <dépôt>` : il pose la limite (sans elle `gh` s'arrête à 30
items, sans erreur) et le repli sur `.assignees` absent quand personne n'est assigné.

- **assignée au login courant** : la tour peut la traiter ;
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
qui lisent le board en même temps s'assignent toutes les deux. `assets/board.sh assigner <dépôt> <N>`
assigne, relit, et se retire si quelqu'un d'autre y figure (code 3 : ne pas lancer, le dire) ou si
l'assignation n'a pas pris (code 4). Si les deux tours se retirent, l'issue redevient libre et sera
reproposée.

**Poser un champ** : `gh project item-edit <n> --owner <o> --url <issue> --field
Status --value "En cours"` (la forme par URL et nom de champ évite les identifiants de
nœuds). **Pour plus d'une dizaine de champs, `assets/board-field.py`** : la forme par
URL relit tous les items du projet à chaque appel et épuise le quota GraphQL en points
(seize issues à quatre champs ont bloqué GraphQL quarante-cinq minutes alors que
`rate_limit` affichait 4 300 appels restants) ; le script lit le projet une fois puis
pose un champ par mutation. À la création d'une issue, poser Statut, Priorité et
Points avec l'id que `gh project item-add` rend : le listing du projet est en retard
de plusieurs minutes après des ajouts (comme le compteur `open_issues` des jalons :
recompter par `gh issue list --milestone`), et un workflow du board peut poser « À faire »
par défaut.

**Re-prioriser ou re-chiffrer, c'est une écriture sur le board, et une seule** : la
priorité et les points ne sont ni dans le corps ni en label. Une issue d'avant cette
règle porte encore un pied « Complexité (planning poker) » et un label `complexité: N`
qui deviendraient faux : en re-chiffrant, proposer de les retirer.

**Review n'en sort que par le merge**, via le workflow « item closed → Fait » : la tour
ne passe jamais une issue en Fait elle-même.

**Relire l'état d'une PR (`gh pr view <N> --json state,mergedAt`) avant toute phrase
sur lui** : une PR prise par l'auto-merge a été annoncée deux fois « en attente de ton
merge » alors qu'elle était fusionnée depuis deux heures.

**Les issues « méta »** (une brique à 13 points) deviennent des parentes GitHub avec des
sous-issues natives (`POST /repos/{o}/{r}/issues/{parent}/sub_issues`, id numérique de
l'enfant) : la parente reste en Backlog avec une priorité, sans points ni assigné, et
seules les sous-issues se traitent. GitHub ne ferme pas une parente quand ses enfants
le sont : à chaque sous-issue fermée, la tour coche sa case dans la Must-Have de la
parente (geste mécanique), et quand tout est coché, elle propose à l'utilisateur de la
fermer. Avant de créer une sous-issue, lire la parente d'une issue voisine du même sujet : une parente recopiée
d'un exemple a rattaché une issue à la mauvaise mère.

## Trier et relire le backlog

**Relire une issue contre le code** avant de la traiter ou de la reprioriser, par des
agents `Explore` (trois à cinq issues chacun, en parallèle) : reproductible encore ?
fichiers touchés ? choix laissés ouverts, avec recommandation ? doc du dépôt
contredite ? chiffre du Why mesuré maintenant ? Sur vingt issues, huit prémisses
fausses ont été trouvées ainsi.

**Vérifier que le défaut peut encore arriver.** Pour chaque issue, écrire en une
phrase le scénario daté qui le déclenche dans l'état actuel du projet. Si on n'y
arrive pas, le dire à l'utilisateur, « jeter » en première option : une issue codée
et revue a déjà été jetée pour cette raison. Confronter aussi la piste de l'issue à
la doc du dépôt avant de la recopier dans une consigne, et une option proposée par un
tiers (courriel du client) aux données avant d'en faire une issue : une option irréalisable
dans les données coûte une question fausse à l'utilisateur.

**Une relecture qui ne produit pas de code** (audit du dépôt, relecture complète du
backlog) se confie à des agents de lecture seule (une zone ou un groupe d'issues
chacun, format de constat imposé, chiffre mesuré par ligne) ; les textes d'issues sont
rédigés dans un dossier par des agents qui ont l'outil Write, repris par `SendMessage`
(contexte gardé) ; la tour les applique par `appliquer-issues.py` après relecture de
l'utilisateur, et aucun agent n'écrit sur GitHub. Quand le travail naît d'un besoin
utilisateur plutôt que d'un backlog, **interviewer d'abord** (`AskUserQuestion`, quatre
questions par tour, état mesuré de la commande en main), et donner la trame de décisions
aux agents comme contrainte ; après chaque décision prise en cours de route, leur demander
quelle décision n'est portée par aucune issue : une décision en crée d'autres.

**Avant de montrer des textes rédigés par des agents, le lecteur froid.** Des agents
neufs, sans le contexte de la session ni accès au code, lisent chaque texte. Ils le
résument en une phrase et citent tout ce qui les arrête. Un texte qui échoue repart à
son auteur, avec un vocabulaire commun pour les mots internes, puis il est relu à
froid. Sur 87 textes passés par humanize, 30 restaient incompréhensibles hors de la
session. La consigne du lecteur dit qu'un texte à plusieurs points mineurs mais sans point
bloquant reste « clair », sinon chaque lecteur applique sa règle. Puis une relecture
factuelle, chaque chiffre (lignes, tests, numéros de ligne, pistes déjà faites) remesuré :
un chiffre repris d'une doc ou d'un rapport est faux une fois sur trois. Une affirmation d'absence
(« plus aucun », « seul ») se prouve par un `grep` sur tout le dépôt, pas sur les fichiers de l'issue. Plusieurs relecteurs
aux angles distincts (architecture, langage cible, exactitude, utilisateur final) se
recouvrent peu ; la seconde passe revient au même relecteur par `SendMessage`. Avant de
montrer un texte à valider, compter les décisions encore ouvertes et les poser toutes : ce
qui a sa réponse dans les sources (la tour répond et cite), ce qui se tranche à la PR
(« à trancher à la PR » dans le What), ce qui revient à l'utilisateur.

## Écrire sur GitHub

Tout ce que la tour écrit sur GitHub suit `~/.claude/skills/tc-commun/conventions.md` :

- **le gabarit d'issue** (`~/.claude/skills/tc-commun/issue.md`) : Why ?, What ?, Must-Have,
  How ? ; la Must-Have ne liste que ce que la PR livre ;
- **une priorité et des points sur le board à chaque création**, `13` quand on ne sait
  pas chiffrer ; une parente a une priorité, pas de points ;
- **la passe `humanize`** sur chaque corps, retouche de corps et commentaire, texte
  final montré à l'utilisateur avant l'envoi (« Écrire sur GitHub » des conventions) ;
  cocher une case de la Must-Have n'en est pas une, c'est un geste mécanique.

**Une issue créée en chemin va dans la colonne Backlog, explicitement** (`item-add`
laisse le statut vide) : c'est l'utilisateur qui trie. Elle est créée avec ses champs par
`~/.claude/skills/tc-commun/appliquer-issues.py` (un fichier par issue, en-tête titre / labels / priorité /
points / parente / jalon, `--dry-run` d'abord), la priorité et les points proposés avec le texte.
Un renvoi d'un fichier à un autre s'écrit `#NEUVE-<fichier>`, que le script résout ; dans un commentaire
posté à la main, le remplacer puis vérifier par `grep NEUVE` (deux commentaires sont partis avec). Un corps réécrit
par script passe par un fichier vérifié (refusé s'il est vide ou plus court que l'original) puis
`gh issue edit --body-file` : un `python3 -c` cassé par des guillemets a posé un corps vide. Chaque
version reste lisible par GraphQL (`issue { userContentEdits { nodes { editedAt diff } } }`), qui sert à
restaurer. Pour la
forme, le gabarit fait foi ; une issue existante du dépôt ne sert qu'à relever les
labels propres au projet et le jalon. En méta-dépôt, écrire soi-même ce que `board.ts`
ajoute : `**Dépôt.** <nom>` en tête du corps, le préfixe `[<nom>]` du titre et le label
`dépôt: <nom>`. Onze issues créées sans priorité ni
points ont été relevées deux fois par l'utilisateur. `gh issue create` n'a pas de
`--json` : prendre le numéro sur l'URL imprimée.

**Une décision prise avec l'utilisateur sur une issue va dans son How** (relire le
corps, ajouter, réécrire, passe humanize), pas seulement dans la conversation. L'ajout part avec les
corrections du What, du Why ou de la Must-Have qu'il contredit, et le lecteur froid lit le corps entier :
il a trouvé dix contradictions laissées ainsi en un lot. En lot,
elle va aussi dans `lot-<n>/decisions.md`.

**Une remarque qui se rattache à une issue existante** devient un commentaire sur
elle, avec `fichier:ligne`, pas une issue de plus.

