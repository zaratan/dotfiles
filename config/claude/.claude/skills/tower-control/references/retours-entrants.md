# Leçons en attente

Ce qu'un lot a appris et qu'aucun skill ne porte encore. Lu au début de chaque lot (`/tc-lot`). Rempli depuis
`~/.claude/tower-control/entrants/` par une session dotfiles, vidé à chaque promotion (« Clore le lot ») ; au-delà de
100 lignes, promouvoir avant d'ajouter. Sans nom de projet ni numéro d'issue : ce fichier est public.

- Une surveillance de PR lancée en arrière-plan par la tour expire au bout de deux heures : la relancer. Vu une
  fois ; à confirmer sur la version courante de Claude Code.
- Une seconde relecture UX, indépendante des textes, dès qu'une issue ajoute des écrans de refus qui renvoient
  ailleurs : elle a trouvé deux boucles de parcours qu'une première relecture n'avait pas vues. Vu une fois ;
  règle du cycle ou cas UI ?
- « Aucune donnée réelle d'un client, même dans un exemple » : un agent de lecture le cherche avant le premier
  lot. Vaut pour tout projet client, vu une fois ; consigne commune (Interdits) ou consigne projet ? Le contenu
  livré au client appartient à l'utilisateur.
- Un artefact long (2 200 lignes) se relit en entier après un `/compact` de la tour avant d'être republié :
  aucune perte, une partie datée ajoutée. Vu une fois ; règle de « Enchaîner une tâche » dans `cycle.md`, ou rien ?
- Deux lots menés ensemble dans un seul dossier (décisions, consignes, rapports, une QA, un audit, une
  livraison) : 100 décisions numérotées sans collision. Vu une fois ; règle de `preparer.md` ?
- Avant d'ajouter à une issue une case « prévenir X », vérifier que la chose est dans le périmètre de
  l'utilisateur : la tour a rédigé une question à un tiers sur un jeton qui appartenait à l'exploitant. Vu une
  fois ; règle de « Écrire sur GitHub » ?
- Des grappes déséquilibrées se complètent par des refactos du Backlog, ajoutées avec l'accord de
  l'utilisateur : sept agents finis à moins d'une heure d'écart. Vu une fois ; règle de `preparer.md` ?
- CI en file sans job : lire `githubstatus.com/api/v2/summary.json`, et le relire dix minutes plus tard, avant
  d'avancer une cause. La tour a dit « quota du compte » ; c'était une panne d'Actions, déclarée 15 minutes après
  le premier run bloqué. Fermer et rouvrir la PR ne débloque rien pendant une panne. Vu une fois ; règle de
  « Commit, PR, CI » ?
- Les contrôles statiques des specs e2e (doublons de textes, règles de parallélisme) ne tournaient pas dans l'e2e
  de zone de la tour : un convoi est passé au rouge sur des doublons nés des fusions. Les ajouter à chaque e2e de
  zone, puis les rejouer sur l'arbre du convoi avant le push. Vu une fois ; règle de `trains.md` ?
- Le convoi élargi pendant une CI bloquée : trois issues finies sont entrées dans le convoi en attente plutôt que
  dans un convoi de plus, une seule CI a servi. Et la QA lancée sur la tête du convoi pendant sa CI : ~30 min
  gagnées. Vu une fois chacun ; règles de `trains.md` et `qa.md` ?
- Un contrat d'interface mergé tôt en mini-PR, et les contrats nommés dans le fragment de lot (types, sentinelles,
  registres figés d'avance), ont réduit les conflits d'un convoi de six trains ; les fixtures qui changent de forme
  restent le coût principal. Vu une fois ; règle de `preparer.md` ?
- `--force` ou un contournement de cache recopié d'un `AGENTS.md` dans la consigne projet a saturé le poste à
  sept agents (129 s de CPU contre 28, charge 350, connexion perdue) : mesurer le coût CPU d'une vérification et
  le multiplier par le nombre d'agents avant de l'écrire. Vu une fois ; règle de `preparer.md` ?
- Une QA en `next start` sans `-H 127.0.0.1` a exposé le site local sur l'IP publique du serveur. Vu une fois ;
  `consigne-qa.md` ?
- Le classificateur refuse `pnpm dlx <outil>` (téléchargement puis exécution) à la tour : une mesure de bundle se
  confie à l'agent dans son worktree, code restauré ensuite. Vu une fois.
- Une consigne a nommé un paquet npm déprécié : `npm view <paquet> deprecated` avant de nommer une dépendance.
  Vu une fois.
- Une demande d'issue faite en passant (« le ticket avec la double couleur de fond ») n'a laissé aucune trace :
  l'écrire tout de suite dans `decisions.md` avec « issue à créer », et la clôture relit ces lignes. Vu une fois ;
  règle de `clore.md` ?
- L'utilisateur a répondu une fois dans le terminal d'un agent, et la décision n'est revenue que par le compte
  rendu : relire « Décisions prises seul » pour celles attribuées à l'utilisateur et les lui confirmer. Vu une fois.
- « Prends ta reco partout » en milieu de journée : chaque choix pris ainsi est numéroté dans `decisions.md` et
  listé dans le point suivant ; un seul a été corrigé après coup. Vu une fois ; règle de « Les questions » ?
- Une piste d'issue qui vise un élément à deviner (quel élément Safari lit) : une branche sonde poussée, un essai
  sur l'appareil par l'utilisateur, puis l'issue. Vu une fois.
- Une revue UI/UX menée dans un artefact (captures avant/après par fiche, choix relus par `ArtifactData`) : 25
  fiches tranchées en deux tours, issues créées depuis les choix. Vu une fois ; cas de `cas.md` ?
