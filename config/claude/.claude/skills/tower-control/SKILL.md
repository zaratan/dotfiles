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

**Grouper les issues par fichiers touchés, pas par thème.** Deux issues qui
modifient le même fichier vont dans le même worktree, l'une après l'autre ; sinon le
second merge conflicte à coup sûr. Lire chaque issue, noter les fichiers probables,
former des grappes. Trois ou quatre worktrees est un bon nombre : au-delà, la tour
ne suit plus et la machine chauffe.

**Ordonner chaque grappe** du plus simple au plus discutable, et mettre en dernier
ce qui finira « Bloqué » sur une décision externe.

**Trancher avant de lancer** ce que les issues laissent ouvert (« à trancher »). Un
agent bloqué sur une décision produit est un agent qui attend ; la tour prend la
décision avec l'utilisateur en amont et l'écrit dans la consigne.

**Préparer les consignes** : `assets/consigne-commune.md` (règles, interdits,
forme du compte rendu), complétée par la section propre au projet, plus une
consigne courte par issue sur le modèle de `assets/consigne-issue.md`. Les montrer à
l'utilisateur avant tout lancement.

**Faire committer** ce qui doit être dans les worktrees (un `CLAUDE.md` retouché,
par exemple) : les branches partent du `main` commité, pas de l'arbre de travail.

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

Passer les issues lancées en « En cours » sur le board.

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

**Vérifier indépendamment.** Le compte rendu de l'agent est une affirmation. Avant
de résumer à l'utilisateur, relancer soi-même dans le worktree les vérifications
que le projet définit (`pnpm run check`, référence de non-régression, contrôle des
données) et comparer aux chiffres annoncés. Un écart entre les deux est la première
chose à dire.

**Résumer court** : ce qui est fait, les chiffres vérifiés, les décisions que
l'agent a prises seul (pour que l'utilisateur puisse les contredire avant la PR),
ce qui reste ouvert. Le compte rendu complet est dans `travail/rapport-<N>.md` ou
lisible par `herdr agent read`.

**Une branche par issue, et d'où elle part.** Après le commit de l'utilisateur, la
tour crée la branche suivante dans le même worktree (`git switch -c` — c'est la tour
qui le fait, l'agent en est interdit). Elle part de **`origin/main` après un
`fetch`**, pas du HEAD local : d'autres worktrees ont pu merger entre-temps, et une
branche partie du HEAD local ne « prend » jamais ces changements toute seule. Faire
`git branch --unset-upstream` aussitôt, sinon un `push` nu irait sur `main`. On
n'empile sur le HEAD local que si la PR précédente n'est pas encore mergée.

**Avant de passer en Review, mesurer le retard.** `git fetch` puis
`git rev-list --left-right --count origin/main...HEAD`, et prédire le rebase sans
toucher aux branches : `tree=$(git write-tree); tmp=$(git commit-tree $tree -p HEAD
-m x); git merge-tree --write-tree origin/main $tmp` (un commit sans référence n'est
pas de l'historique). Le point à l'utilisateur dit « N commits derrière, rebase sans
conflit » ou nomme les fichiers en conflit. Le rebase lui-même est une écriture git :
il se fait sur sa demande explicite, ou par lui.

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
  l'agent avant d'envoyer quoi que ce soit, pour ne pas répondre deux fois.

Un agent qui tourne en rond se voit au `agent read` : l'interrompre
(`agent send-keys <nom> esc`), reformuler, et ne pas dépasser deux relances sans en
parler à l'utilisateur.

## 5. Clore le lot

- Proposer l'ordre de merge qui minimise les conflits (les grappes qui partagent un
  fichier en dernier, l'une après l'autre).
- Une fois tout mergé : `herdr workspace close` des sous-espaces créés par la tour,
  `git worktree remove`, suppression des liens de mémoire.
- **Écrire le journal du lot dans le dépôt**, `.claude/tower-control/journal.md` :
  issues traitées, décisions prises par l'utilisateur, prémisses corrigées, ce qui
  reste à faire. C'est du projet, ça reste dans le projet.
- **Remonter dans `references/retours.md` du skill** ce qui vaut pour tout projet :
  ce qui a coincé et la règle qui en sort, ce qui a bien marché, les ordres de
  grandeur — sans nom de projet, sans numéro d'issue. Puis retoucher `SKILL.md` et
  `assets/` en conséquence. C'est cette étape qui fait que le lot suivant se passe
  mieux ; ne pas la sauter parce que le lot est fini.
