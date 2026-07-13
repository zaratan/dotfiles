---
name: humanize
description: Réécrire un texte pour éliminer les AI-isms et coller au style d'écriture de l'utilisateur
user-invocable: true
arguments:
  - name: file
    description: Chemin du fichier à humaniser (optionnel, utilise le dernier fichier édité si absent)
    required: false
---

# Humanize

Réécrire un texte pour qu'il sonne humain et colle au style d'écriture de l'utilisateur.

## Étapes

1. **Charger le style de l'utilisateur** : Lire le fichier `~/.claude/memory/user_writing_style.md` (mémoire globale). S'il n'existe pas, vérifier dans la mémoire du projet (`~/.claude/projects/*/memory/user_writing_style.md`). Si aucun fichier de style n'est trouvé, demander à l'utilisateur de décrire son style ou proposer d'analyser ses messages Slack pour en construire un.

2. **Lire le fichier cible** : Lire le fichier passé en argument. Si aucun argument n'est fourni, demander à l'utilisateur quel fichier humaniser.

3. **Scanner les AI-isms** : Identifier les patterns d'écriture IA dans le texte. Liste non exhaustive :

   **Formulations corporate/IA :**
   - Em-dashes (—) sauf dans du code
   - "afin de" → "pour"
   - "significativement" → "bien", "beaucoup", ou supprimer
   - "le présent [document/devis/rapport]" → "ce [document/devis/rapport]"
   - "constitue" → "c'est"
   - "il convient de" → supprimer ou reformuler
   - "dans le cadre de" → "pour" ou "pendant"
   - "en mesure de" → "peut"
   - "conçu pour être [adjectif]" → reformuler plus directement
   - "pourront faire l'objet de" → "pourront donner lieu à" ou reformuler
   - "s'inscrit dans la continuité de" → vérifier si nécessaire
   - "souhaite optimiser son processus" → trop corporate
   - "afin d'assurer" → "pour"
   - "N'hésitez pas à" → "Si c'est plus simple" ou reformuler selon le style

   **Structure trop parfaite :**
   - Phrases toutes de longueur similaire
   - Transitions trop lisses entre les paragraphes
   - Bullet points trop symétriques (tous commencent par un verbe, tous même longueur)
   - Headers trop polis ("Ce que j'ai compris de votre besoin prioritaire")
   - **Phrases sans verbe** : les LLMs en abusent ("Une approche progressive en deux étapes." au lieu de "Je propose une approche..."). Un humain met un sujet et un verbe.

   **Vouvoiement/tutoiement :**
   - Vérifier la cohérence avec le style de l'utilisateur
   - Si le style indique tutoiement, signaler tout vouvoiement dans les parties non-juridiques

   **Mots et expressions surreprésentés par les LLM :**
   - "notamment"
   - "il est important de noter que"
   - "en effet"
   - "par ailleurs"
   - "en toute transparence" (sauf si c'est dans le style de l'utilisateur)
   - "permettre de" (souvent superflu)
   - "au sein de" → "dans"
   - "mettre en place" → "créer", "faire", "lancer"
   - "dans un premier temps" / "dans un second temps"
   - "force est de constater"

4. **Présenter les trouvailles** : Lister chaque AI-ism trouvé avec :
   - La ligne et le texte original
   - La correction proposée
   - La raison (AI-ism, incohérence de style, formulation corporate)

5. **Demander confirmation** : Demander à l'utilisateur s'il veut appliquer toutes les corrections, certaines, ou aucune.

6. **Appliquer** : Faire les corrections validées via l'outil Edit.

## Notes

- Les sections juridiques (Conditions, RGPD, clauses légales) peuvent garder un ton formel. Ne pas les tutoyer si elles utilisent "le client" à la troisième personne.
- Ne pas sur-corriger : le but n'est pas de rendre le texte familier, c'est d'enlever ce qui sonne robot.
- Garder la structure et le contenu intact. On change le ton, pas le fond.
- Si le fichier est un devis ou un document professionnel, rester plus formel qu'un email, mais retirer les AI-isms quand même.
