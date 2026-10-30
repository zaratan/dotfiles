# Gabarit de section du journal

Une section par lot en fin de `.claude/tower-control/journal.md` du dépôt des issues. La table et la ligne
d'ordres de grandeur sortent de `assets/journal.sh <dépôt> <n>` ; la tour écrit le reste. Quatre projets avaient
quatre formats : les deux à tableau se lisaient, les deux en puces se subissaient.

```
## Lot <n>, du <date> au <date> (<login>) : <but en une ligne>

**Contexte.** <grappes, agents au plus, délégation ou non, préparation : relecture, prémisses corrigées, décisions avant lancement>

| Issue | Pts | PR | Merge | État |
|---|---|---|---|---|
| #234 <titre court> | 5 | #61 | `a4be4b8` | Fait, lot: <n> |
| #240 <titre court> | 3 | #62 | `c25f86c` | Fait après QA, lot: <n> |
| #87 <titre court> | 2 | | | Ouverte : attend <quoi> |

**Décisions de l'utilisateur.** `lot-<n>/decisions.md` ; les structurantes ici, une ligne chacune.

**Prémisses corrigées.** <une ligne chacune : ce que l'issue ou la consigne disait, ce qui était vrai>

**Coincé.** <ce qui a mal tourné et la règle qui en sort ; recopié dans ~/.claude/tower-control/entrants/ si ça vaut ailleurs>

**QA.** <lignes jouées, OK / KO / bloquées, régressions du lot, issues ouvertes>

**Reste.** <livraison, issues au Backlog, ce qui attend un tiers>

**Ordres de grandeur.** <forme du projet> · <issues> issues · <points> pts · <PR> PR · <agents max> agents ·
<durée> · <retouches>/<comptes rendus> retouches · <min/issue> · <questions à l'utilisateur>
```

La ligne d'ordres de grandeur a les colonnes de `references/ordres-de-grandeur.md` : elle s'y recopie sans
réécriture à la promotion.
