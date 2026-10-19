# Préparer le lot

Les chemins `assets/…` et `references/…` sont ceux de `~/.claude/skills/tower-control/`.

**Le lot est ce qui est assigné au login courant dans la colonne « À faire ».** C'est
l'utilisateur qui trie ; la tour ne rediscute pas la sélection, elle lit chaque issue
retenue et passe au groupement. La lecture du board et les règles d'assignation
(assignée à quelqu'un d'autre, sans assigné, co-assignée, l'assignation n'est pas un
verrou) sont dans « Le board et l'assignation » de tower-control : elles s'appliquent
à chaque issue du lot.

**Une méta que l'utilisateur pose en « À faire »** veut dire « toutes ses sous-issues ouvertes
dans le lot » : la tour les passe en « À faire » et les traite comme les autres ; la méta reste
pour les regrouper.

**Un lot peut ne pas contenir de code** : un audit du dépôt ou une relecture complète
du backlog suit « Trier et relire le backlog » de tower-control, avec un agent de
lecture seule par zone ou par groupe d'issues.

**Relire chaque issue contre le code avant de grouper** (« Trier et relire le backlog »
de tower-control). Le résultat va dans `lot-<n>/decisions.md` du dépôt des issues
(prémisses corrigées, groupement, décisions de l'utilisateur) : c'est de là que les
consignes se rédigent. **Garder au groupement les grappes hors lot encore ouvertes** dans
le fichier de lot.

Poser d'abord les **questions transverses** (une brique est-elle dans l'échéance, une
séance est-elle datée, une décision tient-elle encore) : sur un lot, douze d'entre elles
ont décidé les deux tiers des verdicts avant la première question d'issue. Puis
trancher issue par issue (« Trancher avant de lancer » de `references/lancer.md`).

**Grouper les issues par fichiers touchés, pas par thème.** Deux issues qui
modifient le même fichier vont dans le même worktree, l'une après l'autre ; sinon le
second merge conflicte à coup sûr. Lire chaque issue, noter les fichiers probables,
former des grappes. Trois ou quatre worktrees est un bon nombre : au-delà, la tour
ne suit plus et la machine chauffe.
Trois petites issues (≤ 5 points) qui touchent le même fichier de tests ou le README vont dans
une seule chaîne même si l'horloge en souffre : réparties sur deux grappes pour aller vite, elles
ont coûté quatre `git merge origin/main` résolus par les agents (lot 10).

**Quand la CI d'une PR dépasse une dizaine de minutes**, proposer au groupement de réunir
les petites issues d'une même grappe en une seule PR (une branche, un `Closes` par issue) :
chaque PR coûte une CI complète et une relecture. Trois issues d'un banc de mesure sont
passées ainsi en une PR, à la demande de l'utilisateur, sur une CI de quinze minutes.

**Contrôler la couverture** : chaque issue du lot est dans exactement une grappe (`comm` entre la
liste « À faire » assignée et la somme des grappes) ; une issue décidée et jamais lancée a été
retrouvée en fin de lot par la colonne du board.

**Ordonner chaque grappe** du plus simple au plus discutable, et mettre en dernier
ce qui finira « Bloqué » sur une décision externe.

**Une issue qui change l'outillage de tous les worktrees** (pile de dev par worktree,
amorçage, scripts de test) **se lance seule, d'abord** ; les grappes partent du `develop`
qui la contient.

Écrire les grappes dans `lot-<login>.sh` (« Le fichier des worktrees » de
`references/lancer.md`), préparer les consignes et lancer.
