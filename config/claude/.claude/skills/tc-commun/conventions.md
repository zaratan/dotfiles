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
| `dépôt: <nom>` | Méta-dépôt seulement : le sous-dépôt concerné |

Les labels GitHub par défaut inutilisés sont supprimés (`enhancement`, `question`,
`wontfix`…), sauf ceux que Dependabot recrée (`dependencies`, `javascript`).
Les labels `complexité: N` des anciens dépôts ne se posent plus : les points vivent
sur le board.

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
journée, plusieurs fichiers · 8 conception nécessaire · 13 chantier à découper, ou
impossible à chiffrer en l'état. Écrits une seule fois, dans le champ Points du board
(sommable par colonne, affiché sur l'issue).

**Toute issue a une priorité et des points dès sa création.** Quand on ne sait pas
chiffrer, c'est `13`. Seule exception : une issue parente a une priorité mais pas de
points, ses sous-issues les portent et le board ne compte pas deux fois.

## Statuts du board

Backlog → À faire → En cours → Bloqué → Review → Fait.

- **Bloqué** : en attente d'une information, d'une donnée ou d'une décision d'un
  tiers. Placé après « En cours » dans le flux.
- **Review** : implémenté, Must-Have entièrement cochée, en attente de relecture et
  de test par l'utilisateur.
  La tour y met l'issue ; **elle n'en sort que par le merge** de la PR qui la ferme,
  via le workflow intégré « item closed → Fait ». La tour ne passe jamais une issue
  en Fait elle-même.

## Forme d'une issue

Voir `issue.md`, à côté. Le titre nomme le défaut, pas la solution (« PROTECTION
vide imprime NON », pas « Gérer PROTECTION vide »). Le corps a quatre sections :
Why ?, What ?, Must-Have, How ?. Le Why dit si le constat est vérifié et comment. Le
pointeur `fichier:ligne` est cliquable, mais périme vite : le Why doit tenir sans lui.
La Must-Have ne liste que ce que la PR livre ; ce qui se vérifie après le merge va
dans le How.

Une remarque mineure qui se rattache à une issue existante devient un commentaire
sur cette issue, pas une issue de plus. Un backlog de trente-cinq issues se lit ;
un de soixante-dix se subit.

## Écrire sur GitHub

Tout texte qui part sur GitHub passe d'abord par le skill `humanize` : corps d'issue,
retouche d'un corps (une décision ajoutée au How), commentaire. C'est une passe
appliquée, sans liste de trouvailles à valider une par une :

- charger le skill, et le recharger s'il n'est plus dans le contexte après un résumé
  automatique ;
- charger le style de l'utilisateur, registre docs, en français : précis et concis ;
- chercher dans l'ordre du skill (gestes, structure et rythme, mise en forme,
  ponctuation, lexique, puis « PR et issues ») et corriger directement ;
- ne toucher qu'à la prose. Le squelette reste tel quel, même quand le skill le
  signalerait : titres `## Why ?` et suivants, `**Dépôt.**`, cases `- [ ]` ;
- un détail qui manque (chiffre, nom, pourquoi) se demande, il ne s'invente pas ;
- relire le résultat contre les « Interdits du réécrivain » du skill ;
- montrer le texte final à l'utilisateur, avec les coupes faites en une ligne
  dessous : son accord sur le texte vaut pour elles. Puis envoyer.

Cocher une case de la Must-Have n'est pas une écriture de texte : pas de passe, pas
d'accord. Les textes à format fixe non plus : le commentaire de fermeture d'une issue
(PR et commit de merge), le titre et le corps d'une PR sous `/tc-delegate`, qui suivent
le format des PR de l'utilisateur. Relire le corps juste avant (`gh issue view <N> --repo <dépôt> --json
body`), ne changer que la ligne `- [ ]` visée en `- [x]`, vérifier que le diff ne
porte que sur elle (les corps édités dans l'interface ont des `\r\n`), écrire avec
`gh issue edit <N> --repo <dépôt> --body-file <fichier>`. La même recette (relire,
modifier, réécrire) vaut pour une décision ajoutée au How.
