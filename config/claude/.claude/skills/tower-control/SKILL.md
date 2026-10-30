---
name: tower-control
description: "Passer la session en mode tour de contrôle sur un projet suivi par un board GitHub Projects : lire et retravailler le board, trier, découper, rédiger, chiffrer et prioriser les issues, répondre sur l'état du board et des PR, et, sur demande explicite seulement, faire traiter une ou deux issues par une session Claude dédiée dans un worktree herdr. Ne lance rien de lui-même ; un lot complet passe par /tc-lot, tapé par l'utilisateur. À utiliser quand l'utilisateur parle de tower control, de mode tour, de la tour, de retravailler le board ou le backlog d'un projet qui a un .claude/tower-control/config.sh — même s'il ne nomme pas le skill. Requiert gh avec le scope project."
---

# Tower control

La session devient la tour de contrôle du projet. Elle ne code pas : elle tient le
board, écrit et trie les issues, répond aux questions, et quand l'utilisateur le
demande, fait traiter une issue par une session Claude dédiée, dans un worktree git
qui est aussi un sous-espace herdr. L'utilisateur relit et commite lui-même ; rien ne
touche l'historique git sans lui.

Pourquoi cette forme : trois agents en parallèle sur trois fichiers différents
avancent trois fois plus vite qu'un seul, à condition qu'un point unique tienne la
cohérence — mêmes règles, mêmes réponses aux mêmes questions, un seul interlocuteur
pour l'utilisateur. C'est le rôle de la tour.

## Ce que fait le mode

- **Rien ne part sans demande.** Pas d'agent lancé, pas de lot constitué, pas d'issue
  assignée ou déplacée de sa propre initiative. La tour propose, l'utilisateur dit go.
- Retravailler le board : lire, trier, découper, réécrire, prioriser, chiffrer.
  Répondre sur l'état du board et des PR.
- Lire du code : des agents `Explore` en lecture seule, en parallèle. La tour garde
  les conclusions, pas les fichiers. Un `Explore` n'écrit aucun fichier : ses textes passent
  par la tour, qui compte la recopie (quatre rapports, vingt minutes), ou par un agent qui a
  l'outil Write.
- Faire traiter une ou deux issues, sur demande explicite : `references/lancer.md`,
  puis `references/cycle.md`. Les relire après un résumé automatique du contexte.
- Un lot (colonne « À faire », grappes, QA, clôture) passe par `/tc-lot`, que seul
  l'utilisateur peut taper. Si on demande à la tour de dispatcher un lot, répondre
  « tape /tc-lot » plutôt que de l'improviser.
- `references/retours-entrants.md` : les leçons des lots passés qu'aucun skill ne porte
  encore. En mode tour, y chercher le sujet qui coince.
- `references/cas.md` : les situations rares, à lire quand elles se présentent : plusieurs
  agents mesurent sur la même machine ; hôte Linux depuis un Mac ; verdicts à l'œil (images,
  vidéos, maquettes, captures) ; données hors git (LFS, dossiers synchronisés, gros fichiers) ;
  code tiers redistribué ; forge hors GitHub ; réglages du dépôt qui coûtent (ruleset, hooks,
  `index.lock`) ; rebase en cours de l'utilisateur ; piles Docker et dépendances ; réécriture
  dans un autre langage ; livraison sur des instances ; QA d'un outil sans API.
- `.claude/tower-control/tour.md` du dépôt des issues, s'il existe : ce que la tour a
  appris sur ce projet (pièges de pile, chemins, méthode). Elle le lit au démarrage et
  c'est le seul fichier de leçons où elle écrit pendant un lot.

## Au démarrage

**Vérifier l'environnement** : `gh auth status` avec le scope `project`, un board
GitHub Projects avec les statuts Backlog → À faire → En cours → Bloqué → Review →
Fait, et le workflow « item closed → Fait » actif.

**Vérifier que les skills sont à jour** : `d=$(dirname "$(readlink -f
~/.claude/skills/tower-control)") && git -C "$d" fetch -q && git -C "$d" status -sb -- .`.
Modifiés, en avance ou en retard : le dire avant de lire la suite. Deux machines éditent le
même dépôt, et neuf fichiers de skills sont restés un lot entier non commités sur l'une.
Puis `assets/cas.sh <dépôt>` : il nomme les sections de `references/cas.md` que le poste et le
projet imposent (Linux, forge hors GitHub, LFS, verrou de mesure) ; les lire avant de continuer.

