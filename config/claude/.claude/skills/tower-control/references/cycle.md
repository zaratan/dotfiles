# Le cycle d'une issue

À lire une fois l'agent lancé (`references/lancer.md`). Les chemins `assets/…` sont
ceux du skill `tower-control`. Relire ce fichier après un résumé automatique du
contexte.

```
tour  : consigne commune + consigne issue → agent        board : (Backlog ou) À faire → En cours
agent : lit l'issue, code, teste, revue lead-engineer, compte rendu, s'arrête
tour  : attend en arrière-plan, lit le compte rendu, VÉRIFIE ELLE-MÊME,
        coche la Must-Have, résume à l'utilisateur        board : En cours → Review
user  : ouvre le sous-espace herdr, relit le diff, commite, ouvre la PR (Closes #N)
tour  : vérifie le lien PR → issue par `gh pr view <PR> --json closingIssuesReferences`,
        jamais par une regex sur le corps (GitHub accepte « Closes: #N », « fixes #N »…) ;
        si le lien manque au merge, c'est la tour qui ferme l'issue, avec un commentaire
tour  : s'il reste une issue dans la grappe, crée sa branche
        (`git switch -c <b> --no-track origin/<base>`) et envoie sa consigne
merge : ferme l'issue, le workflow du board la passe en Fait — la tour n'y touche pas
tour  : en lot, pose le label du lot sur l'issue fermée (voir /tc-lot)
```

## La Must-Have

La Must-Have de l'issue est le contrat entre la tour, l'agent et l'utilisateur. La
consigne la reprend comme Attendu ; le compte rendu de l'agent la reprend case par
case, avec la preuve. Après sa vérification indépendante, la tour coche sur l'issue ce
qu'elle a constaté elle-même, selon la recette de « Écrire sur GitHub » dans
`~/.claude/skills/tc-commun/conventions.md` : un geste mécanique, sans
passe humanize ni accord, qu'elle dit dans son point à l'utilisateur. Ce que l'agent
affirme et que la tour n'a pas revu reste décoché.

L'issue passe en Review quand toutes les cases sont cochées et que sa PR existe, ou quand sa PR est
mergée et que ses cases ouvertes n'attendent plus que la QA ou une autre issue. Sans PR, pas de Review,
même dans un train (`references/trains.md`) : l'utilisateur a vu sept issues en Review et aucune PR. « En cours » ne garde que ce
qu'un agent a entre les mains : cinq issues « En cours » dont deux seulement travaillées ont
fait demander à l'utilisateur ce qui se passait. Une case qui attend un tiers passe l'issue en
Bloqué. Abandonner une case est une
décision de l'utilisateur : la retirer de la Must-Have et l'écrire dans le How. Sur une
issue d'avant ce gabarit, sans Must-Have, la tour rédige l'Attendu de la consigne comme
avant, chiffré, et ne coche rien.

## Commit, PR, CI, branches, rangement

`references/merge.md` : lire la CI, attendre la base, créer la branche suivante, mesurer le retard avant la
Review, prédire la fusion, ranger un worktree. À lire avant le premier commit d'une issue.

## Attendre
**Un guetteur par consigne envoyée, recadrage compris** : après un `esc` + `prompt` qui change le périmètre
d'une issue, le guetteur précédent a déjà rendu la main, et un compte rendu a attendu une heure.

**Envoyer par `assets/envoyer.sh <agent> <fichier>`**, jamais par un `agent prompt` nu : il refuse un agent
bloqué, vérifie le passage à `working`, ferme par `esc` la boîte ou le panneau qui avale un texte et renvoie une
fois. Douze consignes se sont perdues ainsi, herdr répondant `agent_prompted`. **Avant de lancer un guetteur sur
une section, la compter dans le fichier** (`grep -c '^## <section>'`) : une section déjà présente a fait
attendre un guetteur sans fin.

**Attendre sans surveiller, un guetteur par agent** : `assets/guetter.sh <agent> <compte rendu attendu>
[section]`, lancé par `run_in_background`, sans `timeout`, sans `&`, seul dans sa commande : un guet lancé avec
un délai aurait été tué au bout de dix minutes d'une passe de trois heures, et un guet lancé avec `&` ne notifie
jamais. Il rend la main sur une question ou une demande de permission, sur un compte rendu **modifié après le
lancement du guet** suivi d'un arrêt, ou sur un long arrêt sans compte rendu ; les délais tiennent compte des
shells de fond (un `next start` laissé ouvert), ils sont dans `references/herdr.md`. Le verdict « ARRÊTÉ » porte
la dernière ligne visible de l'agent : la lire avant de conclure. Pour une retouche, passer la section attendue
(`"## Retouche"`) plutôt qu'une boucle `until grep` maison. Demander dans chaque consigne de fermer ses shells
de fond avant d'écrire le compte rendu. Le relancer après chaque réponse. Ne pas guetter seulement le fichier :
trois agents sont restés bloqués sur une question pendant que la tour attendait leur compte rendu. Ne pas se
fier à `herdr agent wait` seul : il rend « done » pendant que l'agent a des mesures en arrière-plan. Ne pas
partager une attente entre agents, ni enchaîner leurs guets dans une seule commande : la fin de l'un est passée
inaperçue, et un guet séquentiel de trois agents n'a prévenu qu'avec le dernier.

