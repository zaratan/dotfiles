# La passe SOLID / DRY / KISS de fin de lot

Les chemins `assets/…` sont ceux de `~/.claude/skills/tower-control/`. Lancée au dernier merge du lot, en
parallèle de la QA : elle ne lit que le code, n'a besoin d'aucune pile, et ne change rien. Elle ouvre des
issues. Le protocole est celui de « Trier et relire le backlog » du skill (agents de lecture seule, format de
constat imposé, textes rédigés par les mêmes agents, lecteur froid, humanize, création par script, aucune
écriture GitHub par un agent) ; ce fichier dit ce qui est propre à l'audit.

- **Zones** : trois à cinq, proposées par la tour depuis l'arborescence (un domaine métier, le socle, le
  web, les paquets partagés…), validées par l'utilisateur avec la question « avant quelle échéance ? ».
  Un agent `Explore` par zone, brief `assets/consigne-audit.md`, sur la base à jour (`git archive` du
  dernier merge si le checkout est en retard) ; 100 à 150 k tokens chacun, une heure.
- **Le constat**, une ligne chacun : où (`fichier:ligne`), la mesure (lignes dupliquées, nombre d'appelants,
  branches, paramètres), le principe touché (SOLID, DRY ou KISS, lequel), le refactoring proposé, sa
  complexité en points, « avant l'échéance ? », et l'issue ouverte qu'il rejoint s'il y en a une. Un constat
  sans mesure est une opinion : il ne passe pas. Un agent dédoublonne l'ensemble avant la rédaction.
- **Avant d'écrire une issue, confronter chaque constat au Backlog** (`board.sh lire`, puis `gh issue list
  --search`) : s'il rejoint une issue existante, c'est un commentaire avec `fichier:ligne`, pas une issue.
- **Les textes** : un agent `Explore` ne peut pas écrire de fichier ; les constats passent à un agent
  `general-purpose` repris par `SendMessage` (contexte gardé), qui rédige au gabarit d'issue, un fichier par
  issue au format de `~/.claude/skills/tc-commun/appliquer-issues.py`, relus par un lecteur froid, passés
  par humanize ; priorité et points proposés avec le texte. Les constats P3 d'une même zone vont dans une
  issue index unique plutôt que dix issues d'une ligne.
- **Montrer, puis créer** : les décisions que les textes laissent ouvertes se posent à l'utilisateur avant
  la reprise, pas après (le lecteur froid en a trouvé trois, bloquantes) ; il relit les fichiers ;
  `appliquer-issues.py --dry-run`, puis sans, tout au Backlog avec priorité et points. Un même constat deux
  lots de suite sans décision : le dire, pas le recréer.
- Ordres de grandeur : cinq zones, 62 constats et 20 prémisses fausses du Backlog corrigées en passant en
  une heure de machine ; 72 constats, 27 issues et 6 commentaires en deux heures ; trois passes sur deux
  projets.
