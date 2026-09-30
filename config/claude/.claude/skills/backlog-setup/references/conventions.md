# Conventions du backlog

Les mêmes sur tous les projets, pour que les vues, les filtres et `tower-control`
marchent partout à l'identique.

## Labels

| Label | Sens |
|---|---|
| `bug` | Défaut constaté, ou défaillance silencieuse (sortie valide mais fausse) |
| `produit` | Fonctionnalité ou contrôle manquant côté livrable |
| `qualité` | Robustesse, lisibilité, dette technique |
| `tests` | Couverture de test et CI |
| `documentation` | Documentation à corriger ou compléter |
| `vérifié` | Le constat a été mesuré sur les données réelles ou les journaux, pas seulement lu dans le code |
| `complexité: 1/2/3/5/8/13` | Planning poker, Fibonacci |
| `dépôt: <nom>` | Méta-dépôt seulement : le sous-dépôt concerné |

Les labels GitHub par défaut inutilisés sont supprimés (`enhancement`, `question`,
`wontfix`…), sauf ceux que Dependabot recrée (`dependencies`, `javascript`).

## Priorités (champ Priorité du board)

| | Nom court | Sens générique |
|---|---|---|
| **P0** | Critique | Le livrable est faux ou inutilisable |
| **P1** | Haute | À faire avant la prochaine livraison ; typiquement une panne silencieuse à venir |
| **P2** | Normale | Quand l'occasion se présente |
| **P3** | Basse | Plus tard, ou en attente d'un prérequis (données, décision) |

Le nom de l'option est le code seul (`P0`), le sens va dans la description de
l'option : une colonne de board ne doit pas être verbeuse.

## Points

Fibonacci, en planning poker : 1 trivial · 2 simple · 3 quelques heures · 5 une
journée, plusieurs fichiers · 8 conception nécessaire · 13 chantier, à découper.
Écrits deux fois : en label (`complexité: N`, lisible sur l'issue) et dans le champ
Points du board (sommable par colonne). Rappelés en pied de corps d'issue.

## Statuts du board

Backlog → À faire → En cours → Bloqué → Review → Fait.

- **Bloqué** : en attente d'une information, d'une donnée ou d'une décision d'un
  tiers. Placé après « En cours » dans le flux.
- **Review** : implémenté, en attente de relecture et de test par l'utilisateur.
  La tour y met l'issue ; **elle n'en sort que par le merge** de la PR qui la ferme,
  via le workflow intégré « item closed → Fait ». La tour ne passe jamais une issue
  en Fait elle-même.

## Forme d'une issue

Voir `assets/issue.md`. Le titre nomme le défaut, pas la solution (« PROTECTION
vide imprime NON », pas « Gérer PROTECTION vide »). Le corps a quatre parties :
constat, pourquoi c'est grave, piste, complexité. Le constat dit s'il est vérifié et
comment. Le pointeur `fichier:ligne` est cliquable, mais périme vite : le constat
doit tenir sans lui.

Une remarque mineure qui se rattache à une issue existante devient un commentaire
sur cette issue, pas une issue de plus. Un backlog de trente-cinq issues se lit ;
un de soixante-dix se subit.
