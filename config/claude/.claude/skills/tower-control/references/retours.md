# Leçons des lots passés

Générales, valables pour tout projet. À relire avant chaque lot. Le journal détaillé
de chaque lot — issues, chiffres, décisions — vit dans le dépôt concerné, dans
`.claude/tower-control/journal.md`, à côté de `config.sh` ; c'est là qu'on écrit à la
clôture, et c'est de là qu'on remonte ici ce qui vaut ailleurs.

## Ce que la tour fait mal si on ne l'en empêche pas

- **Elle prend des décisions qui ne sont pas les siennes** en les appelant
  « routine » ou « réversibles ». Un critère, un seuil, une sévérité, une règle : à
  l'utilisateur, quelle que soit la taille. En pratique il répond en une ligne et
  l'agent attend dix minutes ; le coût est nul, l'objection était juste.
- **Elle écrit des « Attendu » de mémoire.** Deux prémisses fausses sur un lot de
  neuf issues, chacune ayant coûté une question d'agent ou un correctif. Mesurer
  avec la commande qui servira à vérifier, avant d'écrire la consigne.
- **Elle laisse un choix dans une consigne** (« indique la sévérité que tu as
  retenue »). Relire chaque consigne avec la question « qu'est-ce que je laisse
  décider à l'agent ? » et transformer chaque réponse en question à l'utilisateur.
- **Elle empile sur le HEAD local** alors que `main` a avancé. Nouvelle branche
  depuis `origin/main` après `fetch`, retard mesuré avant Review, et dès qu'un merge
  est annoncé, vérifier le retard des branches en cours sans attendre.

- **Elle vérifie dans un worktree pendant que l'agent y travaille.** Deux `replay` en
  parallèle dans le même `travail/` ont produit des écarts fantômes que l'agent a
  passé dix minutes à chercher. Vérifier quand l'agent est `done` et l'écran arrêté,
  jamais avant ; et le dire dans la consigne de retouche.
- **Elle déclare un rebase « sans conflit » comme s'il était vert.** Deux fois dans un
  lot, une branche rebasée sans conflit a cassé `tsc` : un champ ajouté à un type par
  une branche, une fixture littérale dans l'autre. Après tout rebase, `check` complet
  avant de pousser, et la CI le rappelle sinon.

## Ce qui a bien marché

- Grouper les issues par fichiers touchés, pas par thème : zéro conflit de merge
  sur un lot de neuf issues avec trois agents.
- Une consigne commune + une consigne par issue de 5 à 8 lignes, avec un « Attendu »
  chiffré : les agents ont rendu des comptes rendus au format demandé, et la tour a
  pu tout revérifier. Aucun compte rendu n'a menti sur ses chiffres.
- Les agents posent une question sur deux issues environ, toujours avec une
  recommandation, et continuent le reste en attendant. Les laisser faire.
- Une session d'agent tient trois ou quatre issues d'une même grappe sans
  relance : 9 à 17 % de contexte consommé. Pas de raison de repartir de zéro.
- Ordres de grandeur : 6 minutes d'agent par issue de 2-3 points, 10 à 14 pour
  3-5 points ; trois agents, une soirée, neuf issues mergées, relectures comprises.

- Le lot = les issues de « À faire » assignées au login courant, triées par l'utilisateur : la tour ne
  re-trie pas, elle groupe et ordonne. Sept issues, dix-neuf points, trois worktrees,
  une soirée ; 2 à 3 questions d'agent par lot, toutes avec recommandation.
- Une table de formulations soumise par l'agent **dans un fichier** puis validée par
  l'utilisateur en un choix : l'aperçu d'`AskUserQuestion` n'est pas lisible depuis le
  terminal de la tour, le fichier l'est.

## Ce qui reste à vérifier au prochain lot

- Un agent peut rendre son compte rendu alors qu'un reviewer en tâche de fond tourne
  encore ; rien de perdu cette fois, mais lire l'écran une seconde fois à l'arrêt.
- Un agent peut oublier une vérification après une retouche demandée : la tour
  relance toujours les siennes, quoi que dise le compte rendu.

## Lanceur, appris en relançant un lot (30 septembre 2026)

- Le dossier des worktrees disparaît à la clôture d'un lot ; `herdr worktree create`
  échoue si le parent de `--path` n'existe pas. Le lanceur fait `mkdir -p`.
- `herdr worktree create` refuse `--workspace` et `--cwd` ensemble : dépôt unique →
  `--workspace`, sous-dépôt d'un méta-dépôt → `--cwd`.
