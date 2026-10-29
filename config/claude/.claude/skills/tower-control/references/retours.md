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

## Lot d'audit et de nettoyage de backlog, méta-dépôt, 41 issues relues (8 octobre 2026)

- **Un lot sans code existe** : audit SOLID par cinq agents de lecture (une zone chacun, format de constat imposé : où, mesure,
  principe, refactoring, complexité, « avant janvier ? ») et relecture de 41 issues par quatre agents (scénario daté, prémisses,
  chiffre, priorité, doublons). 62 constats, 20 prémisses fausses, en une heure de machine. Les mêmes agents, repris par
  `SendMessage` avec leur contexte, ont ensuite rédigé les 81 fichiers d'issues (éditions, créations, sous-issues, fermetures)
  dans un dossier que la tour applique par script : zéro écriture GitHub par un agent.
- **Une règle de priorité donnée en cours de route se renvoie aussitôt aux agents en vol** ; ils l'appliquent sans relance.
- **`AskUserQuestion` en « coche ce que tu refuses » n'est pas lisible** : l'utilisateur a demandé la forme positive. Toujours
  « coche ce que tu veux appliquer », quatre options au plus, et grouper le mécanique (titres, points) en une seule question
  « tout appliquer / sauf… / un par un ».
- **Les questions transverses d'abord** : douze questions (une brique est-elle dans janvier, une séance est-elle datée, une
  décision tient-elle) ont décidé les deux tiers des verdicts avant la première question d'issue.
- **Briques à 13 points : sous-issues natives GitHub**, parente en Backlog sans points ni assigné, lots dispatchables ; un jalon
  reste possible par-dessus. Lien par `POST /repos/{o}/{r}/issues/{parent}/sub_issues` avec l'id numérique de l'enfant.
- **`gh project item-edit --url --field` brûle le quota GraphQL en points** : chaque appel relit tous les items du projet. Seize
  issues à quatre champs ont suffi à bloquer GraphQL pendant 45 minutes alors que `rate_limit` affichait 4 300 appels restants.
  Pour plus de dix issues : une lecture du projet (ids des champs, options, items) puis `updateProjectV2ItemFieldValue` par
  champ, en GraphQL direct, avec un fichier de reprise.
- **Vérifier soi-même le bloquant avant de le dire** : l'`audit:ci` rouge signalé par un agent a été rejoué par la tour
  (exit 1, hook et stage cités) avant d'être annoncé comme bloquant tout push.

## Lot d'un seul worktree, quatre issues à la suite, réponses d'un client (9 octobre 2026)

- **Traduire un courriel de décisions en issues passe par la mesure, pas par la recopie.** Le
  client proposait un repli (« le même emplacement vide pour les deux espèces ») qui n'existait
  pas dans les données : une espèce n'avait qu'une case libre, l'autre l'avait occupée. Mesuré
  avant de rédiger, la question à l'utilisateur a été juste du premier coup et la décision
  finale a réduit l'issue de 5 à 1 point. Règle : pour chaque réponse du client, vérifier dans
  les données que l'option proposée est réalisable, avant de la transformer en consigne.
- **Une preuve locale qui duplique la CI coûte un dialogue d'autorisation par issue.** Une
  consigne projet exigeait de renommer un lien symbolique vers un dossier hors du worktree
  (chemin iCloud) pour tester « sans le dossier » ; le classificateur du mode auto a bloqué
  l'agent trois fois sur deux issues, alors que la CI faisait le même test en 27 s. Avant
  d'écrire une preuve dans une consigne projet, vérifier qu'elle n'est pas déjà rendue par la
  CI, et qu'elle ne touche pas un chemin hors du worktree.
- **Après un `send-keys` (esc ou enter) sur un dialogue, `agent wait` peut rendre la main tout
  de suite** : l'agent passe par un état intermédiaire. Attendre quelques secondes et relancer
  l'attente ; vérifier `agent get` avant de lire un compte rendu.
- **Une phrase de consigne avec un pronom flou coûte une prémisse.** « Il n'y en a pas
  aujourd'hui » (visant une ligne de doc absente) a été lue comme « aucun cas dans les données »
  ; l'agent a remesuré et bien fait, mais la consigne aurait dû nommer la chose.
- **Supprimer les branches locales mergées n'est pas dans la clôture.** La tour l'a fait par
  réflexe (`git branch -D` sur quatre branches mergées) alors que l'utilisateur n'écrit jamais
  dans git sans demande : rien de perdu, mais c'est une écriture git de plus que prévu. La
  clôture, c'est `workspace close`, `worktree remove`, le lien mémoire, et rien d'autre.
- **Ordres de grandeur** : un agent, un worktree, quatre issues de 1 point enchaînées sur
  quatre branches, 2 h 40 du courriel au dernier merge, PR mergées au fil de l'eau par
  l'utilisateur ; 7 à 13 % de contexte consommé par l'agent sur toute la série.
- **Un amorçage qui dérive les ports d'une table de noms connus met tout nom nouveau sur le même port** : deux
  worktrees lancés le même jour ont voulu le même PostgreSQL. Dériver l'offset du nom (checksum modulo) pour les noms
  hors table, et vérifier dans le lanceur que le port est libre avant `docker compose up`.
- **Jamais `git diff origin/main` à deux voies pour lire une branche** : les commits fusionnés entre-temps y apparaissent
  comme des retraits, et la tour a annoncé un « retrait » qui n'existait pas. Toujours `git diff $(git merge-base HEAD