## Vérifier
**Vérifier indépendamment, mais jamais en même temps que l'agent.** Attendre `done` et un écran arrêté : deux
générations dans le même `travail/` se marchent dessus et fabriquent des écarts fantômes. Ni deux vérifications
complètes en même temps : des tests à délai fixe tombent sous charge et jamais seuls ; un échec vu sous charge
se rejoue seul avant d'être jugé.

**Mesurer la sortie de succès de chaque commande de vérification avant de l'écrire dans une consigne** (« doit
être muet » était faux pour un script qui imprime une ligne de succès : trois agents sur trois l'ont signalé).
Dans un worktree à ports dérivés, les tests de base passent par le wrapper du projet, pas par le CLI brut.

**Relire le diff pour ce que le poste local ne voit pas** : un import ou une aide qui ne sert qu'à un test
réservé à un système (`#[cfg(unix)]`), inutilisé ailleurs et refusé par `-D warnings` ; une égalité exacte sur
la sortie d'erreur, qu'un runner virtualisé salit de ses propres messages ; un binaire du poste absent du
runner, à installer dans le workflow ou à documenter avant la première PR. Deux PR ont cassé en CI ainsi, vertes
sur le Mac. Et les fichiers générés (migrations, types) : un horodatage rond trahit un nommage à la main là où
le dépôt impose son outil.

**Vérifier indépendamment.** Le compte rendu de l'agent est une affirmation. Avant de résumer à l'utilisateur,
relancer soi-même dans le worktree les vérifications que le projet définit (`pnpm run check`, référence de
non-régression, contrôle des données) et comparer aux chiffres annoncés. Un écart entre les deux est la première
chose à dire. Quand elles sont longues et que la CI les relance : « Vérifications longues relancées par la CI »
de `references/cas.md`.