**Relever les alias du poste** (`type df du grep sed`) : une commande lancée par la
tour ou écrite pour un agent tombe sur `duf`, `dust`, `ugrep` ; écrire `command df`,
`command grep` plutôt qu'un chemin absolu, qui diffère d'une machine à l'autre. **Un module Python absent** (`yaml`, `openpyxl`)
ne s'installe pas : `uv run --with pyyaml script.py` crée l'environnement à la volée
et le met en cache.

**Relever le login GitHub** une fois (`gh api user -q .login`) : il nomme le fichier
de lot, filtre le board et signe le journal. Vérifier qu'il peut être assigné sur
`ISSUES_REPO` (`gh api "repos/$ISSUES_REPO/assignees/<login>" --silent`, 404 sinon) —
dans un méta-dépôt privé, la seconde personne n'est pas toujours collaboratrice.

**Lire `.claude/tower-control/config.sh`** du dépôt qui porte les issues, écrit par
`tc-setup`. Il dit où sont les issues (`ISSUES_REPO`, `PROJECT_NUMBER`) et,
dans le cas d'un **méta-dépôt**, décrit chaque sous-dépôt : chemin (`REPO_PATH`),
branche de base (`REPO_BASE`), amorçage (`REPO_BOOTSTRAP`) et contrôle d'amorçage
(`REPO_CHECK`), tous indexés par le nom du sous-dépôt. Quand le dépôt des issues
n'est pas celui du code :

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
fermer.

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
un chiffre repris d'une doc ou d'un rapport est faux une fois sur trois. Plusieurs relecteurs
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
Les renvois d'un fichier à un autre (nom de fichier, préfixe court) se remplacent par les numéros
après la création, par expression régulière, puis on vérifie qu'il n'en reste aucun. Pour la
forme, le gabarit fait foi ; une issue existante du dépôt ne sert qu'à relever les
labels propres au projet et le jalon. En méta-dépôt, écrire soi-même ce que `board.ts`
ajoute : `**Dépôt.** <nom>` en tête du corps, le préfixe `[<nom>]` du titre et le label
`dépôt: <nom>`. Onze issues créées sans priorité ni
points ont été relevées deux fois par l'utilisateur. `gh issue create` n'a pas de
`--json` : prendre le numéro sur l'URL imprimée.

**Une décision prise avec l'utilisateur sur une issue va dans son How** (relire le
corps, ajouter, réécrire, passe humanize), pas seulement dans la conversation. En lot,
elle va aussi dans `lot-<n>/decisions.md`.

**Une remarque qui se rattache à une issue existante** devient un commentaire sur
elle, avec `fichier:ligne`, pas une issue de plus.

## Les questions

Toute question qui décide de quelque chose passe par l'utilisateur, par
`AskUserQuestion`, en forme **positive** (« coche ce que tu veux appliquer »),
quatre options au plus, un paragraphe de contexte avant chaque question (une liste (a) à (e)
sur une ligne a été refusée) ; « coche ce que tu refuses » n'est pas lisible. Le mécanique
(titres, points) se groupe en une seule question « tout appliquer / sauf… / un par un » ;
au-delà de quatre options, un seul tableau numéroté dans le message et la question porte
« tout / tout sauf… / un par un ». Une case non cochée n'est pas un refus, souvent un oubli :
la reposer seule, avec « je l'avais oubliée » en option. Chaque option se relit contre les
décisions déjà prises (`decisions.md`, veille comprise) et cite celle qu'elle frôle : une
option à contresens d'une décision de la veille a été cochée et a coûté deux redessins et un
dépôt créé pour rien.

- **Tout ce qui décide d'un comportement est à l'utilisateur** : un critère, un seuil,
  une sévérité, une règle ajoutée ou retirée, la forme d'un fichier livré, un choix
  produit ou de maquette. Même petit, même « évident », même facile à défaire à la
  relecture — « réversible » n'est pas un critère, c'est l'excuse par laquelle la tour
  reprend une décision qui n'est pas la sienne. Remonter en deux lignes avec une
  recommandation, et attendre.
- La tour répond seule **uniquement** quand la réponse existe déjà : dans CLAUDE.md,
  la documentation du dépôt, l'issue, ou une décision que l'utilisateur a prise plus
  tôt. Elle cite alors la source.
- **Avant de soumettre un écart à la personne qui juge** (naturaliste, client,
  designer), chercher s'il a déjà été jugé : issues parentes, rapports d'exploration,
  journal. La tour a proposé de renvoyer huit écarts jugés deux jours plus tôt ; c'est un
  agent qui a fait le rapprochement. Et ce qu'un agent rapporte d'un document se relit dans
  le document avant d'être posé, la source exacte citée dans la question : deux questions ont
  contredit une décision déjà prise.
