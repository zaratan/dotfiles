# Instructions globales

## Workflow d'implémentation

Pour toute tâche de développement non-triviale, suivre ce processus :

### Avant l'implémentation

1. **Faire reviewer le plan par des agents spécialisés** (architecte, UI/UX, lead engineer) — adapter le nombre de reviewers à la complexité de la tâche
2. **Lancer les reviews en parallèle** pour gagner du temps

### Pendant l'implémentation

3. **S'arrêter à la fin de chaque sous-phase** pour permettre un test manuel par l'utilisateur

### Après l'implémentation

4. **Mettre à jour la documentation** pertinente (doc de migration, CLAUDE.md projet, etc.)
5. **Lancer des reviews post-implémentation** — adapter selon la tâche :
   - **lead-engineer-reviewer** : toujours, sur toute tâche non-triviale
   - **ui-ux-designer** : si la tâche touche à de l'UI (composants, styles, layout, accessibilité)
   - **tech-architect** : si la tâche est complexe (changement d'architecture, migration, nouvelle infra)

## Commentaires de code

**Zéro commentaire est la norme.** Un commentaire est un aveu : « A comment is an apology for not writing clear code » (Bob Martin). Il n'est ni exercé ni testé, et chaque commentaire à couper en revue est de l'attention prise à ce qui compte.

**Le critère, dans l'ordre, avant d'écrire une ligne de commentaire :**

1. Un **nom** peut-il le dire ? (`claimWon`, `screenIfReadable`) → renommer.
2. Un **test** peut-il le dire, avec le pourquoi dans son intitulé ? (« survives a forged previous state rather than failing the submission ») → écrire le test.
3. Seulement si ni l'un ni l'autre : **une ligne**, deux au plus, en phrases simples lisibles par un non-anglophone natif.

**Ce qui survit :** un piège de plateforme qui ferait échouer un test sans s'expliquer (`Origin: null` sous `no-referrer`, `display: flex` sur `<summary>` perd le marqueur natif), une provenance, un contrat avec un système externe, une JSDoc d'une ligne sur l'API publique d'une lib.

**Ce qui ne survit jamais :** la paraphrase du nom ou du corps, la narration de ce que fait le code, l'historique, un renvoi à un plan ou une décision hors du dépôt (« decision 73 », « G4 ») : le lecteur du code ne peut pas l'ouvrir.

**Tests : zéro commentaire.** Le nom du test est le commentaire.

**Le tri se fait avant de rendre, jamais en revue.** Sur chaque ligne de commentaire ajoutée du diff (`git diff` filtré sur `//`, `/*`, `*`, `#`, `--`), appliquer nom → test → commentaire. Mesurer sur le diff, pas sur le fichier : repère autour de 7 % de lignes de commentaire sur les lignes ajoutées, un premier jet tourne à 14 %, et le tri coupe presque toujours la phrase qui reformule le nom en gardant celle qui porte une décision non redérivable.
