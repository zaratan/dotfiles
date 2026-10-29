# Clore le lot

Les chemins `assets/…` et `references/…` sont ceux de `~/.claude/skills/tower-control/`.

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
      instance » de son runbook, ou de la vérification d'après merge écrite dans le How de
      l'issue, à défaut de l'Attendu de sa consigne.
  - **Une ligne vaut par son résultat**, pas par l'absence d'erreur : réponses écrites et
    comptées, score affiché avec sa valeur, mail arrivé dans la boîte de test.
  - **Chaque attente du cahier se relit contre les règles du produit avant la passe** : une
    question attendait que l'outil compte des jours, ce que son skill lui interdit, et l'écart
    n'a été vu qu'en pleine passe. Une suite de tests à rejouer se lance avec sa sortie dans un
    fichier : un échec vu une fois sur cinq passages n'a pas gardé son nom, et ne s'est plus
    reproduit.
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
  - **En deux temps quand une chaîne finit tard** : la zone du cahier que la dernière chaîne ne touche
    pas se joue avant son dernier merge, sur la base du moment, et la zone qu'elle touche après. Une
    heure gagnée sur un lot, aucun KO manqué. **`git fetch` avant d'amorcer un worktree de QA** : le
    lanceur lit `origin/<base>` dans les références locales, et un merge arrivé entre-temps manque
    (un worktree amorcé sur l'avant-dernier `main`, avancé à la main).
  - **Pour une commande plutôt qu'une application web**, la passe joue la vraie commande sur des **copies** des données
    (une commande qui écrit à côté de ses entrées ne doit jamais toucher les originaux), avec des chemins d'argent
    (entrées, options, langue et terminal, relances, pannes simulées) et des contrôles transverses : code de sortie,
    sortie standard contre sortie d'erreur, rien d'écrit hors des dossiers de sortie ni dans le dossier temporaire,
    pic de mémoire. Un seul agent suffit quand tout passe par le même verrou de mesure.
  - **Pour une TUI**, la passe se joue dans la vraie TUI par herdr, dans le terminal que le lanceur ouvre à droite
    de l'agent : `pane run` lance le binaire, `pane send-keys` envoie les touches **une par appel** (`down`, `enter`,
    `esc`, `ctrl+c`, `backspace`, `shift+tab`), `pane read --format ansi` relit l'écran avec ses couleurs (`38;5;n`),
    `pane wait-output --regex` attend un texte (`--match "EXIT="` trouverait la ligne de commande elle-même).
    `stty rows 24 cols 80` avant de lancer. L'historique zsh est partagé entre les panes : une flèche haut envoyée
    après la sortie du binaire a rejoué la commande d'un autre agent ; ne rien envoyer si le binaire ne tourne pas,
    quitter par Échap, lancer par un script. `HOME` isolé et faux binaires externes en tête du `PATH` dès que
    l'outil lit une configuration réelle (identifiants d'un service distant). Un binaire `bun --compile` local se
    signe (`codesign --sign -`) ou macOS le tue (137). Les données de la passe vont dans un dossier à soi
    (`/tmp/<projet>-qa-<k>`), supprimé à la clôture.
- **Mesurer le dossier des comptes rendus et les dossiers temporaires des agents** (planches, maquettes des
  sous-agents de revue) : 9,7 Go et 2 Go s'y étaient accumulés en un lot. Proposer la liste à supprimer.
- Ranger chaque worktree selon « Ranger un worktree » de `references/cycle.md`.
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
- **Remonter dans `references/retours.md`** ce qui vaut pour tout projet :
  ce qui a coincé et la règle qui en sort, ce qui a bien marché, les ordres de
  grandeur — sans nom de projet ni numéro d'issue, titre de section compris.
- **Puis confronter les skills aux leçons du lot** : pour chaque leçon, l'endroit de
  `tower-control` (`SKILL.md`, `references/`, `assets/`) ou de `tc-lot` qui la contredit
  ou l'omet. Proposer
  les retouches à l'utilisateur (AskUserQuestion en forme positive, une recommandation
  par retouche) et les appliquer après son accord. Deux lots ont rempli `retours.md`
  sans toucher au skill, qui disait encore l'inverse sur l'attente ; l'utilisateur a dû
  le demander. C'est cette étape qui fait que le lot suivant se passe mieux ; ne pas la
  sauter parce que le lot est fini.
