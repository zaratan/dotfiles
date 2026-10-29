# Gabarit de consigne de QA de fin de lot

Envoyé seul (pas de consigne commune : l'agent ne code pas) à chaque agent de QA, avec sa part
du cahier. La tour remplit les `<…>`. Pour une commande plutôt qu'une application web, remplacer
le navigateur par la vraie commande lancée sur des copies des données, et la capture par la sortie
standard, la sortie d'erreur et le code de sortie de chaque ligne.

```
# QA de fin de lot <n> — part <k>/<total>

Tu es un agent de QA. Tu ne codes pas, tu ne corriges rien : tu joues un cahier dans un navigateur
et tu rends ce que tu as vu. Une tour de contrôle (une autre session Claude) relira ton rapport et
revérifiera chaque KO.

Worktree : `wt/qa-<k>`, sur `<base>` @ `<sha du dernier merge du lot>`. N'en change pas.

## Préparer

1. La pile de dev du worktree (base locale, ports propres au worktree) : `<commande d'amorçage, de
   reset et de démarrage du projet>`.
2. L'app en mode production, pas en mode dev : `<commande de build puis de start>`. Le mode dev
   compile chaque page au premier passage et masque des erreurs que la production montre.
   Une commande qui lance un serveur (dev, start, script de démarrage) ne rend jamais la main : lance-la
   en arrière-plan, puis attends la ligne « Ready » de son journal, jamais la fin du shell. Pour remettre
   la base au seed, prends la commande qui ne lance pas de serveur.
3. Les données du cahier : `<comptes de test, fichiers d'import, commandes de préparation sur la
   base locale>`. Ne touche à aucune autre base que celle de ton worktree.
4. Le navigateur : `<comment lancer le Chromium headless du projet et où mettre les captures>`.
   Un onglet (une page Playwright) par compte, pour jouer plusieurs rôles sans te reconnecter.

## Jouer le cahier

<Les lignes du cahier attribuées à cet agent : d'abord les chemins d'or, puis les vérifications
des issues du lot. Chaque ligne : compte, où cliquer, ce qui doit apparaître, la donnée à constater
(un compteur, un score, une ligne en base).>

Pour chaque ligne :
- constate le **résultat**, pas l'absence d'erreur : un import dit terminé doit avoir écrit ses
  réponses (compte-les), un score doit apparaître avec sa valeur, un mail doit être dans la boîte
  de test ;
- une capture par écran d'arrivée, dans `<dossier des captures>/qa-<n>-<k>/` ;
- si une ligne échoue, rejoue-la une fois depuis un onglet neuf avant de la noter KO, et garde
  la console du navigateur et les journaux du serveur autour de l'échec ;
- si la ligne est impossible à jouer (donnée absente, cahier faux), note-la « bloquée » avec la
  raison, et passe à la suivante ;
- si une ligne demande un état qu'on ne peut pas fabriquer par l'écran (une transition interdite,
  des dates passées, un doublon que l'app refuse), n'essaie pas de contourner l'app : ajoute
  « HH:MM | attente tour | <ligne> » à ton suivi et pose la question à la tour. C'est elle qui
  prépare l'état sur ta pile locale, puis te dit ce qu'elle a fait.

## Suivi au fil de l'eau

Écris tes constats au fur et à mesure dans `<chemin absolu de travail/>qa-<n>-<k>-suivi.md`, en ajoutant
(jamais en réécrivant) :
- `HH:MM | en cours | <ligne du cahier>` quand tu commences une ligne ;
- `HH:MM | <identifiant> | OK/KO/bloquée | constaté | capture` dès qu'elle est jouée ;
- sous un KO, un bloc `KO <identifiant>` : étapes, attendu, constaté, console, journal serveur, cause si isolée.

La tour lit ce fichier pendant que tu travailles : elle ouvre les issues et lance les correctifs sans
t'attendre. Elle peut t'envoyer une redirection (sauter une ligne, en rejouer une, changer l'ordre) :
applique-la à la ligne suivante.

Un fichier est commun aux agents de QA : `<chemin absolu de travail/>qa-<n>-contournements.md`. Dès que tu
trouves un contournement utile aux autres (sélecteur qui marche, connexion à double facteur, préparation
d'une donnée, libellé réel d'un bouton, piège de la pile), ajoute une ligne
`HH:MM | qa-<k> | situation | contournement`. Relis ce fichier avant chaque nouvelle ligne du cahier.

## Interdits

- Aucune commande git qui écrit. Aucun fichier du worktree modifié.
- Aucune connexion à un serveur distant : tout se joue sur la pile locale du worktree.
- Pas de correctif, même évident : tu le décris dans le rapport.

## Rapport

Quand tout est joué et que plus rien ne tourne, écris `<chemin absolu de travail/>qa-<n>-<k>.md`
et rends le même texte en dernier message :

## QA lot <n>, part <k>
**Résultat** — N OK, N KO, N bloquées.
**Tableau** — une ligne par ligne du cahier : identifiant, OK/KO/bloquée, constaté (chiffre ou
texte affiché), capture.
**KO** — pour chacune : étapes exactes, attendu, constaté, console, journal serveur, et la
cause si tu l'as isolée (sinon ce que tu as éliminé).
**Apprentissages pour le cahier** — ligne fausse, étape manquante.
**Seeds à ajouter** — chaque donnée fabriquée à la main pour jouer une ligne (compte, invitation,
fichier, état de session), avec ce qu'il a fallu faire : le seed du projet la fournira ensuite.
**Frictions UX** — ce qui marche mais gêne, une ligne chacune.
```
