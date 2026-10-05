---
name: backlog-setup
description: "Auditer un projet (code, docs du dépôt, sources externes, données réelles) et en tirer un backlog GitHub prêt à travailler : issues rédigées et chiffrées en planning poker, labels, GitHub Project avec statuts Backlog → À faire → En cours → Bloqué → Review → Fait, champs Points et Priorité, priorisation avec l'utilisateur, puis la méthode de travail qui passe la main à tower-control. À utiliser dès que l'utilisateur veut « se constituer un backlog », « lister ce qui ne va pas », « ouvrir les issues », « faire un board », « setup le projet sur GitHub », reprendre un projet ou un dépôt client, ou auditer avant de planifier — même s'il ne nomme pas le skill. Requiert gh avec le scope project."
---

# Backlog setup

Partir d'un projet — le sien, ou celui d'un client — et arriver à un backlog qu'on
peut dispatcher : des issues qui disent ce qui est cassé, pourquoi ça compte et par
où commencer, un board qui suit l'avancement sans qu'on le tienne à la main, et une
méthode de travail écrite là où elle survivra. `tower-control` prend le relais
ensuite, lot par lot.

Ce skill dit **comment** faire chaque phase. Le jugement — ce qui est grave, ce qui
passe en premier — se prend dans la session, avec l'utilisateur. Rien n'est créé sur
GitHub avant qu'il ait relu la liste.

Lire `references/conventions.md` (forme des issues, labels, priorités, points,
statuts) avant de rédiger quoi que ce soit, et `references/github-projects.md` avant
de toucher à un projet GitHub.

## 0. Où vivent les issues

Première question, à poser, jamais à deviner : **quel dépôt porte les issues et le
board ?** Trois cas rencontrés :

- **Le dépôt lui-même.** Un projet à un seul dépôt : issues, board et code au même
  endroit ; les PR ferment les issues par `Closes #N`.
