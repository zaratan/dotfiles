# Instructions globales

## Workflow d'implémentation

Pour toute tâche de développement non-triviale, suivre ce processus :

### Avant l'implémentation

1. **Faire reviewer le plan par des agents spécialisés** (architecte, UI/UX, lead engineer) — adapter le nombre de reviewers à la complexité de la tâche
2. **Lancer les reviews en parallèle** pour gagner du temps

### Pendant l'implémentation

3. **Déléguer les tâches de dev non-triviales** au **clean-ts-developer** (pour du TS/Next.js) ou au **rails-craftsman** (pour du Ruby/Rails)
4. **S'arrêter à la fin de chaque sous-phase** pour permettre un test manuel par l'utilisateur

### Après l'implémentation

5. **Mettre à jour la documentation** pertinente (doc de migration, CLAUDE.md projet, etc.)
6. **Lancer des reviews post-implémentation** — adapter selon la tâche :
   - **lead-engineer-reviewer** : toujours, sur toute tâche non-triviale
   - **ui-ux-designer** : si la tâche touche à de l'UI (composants, styles, layout, accessibilité)
   - **tech-architect** : si la tâche est complexe (changement d'architecture, migration, nouvelle infra)