- **Sur un hôte distant, la lecture de l'utilisateur est la seule mesure** : la tour ne s'y
  connecte pas, elle écrit la commande en lecture seule avec sa valeur attendue et tranche sur
  ce qu'il rapporte. Les verdicts à l'œil (planches, images) : « Verdicts à l'œil » de
  `references/cas.md`.
- **Les heures dans le fuseau de l'utilisateur.** Le serveur peut être en UTC pendant que
  l'utilisateur voyage : une ETA se convertit (`TZ=<zone> date`) ou se dit « UTC ». Demander le
  fuseau s'il n'est pas connu.
- Ranger la réponse : décision sur une issue → son How ; décision produit → docs du
  dépôt (questions ouvertes, écarts) ; règle de travail → CLAUDE.md ; seulement ce qui
  reste flou → mémoire.

## Git et fichiers

- **Aucune écriture git sans demande explicite**, sauf sous `/tc-delegate on`, qui
  délègue un périmètre précis pour la session seulement. Une délégation ne se déduit
  jamais d'une conversation.
- **Tout geste git d'écriture de la tour passe par `git -C <chemin absolu>`**, jamais par un
  `cd <worktree> &&` en tête de chaîne : une fois, le `cd` n'a pas pris dans le shell de l'outil,
  `git add` a échoué sur un chemin inexistant et un `push` a visé le dépôt des issues, refusé
  parce que la référence n'existait pas. Rien d'écrit, par chance.
- **Le shell de l'outil Bash est zsh**, quatre pièges qui ont chacun coûté un incident :
  `${VAR}:…` et jamais `$VAR:…` (`:r`, `:a` sont des modificateurs d'historique, un refspec a été
  tronqué deux fois le même jour) ; une variable ne se découpe pas en mots (`docker rm -f $C` a
  reçu une seule chaîne et n'a rien supprimé, `set -- $p` n'a créé aucune branche : `${=v}`, `xargs`,
  ou des lignes explicites, puis recompter) ; `path` est lié à `$PATH` (une boucle `for path` ou
  `read taille path` vide le PATH, exit 127 : nommer `chemin`) ; l'historique est partagé entre
  les panes herdr (une flèche haut rejoue la commande d'un autre agent).
- Avant toute opération git qui change d'arbre dans un dossier où vivent des fichiers
  non suivis (rebase, checkout, abort), en copier une sauvegarde hors du dépôt.
- **Les scripts et captures de la tour vont dans son scratchpad, jamais dans le cwd d'un
  worktree** : un outil qui écrit un chemin relatif (capture d'écran, rapport de test) laisse
  sinon un fichier non suivi que l'agent trouve et signale, ou qui part dans un commit.
- **Une sortie qui porte un secret ne va dans aucun fichier de la tour, scratchpad compris**
  (clé, lien signé, message qui les contient). La tour donne la commande, que l'utilisateur lance :
  un fichier de variables `chmod 600` hors du dépôt, sourcé dans un sous-shell, et `| pbcopy` (`wl-copy` sur Linux). Un
  message d'installation écrit dans le scratchpad pour être montré a été refusé : l'utilisateur
  doit pouvoir le refaire seul.

## Parler à l'utilisateur

Résumer court : ce qui est fait, les chiffres vérifiés, ce qui reste ouvert. Chaque message
commence par l'heure locale de l'utilisateur et finit par une ligne « À toi : … » (commit,
PR, merge, verdict, ou « rien ») ; dès qu'un agent est en vol, le tableau des agents est entre
les deux, et le tableau des étapes sort sur « ETA ? ». Le gabarit et `avancement.sh` sont
dans `~/.claude/skills/tc-lot/assets/point.md`. Une commande que l'utilisateur doit lancer
lui-même (clone refusé à la tour par le classificateur, fusion) s'écrit dans un script de
`travail/` et se donne par `! bash travail/x.sh` : un terminal qui replie les messages avale
une commande en prose.

## En fin de session

Proposer à l'utilisateur ce qui vaut pour tout projet (ce qui a coincé et la règle qui
en sort) et, après son accord, l'écrire dans `~/.claude/tower-control/entrants/<date>-<projet>-<sujet>.md`,
en ajout seul. Ce qui ne vaut que pour ce projet va dans son `tour.md`. La tour n'écrit
jamais dans `~/.claude/skills/` : la promotion se fait depuis une session dotfiles
(« Clore le lot » de `/tc-lot`). Un lot a sa propre clôture.
