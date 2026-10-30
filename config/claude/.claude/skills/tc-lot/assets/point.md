# Le point d'avancement

Chaque message de la tour pendant un lot, quel que soit son sujet, commence par l'heure et finit par « À toi ».
Dès qu'un agent est en vol, le tableau des agents est entre les deux. Le tableau des étapes ne sort que sur
« ETA ? ». Avec trois agents en vol, l'utilisateur a dû demander deux fois où en était une branche qu'un
message sur une autre laissait invisible ; des ETA en UTC ont été lues fausses pendant qu'il voyageait.

```
Il est <heure locale de l'utilisateur, fuseau connu ou demandé>.

<le sujet du message, court : ce qui est fait, les chiffres vérifiés, ce qui reste ouvert>

| Grappe | Issue | État | Depuis | Contexte | Fait | ETA | Ce qu'il fait |
|---|---|---|---|---|---|---|---|
| front | #234 | travaille | 48 min | 64 % | 3/5 sous-phases | 16 h 45 | revue lead-engineer de 69 fichiers |
| ops | #240 | question | 3 min | 31 % | code fait | attend ta réponse | sévérité du refus |
| tests | #87 | compte rendu | 12 min | 22 % | vérifié par la tour | PR dès ton commit | — |

À toi : <commit, PR, merge, verdict, réponse… ou « rien »>.
```

- **État** : consigne envoyée, travaille, question, compte rendu, vérifié, PR, mergé. `assets/avancement.sh <dépôt>`
  rend grappe, état herdr, depuis, contexte et le titre de l'agent ; la tour affine l'état et remplit Fait et ETA.
- **Fait** : ce qui est prouvé, pas un pourcentage de Must-Have (la tour ne coche qu'après vérification) :
  sous-phases du plan faites, « code fait », « vérifié par la tour ».
- **Contexte** : le pourcentage de la ligne d'état de l'agent (`~/.claude/tower-control/ctx/<session>`). Au-delà
  de 50 % avant une nouvelle tâche, compacter (« Enchaîner une tâche » de `cycle.md`).
- **ETA** : une heure absolue dans le fuseau de l'utilisateur, jamais une durée. Nourrie par
  `references/ordres-de-grandeur.md` (même forme de projet) et par ce que l'agent a déjà pris. Quand une ETA glisse,
  le dire avec l'écart (« 16 h 45, était 16 h 20 »).

Sur « ETA ? », ajouter le tableau des étapes jusqu'à la fin du lot, dans l'ordre, avec les attentes qui dépendent
de l'utilisateur marquées comme telles :

```
| Étape | Vers |
|---|---|
| Compte rendu de #234 | 16 h 45 |
| Ma vérification (diff, relecteur neuf, gates, e2e) | 17 h 30 |
| CI et merge (ton merge) | 17 h 50 |
| QA de fin de lot et passe SOLID/DRY/KISS, en parallèle | 18 h 50 |
| Textes des issues de l'audit, à ta validation | 19 h 30 |
```