origin/main) HEAD`, et `merge-tree` + worktree jetable pour la fusion ; c'est ce dernier qui a vu un identifiant
  Bicep déclaré deux fois là où `merge-tree` disait « sans conflit ».
- **`git branch -d` après un merge est une écriture git** : la tour l'a faite sans demande. La clôture retire le
  worktree et ferme le sous-espace ; la branche locale reste à l'utilisateur.
- **Une question de l'utilisateur en cours de lancement peut invalider une consigne déjà écrite** (« et si la recette n'a
  pas de Front Door ? ») : la lancer quand même aurait coûté une retouche entière. Lancer d'abord ce qui n'en dépend
  pas, répondre, réécrire la consigne et l'issue, puis lancer.
- **Un jalon « ce qu'il faut pour la recette » demande deux passes** : d'abord ce que le code peut faire seul (l'utilisateur
  l'a trouvé trop court), puis les lots bloqués et les issues porte-voix, pour que le jalon montre aussi ce qu'on attend
  des tiers. Le demander explicitement.

## Lot de planification par interview, dépôt unique, 34 issues créées (9 octobre 2026)

- **Interviewer l'utilisateur avant d'auditer.** Quatre tours de `AskUserQuestion` (qui, séance type,
  avancement, bilan, erreurs, langue, aide, complétion, fichiers, docs) ont produit la trame de décisions
  dont chaque issue découle ; les agents de lecture l'ont reçue comme contrainte (« chaque issue doit
  découler d'une décision qui y figure, sinon pose la question »). 38 questions d'agents sont remontées,
  toutes tranchées en quatre tours avant la première création ; aucune n'a été prise par la tour.
- **Mesurer l'état de départ avant l'interview** (une exécution complète sous `script`, `--help`, dossier
  produit) : les questions se posent sur des chiffres (« rien pendant 22 s puis 5 lignes »), pas sur des
  impressions, et les agents reçoivent les mêmes mesures sans les refaire.
- **Les questions transverses des agents se recoupent et se contredisent** (« entrée fautive : refuser ou
  sauter ? » posée par deux zones avec deux recommandations opposées) : les poser en premier, une fois, et
  renvoyer la décision aux quatre agents d'un coup.
- **`gh project item-add` rend l'id de l'item : s'en servir.** Le listing du projet est en retard de
  plusieurs minutes après des ajouts (6, 19, puis 27 items visibles sur 34), et `board-field.py`, qui
  relit le projet, tombe en `KeyError`. Poser les champs avec l'id rendu par `item-add`, sans relire.
- **Un workflow de board peut poser « À faire » à l'ajout** : Backlog se pose explicitement, toujours.
- **Les agents citent les autres issues sous deux formes** (nom de fichier et préfixe court `zone-nn`) :
  le remplacement par numéro après création couvre les deux, par expression régulière, puis vérifie qu'il
  n'en reste aucune.
- **Une décision prise en cours de route en crée d'autres** : « piste = sortie, passage = confirmé » a fait
  apparaître une issue que personne ne portait (le bandeau de l'image) ; après l'alignement, demander à
  chaque agent « quelle décision n'est portée par aucune issue ? ».
- **Ordres de grandeur** : 4 agents de lecture, 7 min chacun en parallèle, 120–170 k tokens chacun ;
  34 textes d'issues de 500 mots en moyenne ; 2 h 30 de l'interview aux issues créées.
- **Une vérité terrain donnée en passant par l'utilisateur contredit la doc** : « tout est chauve-souris sauf la
  lente » renversait un passage confirmé que CLAUDE.md et deux docs tenaient pour acquis, et dont le test de
  référence se réclame. Avant de consigner, relire la doc sur le point précis et poser la contradiction en une
  question ; puis mettre à jour doc, CLAUDE.md, issues liées et questions ouvertes dans le même mouvement.

## Lot d'un worktree, quatre issues enchaînées sur un socle transverse (10 octobre 2026)

- **Lancer d'abord, seul, ce qui change les chaînes ou les noms partout** (langue, noms de fichiers produits),
  et faire passer avant lui les petites issues qui réécrivent les mêmes textes : on traduit une fois des textes
  définitifs. Quatre issues, zéro conflit.
- **Poser les décisions d'agent en question à cases « valide tel quel »** : une case non cochée n'est pas un
  refus, c'est souvent un oubli. Reposer la question pour cette case seule, avec « je l'avais oubliée » en
  option ; deux cas sur deux dans ce lot, un oubli et un vrai changement.
- **Une question de l'utilisateur sur un fichier vu dans le worktree** (« on va commiter du binaire ? ») vaut
  décision à transmettre tout de suite : `agent prompt` pendant que l'agent travaille est lu à son tour suivant,
  sans l'interrompre.
- **Le `worktree remove` sans `--force` échoue sur des fichiers non suivis** (restes `.coverage.*` de
  pytest-xdist) : les signaler à l'agent dès qu'ils apparaissent, pour qu'ils ne finissent ni dans un commit ni
  dans un retrait forcé.

## Lot de planification d'une réécriture dans un autre langage (10 octobre 2026)

- **Une contrainte de publication change l'ordre.** L'utilisateur a annoncé en cours de route « rien avant la
  0.2.0 ». Du coup, l'ergonomie faite dans l'ancien langage n'a plus de valeur : personne ne la verrait. Et le
  raccord temporaire entre les deux langages devient du travail jeté. Poser la question de la prochaine
  publication avant d'ordonner une migration.
- **Enregistrer une fois la référence de l'ancienne version** (sorties, détections, tirages aléatoires, sommes
  des fichiers d'entrée), dans une issue dédiée lancée en premier. Elle supprime toute exécution croisée,
  survit à la suppression de l'ancien code et permet de vérifier chaque module seul.
- **Les chiffres repris de la doc ou d'un rapport sont faux une fois sur trois.** Ici : nombres de lignes, de
  tests, numéros de ligne, et une piste déjà faite. Une relecture factuelle, avec chaque affirmation mesurée,
  en a trouvé 18 sur 14 textes, plus 5 à la seconde passe. Elle passe avant toute création par script.
- **Quatre relecteurs aux angles distincts** (architecture, langage cible, exactitude, utilisateur final) ont
  trouvé des choses différentes, avec peu de recouvrement. Une seconde passe confiée au même relecteur, qui
  garde son contexte, suffit pour vérifier les corrections.
- **Le script de création doit être idempotent jusqu'aux commentaires** : les corps sont réécrits à
  l'identique, mais un commentaire se reposte à chaque relance. Il faut noter ceux déjà postés.
- **Le compteur `open_issues` de l'API des jalons est en retard** après une création en lot (13 au lieu de 21) :
  recompter avec `gh issue list --milestone`.

## Réécriture en Rust, premier lot de code, jusqu'à quatre agents (10 au 12 octobre 2026)

- **Une attente par agent.** Une seule attente en arrière-plan partagée entre agents a laissé passer la fin de
  l'un d'eux : l'utilisateur a dû demander « on fait quoi de cette issue ? ». Lancer une attente dédiée à chaque agent,
  avec le compte rendu comme signal de fin, puis l'écran arrêté trois minutes de suite.
- **Le verrou de mesure doit couvrir la compilation.** `MESURES.md` classait `cargo build` et `clippy` comme
  légers. Les compilations froides d'un agent (dossier `target` neuf) ont donc tourné hors du verrou pendant
  les chronométrages d'un autre, et l'utilisateur l'a vu avant la tour. Toute compilation chronométrée ou
  partie de zéro passe sous le verrou, et le `pgrep` d'avant mesure cherche aussi `rustc|cargo|clippy-driver`.
- **Recommander sur chaque choix d'agent.** L'utilisateur l'a demandé explicitement : une question par choix,
  avec la recommandation de la tour et sa raison, en forme positive (« coche ce que tu acceptes »). Les
  réponses ont presque toujours suivi la recommandation, et un « je déconseille » explicite a été demandé.
- **Chercher si un écart a déjà été jugé avant de le renvoyer à la personne qui juge.** La tour a envoyé à la
  naturaliste huit pistes déjà jugées deux jours plus tôt (les divergences du prototype, écrites dans une issue
  parente). C'est l'agent suivant qui a fait le rapprochement. Avant de poser un écart, chercher sa vidéo et son
  temps dans les issues parentes et les rapports d'exploration.
- **Vérifier ce qu'une issue produit avant d'y attacher un reliquat.** La tour a annoncé qu'une issue
  fournirait des extraits vidéo alors qu'elle ne sort que des tableaux. Relire le « À faire » de l'issue cible
  avant d'écrire « quand X le permettra ».
- **Les agents corrigent les consignes.** Cinq erreurs de la tour (une API FFmpeg, une option d'encodeur, un
  refus oublié, un fait sur OpenCV) ont été trouvées par les agents parce que la consigne commune leur demande
  de signaler une prémisse fausse au lieu de l'appliquer. Garder cette clause.
- **Un temps de CI se mesure par étape avant d'être expliqué.** « La CI Rust est plus longue que la Python » :
  la ventilation par étape (API `actions/jobs`) a montré une tâche en chaîne, un cache sans repli et un test d'une seconde
  qui en prenait 83 sous la couverture. Elle a permis de passer de 9 min 39 à 6 min 22, avec la liste des tests
  passés comparée avant et après pour prouver qu'aucun n'a disparu.
- **Ne jamais lancer `git pull` sur la branche de base, même en avance rapide** : `fetch` puis `git show` ou
  `origin/<base>` suffisent à la tour.

## Réécriture en Rust, deuxième lot de code, jusqu'à trois agents (12 et 13 octobre 2026)

- **Une attente qui ne guette que le compte rendu ne voit pas les questions.** Trois agents sont restés bloqués sur une
  question pendant que la tour attendait leur fichier ; l'utilisateur l'a vu (« je pense que tes shells marchent pas »).
  L'attente doit rendre la main dès que l'agent est `blocked`, et aussi s'il s'arrête longtemps sans écrire le fichier.
- **La vérification de la tour, c'est ce que la CI ne fait pas.** La tour relançait en local `check`, `slow` et `reference`
  après chaque issue, que l'agent venait de lancer et que la CI relancerait sur trois systèmes : 15 à 20 min de verrou par
  issue. L'utilisateur l'a relevé. Revérifier seulement les tests locaux que la CI ne voit pas (les 26 vidéos), le diff
  (commentaires, fichiers non suivis), et remesurer au calme un temps annoncé quand il compte. Pour l'utilisateur, la
  règle tient aux tests de ce projet, très longs ; avec des tests rapides, la tour garde sa vérification complète.
- **Une issue créée en chemin suit toute la convention du dépôt**, pas seulement le statut Backlog : points et priorité
  sur le board, étiquettes (type et `complexité: N`), ligne « Complexité (planning poker) » en pied, jalon s'il y en a un.
  Onze issues du lot 7 en manquaient, relevé deux fois par l'utilisateur. Lire une issue existante du dépôt pour la
  convention, proposer points et priorité avec la création, tout poser dans le même script.
- **Une PR pour plusieurs petites issues quand la CI est longue.** Sur une CI de quinze minutes, l'utilisateur a demandé
  de livrer trois issues d'un banc de mesure en une seule PR : une CI et une relecture au lieu de trois. À proposer dès
  le groupement.
- **Un critère de calme se mesure avant d'être écrit.** `MESURES.md` demandait une charge moyenne basse et aucun
  processus « chrome » : sur ce Mac, la charge vaut 5 à 6 au repos et un `crashpad_handler` de messagerie tourne
  toujours. Un agent a attendu sans fin. Critère retenu : somme des `%CPU` des autres processus sous 100 %, `pgrep` des
  outils lourds vide.
- **Une demande de permission bloque comme une question.** Un agent a demandé `rm -f $S/*.profraw` ; la tour a refusé
  et demandé `"${S:?}"`, pour qu'une variable vide ne vise jamais la racine.
- **Un temps réel mesuré sous charge n'est pas un coût.** La tour a annoncé 6 s pour une étape ; mesurée au calme, elle
  en coûtait 0,5. Remesurer seul, sous le verrou, avant de citer un coût.
- **L'agent peut refuser une retouche de la tour.** Une réutilisation proposée par la tour aurait fait dépendre une crate
  sans FFmpeg d'une crate qui l'embarque ; l'agent l'a refusée, à raison. Une retouche de la tour est une proposition.
- **Un `index.lock` périmé bloque git dans un worktree** après une commande interrompue ; c'est l'utilisateur qui le
  retire, la tour le signale avec le chemin.
- **Revue du skill à la clôture.** Les lots 6 et 7 ont rempli ce fichier sans retoucher `SKILL.md`, qui disait encore
  d'attendre par `agent wait` ; l'utilisateur a dû le demander. L'étape est maintenant écrite dans « Clore le lot ».
- **Ordres de grandeur** : 15 issues et 13 PR en deux jours, jusqu'à trois agents en parallèle ; la CI d'une PR, ramenée
  à 4 min au lot précédent, est remontée à 14-17 min avec les nouveaux tests de bout en bout.
- **Guet bloqué par les shells de fond (lot 3, 14 oct. 2026).** `guetter.sh` ne rendait la main qu'avec zéro shell de fond : un agent qui laisse un `next start` ou une mesure ouverte (« 2 shells ») le faisait attendre sans fin, compte rendu écrit depuis longtemps ; l'utilisateur l'a relevé deux fois. Corrigé : le fichier compte s'il a été modifié après le lancement du guet (un ancien compte rendu ne déclenche plus rien), une section optionnelle (`## Retouche`) remplace la boucle `until grep` maison, et l'agent arrêté rend la main après 3 minutes sans shell ou 10 minutes avec. Testé contre un faux `herdr` (7 cas). Les consignes de retouche demandent aussi de fermer ses shells de fond avant de finir.
- **Suggestion de prompt prise pour une réponse de l'utilisateur.** Claude Code affiche dans la zone de saisie d'un agent arrêté une suggestion grisée (« Garde la ligne sans lien… », « donne-moi un message de commit ») : ce n'est pas un texte tapé par l'utilisateur, et `send-keys Enter` ne l'envoie pas. Ne jamais l'attribuer à l'utilisateur.
- **Droits délégués quand l'utilisateur est absent.** Un utilisateur en déplacement a donné le droit de commiter (format de ses messages : un titre, rien d'autre), d'ouvrir puis de merger les PR. Ce qui a marché : relire son format sur `git log` et ses PR avant le premier commit ; commit, `push` de la seule branche, `gh pr create` au corps vide ; merger une PR à la fois, en attendant sa CI puis celle de la branche de base ; poser les décisions des agents par AskUserQuestion, qu'il peut cocher depuis un téléphone. La délégation vaut pour la session, pas au-delà.
- **Ordre des migrations ≠ ordre des merges.** Deux branches ont créé leurs migrations dans l'ordre inverse de leurs merges prévus ; le script de migration des instances refuse une migration plus ancienne que la dernière appliquée, et la branche de base se déploie à chaque merge. Comparer les horodatages des migrations des PR ouvertes avant de proposer l'ordre de merge, et le dire à l'utilisateur.
- **Attendre une CI par « toutes les exécutions du commit terminées », pas par un nombre.** Un enchaînement qui attendait trois workflows sur la branche de base est resté bloqué : un merge qui ne touche pas la base n'en lance que deux (filtre `paths:`). De même, une PR empilée que GitHub recible sur la base après le merge de la PR du dessous ne relance pas sa CI : fermer puis rouvrir la PR la déclenche.
- **Une mesure d'agent de relecture n'est pas une preuve.** Une consigne a recopié « déjà équivalent » d'un rapport de relecture ; l'agent de code a trouvé le contraire dès la lecture. Une affirmation d'équivalence ou d'absence dans une consigne vient avec la commande qui la prouve, ou se formule en question.
- **Réutiliser un worktree terminé pour la grappe suivante** plutôt qu'en créer un : pas d'installation ni de pile à monter, l'agent garde le contexte du dépôt. Branche nouvelle depuis `origin/<base>` quand rien n'est commun, sur la branche précédente quand un fichier l'est.
- **Conflits de doc entre deux branches de la même grappe** : quand l'utilisateur a délégué les commits, la tour merge la base dans la branche et résout (les deux côtés d'un runbook sont souvent deux ajouts), puis revérifie la suite complète sur l'arbre fusionné avant d'ouvrir la PR.

## Réécriture en Rust, troisième lot de code, deux agents, QA d'une commande (13 au 15 octobre 2026)

- **Un message perdu sans erreur.** `agent prompt` a répondu `agent_prompted`, mais l'agent est resté `idle` : la vue
  d'un shell de fond était ouverte dans son pane et a avalé le texte. C'est sans doute aussi la cause du message perdu
  au lot précédent. Vérifier l'état après chaque envoi ; `esc` ferme la vue.
- **Une sonde d'agent sous le verrou se dimensionne comme une série de la tour.** Une mesure de mémoire sous `dhat`
  prévue à « deux ou trois points » en a pris sept, dont les plus coûteux au bout : plus de deux heures de verrou, et un
  autre agent bloqué à ses tests de fin. Cinq points alignés sur la formule suffisaient. Demander dans le plan le nombre
  de points et le temps estimé de chacun, et regarder le verrou quand une mesure dure.
- **L'exigence de branche à jour coûte cher en parallèle.** Avec deux worktrees et dix minutes de CI, presque chaque
  merge demandait une mise à jour et une CI de plus. L'utilisateur l'a retirée du ruleset, en gardant les vérifications
  requises. Ce qui compense : la tour prédit chaque fusion avant la Review, la joue quand des fichiers sont partagés,
  et lit la CI de la branche de base après chaque merge. La file de fusion de GitHub ne vaut que pour un dépôt
  d'organisation.
- **Un état de PR se relit avant d'être annoncé.** La tour a écrit deux fois « la PR attend ton merge » alors qu'elle
  était fusionnée depuis près de deux heures (l'auto-merge l'avait prise). Et un guetteur de la CI de la branche de base
  attendait un commit précis : un merge suivant l'a rendu introuvable, et la boucle aurait tourné sans fin. Relire
  `gh pr view` avant chaque phrase sur l'état d'une PR, et guetter « la dernière CI de la base terminée », pas un commit.
- **`board-field.py` juste après `gh project item-add`** échoue parfois (`KeyError` : l'item n'est pas encore lisible
  dans le projet). Relancer le champ manquant suffit ; vérifier les trois champs après une création.
- **Ce que le poste local ne voit pas, la CI le voit.** Deux classes d'échecs sont apparues seulement en CI : un import
  utilisé par un seul test réservé à un système (inutilisé ailleurs, donc refusé par `-D warnings`), et un test qui
  exige une sortie d'erreur vide, alors que le runner macOS virtualisé y écrit lui-même un message du système. À la
  relecture d'un diff, la tour cherche les `#[cfg(...)]` sur des tests et les égalités exactes sur stderr.
- **Une retouche proposée par la tour se vérifie dans le code avant d'être envoyée.** La tour a demandé de contrôler des
  `pts` « déjà rendus » d'après le compte rendu de l'agent ; le code montrait que ces fichiers sont réécrits à une autre
  cadence, et le contrôle aurait échoué. L'agent l'a vu et a posé la question. Lire le passage cité avant de transformer
  une remarque de revue en retouche.
- **Avant de déclarer un attribut inutile, chercher ce qu'il permet.** La tour a fait retirer des `#[cfg(test)]` de
  fichiers de tests en les disant sans effet ; ils servent à un lint (`unwrap` permis seulement en `cfg(test)`). L'agent
  l'a vérifié en essayant, et n'a retiré que ceux des aides sans `unwrap`.
- **Le dossier des comptes rendus enfle sans qu'on le voie.** Les planches vidéo d'un lot de rendu ont porté
  `rapports/` à 9,7 Go, dont 9 Go pour deux issues déjà fusionnées ; les sous-agents de revue ont laissé 2 Go de
  maquettes dans les dossiers temporaires. À chaque merge, proposer de retirer la planche lourde de l'issue fusionnée ;
  à la clôture, mesurer `rapports/` et les dossiers temporaires des agents.

- **Avec le guetteur qui ne compte qu'un fichier écrit après son départ, ne plus mettre de `sleep` avant lui.** Un agent
  rapide a écrit sa retouche pendant les 45 s d'attente : le guetteur a vu un fichier « ancien » et a rendu « arrêté sans
  compte rendu ». La fraîcheur suffit à écarter l'ancien compte rendu ; lancer le guet dans le même tour que le prompt.
- **Une passe de QA sur une commande, pas un navigateur.** Le cahier joue la vraie commande sur des **copies** des données
  (sans `-o`, la commande écrit à côté des vidéos), avec chemins d'or, chemins d'argent demandés par l'utilisateur
  (entrées, options, langue et terminal, relances et pannes, disque plein par une image disque) et contrôles transverses
  (code de sortie, stdout contre stderr, rien d'écrit ailleurs, pic de mémoire). Un agent, ~2 h, 58 lignes, 3 KO dont un
  né du lot, corrigé avant la clôture. La tour rejoue chaque KO et le date par `git log` avant d'en parler.
- **Des données de test hors du poste.** Le quota LFS gratuit de GitHub est de 10 Gio de stockage et 10 Gio de bande
  passante par mois pour tout le compte, et un budget à 0 $ bloque tout le LFS au dépassement, CI comprise. 11 Go de
  vidéos sont allés dans un bucket S3 (Scaleway, quelques centimes par mois), le reste dans un dépôt privé.
- **Ordres de grandeur** : 19 issues et 18 PR en trois jours, deux agents ; une garde de 3 points en 1 à 2 h d'agent,
  plan court compris ; CI d'une PR divisée par deux (15 → 7 min) par trois issues de CI.

## Reprise d'un lot depuis un serveur Linux, forge GitHub, délégation des gestes git (14 octobre 2026)

- **Un amorçage écrit sur Mac casse trois fois sur un serveur EL.** `sed -i ''` (BSD) fait lire à GNU sed un fichier vide ;
  `lsof` absent ; SELinux `Enforcing` refuse au conteneur un bind-mount du worktree (`Permission denied` sur
  `/docker-entrypoint-initdb.d`, exit 2), à corriger côté hôte par `chcon -Rt container_file_t <dossier>` quand
  `getenforce` dit Enforcing. Règle : `sed -i.bak … && rm -f *.bak`, repli `ss -ltnH "sport = :<port>"`, et sonder
  l'amorçage sur l'hôte cible avant le premier agent ; lire la sortie du pane quand il échoue.
- **Reprendre un lot sur une autre machine demande cinq choses** : la passation dans le dépôt des issues, les branches
  poussées, le fichier de lot ignoré par git recréé, `mise trust` et `gh auth`, et des worktrees sur des **branches
  existantes** : `herdr worktree create` crée une branche, donc `git worktree add <chemin> <branche>` puis
  `herdr workspace create --cwd <chemin>` pour le pane de l'agent. Un pre-rebase sur la branche voisine, décidé par
  l'utilisateur, a gagné une heure de chemin critique ; après la fusion de la voisine, la branche en était un descendant.
- **Un close/reopen de PR à trois secondes d'écart ne déclenche aucun workflow `pull_request`** : zéro run sur deux PR.
  Avec 45 s entre `close` et `reopen`, les deux sont parties. Le changement de base seul (`edited`) ne déclenche rien.
- **Le titre par défaut d'un merge commit GitHub cite le numéro de PR et le propriétaire** (« Merge pull request #10 from
  owner/branche »). Quand le dépôt interdit ces références, `gh pr merge --merge --subject "Merge branch '<branche>'"`.
  Vérifier aussi `git log` des branches et de la base pour les mentions interdites avant la première PR.
- **Sans déclencheur `push` sur la base, chaque PR en attente se recible sur la base courante avant son merge**
  (close, pause, reopen, run complet) : c'est ce qui remplace le run d'après merge. Décision de coût de l'utilisateur,
  posée en question avec le gain chiffré (un run de 20 min par merge).
- **Paralléliser une CI se mesure d'abord par étape** (`actions/runs/<id>` → `jobs[].steps[].startedAt/completedAt`) :
  une chaîne de 20 min s'est séparée en deux jobs de 5,8 et 11,9 min, soit 12 min murales pour 17,7 facturées.
  L'agent a trouvé une prémisse fausse de la consigne (le job e2e avait besoin du build et des migrations : la suite
  compile l'API par un script et le profil des images ne migre pas la base) : lire les helpers de la suite avant de
  découper.
- **Une chaîne `cd <worktree> && git add …` a tourné une fois depuis le mauvais dossier** (le `cd` n'a pas pris dans le
  shell de l'outil) : `git add` a échoué sur un chemin inexistant et un `push` a visé le dépôt des issues, refusé parce
  que la référence n'existait pas. Rien d'écrit, par chance. Règle : tout geste git d'écriture passe par `git -C <chemin>`
  ou un chemin absolu, jamais par un `cd` en tête de chaîne.
- **Un agent repris pour une seconde issue dans le même worktree garde son contexte** (12 % consommé après deux issues et
  une retouche) : la tour crée la branche depuis la base distante, envoie la nouvelle consigne avec un rappel d'une
  ligne que le cadre reçu au début tient, pas besoin de renvoyer la consigne commune.
- **`herdr agent prompt '<texte avec apostrophes>'` casse le shell** (« unmatched ' ») : écrire la consigne dans un fichier
  et envoyer `"$(cat fichier)"`, ce qui protège aussi les backticks.
- **Délégation des gestes git** : relire d'abord le format de l'utilisateur (`git log` : titre seul, type conventionnel,
  sans corps ; commitlint y borne le corps à 100 colonnes), préparer les corps de PR dans le scratchpad pendant les runs,
  un merge à la fois, fermer l'issue privée au merge avec PR, commit et durée du run. Chaque décision d'agent reste posée à
  l'utilisateur avant le commit.
- Ordres de grandeur : reprise à 16 h 15, 6 PR fusionnées à 19 h ; une issue d'outillage de 3 points en 12 min d'agent,
  sa suite de 2 points en 10 min + 5 de retouche ; un portage de rebase (9 erreurs TypeScript dans deux specs) en 5 min
  d'agent ; 0 compte rendu faux ; 2 prémisses de la tour fausses (le job e2e, « azure/main » sur une machine sans ce
  remote) ; une dizaine de questions directes à l'utilisateur.
- **Première passe de QA de fin de lot, trois agents (14 octobre 2026, même lot).** Le cahier n'existait pas : un agent de lecture l'a écrit en deux passes (la première jugée « sparse » par l'utilisateur : demander d'emblée les variantes de chaque écran, les profils, les états forcés, les contrôles transverses ; 475 lignes à la seconde), puis trois agents de QA ont joué 131 lignes en 28 minutes sur les images de production de trois worktrees : 4 KO (deux défauts préexistants corrigés dans le lot, un préexistant au Backlog, une ligne de cahier fausse), 1 bloquée, 0 régression. Ce qui a marché : la section 0 « contournements connus » du cahier, le fichier de contournements partagé (dix lignes en 20 minutes, dont deux pièges de pile vus par les trois agents à la même minute), le suivi au fil de l'eau lu par la tour, et la tour qui classe chaque KO (préexistant ou régression) en datant les fichiers par `git log` avant d'ouvrir l'issue. Les agents de QA rendent aussi des « apprentissages pour le cahier » précis (libellés réels, `h2` contre `h3`, montants à figer, HTTP 200 sur un lien expiré) : réécrire le cahier le jour même, sinon ils se perdent.
- **Le nom d'agent herdr est global à la machine, pas au workspace** : `qa-1` existait dans un autre projet, le lanceur a refusé cinq fois et s'est arrêté avant les grappes suivantes. Préfixer les noms de grappes par le projet (`fepem-qa-2`) ou faire préfixer le nom d'agent par le lanceur. Un agent en place dans son pane se démarre à la main avec `herdr agent start <nom> --kind claude --pane <pane> -- …`.
- **Pièges de pile vus par la QA** : SELinux Enforcing refuse aussi le volume du certificat du stand-in (`dev/legacy-bridge/tls`, `chcon -R -t container_file_t` avant `compose up`) ; la version de Playwright du worktree peut réclamer un `chromium_headless_shell-<n>` absent du cache (`pnpm exec playwright install chromium-headless-shell` depuis le worktree, sans root ; un `executablePath` forcé vers une autre version a marché mais l'utilisateur l'a refusé après coup) ; le POST auto-soumis d'une page https vers http part avec `Origin: null`, donc le vrai pont ne se joue pas en local, il faut poster le jeton soi-même ; les horodatages des agents sont en UTC, ne pas s'en servir pour mesurer.
- **Modules Python absents du poste** (`yaml`, `openpyxl`) : ne pas les installer, lancer `uv run --with pyyaml script.py` ; l'environnement est créé à la volée et mis en cache, indépendant du Python de mise (utilisateur, 15 octobre 2026). Alias du poste : écrire `command cat`, `command df` plutôt qu'un chemin absolu.
- **Les correctifs nés de la QA passent par le cycle normal, dans un worktree libéré** : agent qui a déjà le cadre (`ci`, `severance`), branche depuis la base distante, décisions posées, retouche, PR reciblée. Deux correctifs de 1 et 2 points en 25 et 40 minutes d'agent, revue comprise ; l'un a révélé un troisième endroit avec le même défaut (la branche renvoyée), que l'agent a corrigé en le disant.
- **Classer un KO demande de dater les fichiers**, pas seulement de lire la cause : `git log -- <fichiers>` entre la base du lot et la tête dit si le lot y a touché. Les quatre KO de la passe étaient antérieurs au lot ; le dire à l'utilisateur change la décision (corriger maintenant ou trier).

## Première passe de QA de fin de lot (14 octobre 2026)

- **La passe a trouvé ce que la CI ne voyait pas.** Sur 21 issues mergées avec CI verte, 4 régressions sont sorties
  dans le navigateur en build de production : une dépendance qui charge deux versions d'une même bibliothèque (écran
  noir, aucun test ne rend la vue), une garde ajoutée en base qui casse une écriture faite champ par champ, un prédicat
  de menu qui plante sur une valeur nulle, et un consommateur que l'issue n'avait pas branché sur la nouvelle règle
  alors que le runbook l'affirmait. Les deux premières n'étaient sur aucun chemin d'or : elles sont sorties de lignes
  jouées en variante (session sans validation, dernière question) ou hors cahier. D'où les chemins d'argent.
- **Agir en direct paie.** Les fichiers de suivi au fil de l'eau ont permis d'ouvrir l'issue, de lancer le correctif et
  de rediriger les autres agents pendant la passe ; quatre correctifs étaient mergés avant la fin des rapports.
- **Un état de déploiement repris d'un résumé est une hypothèse.** Un résumé de session disait un correctif « déjà
  appliqué » sur deux instances ; c'était faux, et toute une doc de livraison (scénario de migration hors ordre) a été
  écrite dessus avant que l'utilisateur corrige. Avant d'écrire une livraison : demander l'état réel de chaque instance
  (ou la commande de lecture qui le donne), ne jamais le déduire des heures de merge ni d'un résumé.
- **Données hors écran** : un agent de QA s'est vu refuser la préparation d'un état impossible par l'écran (transition
  interdite) ; la tour l'a faite sur la pile locale en contournant les triggers. Un écart vu sur ces données doit être
  rejoué sur des données faites par l'écran avant d'être compté : un des KO de la repasse venait de là.
- **Ordres de grandeur** : 3 agents, ~50 minutes chacun pour 12 à 21 lignes ; repasse ciblée 1 agent ~50 minutes ;
  chaque correctif 20 à 60 minutes d'agent ; ~40 frictions UX relevées sans les chercher, regroupées en 5 issues.
- **Une boîte de dialogue de Claude Code peut avaler une consigne** : après une longue session, l'agent a affiché
  « Teach auto mode about your environment? » (proposition de lire l'historique du shell), et le `prompt` suivant est
  resté sans effet, l'agent en `done`. Après chaque envoi, vérifier que l'agent passe en `working` ; sinon lire l'écran,
  fermer la boîte par `esc` (ne pas accepter de lecture de l'historique sans l'utilisateur) et renvoyer.
- **Un agent lancé sans guet attend en silence** : un agent démarré en fin de série (après d'autres réponses) n'a pas eu
  son `guetter.sh`, et sa question est restée sans réponse jusqu'à ce que l'utilisateur la voie. Lancer le guet dans le
  même tour que le `agent prompt` de la consigne, sans exception, et vérifier au point périodique que chaque agent
  vivant a un guet en cours.

## La bascule vers le Rust, neuf issues, délégation des gestes git sur deux jours (15 et 16 octobre 2026)

- **Un libellé d'option se relit contre les décisions déjà prises.** « Vidéos de QA en LFS » est passé dans une
  question posée à 19 h, à contresens de ce que l'utilisateur avait dit la veille (tout dans le seau, rien en LFS) ; il
  l'a cochée, l'issue a été redessinée deux fois et un dépôt créé pour rien. Avant d'écrire une option, vérifier qu'elle
  ne contredit pas une décision du lot ; en cas de doute, la citer dans l'option.
- **Le réseau n'est jamais sous le verrou.** Un téléchargement de 11 Go mis sous le verrou par la consigne a bloqué les
  mesures 24 min sur un réseau d'hôtel. Le verrou est à deux niveaux : `lourd` partagé (vidéos entières, construction
  de zéro, tests lents) et `chrono` exclusif (temps publiés), un script Python `fcntl.flock` compatible `lockf`.
- **Prédire la fusion juste avant de merger, pas à l'ouverture de la PR.** Un `merge-tree` propre à l'ouverture a été
  suivi de trois merges ; la PR était DIRTY sur cinq fichiers à son tour. Refaire la prédiction sur `origin/<base>`
  du moment, et lancer la fusion dans le worktree de l'agent dès qu'elle est sale.
- **Un hook de poussée nouvellement posé se teste par un vrai push.** Le pre-push qui lance `check` a refusé son propre
  premier push : git exporte `GIT_DIR` dans les hooks et un test « hors d'un dépôt » voyait le dépôt. Défaut réel du code
  (une commande git sans `env_remove`), trouvé par le hook, invisible en CI.
- **Sortir un dossier du suivi git quand des fichiers non suivis y vivent déjà** : le rebase bute sur le fichier non
  suivi (« would be overwritten »), et un `--abort` efface du disque tout ce que le commit de départ ne suit plus. Copier
  le dossier hors du dépôt avant, déplacer le fichier gênant, prédire chaque `pick` par `merge-tree --merge-base`, puis
  rebaser. La copie a servi : 11 fichiers restaurés.
- **Signature gpg sous délégation** : deux commits délégués ont expiré sur pinentry, et le `!` de la session n'est pas un
  terminal interactif. Avant le premier commit délégué, faire taper `gpg --clearsign <<< test` à l'utilisateur dans un
  vrai terminal, et le redire après une longue pause.
- **Guetteur** : « ARRÊTÉ » rendu après 10 min alors que l'agent attendait un shell de fond long (mesures de 8 min) ;
  le compte rendu est arrivé une minute après. Avec des shells de fond ouverts, attendre plus longtemps avant de
  conclure, et relire l'écran de l'agent avant de le dire arrêté.
- **Un `check` de 20 min tue la cadence** : l'utilisateur l'a dit (« c'est aussi pour ça que ce projet avance moins »).
  Couper tôt : le rapide (statique + tests nus, 20 s) en local et dans le pre-push, le lourd (couverture 519 s, lents,
  réglages) en CI. Mesurer chaque morceau avant de décider : la couverture seule valait 85 % du temps.
- **Le dossier de la tour dans un dépôt public** : l'utilisateur l'a sorti du suivi (l'historique reste). Si le dépôt des
  issues est public, ignorer tout `.claude/tower-control/` dès le départ, pas seulement `lot-*.sh`, ou le tenir dans un
  méta-dépôt privé.
- **Une PR de docs seules coûte la CI entière** quand le ruleset exige des contrôles nommés : `paths-ignore` seul les
  laisse « en attente » à jamais ; il faut un second workflow aux mêmes noms qui réussit sans rien faire. Issue ouverte
  (#219) ; l'utilisateur a mergé en administrateur ce jour-là.
- **Ordres de grandeur** : 9 issues, 9 PR, 28 points en deux jours, jusqu'à trois agents ; CI d'une PR 15 min ; une issue
  de docs de 5 points (13 fichiers) en 2 h 30 d'agent, plan et deux relectures compris ; la 092 entière en 19,8 s.

## Treize issues, une release et un push sur `main` par erreur (16 octobre 2026)

Lot 10 de chiro-dvr : toutes les P1 et P2, clôture de la migration Rust, release 0.2.0 à la main à la fin, délégation
des gestes git toute la journée. Quatre grappes, jusqu'à quatre agents, 15 PR, une QA d'un agent.

- **`push.default = upstream` + branche créée depuis `origin/main` = push sur `main`.** `git checkout -b x
  origin/main` pose l'amont `origin/main` ; `git push -u origin x` sans `:dst` pousse alors vers l'amont, et le
  ruleset de `main` a accepté le commit. Toujours : `checkout -b x --no-track origin/main`, push par
  `refs/heads/x:refs/heads/x`, `git branch --set-upstream-to`, `git ls-remote --heads origin x` avant `gh pr create`.
  Relever `git config push.default` au relevé des alias du poste.
- **Grouper par fichiers, encore.** #66, #83, #84 et #70 touchaient `previous.rs`, `texts/tests.rs` et le README :
  réparties sur deux grappes pour aller vite, elles ont coûté quatre `git merge origin/main` résolus par les agents.
  Une chaîne unique aurait été plus lente sur l'horloge et moins chère en tout.
- **gpg expire** après une longue pause : faire déverrouiller avant chaque série de commits, pas une fois par jour.
- **`git merge origin/main` refuse un arbre non commité** : commiter l'état de l'agent d'abord, puis merger, puis
  l'agent résout sans git, puis `git add` + commit de fusion. `gh pr update-branch` échoue sur conflit.
- **Reciblage d'une PR empilée** : GitHub ne relance pas la CI ; close/reopen la relance en 45 s.
- **Agents sans écran** : une capture d'un Terminal, d'une notification ou du Finder ne se fait pas par un agent ;
  rendre le texte par `magick`, laisser les vraies captures à l'utilisateur hors lot.
- **Rien de technique dans les docs naturaliste** : règle écrite dans le CLAUDE.md du projet après que trois agents
  y ont mis commandes et `<details>` ; un script `tools/docs-images.sh` porte la reproduction des captures.
- **Mesurer sur la machine cible** : `/usr/bin/time` absent sur Rocky, `%M` de zsh en Mo ; un binaire `-dirty`
  ne saute jamais une vidéo, poser `BATDETECT_VERSION` pour une QA de relance.
- **Un clone local d'un autre dépôt n'est pas forcément à jour** : `git status` montrait « à jour » avec deux
  commits de retard (pas de fetch) ; faire `git fetch` ou lire `origin` avant d'écrire une consigne dessus.
- **`brew audit --strict` sur une formule avec `version`** est rouge par construction quand un script de bump lit
  cette ligne ; le dire dans la consigne plutôt que d'en faire un critère.
- **La QA de fin de lot en un agent** : 126 lignes en ~2 h, 1 KO réel trouvé et corrigé le jour même ; le cahier
  grandit de 196 à 466 lignes et les sorties de QA (23 Go) se suppriment à la fin.

## Soixante issues en trois jours, des planches jugées à l'œil, une release en fin de lot (16 au 18 octobre 2026)

Cinq grappes, jusqu'à cinq agents, 59 issues et 50 PR en ~38 h, 215 décisions, délégation des gestes git sur tout le lot, une release à la fin et une QA d'un agent sur la version publiée.

- **Le guetteur accepte `idle` comme `done`.** herdr rend maintenant `idle` à la fin d'un tour ; un guetteur qui n'attendait que `done` a manqué deux fins d'agent, et l'utilisateur a dû dire « il attend ».
- **`git merge-tree` : lire toutes ses lignes.** Un filtre `sed -n 2,4p` a caché la ligne CONFLIT, et une PR a été annoncée fusionnable. Lire `--name-only` en entier, ou chercher `CONFLIT|CONFLICT`.
- **Un commit construit à la main n'est pas signé.** `git commit-tree` ignore `commit.gpgsign` : deux commits sans `-S` ont bloqué une PR verte sur un ruleset `required_signatures`, qui n'est passée qu'en contournement administrateur. Toujours `-S`, et vérifier `git cat-file commit <sha> | grep gpgsig` avant de pousser.
- **Séparer une fusion de main du travail de l'agent** quand les deux sont mêlés sur disque : arbre de la fusion seule par `merge-tree --write-tree`, conflits résolus dans un index temporaire (`GIT_INDEX_FILE`), `commit-tree -S` pour la fusion puis pour le travail, `merge --quit`, `update-ref`. L'historique reste lisible ; vérifier que la fusion intermédiaire compile.
- **zsh : `path` est `PATH`.** Une variable de boucle nommée `path` a vidé le `PATH` du shell ; et zsh ne découpe pas une variable en mots (`$=v` ou arguments littéraux).
- **L'heure dans le fuseau de l'utilisateur.** Le serveur est en UTC, l'utilisateur voyage : des ETA en UTC ont été lues fausses. Convertir (`TZ=<zone> date`) ou dire « UTC ».
- **Une planche dit quoi regarder.** Deux images côte à côte sans consigne ont été lues « je ne vois rien », et la tour l'a pris pour « aucune différence ». Pour chaque cas : la question, ce qui change, où regarder. Carrés autour des détections plutôt que points sur l'animal, image entière sans recadrage.
- **Les verdicts d'une planche font une règle mesurable.** 34 cas jugés « même animal ? » ont donné 21 mieux, 5 pire ; l'agent a corrigé 3 des 5 sans toucher aux 21, et les 2 autres sont partis en issues. Demander « corrige les pires sans défaire les bons, sinon arrête-toi avec les chiffres ».
- **Vérifier les chiffres d'un compte rendu avant de les répéter.** Un gain annoncé −30,8 % était −20,7 % ; la correction a été dite à l'utilisateur, qui a gardé le changement.
- **Un texte dans la zone de saisie d'un agent** (suggestion grisée de Claude Code) n'est pas une réponse de l'utilisateur : deux fois, il ressemblait à un feu vert.
- **Le délai « main vert » vaut entre deux merges, pas avant un lancement** : un agent peut partir de main dès le merge, le contenu est celui que la CI de la PR a validé.
- **Une méta posée en « À faire »** veut dire « toutes ses sous-issues ouvertes dans le lot » ; les passer en « À faire » et laisser la méta pour les regrouper.
- **Un fichier de plus de 30 Mo ne s'envoie pas à l'utilisateur** : découper par cas (2 cas par zip) ou donner une commande `scp` d'un seul zip ; demander lequel avant de produire.
- **Un prototype peut ne vivre que dans un dossier ignoré** (`out/` d'un worktree, sans commit) : au ménage, chercher ce qui n'est nulle part ailleurs avant de retirer un worktree, et proposer de le mettre sur une branche.
- **Une règle de forme change en cours de lot** : « un paragraphe par ligne » est devenu « coupure en fin de phrase, ~140 » par un commentaire de l'utilisateur sur l'issue, lu après le lancement. Relire les commentaires d'une issue juste avant de la lancer, pas seulement au groupement.
- **Ordres de grandeur** : CI d'une PR ~8 min en médiane, quelques secondes pour des docs seules ; gardes lourdes d'un changement de suivi ~1 h 30 (mesure puis confirmation) ; release 9 min ; planche de 34 cas en 67 extraits, 387 Mo.
- **Vérifier une copie avant de supprimer la source.** Au ménage, les scripts des dossiers temporaires de deux agents devaient être copiés puis les dossiers vidés, dans la même commande ; la copie n'avait rien pris (`find -size -1M` de GNU arrondit au Mo supérieur et ne garde que les fichiers vides : écrire `-size -1024k`), et les scripts de mesure sont perdus. Compter les fichiers copiés, puis supprimer dans une commande à part.

## Réécriture d'un backlog entier au gabarit, relu contre le code et à froid (19 octobre 2026)

Soixante-dix-huit issues ouvertes réécrites au gabarit Why / What / Must-Have / How. Quinze agents de relecture, une grappe chacun, puis trois passages de reprise et deux tours de lecteur froid. Neuf issues créées, deux fermées, environ 140 prémisses fausses corrigées. Sept paquets appliqués par un seul script.

- **Poser toutes les questions avant les paquets.** La tour a annoncé « 160 questions », en a posé 15 et gardé le reste « pour la relecture » : c'est l'utilisateur qui les a réclamées. Avant de montrer un texte à valider, compter les décisions encore ouvertes et les poser toutes. Séparer ce qui a déjà une réponse dans les sources (la tour répond et cite), les choix d'implémentation (« à trancher à la PR » dans le What) et ce qui revient à l'utilisateur. Les recommandations nombreuses passent en un seul tableau numéroté, avec « tout appliquer / tout sauf / un par un ».
- **Le test du lecteur froid après la passe humanize.** Des agents neufs, sans le contexte de la session ni accès au code, doivent résumer chaque issue en une phrase et citer ce qui les arrête. Au premier tour, 30 textes sur 87 ont échoué, alors que les auteurs les jugeaient clairs : sigles internes, mots du projet jamais présentés, décomptes faux, contradictions entre deux issues. Donner aux auteurs un vocabulaire commun (une définition par mot interne, posée à la première apparition dans chaque issue), puis faire relire à froid les seuls textes repris. Préciser dans la consigne qu'un texte avec plusieurs points mineurs reste « clair » s'il n'a aucun point bloquant : sinon les lecteurs appliquent des règles différentes.
- **Une question construite sur l'interprétation d'un agent se vérifie contre la source avant d'être posée.** Deux fois, la tour a présenté la lecture d'un agent comme le contenu d'un document. La première a contredit une décision que l'utilisateur avait prise sept jours plus tôt. La seconde a donné une liste différente d'un commentaire de l'utilisateur, et il a fallu reposer la question pour trancher entre deux décisions contradictoires. Chercher la décision antérieure (docs, commentaires de l'issue), et citer la source exacte dans la question.
- **Une phrase de consigne se propage telle quelle.** « Le refus de X tient » a été écrit par la tour pour une décision, et deux agents l'ont recopié comme un fait de code, alors que ce refus était encore à faire. Il a fallu corriger une issue déjà publiée. Dans une consigne, distinguer ce qui est décidé de ce qui est fait.
- **Un tableau soumis à validation se contrôle par script avant d'être montré.** Un passage de 5 à 4 points, hors de la suite de planning poker, a été validé dans un tableau puis relevé par l'utilisateur à l'envoi. Vérifier les points (1, 2, 3, 5, 8, 13), les décomptes annoncés contre les listes, les jalons et les colonnes.
- **Réécrire tout un backlog se fait par fichiers, puis par paquets.** Un fichier « avant » et un fichier « après » par issue. Un fichier de constats par grappe, avec le verdict, le scénario daté, les prémisses fausses et les questions. Un script par paquet fait tout, dans l'ordre : créer les nouvelles issues, remplacer les renvois « suivi à part » par leur numéro, poser les corps, retirer les labels obsolètes, poser les champs du board et les jalons, fermer avec un commentaire. Il saute toute issue dont le corps a changé sur GitHub depuis l'export, et relit chaque corps après écriture. Zéro écart sur 87 textes.
- **Vérifier un déploiement soi-même avant de fermer.** L'utilisateur doutait qu'un environnement soit bien déployé. Un `az login` tapé par lui, puis une lecture des variables et de l'ingress (sans afficher de secret), a tranché en deux minutes. La même lecture a montré que le risque décrit par l'issue avait seulement changé de porte : il est passé dans une nouvelle issue au lieu de disparaître à la fermeture.
- **Ordres de grandeur.** Une relecture contre le code prend 7 à 12 minutes par grappe de quatre à sept issues. Une reprise prend 15 secondes à 2 minutes par agent. Un lecteur froid lit 15 à 25 textes en 2 à 4 minutes. Comptez environ cinq heures pour 87 textes, questions comprises.

## Lot 5B de fin de contrat, quatre worktrees, délégation depuis un serveur Linux (20 octobre 2026)

- **La signature n'est pas toujours gpg.** Quand `gpg.format = ssh`, un commit se signe sans gpg ni pinentry, et la règle « faire déverrouiller gpg avant le premier commit délégué » ne vaut que pour une signature gpg. La tour l'a appliquée à l'aveugle et a fait attendre l'utilisateur pour rien. Avant de parler de gpg, lire `git config gpg.format` ; en `ssh`, commiter directement et vérifier la signature par `git cat-file commit HEAD | grep -c '^gpgsig'`. La règle de tc-delegate lit maintenant `gpg.format` avant de parler de gpg.
- **Compacter les agents entre deux issues.** Un agent qui enchaîne dans le même worktree arrive à 79 % de contexte sur sa seconde issue, et le résumé automatique tombe alors au milieu du travail. Après le commit d'une issue, avant la consigne suivante, la tour envoie `/compact` à l'agent (`herdr agent prompt <agent> "/compact"`) et relève le remplissage sur sa ligne d'état. Demandé par l'utilisateur.
- **Une seule pile e2e, pilotée par la tour.** Faire jouer la suite end-to-end par chaque agent dans son worktree a coûté un piège d'environnement (le Switch de substitution que Playwright démarre en TLS auto-signé, que l'API ne reconnaît qu'avec `NODE_EXTRA_CA_CERTS` sur le certificat : 60 rouges pour rien), puis un agent qui a tué le `flock` d'un autre en croyant arrêter le sien. Les ports étant fixes, les runs étaient sériels de toute façon. Règle retenue : les agents ne jouent pas les e2e ; la tour les joue sur chaque branche avant de pousser, une à la fois, et renvoie les noms des tests rouges avec la trace. Les images de production restent pour la QA de fin de lot.
- **La sonde de port de l'amorçage ne voit pas un conteneur.** `ss -ltnH "sport = :<port>"` n'a pas vu le PostgreSQL d'un autre worktree qui écoutait sur ce port, et `docker compose up` a échoué sur « port is already allocated » : le lanceur a laissé la grappe sans agent après le délai. Sonder aussi `docker ps` (les ports publiés) ou lire le port dans la sortie de `docker compose` avant de l'écrire dans `.env`. Réparé à la main : port changé dans `.env`, `docker compose down`, puis la fin de l'amorçage rejouée dans le pane et l'agent démarré avec la commande du lanceur.
- **`$VAR:mot` sous zsh est un modificateur d'historique.** `git push origin "refs/heads/$BR:refs/heads/$BR"` a visé `…isolationefs/heads/…` (`:r` a mangé le `r`), et `git show "$B:apps/…"` avait fait de même plus tôt (`:a`). Rien de poussé, mais une PR refusée et dix minutes. Toujours `${VAR}:…` dans les chaînes que la tour tape dans un shell zsh.
- **Une copie d'un worktree sous `/tmp` garde le nom de projet compose du worktree.** Un `docker compose` lancé depuis la copie a recréé le PostgreSQL du worktree d'origine en plein run e2e (87 rouges). Une copie de dépôt se fait avec `COMPOSE_PROJECT_NAME` propre, ou pas de compose du tout.
- **L'amorçage ne garantit pas l'unicité des ports d'images entre worktrees.** Deux worktrees ont reçu 3270 à 3273 (le décalage dérive du nom, et seul le port PostgreSQL est sondé). Sonder aussi les ports web, api et substitut, ou dériver tous les ports du port PostgreSQL trouvé libre.
- **GitHub ne lance pas la CI d'une PR en conflit, et ne le dit pas.** Le rollup des checks reste vide, le guet de merge attend pour rien, et un close/reopen ne change rien. Avant d'attendre une CI, lire `mergeable` de la PR (`gh pr view --json mergeable`) : `CONFLICTING` veut dire « fusionner la base d'abord ». Vu sur une PR ouverte dix minutes après le merge d'une autre qui touchait le même helper.
- **Ce qui a bien marché.** Dix issues plus cinq correctifs, 53 points, en 8 h 30 avec quatre agents au plus : 8 points par heure sur les issues indépendantes, trois fois moins par point sur quatre issues sérielles qui partagent un questionnaire, un moteur et un écran. Les fusions à conflits (22, 9, 9 fichiers) confiées à l'agent qui avait écrit les deux côtés, sans git, puis commitées par la tour : aucune erreur. Le cahier de QA de la zone neuve écrit le jour même par un agent de lecture qui cite fichier et ligne pour chaque libellé et chaque montant, puis joué par deux agents : 143 lignes, 0 KO, trois lignes du cahier fausses et corrigées. Le compte rendu d'un agent qui mesure (compteurs relevés seconde par seconde) a tranché un diagnostic faux de la tour. Compacter un agent entre deux issues (79 % → 0 %) sans perte : la consigne suivante se suffit.
- **Ordres de grandeur.** Suite e2e locale complète 5 à 6 min, CI de PR 12 min (Checks 6, End-to-end 12 en parallèle), hook pre-push 100 s, fusion à 22 conflits résolue et vérifiée en 25 min d'agent, issue de 5 points en 45 à 90 min d'agent, QA de deux agents 1 h 25 pour 143 lignes.

## Vingt-six issues en une journée, sept fusions sur une chaîne sérielle, une régression de somme de merges (21 octobre 2026)

- **Le hook pre-push joue l'arbre de travail, pas le commit poussé.** Quand la tour crée la branche suivante dans le même worktree avant de pousser la précédente, le hook rejoue les gates sur les modifications en cours de l'agent et rougit. Pousser avec `--no-verify` quand le commit a déjà ses gates et ses e2e, et le dire dans le journal.
- **Une PR poussée pendant que sa base est en conflit ne reçoit aucune CI, même après le merge de sa base.** `mergeable` reste `UNKNOWN`, le rollup vide, close/reopen sans effet. Pousser un commit neuf (la fusion de la base) pour relancer.
- **Deux PR vertes peuvent se casser l'une l'autre** : un test e2e écrit contre un parcours à cinq étapes, mergé après la PR qui en a ajouté une sixième, a laissé la base rouge cinquante minutes. Avant tout merge dont la base a bougé depuis la CI : fusionner la base dans la branche, rejouer les gates et la suite e2e sur l'arbre fusionné. Ouvrir les PR dès le push (CI en parallèle), ne sérialiser que le merge.
- **Un registre de textes vérifié par un instantané rougit à chaque fusion** qui apporte un libellé par motif : le régénérer sur l'arbre fusionné avant le push, sinon la CI tombe sur une ligne.
- **Deux migrations de semence écrites le même jour par deux agents ont pris les mêmes identifiants** (copiés d'un fichier voisin) : `ON CONFLICT DO NOTHING` sautait l'une en silence et son `down` effaçait l'autre. Consigne : un identifiant se tire de la base, jamais d'un fichier voisin, et la fusion le vérifie par `up`, `down`, `up` avec le compte des lignes.
- **Une chaîne sérielle sur les mêmes fichiers coûte une fusion par issue** quand une autre branche touche ces fichiers en parallèle : sept fusions sur une chaîne de quatre motifs plus une branche voisine, près de deux heures de chemin critique. Soit tout mettre dans une seule chaîne, soit accepter les fusions et les confier à l'agent qui connaît un des deux côtés, dans un worktree jetable amorcé (`git worktree add` + amorçage), la tour commitant.
- **Le board se tient au fil de l'eau** : « En cours » au lancement de l'agent, « Review » à l'ouverture de la PR. La tour l'a oublié toute une matinée, l'utilisateur l'a vu.
- **Avant d'amorcer un worktree de QA sur `origin/<base>`, `git fetch`** : le lanceur lit la référence locale, et un merge arrivé entre-temps manque.
- **Un paragraphe de contexte avant chaque question** : une liste (a) à (e) en une ligne de question n'est pas lisible, l'utilisateur l'a refusée.
- **`$VAR:chemin` sous zsh, encore** : le modificateur d'historique avale le nom. `${VAR}:…` partout, y compris `git show "${T}:…"`.
- **Les agents de lecture `Explore` ne peuvent pas écrire de fichier**, la tour recopie leur rapport : prévoir la recopie dans le temps de préparation (quatre rapports, vingt minutes).
- **Ce qui a bien marché** : la relecture contre le code par quatre agents (deux issues à jeter ou recadrer, huit prémisses fausses, deux points re-chiffrés) ; les conventions provisoires nommées avec test `provisional:` et section de doc, qui ont permis de livrer neuf motifs sans le juridique ; les fusions confiées aux agents avec la fiche « ## Fusion » de la fusion précédente comme modèle ; la QA en deux temps (le hors-5B lancé avant le dernier merge) ; `bin/e2e-local` qui joue chaque branche sur ses ports, sans verrou de certificat.
- **Ordres de grandeur** : vingt issues et 51 points en 5 h 15 de merges, 9,8 points par heure ; e2e locaux 5 à 7 minutes, CI 10 à 14 minutes par PR ; une QA de 174 lignes en 45 minutes par agent (deux agents) ; 2 KO, une régression de somme de merges.

## Premier lot d'un projet neuf, TUI, QA dans la vraie TUI par herdr (25 octobre 2026)

Quinze issues livrées en une journée, dont une née de la QA. Quatre agents de code, puis deux agents de QA. Délégation des gestes git toute la session.

- **Le `CLAUDE.md` d'un projet antérieur aux skills contredit le cadre de la tour** : mode plan et trois revues pour toute tâche, sous-phases avec arrêt, « tu peux `git add` ». Le réécrire avant le premier lancement, avec l'utilisateur : une section pour la session directe, une pour l'agent de la tour (plan relu et sous-phases à partir d'un seuil de points, aucun git), une commune. Le commiter avant de créer les worktrees.
- **Lancer d'abord, seule, la PR qui remet la doc d'accord avec le code.** Les agents relisent la doc des écrans avant de toucher un libellé : sur une doc périmée, ils « corrigent » le code dans le mauvais sens. Les parties de doc qu'une issue de code va réécrire restent à cette issue.
- **Une question par dialogue d'agent.** Un `AskUserQuestion` à plusieurs onglets ne se lit pas depuis la tour, qui ne voit que l'onglet affiché. Au-delà d'une question, l'agent les écrit dans un fichier, et la tour les pose toutes à l'utilisateur en une fois. Les questions de wording d'une même issue se tranchent ainsi en un tour au lieu de cinq.
- **Un agent a écrit de lui-même une mémoire de projet**, partagée par toutes les sessions. Le contenu était juste, mais c'était une règle de tour, pas un fait du projet : supprimée, et la règle remontée ici. Les agents n'écrivent pas dans la mémoire.
- **Une relecture UX indépendante des textes, demandée par l'utilisateur après la première, a trouvé deux boucles de parcours** (un écran qui renvoie vers une étape qui ne peut pas corriger le cas). Proposer cette seconde relecture dès qu'une issue ajoute des écrans de refus qui renvoient ailleurs.
- **Ne jamais masquer la sortie d'un `git commit`.** Un commit échoué (gpg expiré) dans une chaîne `>/dev/null 2>&1 || echo` a laissé partir un `push` d'une branche égale à la base et une tentative de PR. Vérifier que le SHA a changé et que le commit est signé avant tout push.
- **zsh lit `$B:r` comme un modificateur** : `refs/heads/$B:refs/heads/$B` est devenu un refspec tronqué. Toujours `${B}` dans un refspec.
- **gpg expire plusieurs fois par soirée.** `echo test | gpg --clearsign --batch --pinentry-mode error` dit sans bloquer si l'agent est déverrouillé : le lancer avant chaque série de commits plutôt que d'échouer au commit.
- **Une branche partie avant le merge d'une issue voisine a conflicté sur quatre fichiers.** La tour commite le travail validé, lance `git merge origin/<base>` dans le worktree, l'agent résout sans git (les deux comportements gardés, l'ordre des contrôles posé à l'utilisateur), puis la tour fait le commit de fusion. Vingt minutes, aucune perte.
- **Jouer la fusion quand la base a changé de dépendances.** Un `merge-tree` propre ne voit pas qu'une montée de lint ou de framework casse la branche. Worktree jetable sur le commit de fusion, install, lint, types, tests : deux fois vert, cinq minutes chacune.
- **Dependabot ne monte pas une peer installée automatiquement par pnpm** : pnpm ne la re-résout pas, même en mise à jour générale. Un override temporaire force la résolution ; une fois le lockfile écrit, le retirer, sinon il réécrit durablement la plage du paquet parent.

### QA d'une TUI dans la vraie TUI

- **herdr remplace `expect`.** Chaque pane est un vrai terminal : `pane run` lance le binaire, `pane send-keys` envoie les touches (`down`, `enter`, `esc`, `ctrl+c`, `backspace`, `shift+tab`), `pane read --format ansi` relit l'écran avec ses couleurs, `pane wait-output` attend un texte. On vérifie les couleurs et la largeur réelle, ce qu'`expect` ne montre pas. Le terminal à droite de l'agent, créé par le lanceur, sert de pane de test.
- **Pièges** : une touche par appel (deux touches dans un appel perdent la première) ; `stty rows 24 cols 80` avant de lancer (`pane resize` ne réduit pas la hauteur) ; `wait-output --match "EXIT="` trouve la ligne de commande `echo EXIT=$?`, il faut `--regex 'EXIT=[0-9]+'` ; les couleurs sortent en `38;5;n`, pas en `3n`.
- **L'historique zsh est partagé entre les panes.** Une flèche haut envoyée après la sortie du binaire a rejoué dans un pane la commande de l'autre agent, avec son `HOME`, et y a écrit des fichiers. Règle : n'envoyer aucune touche si le binaire ne tourne pas, quitter par Échap, lancer par un script à soi.
- **`HOME` isolé obligatoire** quand l'outil lit une configuration réelle (identifiants d'un stockage distant) : sans lui, la passe aurait appelé le vrai service. Faux binaires externes en tête du `PATH`.
- **Un binaire `bun --compile` local est tué par macOS** (« invalid signature », code 137) : `codesign --sign -` après le build, comme la CI de release.
- **Le scratchpad d'un agent peut être déclaré indisponible en pleine passe** : monter les données de QA dans un dossier à soi (`/tmp/<projet>-qa-<k>`) et le nettoyer à la clôture. 14 Go à supprimer en fin de passe.
- **Le cahier de référence est rédigé une fois par un agent de lecture**, avec variantes, états forcés et contrôles transverses dès la première demande : 16 chemins d'or, 155 chemins d'argent, 18 contrôles. Deux agents de QA l'ont joué en une heure chacun. Aucun KO n'était une régression du lot ; un KO a révélé un défaut que la tour croyait absent d'un des deux moteurs, et c'est l'agent qui a mesuré le contraire.
- **Ordres de grandeur** : 15 issues (~55 points), 20 PR, de 11 h à minuit ; 6 à 60 minutes d'agent par issue, plans relus et sous-phases pour les issues à 5 points ; ~60 questions directes à l'utilisateur ; QA 203 lignes, 2 agents, ~1 h chacun ; trois expirations de gpg.

## Premier lot d'un dépôt vide, deux worktrees, délégation des gestes git (26 octobre 2026)

Quatre issues (15 points) mergées en trois heures, deux agents, quatre PR ; la QA finale est manuelle chez l'utilisateur (outil sans API), les issues concernées restent ouvertes après le merge.

- **Le lanceur nommait l'agent d'après le dossier du dépôt, et herdr refuse une majuscule dans un nom d'agent** : cinq refus par grappe, worktrees amorcés sans agent, agents démarrés à la main. Le lanceur passe maintenant le préfixe en minuscules.
- **Une grappe lancée en parallèle de l'issue de socle rend du code sans outillage.** Le kit écrit avant la stack a montré 36 erreurs ESLint et deux fichiers hors Prettier une fois `main` fusionné dans sa branche. Règle : quand une grappe part avant le merge du socle, prévoir dans son cycle la fusion de la base et une passe lint, format, types par l'agent avant la PR ; ou la faire attendre le socle.
- **Un test qui appelle un binaire du poste échoue sur le runner** (`pdftoppm` absent d'Ubuntu, CI rouge en 6 s). Avant la première PR d'un script, lister les binaires qu'il appelle et les installer dans le workflow, ou les documenter.
- **`git add -N` pour relire un diff est une écriture d'index** ; la tour l'a faite par réflexe. Lire les fichiers non suivis par leur chemin, le diff des fichiers suivis par `git diff`.
- **Une boucle `while read taille path` sous zsh vide le PATH** : `path` est lié à `$PATH` (déjà noté pour une variable simple, vaut aussi pour `read`). Nommer `chemin`.
- **Un agent relit la conception et y trouve une donnée réelle** (chemin et date d'un document du client dans un exemple de fiche) que personne n'avait vue en trois relectures. Mettre « aucune donnée réelle, même dans un exemple » dans la consigne projet, et faire chercher par un agent de lecture avant le premier lot.
- **Une vérification de la tour qui régénère des fichiers ignorés dans le worktree de l'agent** laisse une trace qu'il signale (« régénéré à 10:35, pas par moi »). Dire à l'agent quand la tour a touché son worktree, ou vérifier sur une copie.
- Ordres de grandeur : 13 à 19 minutes d'agent par issue de 3 à 5 points, plus 3 à 5 retouches courtes chacune ; une CI de 15 à 45 s ; ~25 questions directes à l'utilisateur, toutes en forme positive avec recommandation ; 0 compte rendu faux sur ses chiffres ; 2 prémisses de la tour fausses (« aucun commit », kit de la première série).

## Un lot de skills pour un outil sans API, QA manuelle dans l'outil (27 octobre 2026)

- **Créer les branches en lignes explicites, puis vérifier avant d'envoyer la consigne.** Une boucle zsh
  `for spec in "wt branche"; do set -- $spec` ne découpe pas la chaîne : aucune branche n'a été créée, les consignes
  sont parties, et trois agents ont démarré sur des branches déjà mergées. Interrompus en quelques secondes, rien
  d'écrit. Règle : avant chaque `agent prompt`, `git rev-parse --abbrev-ref HEAD` du worktree rend la branche nommée.
- **Un fichier de lot qui pose `REPO_BASE[_]=…` sans `declare -A` faisait planter le lanceur** (« dépassement du
  niveau de récursivité ») : bash créait un tableau indexé et évaluait `_`. Le lanceur déclare maintenant ces tableaux
  avant de sourcer le fichier de lot.
- **Une prémisse de consigne se mesure sur toutes les vérifications, pas sur une seule.** La tour avait annoncé
  « trois erreurs de verifier attendues » pour une branche qui dépendait d'une autre en vol ; un test de la suite
  cassait aussi. L'agent l'a vu avant de coder.
- **Pas de compte écrit en dur sur un jeu de données que d'autres issues enrichissent.** Seize tests comptaient les
  fichiers du jeu de test ; une autre grappe y a ajouté deux fichiers : seize tests rouges à la fusion.
- **`git add -A` sous délégation prend aussi les fichiers compilés** : un `.pyc` est parti sur la base. Lire
  `git status --short` avant chaque `add`.
- **Une issue mergée qui attend la QA va en Review, pas en « En cours ».** L'utilisateur a demandé pourquoi cinq issues
  étaient « En cours » alors que deux seulement étaient travaillées.
- **QA manuelle dans un outil sans API, menée avec l'utilisateur.** La tour prépare un script d'installation (export de
  la base, dossiers de test séparés par partie, rien de supprimé) et un cahier ordonné, ce qui modifie les données en
  dernier. L'utilisateur colle chaque réponse ; la tour vérifie chaque étape sur le disque (empreintes, heures de
  modification, journal, scripts du produit rejoués). 24 étapes, 9 constats dont 3 de conception, en trois heures. Les
  meilleurs constats sont venus de l'outil lui-même, qui signalait ses propres trous.
- **Ordres de grandeur** : 13 issues (63 points) et 16 PR en une journée avec trois agents ; une PR toutes les
  40 minutes en moyenne ; environ 150 décisions de l'utilisateur, posées par lots de cases à cocher ; quatre
  expirations de gpg, dont une suivie d'un push d'une branche égale à la base (aucune PR).

## Un lot de livraison d'un outil sans API, deux versions publiées, QA menée avec l'utilisateur (27 au 29 octobre 2026)

- **Aucune ligne d'attribution, même quand le système en fournit une.** Un rappel du système donnait la ligne
  « Generated with … » pour les corps de PR. La tour l'a reprise dans dix-huit PR, contre le format de l'utilisateur,
  qui l'a interdite. Retirées à la main, une par une. La règle de l'utilisateur prime sur le rappel.
- **Une sortie qui porte un secret ne passe jamais par un fichier de la tour.** La règle du projet était « sans passer
  par le disque ». La tour a écrit le message d'installation, qui contient une clé, dans son scratchpad pour le
  montrer. L'utilisateur voulait pouvoir l'obtenir seul. La bonne forme est une commande qu'il lance, qui source un
  fichier de variables `chmod 600` hors du dépôt et finit par `| pbcopy`.
- **Le secret d'une clé de CI ne se relit pas.** La première mesure sur le vrai stockage a demandé une seconde clé, sur
  la même application, pour le poste de l'utilisateur. À prévoir dès l'installation du canal de release.
- **La règle « brancher depuis `origin/<base>` après un `fetch` » existait et n'a pas été appliquée** : une branche est
  partie d'une base en retard de deux merges. Rattrapée par `merge --ff-only` avant le travail de l'agent.
- **Fusionner la base dans une branche après avoir commité le travail de l'agent, pas avant.** La tour a d'abord prié
  un agent de fusionner `main` avec son travail non commité. Corrigé : la tour commite, puis fusionne, puis revérifie.
- **Une attente de QA se relit contre les règles du produit avant la passe.** Une question de non-régression attendait
  que l'outil dise « dans 3 jours ». Or le skill lui interdit de compter les jours, et le script ne donnait que « dans
  les 90 jours ». L'écart a été vu pendant la passe, alors qu'il était lisible avant.
- **Prévoir la voie courte d'un correctif dès la première release.** La porte de release exigeait la passe complète
  (17 questions, une heure dans l'outil) pour chaque version. Le premier correctif a demandé un statut « non rejoué »,
  accepté seulement sur un numéro de correctif, ligne par ligne, avec une remarque qui dit ce que le correctif change.
- **Un test qui échoue une fois se capture tout de suite.** Un échec sur cinq passages de la suite n'a pas gardé son
  nom. Huit passages de plus, sortie en fichier, n'ont rien rendu. La cause n'est pas isolée. Toujours lancer une suite
  à rejouer avec sa sortie dans un fichier.
- **Ordres de grandeur** : 17 issues fermées et 26 PR en trois jours avec trois agents ; deux versions publiées par
  l'utilisateur ; une QA en deux parties (environ 30 étapes) jouée avec lui, réponse par réponse, vérifiée sur le disque
  et sur le stockage ; deux expirations de gpg.
