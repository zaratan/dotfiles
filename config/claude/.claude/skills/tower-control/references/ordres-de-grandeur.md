# Ordres de grandeur des lots

Une ligne par lot, tirée des journaux. Sert à l'ETA du point d'avancement (`tc-lot/assets/point.md`) : comparer un lot
à ceux de même forme, pas à la moyenne. Une case vide : le journal ne le disait pas.

| Date (2026) | Forme | Issues | Points | PR | Agents max | Durée | Retouches | Repères |
|---|---|---|---|---|---|---|---|---|
| 30/09 | méta, web TS | 9 | | | 3 | une soirée | | 6 min d'agent par issue de 2-3 pts, 10 à 14 pour 3-5 |
| 01-02/10 | monorepo, base par worktree | 12 | 36 | | 4 | 1,5 j | 3/12 | 6 à 16 min par issue ; 2 questions d'agent sur 3 nées d'une prémisse fausse de la tour |
| 05-06/10 | méta, forge hors GitHub, deux tours | 16 (+2 jetées) | 48 | | 4 | deux demi-journées | | 7 issues de docs en 5 h sur deux agents ; ~45 questions directes |
| 04-06/10 | dépôt unique, traitement vidéo, mesures | 7 | 43 | | 3 | 2,5 j | 4 | issue de 8 pts en 5 sous-phases = 5 h de bancs ; 0 CR faux ; ~15 issues créées en chemin |
| 07/10 | méta, pile par worktree | 24 | 66 | 23 | 5 | une journée | 13/24 | 3 à 15 min par issue de 2-3 pts ; retouches = reliquats listés par l'agent ; 5 prémisses fausses malgré la relecture |
| 07-08/10 | dépôt unique, traitement vidéo | 9 | 27 | | 4 | 1,5 j | 7 | 6 à 50 min par issue ; 2 plans relus ; 5 prémisses fausses ; ~40 questions |
| 08/10 | dépôt unique, gabarit de document | 2 | 6 | | 1 | 3 h | 8 | 22 décisions en regardant le rendu ; 1 prémisse fausse |
| 09/10 | méta, quatre issues enchaînées | 4 | 4 | 4 | 1 | 2 h 40 | | contexte de l'agent 7 à 13 % sur la série |
| 09/10 | dépôt unique, planification par interview | 34 créées | 101 | | 4 lecture | 2 h 30 | | 7 min d'audit par agent, 120 à 170 k tokens chacun ; 38 questions d'agents |
| 12-13/10 | dépôt unique, Rust | 15 | | 13 | 3 | 2 j | | CI d'une PR 4 → 14-17 min avec les tests de bout en bout |
| 13-15/10 | dépôt unique, Rust, QA d'une commande | 19 | | 18 | 2 | 3 j | | garde de 3 pts en 1 à 2 h ; CI 15 → 7 min ; QA 58 lignes ~2 h, un agent |
| 14/10 | méta, reprise sur serveur Linux, délégation | 6 PR | | 6 | | 2 h 45 | | issue d'outillage de 3 pts en 12 min ; 2 prémisses fausses ; ~10 questions |
| 14/10 | méta, première QA de fin de lot | | | | 3 QA | ~50 min | | 12 à 21 lignes par agent ; 131 lignes en 28 min ; correctif 20 à 60 min ; ~40 frictions → 5 issues |
| 15-16/10 | dépôt unique, Rust, délégation | 9 | 28 | 9 | 3 | 2 j | | CI 15 min ; docs de 5 pts (13 fichiers) en 2 h 30 |
| 16/10 | dépôt unique, Rust, release | 13 | 49 | 15 | 4 | une journée | | QA 126 lignes ~2 h, un agent ; release 9 min |
| 16-18/10 | dépôt unique, Rust, planches à l'œil | 59 | | 50 | 5 | ~38 h | | 215 décisions ; CI ~8 min médiane ; planche de 34 cas en 67 extraits |
| 19/10 | méta, réécriture du backlog | 87 textes | | | 15 lecture | ~5 h | | 7 à 12 min par grappe de 4-7 issues ; lecteur froid 15-25 textes en 2-4 min |
| 20/10 | méta, délégation depuis Linux | 10 (+5 correctifs) | 53 | | 4 | 8 h 30 | | 8 pts/h sur issues indépendantes, 3× moins en sériel ; e2e 5-6 min ; CI 12 min ; QA 143 lignes 1 h 25, deux agents |
| 21/10 | méta, chaîne sérielle | 20 (+6) | 51 | | 4 | 5 h 15 de merges | | 9,8 pts/h ; 7 fusions sur la chaîne ; CI 10-14 min ; QA 174 lignes 45 min par agent, 2 KO |
| 25/10 | dépôt unique, TUI | 15 | ~55 | 20 | 4 | 13 h | | 6 à 60 min par issue ; ~60 questions ; QA 203 lignes, 2 agents, 1 h chacun ; 3 gpg |
| 26/10 | dépôt vide, délégation | 4 | 15 | 4 | 2 | 3 h | 3-5 par issue | 13 à 19 min par issue de 3-5 pts ; CI 15-45 s ; ~25 questions ; 2 prémisses fausses |
| 27/10 | dépôt unique, pack de skills | 13 | 63 | 16 | 3 | une journée | | une PR toutes les 40 min ; ~150 décisions par lots de cases ; 4 gpg |
| 27-29/10 | dépôt unique, livraison, QA avec l'utilisateur | 17 | | 26 | 3 | 3 j | | deux versions publiées ; QA ~30 étapes avec l'utilisateur ; 2 gpg |
| 27/10 | méta, réponses d'un tiers | 8 | 32 | 7 | 3 → 1 | une journée | | QA 149 lignes 30 min, deux agents, 0 régression ; issue de 8 pts en 1 h 30 |
| 28/10 | méta, trois fusions par branche | 14 (+2 correctifs) | | | | une nuit | | merges sur preuves locales ; e2e 3-4 min ; QA 24 + 40 + 117 lignes, 50 min à 2 h 40 par agent |
| 28/10 | méta, trois branches sur le même moteur | 13 | 47 | 10 | 4 | une journée | | 11 fusions ; QA 178 lignes en deux temps, 0 KO ; branche de 13 pts en 1 h 05 |
