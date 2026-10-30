---
name: tc-lot
description: "Constituer un lot depuis la colonne « À faire » du board (issues assignées à l'utilisateur), le grouper en grappes de worktrees herdr, le dépiler avec une session Claude par grappe, puis le clore : QA de fin de lot, journal, leçons. Suppose le mode tour chargé (/tower-control). Invoqué par l'utilisateur uniquement."
disable-model-invocation: true
---

# Lot

Ce skill suppose le mode tour chargé dans la session (`/tower-control /tc-lot`) : il
n'en répète pas les règles (board, assignation, écriture sur GitHub, questions, git).
S'il ne l'est pas, demander à l'utilisateur de taper `/tower-control` avant d'aller
plus loin.

Les chemins `assets/…` et `references/…` sans autre précision sont ceux de
`~/.claude/skills/tower-control/` ; ceux de ce skill s'écrivent `tc-lot/references/…`.

Lire `references/retours-entrants.md` et le `tour.md` du projet avant de préparer : les
leçons qu'aucun skill ne porte encore, et celles propres au projet.
`references/retours-archive.md` ne se lit pas.

## Les étapes

1. **Préparer** : `tc-lot/references/preparer.md`. Sélection du lot, relecture contre
   le code, grappes, décisions.
2. **Lancer** : `references/lancer.md` de tower-control, en nommant les grappes du lot
   (`lancer.sh <chemin du dépôt des issues> <grappe…>`) : sans nom, le lanceur
   relancerait aussi une grappe hors lot encore ouverte.
3. **Dépiler** : `references/cycle.md` de tower-control, pour chaque issue, avec les
   règles de lot ci-dessous.
4. **Clore** : `tc-lot/references/clore.md`. Ordre de merge, QA de fin de lot,
   rangement, journal, leçons.

Relire le fichier de l'étape en cours après un résumé automatique du contexte.

## Règles de lot pendant le cycle

**Le board se tient au fil de l'eau** : « En cours » quand l'agent reçoit sa consigne, « Review » quand
la PR s'ouvre. Une tour l'a oublié toute une matinée, l'utilisateur l'a vu avant elle.

**Une chaîne sérielle sur les mêmes fichiers coûte une fusion par issue** dès qu'une autre branche touche
ces fichiers en parallèle (sept fusions sur quatre motifs plus une branche voisine, deux heures de chemin
critique). Soit tout va dans une seule chaîne, soit les fusions se confient à l'agent qui connaît un des
deux côtés, dans un worktree jetable amorcé (`git worktree add` plus l'amorçage du projet), la tour
commitant, avec la fiche « ## Fusion » de la fusion précédente comme modèle. Deux agents qui créent une
migration de semence le même jour copient le même identifiant d'un fichier voisin : la consigne dit « un
identifiant se tire de la base », et la fusion le vérifie par `up`, `down`, `up` avec le compte des lignes.

**Une grappe enchaîne ses issues dans le même worktree.** Après le commit de l'une, la
tour crée la branche de la suivante et lui envoie sa consigne (« Branches et retard »
de `cycle.md`). Un hors-périmètre dont le fichier est dans la grappe va en bloc
« reliquats » dans la consigne suivante.

**Les e2e en local sont à la tour**, pas aux agents : avant chaque push, la tour joue les specs de la
zone touchée dans le worktree de la branche (le dépôt dit comment, un script ou une recette), et la CI de
la PR joue la suite complète. Un agent ne lance jamais la suite, sauf quand l'issue porte sur elle. Deux
agents sur une pile aux ports fixes ont testé les serveurs l'un de l'autre, et l'un a tué le run de l'autre.

**Entre deux issues d'une grappe, relever le contexte de l'agent et compacter s'il le faut** : « Enchaîner une
tâche » de `cycle.md`.

**Chaque issue fermée par un merge du lot porte le label `lot: <n>`**, `<n>` étant le numéro du
dossier `lot-<n>/`. On retrouve ainsi ce qu'un lot a livré (`gh issue list --repo "$ISSUES_REPO"
--state closed --label "lot: <n>"`). La tour le pose au moment où elle constate le merge, que
l'issue ait été fermée par `Closes` ou à la main :
`gh issue edit <N> --repo "$ISSUES_REPO" --add-label "lot: <n>"`. Au premier merge du lot, créer
le label s'il manque (`gh label create "lot: <n>" --repo "$ISSUES_REPO" --color 5319e7`). Le label
reste dans le dépôt des issues : il n'existe ni sur la PR ni dans le dépôt du code. Une issue
jetée, découpée ou fermée sans merge ne le reçoit pas. À la clôture, comparer la liste du label
avec le tableau des merges du journal.