- **Un méta-dépôt.** Pour un client, l'utilisateur tient un dépôt qui contient les
  sous-dépôts du client, ses notes, ses skills et ses instructions Claude. Les
  issues et le board vont **dans le méta-dépôt** — le client a souvent son propre
  outil de tickets, fonctionnels et peu rédigés, qui n'est pas le backlog technique.
  Chaque issue nomme alors le sous-dépôt concerné (label `dépôt: <nom>` et préfixe
  dans le titre). Demander si le client connaît ce méta-dépôt ; en général non, et
  alors **rien dans le sous-dépôt ne le cite** (pas de `Closes <owner>/<meta>#N`,
  pas de numéro d'issue dans le code, les runbooks, les commits ou les PR) : c'est
  la tour qui ferme l'issue quand elle constate le merge. Écrire cette règle dans
  la consigne projet de `tower-control`.
- **Un board existant.** L'utilisateur a déjà un projet GitHub : on y rattache, on
  n'en crée pas un second. Vérifier que ses statuts couvrent Bloqué et Review, et
  proposer de les ajouter sinon.

La réponse s'écrit dans `.claude/tower-control/config.sh` du dépôt qui porte les
issues, pour que `tower-control` la lise sans la redemander : `ISSUES_REPO`,
`PROJECT_OWNER`, `PROJECT_NUMBER`, `WORKTREES_DIR` (pour un méta-dépôt : **sous le
méta**, `<méta>/wt`, ajouté à son `.gitignore`, pour que les agents héritent de son
`CLAUDE.md` et voient ses `docs/`), et pour un méta-dépôt un tableau par propriété,
indexé par le nom de chaque sous-dépôt : `REPO_PATH`
(chemin), `REPO_BASE` (branche de base — `develop` sur un projet qui ne déploie pas
depuis `main`), `REPO_BOOTSTRAP` (ce qu'un worktree neuf doit lancer), `REPO_CHECK`
(ce qui prouve que l'amorçage a marché). `config.sh` se partage entre toutes les
personnes qui lancent une tour : les grappes du premier lot vont à côté, dans
`lot-<login GitHub>.sh`, et s'écrivent pour un méta-dépôt `"<dépôt> <branche>"`.
Deux lignes vont avec, dans le dépôt des issues : `.claude/tower-control/lot-*.sh`
dans son `.gitignore`, et `.claude/tower-control/journal.md merge=union` dans son
`.gitattributes`, pour que deux lots clos en parallèle ne conflictent pas.
Le lanceur de `tower-control` lit tout ça ; sans ces
tableaux il suppose un dépôt unique qui part de `main`. Le modèle complet est en
commentaire à la fin de `tower-control/assets/lancer.sh`.

## 1. Auditer

**Tout lire, pas échantillonner.** Le code en entier si c'est possible (quelques
milliers de lignes se lisent), les docs du dépôt, le `CLAUDE.md`, la CI, les tests.
Puis les **sources externes** : demander à l'utilisateur où elles sont (notes de
vault, cahier des charges, comptes rendus, dossier partagé) et les lire aussi — la
moitié des écarts produit viennent d'une spec que le code ne suit plus.

**Regarder les sorties réelles**, pas seulement le code : les derniers relevés, les
journaux, les livrables générés. Un contrôle qui produit 58 faux positifs se voit
dans son TSV, pas dans sa fonction.

**Mesurer avant d'écrire.** Chaque affirmation qui deviendra une issue se vérifie
sur les données réelles : un script jetable dans le scratchpad, un `grep`, un
compte. Marquer ce qui l'a été (label `vérifié`) et dire explicitement ce qui est
une lecture de code non vérifiée. Deux prémisses fausses dans un backlog coûtent
une question d'agent chacune plus tard.

**Classer** en bugs et défaillances silencieuses / produit et contrôles manquants /
qualité et robustesse / tests / documentation en dérive. Les défaillances
silencieuses — un fichier valide mais faux, un repli qui masque une erreur — passent
devant tout le reste.

**Livrer la liste dans la conversation**, numérotée, une à trois lignes par point
avec `fichier:ligne`, avant de créer quoi que ce soit. L'utilisateur écarte, fusionne,
ajoute. C'est lui qui connaît le contexte client.

## 2. Rédiger et créer les issues

Une issue par point retenu, dans la forme de `assets/issue.md` : constat (avec
« vérifié » quand c'est le cas), pourquoi c'est grave, piste, complexité en planning
poker. Les remarques mineures qui se rattachent à une issue existante deviennent des
commentaires, pas des issues. Titre = le défaut en une phrase, pas la solution.

Créer les labels puis les issues avec `scripts/board.ts` à partir d'un JSON
(`assets/backlog.json` en donne la forme) : le script est idempotent, un point déjà
créé n'est pas dupliqué. Les points sont un label `complexité: N` **et** le champ
Points du board, pour pouvoir sommer par colonne.

## 3. Le board

`scripts/board.ts` crée ou rattache le projet, remplace les statuts par défaut par
Backlog → À faire → En cours → Bloqué → Review → Fait (en conservant les
identifiants existants pour ne pas perdre les vues), crée Points et Priorité, ajoute
les issues, renseigne les champs. Il ne sait pas créer les vues — l'API ne le permet
pas : dire à l'utilisateur les deux à créer à la main (kanban par statut avec somme
des Points, liste triée par Priorité puis Points) et le workflow intégré « item
closed → Fait » à activer.

Le lien PR → issue se vérifie par `gh pr view --json closingIssuesReferences`, pas
par une regex sur le corps.

## 4. Prioriser, avec l'utilisateur

Proposer une grille P0 → P3 aux sens génériques de `references/conventions.md`, et
une affectation argumentée en une ligne par issue, groupée par priorité. Puis
attendre : c'est l'utilisateur qui tranche, et il retouche presque toujours deux ou
trois lignes. Ne rien appliquer avant. Les P0 du premier lot passent en « À faire ».

## 5. La méthode de travail

Avant le premier lot, sortir les règles de leur cachette :

- une règle de travail valable partout → `~/.claude/CLAUDE.md` ;
- un fait ou une règle propre au projet → `CLAUDE.md` du dépôt ;
- la mémoire ne garde que ce qui n'a pas encore trouvé sa place — elle ne suit pas
  les worktrees, donc rien de structurel n'y reste.

Puis préparer le relais à `tower-control` : `.claude/tower-control/config.sh`
(dépôt d'issues, projet, dossier des worktrees, amorçage), `lot-<login>.sh` (grappes), la section
« Projet » de la consigne commune, et le journal du dépôt. Grouper les premières
issues par fichiers touchés, pas par thème. Faire committer avant de lancer — le
fichier de lot, lui, est ignoré par git.
