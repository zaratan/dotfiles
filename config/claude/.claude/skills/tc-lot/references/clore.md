# Clore le lot

Les chemins `assets/…` et `references/…` sont ceux de `~/.claude/skills/tower-control/`.

- Proposer l'ordre de merge qui minimise les conflits (les grappes qui partagent un
  fichier en dernier, l'une après l'autre). Les migrations des PR ouvertes peuvent imposer
  cet ordre (« Merger » de tc-delegate) : le dire à l'utilisateur dès que deux PR en portent.
- **Passe de QA de fin de lot**, une fois tout mergé et avant de dire le lot livrable :
  `tc-lot/references/qa.md` (cahier, agents, suivi, KO, deux temps, commande ou TUI).
- **Passe SOLID / DRY / KISS, en parallèle de la QA**, dès le dernier merge : `tc-lot/references/audit.md`.
  Lecture seule, aucun changement de code ; des constats mesurés, confrontés au Backlog, puis des issues.
- **Mesurer le dossier des comptes rendus et les dossiers temporaires des agents** (planches, maquettes des
  sous-agents de revue) : 9,7 Go et 2 Go s'y étaient accumulés en un lot. Proposer la liste à supprimer.
- **Un run de CI qui finit en quelques secondes sans étape** se lit dans les annotations du job
  (`check-runs/<id>/annotations`) : facturation de l'organisation, quota. La tour le dit, suspend les merges, et ne
  reprend sur preuves locales (tc-delegate) que sur décision de l'utilisateur.
- Ranger chaque worktree selon « Ranger un worktree » de `references/cycle.md`.
- **Libérer ce que l'utilisateur abandonne** : une issue encore assignée au login
  courant qui sort du lot sans suite reste invisible pour l'autre tour. Proposer
  `--remove-assignee @me` ; une issue en Review reste à son auteur jusqu'au merge.
- **Écrire le journal du lot dans le dépôt**, `.claude/tower-control/journal.md`, sur le gabarit
  `tc-lot/assets/journal-lot.md` : la table des issues et la ligne d'ordres de grandeur sortent de
  `assets/journal.sh <dépôt> <n>`, la tour écrit décisions, prémisses, coincé, QA, reste. C'est du
  projet, ça reste dans le projet. Le journal est commun : chaque lot y est une section ajoutée en
  fin de fichier. Deux clôtures en parallèle conflictent à cet endroit sans la ligne
  `.claude/tower-control/journal.md merge=union` du `.gitattributes` ; si elle
  manque, la proposer.
- **Écrire les leçons du lot** dans `~/.claude/tower-control/entrants/<date>-<projet>-lot-<n>.md`
  (`mkdir -p` au besoin ; hors de tout dépôt : la tour peut y écrire, alors que `~/.claude/skills/`
  lui est refusé par le classificateur). Ce qui a coincé et la règle qui en sort, ce qui a bien
  marché, les ordres de grandeur aux colonnes de `references/ordres-de-grandeur.md`. Les noms de
  projet y sont permis, ils tombent à la promotion. Ce qui ne vaut que pour ce projet va dans
  `.claude/tower-control/tour.md` du dépôt des issues.
- **Promouvoir, depuis une session dotfiles** que l'utilisateur ouvre sur la machine du lot :
  chaque leçon d'un fichier d'entrants reçoit une destination et une seule, puis le fichier passe
  dans `entrants/traites/`. Une leçon entre dans un skill si elle a été vue sur deux projets, si un
  script peut la porter, ou si elle a déjà coûté une écriture git ; sinon `references/cas.md`
  (situations rares : mesures partagées, TUI, hôte Linux…), `retours-entrants.md` (pas encore
  tranchée) ou le `tour.md` du projet. Avant d'écrire : `grep -rni <mots> ~/.claude/skills/tower-control
  ~/.claude/skills/tc-*` ; si la règle existe, la fusionner dans la rédaction en place, jamais une
  seconde puce. Budget : `SKILL.md` 200 lignes, chaque `references/*.md` 180 ; au-delà, rien n'entre
  sans qu'une règle sorte ou fusionne. Deux lots ont rempli le journal des leçons sans toucher au
  skill, qui disait encore l'inverse sur l'attente : c'est cette étape qui fait que le lot suivant
  se passe mieux.