Pour revoir un écran, démarrer l'app du worktree comme en production avec `assets/demarrer-prod.sh <dépôt des
issues> <grappe>`, en arrière-plan. Le script lit la recette du projet dans `config.sh`
(`REPO_PROD_START[<dépôt>]`, ou `PROD_START` en dépôt unique) ; si elle manque, l'écrire une fois avec
l'utilisateur plutôt que la refaire à la main à chaque vérification. Arrêter ensuite l'app par son port.

**Résumer court** : ce qui est fait, les chiffres vérifiés, les cases cochées, ce qui reste ouvert. Le compte
rendu complet est dans `travail/rapport-<N>.md` ou lisible par `herdr agent read`. **Les décisions que l'agent a
prises seul ne vont pas dans le résumé : elles se posent en questions directes** (AskUserQuestion, une à la
fois, avec le texte avant et après), avant de dire « prêt à commiter ». Ses « Questions ouvertes » se lisent
avant tout commit, même quand le vérificateur dit « prêt » : un correctif a été commité alors que l'agent
signalait deux endroits laissés en l'état. Un utilisateur qui traite plusieurs sujets fusionne sans relire ce
qu'un résumé lui signale en prose. Ces décisions se relisent aussi contre les issues ouvertes qui touchent les
mêmes fichiers : une branche réalise parfois une issue voisine sans le savoir, et c'est un `Closes` de plus sur
la PR.

**Une retouche que la tour tire d'un compte rendu ou d'une revue se vérifie dans le code avant l'envoi** : lire
le passage cité, puis l'écrire sur `assets/consigne-retouche.md` et l'assembler par `consigne.sh … --retouche`.
Même chose pour une affirmation d'agent avant qu'elle devienne une question à l'utilisateur : « le simulateur
borne à 12 h par jour » est passé d'un compte rendu à une décision alors qu'aucune borne n'existait. Sur une
grosse issue (plusieurs dizaines de fichiers), un relecteur neuf lit le diff, pas la conclusion de l'auteur :
sur 70 fichiers il a trouvé un bloquant contraire au besoin, une donnée sensible en clair et un GET qui
écrivait. Trois retouches fausses sont parties ainsi en un lot (des valeurs « déjà rendues » qui ne l'étaient
pas, un attribut dit inutile qui servait à un lint, un chemin de cache dont la forme changeait la version de
l'entrée) ; les agents les ont arrêtées. Au merge d'une issue, proposer de retirer sa planche lourde (vidéos,
images).

**Chaque « hors périmètre repéré » finit quelque part, avant le résumé** : écrire la table point → destination,
avec trois destinations possibles : traité (retouche par le même agent si le fichier est dans sa branche, ou
bloc « reliquats » dans la consigne suivante de la même grappe), attaché à une issue existante (commentaire avec
fichier:ligne), ou nouvelle issue. Jamais seulement listé. Une issue créée en chemin et un commentaire suivent
« Écrire sur GitHub » de `references/github.md`. Avant d'attacher un point à une issue existante, relire ce
qu'elle produit : la tour a annoncé des extraits vidéo d'une issue qui ne sort que des tableaux.

## Enchaîner une tâche

À chaque pause naturelle d'un agent (compte rendu, retouche, fusion, issue suivante de la grappe),
relever son contexte sur sa ligne d'état ; avant l'issue suivante, lire `~/.claude/tower-control/ctx/<session>`
dans la même commande que `branche-suivante.sh`, avant `envoyer.sh` : relevé après l'envoi, un agent à 49 % est
reparti sans compactage. **Au-delà de 40 %, compacter avant la tâche suivante** :
`herdr agent prompt <agent> "/compact"`, attendre `idle` ou `done` (après un `/compact`, herdr rend `done` :
une boucle sur `idle` n'a jamais rendu la main), relire le remplissage. Un agent à 79 % sur
sa seconde issue a vu le résumé automatique tomber au milieu du travail ; un agent compacté entre deux
issues (79 % → 0 %) n'a rien perdu, la consigne suivante se suffit. Après le `/compact`, lire l'écran
avant d'envoyer : la commande reste parfois dans la zone de saisie et partirait avec le message suivant,
et la boîte « Teach auto mode about your environment? » y apparaît et avale le prompt (deux consignes
perdues ainsi) ; la fermer par `esc`, sans rien accepter.

## Les questions des agents

Les agents posent leurs questions par AskUserQuestion ; herdr les montre `blocked`.
**Tout passe par la tour**, pour trois raisons : la même question revient dans
plusieurs agents et doit recevoir la même réponse ; une bonne part a déjà sa réponse
dans les docs du dépôt ; chaque réponse de l'utilisateur doit être rangée là où
elle survivra. Une règle ou une décision de l'utilisateur donnée en cours de route part
aussitôt à tous les agents en vol, par `envoyer.sh` pendant qu'ils travaillent : le texte
est lu au tour suivant, sans les interrompre.

Les règles de décision (ce que la tour tranche seule, ce qui remonte à l'utilisateur,
où ranger la réponse) sont dans « Les questions » du skill. En plus, pour les agents :

- Lire le contexte (`herdr agent read`) avant de répondre.
- **Un agent `blocked` sur une question refuse `agent prompt`** (`agent_blocked`) : fermer la question par
  `agent send-keys <nom> esc`, vérifier qu'il est `done`, puis envoyer la réponse par `envoyer.sh`, avec le texte
  de l'option choisie. Jamais `send-keys enter` sur une option : le classificateur le refuse (deux projets).
- **Une demande de permission bloque l'agent comme une question.** La lire avant de
  répondre ; refuser un `rm` dont le chemin dépend d'une variable qui peut être vide, et
  demander `"${VAR:?}"/…` à la place.
- La tour qui répond seule cite la source à l'agent et liste la réponse dans le
  résumé. Une décision qui remonte à l'utilisateur laisse l'agent attendre : un agent
  qui attend dix minutes coûte moins qu'une décision prise à la place de l'utilisateur.
- Avant de recommander un garde, une colonne ou une contrainte en réponse à un agent,
  se demander si on en a besoin avant l'échéance ; la réponse par défaut est non, et on
  relit la somme de ce qu'on a ajouté sur l'issue, pas la dernière question seule : une
  issue de 3 points a pris trois formes avant que l'utilisateur demande la plus simple.
- L'utilisateur ne répond pas dans les panes (quand il dit l'avoir fait, relire `agent_status` : une
  réponse tapée là n'a jamais été soumise, la renvoyer par `envoyer.sh`), et **un texte non envoyé
  dans la zone de saisie d'un agent n'est jamais de lui** : c'est une suggestion automatique de Claude
  Code (« Compte rendu lu, je commite. », « aligne aussi … »). Ne pas l'interpréter, ne pas
  le consigner, ne pas poser de question dessus ; `agent prompt` le remplace.
- Un agent qui pilote le navigateur a besoin que le site de sa pile (`localhost:<port
  dérivé>`) soit autorisé dans l'extension : le prévoir dans la consigne.

Un agent qui tourne en rond se voit au `agent read` : l'interrompre
(`agent send-keys <nom> esc`), reformuler, et ne pas dépasser deux relances sans en
parler à l'utilisateur.
