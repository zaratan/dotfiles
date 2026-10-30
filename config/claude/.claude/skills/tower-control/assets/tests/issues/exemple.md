---
titre: Le compteur d'étapes descend quand on revient en arrière
labels: bug, produit
priorite: P2
points: 3
depot: app
jalon: Recette
---
## Why ?

Mesuré le 30/10 sur `develop` : le compteur passe de 4 à 3 quand on revient à l'étape précédente.

## What ?

Le compteur ne descend jamais ; il compte les étapes atteintes.

## Must-Have

- [ ] Le compteur reste à 4 après un retour à l'étape 3.
- [ ] Un test e2e couvre le retour.

## How ?

À trancher à la PR.
