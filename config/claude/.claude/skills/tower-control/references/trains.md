# Trains et convois

Le modèle de merge d'un lot de plus d'une dizaine d'issues quand la CI d'une PR vers la base dépasse dix
minutes. Les chemins `assets/…` sont ceux du skill `tower-control`. Le merge PR par PR de tc-delegate
(« Merger ») reste la règle des petits lots : ce modèle se propose à la préparation (`tc-lot/references/preparer.md`)
et ne s'applique que sur décision de l'utilisateur, sous `/tc-delegate on`.

## Pourquoi

Avec une CI de 25 à 30 minutes (checks et e2e en parallèle), le merge sérialisé coûte une CI, un merge, puis
l'attente de toutes les exécutions sur la base, à chaque PR : 29 issues font au moins douze heures de chemin
critique. Et chaque merge sur la base oblige les PR ouvertes à fusionner la base et à rejouer leur CI. Avec
des trains et des convois, ces 29 issues sont entrées dans la base en 4 PR, en 3 h 21 du premier envoi au
dernier merge, toutes vertes du premier coup en CI. La QA de fin de lot (98 lignes) n'a trouvé aucune régression.

## Le train

Une branche par grappe, `train/<lot>-<grappe>`, partie de la base et poussée par la tour. Chaque issue de la
grappe garde sa branche et son commit, et ouvre **sa PR vers la branche du train** : c'est cette PR qui la met
en Review. La CI ne tourne que sur les PR vers la base, donc cette PR n'en a pas. La tour la merge aussitôt
(merge commit, sujet `Merge branch '<branche>'`). L'issue suivante de la grappe part de la tête du train
(`assets/branche-suivante.sh <worktree> <branche> origin/train/<lot>-<grappe>`).

`assets/train.sh <dépôt des issues> <grappe> <issue> <train> <titre>` fait tout le geste après la vérification
de la tour (cycle.md, « Vérifier ») : refus d'un titre de plus de 100 caractères ou d'une référence interdite
(`REFS_INTERDITES` du `config.sh`), commit (signé si le dépôt signe), push `--no-verify` par refspec explicite,
PR vers le train, merge, ligne dans `lot-<n>/trains.md`, issue en Review. `--dry-run` d'abord. Sont refusés : un
train absent d'origin (avec la commande qui le crée), une branche qui ne contient pas la tête du train (la tour a
vérifié un autre arbre que celui qui entre : fusionner le train, revérifier, relancer), une PR en conflit, et une
PR qui a des checks (ce dépôt lance alors la CI vers les trains : le modèle est à revoir avec l'utilisateur). Après
un échec, on relance la même commande : le commit fait, la PR mergée et la ligne écrite sont sautés ; un correctif
sur une branche dont la PR est déjà mergée part dans une nouvelle PR.

## La vérification d'un train

Elle remplace la CI de chaque issue, et se fait en local sur la tête du train, dans un worktree dédié :
`assets/verif-train.sh <dépôt des issues> <dépôt du code | _> verif-<k> <train> [spec e2e…]`, lancé en
arrière-plan (amorçage, suite et e2e dépassent les dix minutes du premier plan) ; sa dernière ligne dit `VERT` ou
`ROUGE` avec le SHA vérifié, et `VERT … sans e2e` quand ni spec ni `--tout` n'est passé. Sortie 0 vert, 1 rouge,
3 refus, 4 panne (fetch, checkout) ; tué, il arrête l'étape en cours avec lui. Le worktree se crée une fois par lot, détaché et amorcé : le script imprime les deux
commandes s'il manque, et rejoue le contrôle d'amorçage (`REPO_CHECK`) à chaque passage. Il refuse un worktree qui
porte une branche, un commit absent d'origin, une fusion en cours ou une vérification déjà lancée, puis se détache
sur `origin/<train>` (`checkout -f` et `clean -fd`, réservés à ce worktree ; jamais de repli sur une branche locale
du même nom). Il joue ensuite les étapes de `VERIF` (ou `REPO_VERIF[<dépôt>]`) du `config.sh`, une ligne
`nom: commande` chacune : install, remise à zéro de la base, build, format, lint, typecheck, tests unitaires, puis
l'étape `e2e` avec les specs de la zone touchée. Chaque étape a son journal (`JOURNAUX=<dossier>`, le scratchpad de
la tour) et sa durée ; une étape `test…` ou `e2e…` qui n'affiche pas au moins `1 passed` (`VERIF_PASSE`) est un
échec, jamais un vert. Un SHA se vérifie seulement s'il est sur origin : un convoi se pousse avant sa vérification.

