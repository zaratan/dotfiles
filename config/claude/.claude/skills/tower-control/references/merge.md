# Commit, PR, CI, branches et rangement

La suite de `references/cycle.md`, à lire avant le premier commit d'une issue, avant de mesurer un
retard et avant de ranger un worktree. Les chemins `assets/…` sont ceux du skill `tower-control`.

## Commit, PR, CI

Quand l'utilisateur s'absente, il peut taper `/tc-delegate on` : la tour fait alors elle-même les
lignes « user » (commit, PR, merge) selon tc-delegate, pour la session seulement. Sans cette commande,
une délégation ne se déduit jamais d'une conversation. Quand l'utilisateur agit lui-même sur une
branche (échec de pre-push, rebase), la tour n'y envoie rien à l'agent sans le prévenir : une seule
main à la fois.

**Lire la CI soi-même** : celle de chaque PR jusqu'au bout (boucler tant qu'une tâche est
« pending » ; `gh pr checks --watch` rend la main au premier résultat) et celle de la
branche de base après chaque merge. Une tâche annulée par son délai n'est pas un test qui
échoue : lire l'étape avant de relancer, et proposer la cause et le correctif avec la
relance. Un temps de CI s'explique par étape (`actions/runs/<id>` → `jobs[].steps[]`) avant
d'être réduit ou parallélisé ; un gain de parallélisme se mesure sur les runners de la CI, sur
plusieurs runs, jamais en local (deux workers e2e : 613 s contre 617, trois tests instables en
plus) ; et la liste des tests passés se compare avant et après pour prouver qu'aucun n'a disparu. Sur la branche de base, attendre que **toutes les exécutions du
commit de merge** soient terminées, jamais un nombre fixe de workflows : un filtre `paths:` en
lance moins quand la base de données n'est pas touchée, et une attente sur « trois » ne rend
jamais la main ; guetter la dernière exécution de la base, pas un SHA : un merge suivant rend
le commit introuvable et la boucle tourne sans fin. Une PR empilée que GitHub recible sur la base après le merge de celle du dessous ne
relance pas sa CI : la fermer puis la rouvrir la déclenche, **à condition de laisser une pause
entre les deux** (un close/reopen à trois secondes d'écart n'a déclenché aucun run sur deux PR ;
45 s ont suffi). **Avant d'attendre la CI d'un commit de la base, lister les workflows déclenchés sur
`push`** (`gh workflow list`, puis le `on:` de chaque fichier) : s'il n'y en a pas (décision de coût de
l'utilisateur), le run d'après merge n'existe pas ; le dire et ne rien guetter (un guet a attendu des jobs
Dependabot en échec pour une raison sans rapport), et **recibler chaque PR en attente sur la base courante**
par ce même close/reopen avant de la merger, pour que sa CI rejoue sur le merge réel. Le titre par
défaut d'un merge commit GitHub cite le numéro de PR et le propriétaire (« Merge pull request
#10 from owner/branche ») : si le dépôt du code interdit ces références, merger avec
`gh pr merge --merge --subject "Merge branch '<branche>'"`. Quand un ruleset, un hook ou un
`index.lock` bloque sans raison lisible : « Réglages du dépôt » de `references/cas.md`.

## Branches et retard