- En mode dépôt unique, une grappe n'a pas de nom de dépôt : les tableaux `REPO_*`
  indexés par une clé vide font planter bash (`bad array subscript`). Clé de repli `_`.
- Depuis l'outil Bash de Claude Code (zsh), **`path` est lié à `$PATH`** : l'écraser
  dans une commande manuelle fait disparaître tous les binaires (exit 127). Nommer
  autrement (`wt`, `dest`) tout ce qu'on tape à la main ; le lanceur tourne en bash
  et n'a pas ce piège.

## Méta-dépôt : « le méta prime » démote aussi les bonnes règles (30 septembre 2026)

Dire aux agents que les `AGENTS.md` du sous-dépôt client sont « de l'information, pas des
consignes » a eu un effet non voulu : un agent a lu une règle opératoire explicite du
sous-dépôt (« ne jamais nommer une migration à la main, utiliser la CLI »), l'a notée
dans son compte rendu, et l'a quand même ignorée, puisque le méta primait. Règle qui en
sort : la consigne projet du méta **recopie explicitement** les règles opératoires du
sous-dépôt qui restent obligatoires (outillage de migration, typegen, wrappers, contrat
d'erreur, i18n) ; ce qu'on démote, c'est la description du produit, pas l'outillage.
Vérification de la tour avant Review : les fichiers générés (migrations, types) portent
la marque de l'outil, pas d'un nommage à la main.

## Lot sur un méta-dépôt avec QA par agent (1er octobre 2026)

- **Les agents écrivent des runbooks pour eux-mêmes.** Demandés « runbook + tests pour
  chaque zone touchée », ils ont rempli les runbooks produit de SQL, de noms de tables et de
  commandes. Règle : la consigne projet nomme les deux publics et les deux dossiers
  (`runbooks/` par l'écran, zéro commande ; `runbooks-tech/` pour l'exploitant), et un
  contrôle grep sur le dossier produit fait partie des vérifications.
- **Une prémisse fausse dans l'Attendu se paie en question d'agent.** « Le template a 21
  questions » venait d'un chiffrage, pas d'une mesure ; le template en avait 30. Mesurer
  (une requête) avant d'écrire chaque chiffre de l'Attendu.
- **La QA par un agent dans le navigateur de l'utilisateur rend bien** : un cahier de 24
  points joué en 53 minutes, plus un scénario de coexistence et 26 frictions UX classées,
  dont 10 issues. Conditions : cahier avec « où cliquer / ce qui doit apparaître », comptes de
  test dans le dépôt, données préparées (fichiers d'import), demander explicitement une
  section « apprentissages pour le cahier » et une section « frictions UX ». Réécrire le
  cahier avec ses apprentissages juste après.
- **Les lectures de l'utilisateur sont la seule mesure sur les hôtes** : la tour ne s'y
  connecte pas ; elle rédige des commandes en lecture seule avec leur valeur attendue, et
  tranche sur le résultat (cas d'un CLI qui change de rôle en silence, vu par `--debug`).
- **Pièges d'outillage** : un `herdr agent prompt "..."` entre guillemets doubles fait
  expanser les backticks par le shell (mots perdus, l'agent reçoit une phrase trouée) —
  guillemets simples ou \` échappés ; une commande interactive dans l'amorçage bloque le
  lanceur jusqu'au timeout (`wait-output` 5 min, porté à 15) ; une surveillance de PR en
  arrière-plan expire à 2 h, la relancer ; un nom de conteneur à horodatage (Coolify) ne va
  pas dans une configuration.
- **Un fichier généré nommé à la main se voit à son horodatage rond** : vérifier avant Review
  que migrations et types portent la marque de l'outil.

## Upstream des branches d'issue (1er octobre 2026)

Le lanceur crée les branches avec `--base origin/<base>` et git les fait suivre `origin/<base>` :
l'utilisateur a vu qu'un `git push` nu serait parti sur `main`. Le SKILL le disait pour les
branches créées à la main par la tour, pas le lanceur. Règle : le lanceur fait
`git branch --unset-upstream` juste après la création, et la tour vérifie
`git rev-parse --abbrev-ref @{upstream}` (doit échouer) avant de dire « prêt à commiter ».

## Répondre à une AskUserQuestion par send-keys (1er octobre 2026)

`send-keys down` puis `enter` a sélectionné la mauvaise option : l'agent a livré la forme que
l'utilisateur avait écartée, en l'attribuant à la tour. Règle : après avoir répondu par touches,
relire l'écran (`agent read --source recent-unwrapped`) et vérifier que l'agent énonce bien le choix
attendu ; sinon l'interrompre tout de suite. Plus sûr : répondre par `agent prompt` avec le texte de
l'option quand la question propose « Type something ».

## Lot sur un monorepo avec base par worktree (1er et 2 octobre 2026)

- **La tour sur-outille quand elle répond à chaque question d'agent par un mécanisme.** Une issue de
  3 points a pris trois formes (commande, générateur, colonnes et contraintes) avant que l'utilisateur
  ne demande le plus simple. Règle : avant de recommander un garde, une colonne, une contrainte, se
  demander « a-t-on besoin de ça avant l'échéance ? » ; la réponse par défaut est non, et la
  recommandation le dit. Relire la somme de ce qu'on a ajouté sur une issue, pas seulement la
  dernière question.
- **Sonder l'amorçage avec un worktree jetable avant de lancer le lot.** Deux défauts trouvés ainsi :
  un nom de projet compose dérivé du dossier (à épingler dans le `.env` du worktree, sans caractère
  interdit dans un nom d'image), et un `bin/setup` qui ne marche que sur un poste déjà construit.
  Lire la ligne de base des tests dans la sonde, c'est le chiffre contre lequel on vérifie ensuite.
- **Une base de données par worktree**, ports distincts posés par l'amorçage ; les e2e à ports figés
  ne se jouent que par la tour, un worktree à la fois, et la consigne l'interdit aux agents.
- **Les vérifications tuées par le délai laissent des `vitest` orphelins** qui chargent la machine et
  font tomber les tests sensibles au temps dans les autres worktrees, avec des échecs différents à
  chaque passage. Avant de conclure à un écart, `pgrep -f vitest` et la charge ; rejouer les fichiers
  tombés isolément ; et borner chaque passage par `timeout` plutôt que par le délai du job.
- **Le compte rendu de l'agent va dans un dossier du méta, jamais dans le worktree** : il cite un
  numéro d'issue, et un `?? travail/` dans le sous-dépôt finit dans un `git add .`. Donner le chemin
  absolu dans la consigne commune.
- **Une preuve de bout en bout vaut plus que le test de contrat** : une pile locale (API contre le
  système réel, front) et un navigateur sans tête qui rejoue le geste de l'utilisateur, mot de passe
  demandé au clavier par un script que l'utilisateur lance lui-même. Deux lectures de l'utilisateur
  (rôles du jeton, en-têtes d'une 302) ont tranché en deux minutes ce qu'une heure de lecture du
  code n'avait pas trouvé.
- Ordres de grandeur : 12 issues, 36 points, 4 worktrees, une journée et demie ; 6 à 16 minutes
  d'agent par issue, 3 retouches sur 12, 2 questions d'agent sur 3 avec une prémisse de la tour fausse.
- **Un nouveau spec d'intégration se vérifie avec ses voisins, pas seul.** Un spec qui nettoie des tables
  dans le mauvais ordre de clés étrangères passe en local, où la table parente est vide à son tour, et
  tombe sur la CI, où un autre spec a laissé des lignes. Avant Review, jouer le spec nouveau dans la même
  commande que les specs qui écrivent dans les mêmes tables ; et quand une politique de build bloque un
  merge, lire la timeline du build et le journal de l'étape, pas le `mergeStatus`.

## PR hors GitHub (5 octobre 2026)

La tour a dit « je ne peux pas lire la PR, `gh` ne voit que GitHub » pour une PR Azure DevOps, sans chercher. L'utilisateur a dû demander s'il n'existait pas une commande. `az repos pr show --id <N> --org <url>` et `az repos pr list --status active` (extension `azure-devops`) rendent l'état, la branche source, le statut de fusion et la description. Règle : avant de dire qu'un outil ne peut pas, chercher l'outil de la forge (`az repos`, `glab`), l'essayer, et seulement alors le dire. Lire une PR n'est pas un geste d'exploitation.

## Lot sur un méta-dépôt, deux tours, forge hors GitHub (5 et 6 octobre 2026)

- **Un résumé en prose ne suffit pas pour une décision.** L'utilisateur, qui traite plusieurs sujets, a fusionné une PR sans la relire alors que le résumé signalait une formulation fausse « à corriger à la relecture ». Règle : tout point qu'il doit trancher ou corriger avant un commit (statut, règle, livrable, décision prise seule par l'agent) se pose en question directe, une à la fois ; le résumé ne porte que du vérifié sans choix. Quinze décisions fusionnées ont dû être rejouées en questions après coup.
- **Vérifier qu'un défaut peut encore arriver avant de lancer son issue.** Une issue codée, revue et vérifiée a été jetée parce que, depuis des décisions du lot précédent, le cas ne pouvait plus se produire. Règle : pour chaque issue, écrire le scénario daté qui déclenche encore le défaut ; si on n'y arrive pas, le dire avant de lancer, avec « jeter » en première option. Un garde-fou de plus sur un sujet déjà sur-certifié : non par défaut.
- **Tout « hors périmètre repéré » finit quelque part** : traité par le même agent (retouche ou bloc « reliquats » dans la consigne suivante de la même grappe) ou ouvert en issue. Jamais seulement listé. Demandé par l'utilisateur dès le troisième compte rendu.
- **La piste de l'issue n'est pas la doc du dépôt.** Une consigne a recopié « ramène à la première étape visible » alors que la doc du parcours disait et motivait l'inverse. Confronter chaque piste à la doc avant de l'écrire dans la consigne.
- **Prédire le rebase ne suffit pas : jouer la fusion.** Branche en retard de 6 commits, aucun conflit de texte, mais quatre fichiers en commun avec une autre branche qui ajoutait un test sur ces fichiers. `git commit-tree` du résultat de `merge-tree`, `git worktree add --detach` jetable, install, build, typecheck, tests : dix minutes, et la certitude. Retirer le worktree ensuite.
- **Les grappes doivent porter dans un seul worktree les docs que plusieurs issues de code touchent.** Une passe de documentation du sous-dépôt lancée depuis une autre pile aurait conflicté : empilée sur la branche qui modifiait ces docs, pas de conflit.
- **Une seule main sur une branche que l'utilisateur pousse.** Pendant qu'il corrigeait lui-même un échec d'audit du pre-push, la tour avait envoyé la même correction à l'agent. Pas de dégât, mais prévenir avant d'agir sur une branche en cours de push.
- **Le pipeline du client peut être rouge pour une raison qui n'est pas la branche** : étape de recette qui échoue depuis des semaines, audit de dépendances tombé la nuit, agent de build à 60 minutes. Lire les étapes (`az devops invoke … timeline`), pas le résultat global, avant de dire « ça casse » ou « ça passe ».
- **Des specs qui démarrent l'application entière à chaque test, dans le projet parallèle, tombent en délai sous charge** et jamais seuls. Trois fichiers, quatre fois dans le lot. Consigner les mesures sur l'issue des tests fragiles ; ne pas les attribuer au hasard.
- **Les réponses de l'utilisateur à vingt faits se portent en une seule retouche** sur la dernière branche de documentation, numérotées, avec « porté, fichier:ligne » exigé en retour : 22 réponses rangées en un passage de dix minutes.
- Ordres de grandeur : 16 issues à faire (48 points) plus 2 jetées, 4 worktrees, deux demi-journées ; 7 issues de documentation en 5 heures sur deux agents ; une factorisation de 48 fichiers en 40 minutes d'agent, e2e compris ; ~45 questions directes à l'utilisateur sur la journée, aucune laissée dans un résumé après la correction.

## Lot de mesure sur un projet de traitement vidéo (4 au 6 octobre 2026)

- **Deux agents qui mesurent sur la même machine se faussent mutuellement.** Règle : un verrou commun
  (`lockf <fichier> <commande>`, une commande par verrou, jamais tout un balayage), écrit dans un
  `MESURES.md` du dossier des worktrees, avec la liste de ce qui est lourd ; chronométrer à l'intérieur
  du verrou ; `pgrep` avant tout temps publié. La tour s'y plie aussi pour ses vérifications. Coût : les
  séries alternent et durent plus ; prévenir les agents de ne rien écourter.
- **Une consigne « au-delà de N pistes, ne les liste pas » n'empêche pas la commande d'écrire N extraits.**
  88 Go et un disque plein en une heure. Règle : avant un balayage qui peut exploser, exiger un seuil
  d'espace libre avant chaque traitement, supprimer les sorties volumineuses au-delà d'un seuil, et
  demander une issue pour une option « sans sorties lourdes » si elle manque.
- **Un réglage validé sur la vidéo de référence doit passer sur d'autres vidéos avant d'être proposé.**
  Trois candidats sur quatre, bons sur la vidéo calme et au banc, sortaient des centaines à des milliers
  de pistes ailleurs. Le banc tourne sur une seule vidéo : il ne voit pas ce défaut. Règle : la
  comparaison des candidats inclut dès le départ toutes les vidéos disponibles sans défaut connu.
- **Remesurer le constat d'une issue avant d'en écrire le plan quand une autre issue mergée entre-temps
  touche la même chaîne.** Deux constats sur sept étaient périmés : l'un avait changé de nature, l'autre
  avait disparu (issue fermée sans code).
- **Les verdicts à l'œil dépendent des conditions de visionnage.** Une piste jugée fausse à vitesse normale
  était réelle, vue zoomée à vitesse ×0,5. Règle : demander à l'utilisateur comment il a regardé, et
  consigner le verdict avec le temps de la piste, pas son numéro, qui change à chaque réglage.
- **Un test qui dépend du désaccord entre deux décodeurs n'est pas portable** (ffprobe 9 sur Mac, ffmpeg 6
  sur le runner). Règle : injecter l'écart par un patch de la fonction maison, et garder un test qui
  accepte les deux comportements mesurés. Plus généralement, tout test fondé sur une vidéo fabriquée
  est « à confirmer au premier passage en CI » dans le compte rendu.
- **Un fichier passé en Git LFS par l'utilisateur hors de la branche casse la CI de `main`** si la tâche
  ne récupère pas les objets. La tour lit la CI de `main` après chaque push, pas seulement celle des PR.
- **La machine portable se met en veille pendant les mesures longues**, même avec `caffeinate -i` : temps
  réels invalides, temps CPU seul fiable. Le dire dans MESURES.md.
- **`herdr agent wait` rend « done » alors qu'un balayage en arrière-plan continue** : attendre
  l'apparition du fichier de compte rendu (boucle `until [ -f … ]`) avant `agent wait`, et demander à
  l'agent de n'écrire le fichier qu'à la toute fin.
- **La résolution d'un rebase à plusieurs fichiers** (cinq, tous additifs des deux côtés) : la tour peut
  résoudre les fichiers et rejouer les tests, puis laisser `git add` et `git rebase --continue` à
  l'utilisateur. Dire aussi qu'un test de référence échouera par construction si les défauts ont changé,
  et préparer ses nouvelles valeurs avant le rebase.
- Ordres de grandeur : 7 issues, 43 points, 3 worktrees, deux jours et demi ; une issue de 8 points en
  cinq sous-phases avec balayages = 5 h de bancs et une dizaine de consignes ; 4 retouches après
  vérification de la tour ; 0 compte rendu faux sur ses chiffres ; une quinzaine d'issues créées en chemin.

## Lot sur un méta-dépôt, pile par worktree (7 octobre 2026)

- **Relire chaque issue par des agents en lecture seule avant le lot.** Quatre agents `Explore`
  (4 à 7 minutes, 70 à 160 k tokens chacun) ont confronté 20 issues au code : toutes
  reproductibles, mais 8 prémisses fausses (un compte, une ligne, un fichier qui n'existe pas,
  une piste à l'envers, une doc qui dit l'inverse). Chaque prémisse fausse non vue aurait coûté
  une question d'agent. Le gabarit : reproductible ? fichiers touchés ? choix ouverts avec
  recommandation ? doc contredite ? Attendu chiffré mesuré maintenant ? Le résultat va dans un
  fichier de décisions du lot, pas dans la tête de la tour.
- **Une issue qui change l'outillage de tous les worktrees se lance seule, d'abord.** Une pile de
  dev par worktree (ports dérivés du chemin) a rendu possibles quatre agents qui testent en base
  en parallèle ; l'utilisateur l'a vu avant la tour. Règle : si une issue du lot conditionne le
  travail des autres, elle part seule, les grappes attendent son merge.
- **Envoyer la consigne commune et la consigne de l'issue en un seul prompt.** Deux prompts
  séparés : un agent a répondu à la commune par « quelle issue ? » avant que la seconde arrive,
  et la seconde est restée dans sa zone de saisie derrière la question. Concaténer les deux
  fichiers.
- **`send-keys enter` ne soumet pas un texte tapé dans la zone de saisie** ; il ne sert qu'aux
  dialogues (`AskUserQuestion`). Un texte visible dans la zone de saisie d'un agent idle est une
  suggestion automatique de Claude Code, jamais l'utilisateur (confirmé par lui le 8 octobre
  2026, après qu'une tour lui a posé la question deux fois) : l'ignorer, `agent prompt` le remplace.
- **Chaque point « hors périmètre » reçoit sa destination avant le résumé**, dans une table
  point → traité (retouche si le fichier est dans la branche) / attaché (commentaire avec
  fichier:ligne sur l'issue existante) / nouvelle issue. L'utilisateur l'a redemandé au troisième
  compte rendu du lot, comme au lot précédent : c'est la règle la plus souvent oubliée.
- **Une issue créée en chemin va dans la colonne Backlog, explicitement** : `gh project
  item-add` laisse le statut vide ou au défaut du board, et l'utilisateur trie lui-même.
  `gh project item-edit <n> --owner <o> --url <issue> --field Status --value Backlog`. La forme
  par URL et nom de champ évite les identifiants de nœuds et le `jq` sur `item-list`, qui casse
  dès qu'un corps d'issue contient un caractère de contrôle.
- **`gh issue create` n'a pas de `--json`** : il imprime l'URL, le numéro se prend par
  `grep -o '[0-9]*$'`. Un repli silencieux a créé une issue au corps « voir ci-dessus ».
- **Mesurer la sortie de succès d'une commande de vérification avant d'écrire « doit être muet »** :
  un script qui imprime une ligne de succès a fait signaler un écart par trois agents sur trois.
- **Dans un worktree à ports dérivés, les tests de base passent par le wrapper du projet**, pas
  par le CLI brut, qui lit les ports par défaut et échoue sans message utile.
- **Les branches empilées deviennent des ancêtres purs après le merge** : une branche créée sur le
  commit de la PR précédente, une fois cette PR mergée, est « N derrière, 0 devant » ; le rebase
  est un déplacement, et seuls les fichiers touchés par d'autres PR mergées entre-temps peuvent
  conflicter. Le dire tel quel dans le point à l'utilisateur.
- **Clone d'un dépôt externe refusé par le classificateur de permissions** (intégration de code
  non vérifié) : ne pas contourner ; écrire la commande dans un script du dossier de travail et
  demander à l'utilisateur de le lancer (`! bash travail/clone-x.sh`), parce qu'un terminal qui
  replie les messages en résumé avale une commande donnée en prose.
- **Un agent qui pilote le navigateur a besoin que le site de sa pile soit autorisé dans
  l'extension** (`localhost:<port dérivé>`) : le dire dans la consigne, ou vérifier que
  l'utilisateur autorise tous les sites.
- Ordres de grandeur : 20 issues (63 points) + 10 ouvertes en chemin ; première issue d'outillage
  35 minutes d'agent + 5 de retouche ; ensuite 4 worktrees, 3 à 15 minutes par issue de 2-3
  points, 4 retouches sur 5 comptes rendus (toutes des reliquats du même fichier), 0 compte rendu
  faux sur ses chiffres, ~12 questions directes à l'utilisateur sur la demi-journée.
- **Un agent a lancé le formateur sur des dossiers entiers** : 62 fichiers modifiés au lieu de 35, un
  diff qui mélange reformatage et correctif. L'agent ne peut pas restaurer (`checkout` interdit) ; il a
  sauvé un patch, la tour a fait `git checkout -- .` (les fichiers non suivis restent) et l'a relancé
  « sans formateur sur les fichiers existants ». Règle pour la consigne commune : `lint:fix` et le
  formateur ne se lancent que sur les fichiers touchés par l'issue, jamais sur un dossier.
- **`git rm --cached` n'était pas dans la liste des outils interdits** : un agent l'a lancé pour supprimer un
  composant mort, l'index a été écrit. Ajoutés au `DENY` du lanceur : `git rm`, `git mv`, `git restore`,
  `git clean`, `git update-index`. La liste doit couvrir tout ce qui écrit l'index ou l'arbre, pas seulement
  l'historique.
- **Une issue décidée mais jamais placée dans une grappe** a été découverte à la fin du lot, en relisant la
  colonne « À faire » du board. Règle : après le groupement, vérifier que chaque issue du lot figure dans
  exactement une grappe (`comm` entre la liste du lot et la somme des grappes), et relire la colonne
  « À faire » à chaque clôture de worktree.
- **Clôture : 24 issues (66 points) en une journée, 23 PR, 5 worktrees** (une issue d'outillage seule
  d'abord, puis quatre grappes, puis un cinquième worktree pour une issue ajoutée en fin de lot).
  13 retouches sur 24 comptes rendus, toutes sur des reliquats que l'agent avait lui-même listés : le
  bloc « hors périmètre » est la source principale des retouches, le lire avant le résumé. 0 compte
  rendu faux sur ses chiffres. 5 prémisses de consignes fausses malgré la relecture par agents : une
  relecture ne remplace pas la mesure de chaque chiffre et de chaque mot d'une décision.
- **Vérifier seulement quand `agent wait` rend `done`, pas `blocked`** : un typecheck lancé pendant que
  l'agent était à mi-chemin a rendu 30/33, fantôme disparu une fois l'agent fini.
- **À la clôture, les piles Docker des worktrees survivent à `git worktree remove`** (les agents laissent
  leur pile montée) : lister par nom de projet, `supabase stop --project-id` + `docker compose -p down`,
  puis la commande de ménage des volumes du projet.
- **L'utilisateur lit mieux un script qu'une commande en prose** quand son terminal replie les messages :
  écrire les commandes de fusion ou de clonage dans `travail/*.sh` et donner `! bash travail/x.sh`.

## Lot sur un projet de traitement vidéo, dépôt unique, neuf issues (7 et 8 octobre 2026)

- **Les chiffres d'une doc du dépôt sont aussi périssables qu'une mémoire.** Deux consignes ont recopié des
  mesures de la doc de profilage (surcoût d'une passe, nombre de pistes d'une vidéo) périmées par le lot
  précédent : une issue entière s'est révélée sans objet une fois remesurée par l'agent. Règle : avant d'écrire
  un chiffre dans un « Attendu », le remesurer avec la commande qui servira à vérifier, même s'il vient de la doc
  — surtout si une issue mergée depuis touche la même chaîne.
- **Un balayage de mesure proposé par la tour se dimensionne au besoin, pas à l'exhaustivité.** 26 vidéos × 2
  réglages ont occupé le verrou commun une matinée et fait attendre trois agents ; 7 vidéos déjà mesurées
  suffisaient au tableau visé. Avant de lancer une série longue : à quoi sert chaque ligne, qui attend le verrou
  pendant ce temps, et le dire à l'utilisateur avec le coût.
- **`merge-tree` sans conflit n'est pas une fusion propre, et la répétition se fait par `git apply`.** Deux
  fois : un conflit textuel additif (même fichier de tests enrichi par deux branches) puis un conflit sémantique
  (un test de la branche A comptait les fichiers d'un dossier, la branche B en ajoute un). Méthode qui tient :
  `git worktree add --detach` sur `origin/<base>`, `git diff HEAD` de la branche appliqué par `git apply --3way`,
  copie des fichiers non suivis, `check` complet, puis retrait du worktree. **Jamais `git add -N` ni
  `git reset`** pour faire entrer des fichiers non suivis dans un `write-tree` : c'est une écriture d'index
  interdite, et l'arbre obtenu était faux (les fichiers manquaient, 41 tests de moins sans que rien ne le dise).
  Quand la branche est déjà commitée, `git merge-tree --write-tree` + `commit-tree` + worktree jetable suffit.
- **La tour peut résoudre un rebase en cours pour l'utilisateur** : lire les hunks, garder les deux côtés quand
  c'est additif, réordonner quand l'un des blocs est une méthode (les `if` d'un `__post_init__` doivent
  précéder la méthode ajoutée), isoler un test d'une option nouvelle (`--zoom none`) plutôt que changer son
  attendu ; vérifier avec lint, types, tests, mais **ne pas formater un fichier que le commit suivant du rebase
  corrige** ; laisser `git add` et `rebase --continue` à l'utilisateur, avec les commandes écrites.
- **Les décisions de licence sont à l'utilisateur, et l'agent doit s'arrêter dessus.** Une roue PyPI livrait un
  FFmpeg GPL alors que son fichier de licences annonçait LGPL : consigne « vérifie d'abord ; GPL → arrête-toi »,
  vérification refaite par la tour (`strings` sur la dylib), décision de l'utilisateur (binaire GPL v3, code MIT),
  puis NOTICE par bibliothèque. Un agent qui aurait continué aurait publié sans le savoir.
- **Une annulation de CI par délai n'est pas un échec de test** : lire l'étape annulée avant de relancer. Ici
  `apt-get install` sur un miroir lent (10 min contre 25 s d'habitude) ; la réponse était de sortir d'apt (binaire
  statique épinglé par sha256 et mis en cache), pas de relancer. L'utilisateur a refusé la relance avant que la
  tour ne la propose : proposer la cause et le correctif en même temps que la relance.
- **Le lanceur** : `herdr agent start` juste après l'amorçage répond parfois `agent_pane_busy` alors que le prompt
  est là (2 fois sur 4) ; cinq essais à 3 s d'écart suffisent. `herdr agent wait` rend « done » pendant des
  mesures lancées en arrière-plan : attendre le fichier de compte rendu, et dire à l'agent de ne pas attendre la
  fin d'un balayage de la tour quand le verrou alterne (il perdait une heure).
- **Le poste a des alias** (`df` → `duf`, `du` → `dust`, `grep` → `ugrep`) : dans les consignes et les commandes
  de la tour, `/bin/df`, `/usr/bin/du`, `/usr/bin/grep`. `gh pr checks --watch` rend la main dès le premier
  résultat : boucler sur « pending ».
- **Un merge sans `Closes #N` laisse l'issue ouverte** : vérifier `closingIssuesReferences` à l'ouverture de
  chaque PR, et fermer soi-même avec un commentaire quand le lien manque et que le merge est constaté.
- **Ne jamais retirer un worktree sans avoir vu la PR mergée et un `git status` vide.** Sur un « PR merged »
  de l'utilisateur qui désignait une autre PR, la tour a fermé le dernier worktree avec `--force` : la
  retouche non commitée y a été perdue, refaite à la main grâce au diff gardé en contexte. Règle : avant
  `workspace close` / `worktree remove`, vérifier `gh pr list --head <branche>` (mergée) **et**
  `git -C <worktree> status --short` vide ; jamais `--force` ; et garder le diff de toute retouche dans le
  compte rendu, pas seulement son résumé.
- Ordres de grandeur : 9 issues (27 points), 4 worktrees, une journée et demie ; 6 à 50 min d'agent par issue ;
  2 plans relus avant code ; 7 retouches après vérification ; 0 compte rendu faux ; 5 prémisses de tour fausses ;
  ~40 questions directes, dont une dizaine de « décisions prises seul » transformées en questions.

## Lot d'une seule issue, piloté en direct par l'utilisateur (8 octobre 2026)

- **Une issue « gabarit modifié » n'est pas une issue, c'est une conversation.** Première passe
  28 minutes, puis 8 retouches en 2 h 30, chacune née d'une décision de l'utilisateur en regardant le
  rendu (alignement, arrondi, justification, plancher de police, partage de hauteur). Règle : quand
  l'issue touche à la maquette, prévoir des allers-retours courts plutôt qu'une consigne exhaustive,
  et **rendre les fiches en image** (PPTX → PDF → PNG recadré sur la zone) à chaque passe : c'est
  l'image qui a déclenché 4 des 8 retouches, pas le compte rendu.
- **Un fichier annoncé « synchronisé » peut ne pas l'être** : copie de sauvegarde identique à
  l'original, iCloud « à jour », aucun verrou — le fichier n'avait pas été enregistré. Mesurer (md5,
  horodatage, `brctl status`) et le dire, avant toute consigne.
- **Mesurer la géométrie dans le XML produit, pas seulement regarder le PDF** : un script de 20 lignes
  (nom, x, y, w, h en mm par forme) a servi à chaque passe, et c'est lui qui a vu le rayon d'arrondi
  (`adj` en fraction du plus petit côté) et le texte centré qui débordait vers le haut.
- **Le texte visible dans la zone de saisie d'un agent idle n'est jamais l'utilisateur** : suggestion
  automatique. Confirmé par lui après deux questions inutiles. SKILL.md corrigé.
- **La CI a cassé sur un test qui lisait le gabarit au chargement du module**, hors `skipIf`, alors que
  le test voisin faisait bien. Règle pour la consigne commune d'un projet à données hors git : tout
  test qui lit le dossier partagé le fait sous `skipIf` et dans le test, avec la preuve
  `mv external_doc external_doc.off && bun test` avant Review.
- **Un « au passage » de l'utilisateur sur une PR ouverte** : issue créée pour la traçabilité, traitée
  sur la même branche, `Closes #N` ajouté au corps de la PR par l'utilisateur. Deux issues fermées par
  une PR, le board a suivi.
- Ordres de grandeur : 1 issue de 5 points + 1 de 1 point, 1 worktree, 3 h ; 22 décisions, 9 comptes
  rendus, 0 chiffre faux dans les comptes rendus, 1 prémisse fausse de la tour (le gabarit absent).
- (suite, lot 4 du même jour) **L'agent bloque sur une approbation de copie hors du dossier de
  travail** quand une donnée vit derrière un lien symbolique iCloud : lecture légitime, écriture dans
  son scratchpad. La tour répond `send-keys enter` après avoir lu le dialogue ; prévoir dans la consigne
  commune que les photos se copient dans le scratchpad avant mesure, pour que l'agent n'attende pas.
- **Un « Attendu » qui range une anomalie dans le mauvais compteur** (tableur vs photos) se voit au
  premier compte rendu : lire la sortie de `controler` avant d'écrire le chiffre, les deux totaux sont
  séparés.
- **Une branche peut réaliser une issue voisine sans le savoir** (source unique des recadrages = la
  piste 1 d'une issue ouverte). Avant Review, relire les « décisions prises seul » contre les issues
  ouvertes du même fichier ; ici, un `Closes` de plus sur la PR et une issue de moins.
