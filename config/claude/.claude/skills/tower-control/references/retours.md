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

## Ce qui reste à vérifier au prochain lot

- Un agent peut rendre son compte rendu alors qu'un reviewer en tâche de fond tourne
  encore ; rien de perdu cette fois, mais lire l'écran une seconde fois à l'arrêt.
- Un agent peut oublier une vérification après une retouche demandée : la tour
  relance toujours les siennes, quoi que dise le compte rendu.