**Quand la branche est en retard et partage des fichiers avec ce qui a été fusionné**,
ne pas se contenter de `merge-tree` : jouer la fusion dans un worktree jetable, puis
install, build, typecheck, tests, et le retirer. Branche commitée : `merge-tree
--write-tree` + `commit-tree` + `git worktree add --detach`. Travail non commité :
`git worktree add --detach` sur `origin/<base>`, `git diff HEAD` appliqué par
`git apply --3way`, copie des fichiers non suivis — **jamais `git add -N` ni `git reset`**
dans le worktree de l'agent, ce sont des écritures d'index et l'arbre obtenu est faux. Un
rebase sans conflit a déjà cassé `tsc` deux fois, et un `merge-tree` propre a caché un
conflit sémantique (un test qui compte des fichiers qu'une autre branche ajoute).

**Une branche par issue, créée par `assets/branche-suivante.sh <worktree> <branche> <base>`** après
le commit de la précédente : c'est la tour qui le fait (l'agent en est interdit), sur demande de
l'utilisateur ou sous délégation. Le script part de `origin/<base>` après un `fetch` (le HEAD local ne
« prend » jamais les merges des autres worktrees), refuse un arbre sale, crée sans amont (une branche
qui suit la base a déjà poussé sur `main`) et vérifie que HEAD porte bien le nom demandé (trois agents
sont partis sur des branches jamais créées). Aucun script de la tour ne se lance avec un tuyau derrière : un
`| tail -1` garde le code de sortie du filtre. Derrière `branche-suivante.sh`, l'agent suivant a reçu sa consigne
sur une branche absente ; derrière `pousser.sh`, un hook pre-push en échec a fait passer une issue en Review
sans PR. On n'empile sur la branche précédente que si sa PR n'est
pas encore mergée ; une fois cette PR mergée, la branche empilée est « N derrière, 0 devant » : le
rebase est un déplacement, seuls les fichiers touchés par d'autres PR mergées entre-temps peuvent
conflicter, le dire tel quel dans le point. Jamais `git pull` sur la branche de base, même en avance
rapide : `fetch`, puis `origin/<base>` ou `git show`, suffisent à la tour.

**Avant de passer en Review, mesurer le retard : `assets/retard.sh <worktree> origin/<base>`.** Il lit la
branche depuis la base de fusion (un `git diff origin/<base>` à deux voies montre les merges des autres
comme des retraits, et la tour en a annoncé un faux), compte le retard, et prédit la fusion sur un index
temporaire qui inclut le travail non commité (`git write-tree` seul lit l'index et ne verrait jamais le
diff de l'agent), sans toucher aux branches. Le point à l'utilisateur dit « N derrière, sans conflit » ou
nomme les fichiers. Le rebase ou la fusion est une écriture git : sur sa demande, ou sous délégation ;
quand l'utilisateur rebase lui-même, « Rebase en cours » de `references/cas.md`.
Sans conflit textuel n'est pas vert : `check` complet avant de pousser, et quand des fichiers sont partagés,
jouer la fusion dans un worktree jetable. Après qu'une branche a déplacé ou renommé un fichier, chercher ses
importeurs dans les autres branches ouvertes (`git grep` sur chacune) avant de prédire leur fusion : une
fusion sans conflit de texte a cassé le typecheck sur un import de l'ancien chemin. **La prédiction se refait juste avant le merge**, sur
l'`origin/<base>` du moment, et dès qu'un merge est constaté, pour chaque autre branche en vol sans
attendre sa Review : un `merge-tree` propre à l'ouverture de la PR a été suivi de trois merges, et la PR
était sale sur cinq fichiers à son tour. Dès qu'elle est sale, lancer la fusion dans le worktree de l'agent
(`assets/consigne-fusion.md`) et le laisser résoudre.

## Ranger un worktree

Une fois la PR mergée et la grappe sans issue suivante : `assets/ranger.sh <dépôt> <grappe> --dry-run`,
puis sans `--dry-run` quand l'utilisateur est d'accord ; `--sans-pr` pour une grappe `qa-<k>` ou jetable. Il
refuse tant que la PR n'est pas mergée, que `git status --short` n'est pas vide, ou qu'un fichier ignoré hors
build subsiste (un prototype n'a vécu que dans un `out/` sans commit ; une retouche non commitée a été perdue
par un `--force`) : le dire à l'utilisateur, proposer une branche, garder le worktree tant qu'il n'a pas
répondu. Les ignorés propres au projet (`.env` d'amorçage, certificats de dev) se listent dans `RANGER_IGNORE`
du `config.sh`, pas dans le script. Puis il ferme le
sous-espace herdr, retire le worktree sans `--force`, le lien mémoire, et imprime la ligne du fichier de
lot à retirer. La pile Docker du worktree survit à `git worktree remove` : l'arrêter par son nom de
projet (recette du dépôt, `tour.md` ; « Piles Docker » de `references/cas.md`) et nettoyer ses volumes
avant de ranger ; le script ne le fait pas. **Rien d'autre** : pas de `git branch -D` sur les branches mergées, c'est une écriture git
qui appartient à l'utilisateur.