**Plusieurs worktrees de vérification** (`verif-1`, `verif-2`…), chacun avec sa base et ses ports : avec un seul,
le deuxième train attend le premier. À la clôture, ils se retirent par `git -C <code> worktree remove`, sans
`--force`, après l'arrêt de leur pile Docker (« Piles Docker » de `references/cas.md`).

## Le convoi

Une branche `convoi/<lot>-<k>` qui fusionne plusieurs trains vérifiés. Elle se compose dans un worktree à elle,
jamais dans un worktree de vérification : celui-ci reste détaché, et `verif-train.sh` refuse un worktree qui porte
une branche. Les conflits entre trains se règlent sur le convoi, puis le convoi est poussé. Il ouvre **une PR vers la base** :
c'est la seule CI qui tourne. Si son arbre (`git rev-parse 'origin/convoi/<lot>-<k>^{tree}'`) est celui d'un SHA
qu'une vérification a rendu `VERT` sur la suite entière (`--tout`, ou la suite entière jouée par un agent), la PR part sans vérification locale (dix minutes gagnées, trois fois en un lot) ;
sinon la suite entière (`verif-train.sh … --tout`) tourne en local pendant la CI, et le merge attend les deux. CI verte, merge
(tc-delegate, « Merger »), et les trains suivants fusionnent la base.

## Les règles

- **« Review » veut dire qu'une PR existe.** Une issue fusionnée dans un train en local, sans PR, ne passe pas en
  Review : l'utilisateur a vu sept issues en Review et aucune PR.
- **Une issue qui coince sort de son train ; un train qui coince sort du convoi** et part dans le suivant. Le
  convoi n'attend personne.
- **Un seul train prêt part seul** : sa PR va directement vers la base, sans convoi.
- **Fermeture** : les PR d'issue sont fermées par leur merge dans le train. L'issue privée se ferme au merge du
  convoi qui la porte, et reçoit à ce moment son label `lot: <n>`.
- **Le conflit d'un train avec la base** se confie à l'agent qui connaît l'un des deux côtés, dans son
  worktree ; la tour commite la fusion.
- **Pendant la QA de fin de lot, sur décision de l'utilisateur**, un train `train/<lot>-qa` reçoit les correctifs
  des KO, sans CI, et une seule PR part vers la base à la fin de la passe : trois correctifs pour une CI de 22 minutes.
- **Délégation** : sous `/tc-delegate on`, avec ce modèle choisi par l'utilisateur, les branches `train/*` et
  `convoi/*` entrent dans le périmètre délégué au même titre que les branches d'issue. Jamais de `--force` dessus.

## Les pièges payés

- Une base de vérification partagée entre deux trains a fait échouer un seed : elle se remet à zéro à chaque
  vérification (une étape de `VERIF`, avant le build).
- Un fichier généré modifié bloquait le `checkout` : `checkout -f`, dans le worktree de vérification seulement.
- Le hook pre-push joue l'arbre de travail et rougit sous la charge : `train.sh` pousse en `--no-verify` un commit
  que la tour a vérifié.
- lint-staged refuse un commit de fusion (« Failed to back up ») : commit de fusion en `--no-verify`, gates
  rejouées à la main avant.
- Un `grep` sans résultat faisait sortir le script de vérification en 1, et le `true` ajouté en fin pour le
  corriger effaçait aussi les vrais échecs : `verif-train.sh` sort en 0 seulement quand tout est vert.
