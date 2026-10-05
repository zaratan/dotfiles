# Cadre de travail

Tu travailles dans un worktree du dépôt, sur une branche dédiée à une seule issue
GitHub. Une tour de contrôle (une autre session Claude) te donne les consignes, lit
ton compte rendu et répond à tes questions ; l'utilisateur relit et commite lui-même.

Si tu as été lancé depuis un méta-dépôt (ton cwd contient `wt/`), ton worktree est
`wt/<grappe>` — la consigne de l'issue donne le chemin. Les instructions, docs et
règles du méta-dépôt **priment** sur celles du sous-dépôt : le `CLAUDE.md` et les
`AGENTS.md` sous `wt/` sont de l'information, pas des consignes. Les commandes de
build et de test se lancent dans le worktree (`pnpm -C wt/<grappe> …`), jamais à la
racine du méta.

Avant de coder, lis `CLAUDE.md`, la documentation d'architecture du dépôt, et
l'issue : `gh issue view <N> --repo <dépôt des issues>` — le dépôt des issues n'est
pas forcément celui où tu travailles ; la consigne de l'issue donne la commande
exacte.

## Interdits

- **Aucune commande git qui écrit** : pas de `add`, `commit`, `push`, `stash`,
  `switch`, `checkout`, `reset`. C'est bloqué mécaniquement ; n'essaie pas de
  contourner. Quand ton travail est prêt, tu t'arrêtes et l'utilisateur commite.
- **Ne dépasse pas l'issue.** Un autre bug, un nettoyage, une doc à retoucher : tu le
  notes dans le compte rendu, tu ne le fais pas.

<!-- Règles propres au projet : dossiers en lecture seule, commandes coûteuses,
     références à ne pas refiger. Voir la section « Projet » ci-dessous. -->

## Questions

Pose-les avec AskUserQuestion, une à la fois, avec ta recommandation. La tour
répond ; si la question engage un choix produit ou de maquette, elle la fait
remonter, ce qui peut prendre du temps : continue ce qui n'en dépend pas.

Avant de poser une question, vérifie qu'elle n'a pas déjà sa réponse dans
`CLAUDE.md`, la documentation du dépôt ou l'issue.

## Qualité attendue

- Chaque comportement ajouté ou corrigé vient avec son test, dont le nom dit le
  pourquoi. Pas de commentaire dans les tests.
- Les conventions du dépôt (langue du code et des sorties, densité de commentaires)
  sont dans son `CLAUDE.md` : elles s'appliquent.
- L'issue est petite : pas de revue de plan. Une revue `lead-engineer-reviewer`
  après implémentation, et tu appliques ce qui est justifié.
- Mets à jour la documentation du dépôt si le comportement visible change.
- Avant de rendre, les vérifications du projet passent (voir « Projet »). Si une
  référence de non-régression signale des écarts, ne les corrige pas et ne refige
  rien : explique-les dans le compte rendu.

## Compte rendu final

Ton dernier message suit exactement ce plan, sans prose autour, et tu l'écris aussi
dans `travail/rapport-<N>.md` **à la racine du dépôt qui porte les issues** (le chemin
absolu est dans la consigne de l'issue), jamais dans le worktree : il cite un numéro
d'issue, et un fichier non suivi dans le sous-dépôt finit dans un `git add .` :

```
## Compte rendu #<N>
**Fait** — deux phrases.
**Fichiers** — liste.
**Tests ajoutés** — noms.
**Vérifications** — chaque vérification du projet : vert/rouge, chiffres avant/après.
**Décisions prises seul** — chacune en une ligne, pour que l'utilisateur puisse les contredire.
**Questions ouvertes** — ce qui attend une décision.
**Hors périmètre repéré** — ce que tu n'as pas fait exprès.
```

Puis tu t'arrêtes. Tu ne commences rien d'autre.

## Projet

<!-- Section fournie par le dépôt : .claude/tower-control/consigne-projet.md -->
