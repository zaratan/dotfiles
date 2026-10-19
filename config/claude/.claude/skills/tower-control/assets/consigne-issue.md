# Gabarit de consigne par issue

Une consigne par issue, envoyée avec la consigne commune. Courte : l'issue GitHub
porte déjà le Why, le What et la Must-Have. La consigne ajoute ce que l'issue ne dit
pas — la décision prise en amont, ce qu'il ne faut surtout pas faire, et les chiffres
de départ, que la tour vérifiera.

```
## #<N> — <titre court>

Issue : `gh issue view <N> --repo <owner/dépôt des issues>`.
Worktree : `wt/<grappe>` (dépôt `<sous-dépôt>`), branche `<branche>` depuis `<branche de base>`.

<Ce qu'il faut faire, en deux à quatre phrases, avec les fichiers visés.>

<Décision prise en amont, si l'issue en laissait une ouverte : « Décision prise : … ».>

<Ce qui est hors périmètre alors qu'on pourrait croire le contraire :
 « **Ne touche pas à …** : c'est une décision produit en attente. »>

Attendu : la Must-Have de l'issue, case par case, avec pour chacune la commande qui
la prouve et les chiffres avant/après ou les cas nominatifs attendus. Une issue sans
Must-Have : <résultat vérifiable, chiffré>.
Mesuré le <date> par <commande>, sur <commit> : <les chiffres de départ, remesurés
par la tour, jamais recopiés d'une doc ou du lot précédent>.
```

Ce qui rend une consigne bonne : l'« Attendu » est ce que la tour relancera
elle-même avant de cocher la Must-Have. S'il n'est pas chiffré, la vérification
indépendante n'est pas possible.
