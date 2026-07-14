---
name: humanize
description: Réécrire un texte pour éliminer les AI-isms et coller au style d'écriture de l'utilisateur
user-invocable: true
arguments:
  - name: file
    description: Chemin du fichier à humaniser (optionnel, utilise le dernier fichier édité dans la session si absent)
    required: false
---

# Humanize

Réécrire un texte pour qu'il sonne humain et colle au style d'écriture de l'utilisateur.

## Étapes

1. **Charger le style de l'utilisateur** : Lire `~/.claude/memory/user_writing_style.md` (mémoire globale). S'il n'existe pas, vérifier dans la mémoire du projet (`~/.claude/projects/*/memory/user_writing_style.md`). Si aucun fichier de style n'est trouvé, demander à l'utilisateur de décrire son style ou proposer d'analyser ses messages Slack pour en construire un.

2. **Identifier la cible** :
   - Fichier passé en argument → le lire.
   - Pas d'argument mais un fichier a été édité dans la session → prendre le dernier fichier édité (confirmer d'une phrase que c'est bien lui).
   - Texte collé dans la conversation → travailler dessus directement, en mode « réécriture proposée » (pas d'Edit).
   - Sinon, demander quoi humaniser.

3. **Détecter la langue et le registre** : Français ou anglais ? Email, devis, README, doc ? Choisir la liste d'AI-isms correspondante ci-dessous et le bon registre du fichier de style (Denis a un registre spécifique pour les READMEs anglais).

4. **Scanner les AI-isms** : Passer le texte au crible des catégories ci-dessous.

5. **Présenter les trouvailles** : Item par item, trié par gravité (AI-ism flagrant d'abord, simple raideur ensuite), avec :
   - La ligne et le texte original
   - La correction proposée
   - La raison (AI-ism, incohérence de style, formulation corporate)

6. **Demander confirmation** : L'utilisateur choisit d'appliquer tout, certaines corrections, ou aucune.

7. **Appliquer** : Faire les corrections validées via Edit (ou donner le texte réécrit si la cible était du texte inline).

## AI-isms — français

### Lexique corporate

- "afin de" → "pour"
- "afin d'assurer" → "pour"
- "significativement" → "bien", "beaucoup", ou supprimer
- "le présent [document/devis/rapport]" → "ce [document/devis/rapport]"
- "constitue" → "c'est"
- "il convient de" → supprimer ou reformuler
- "dans le cadre de" → "pour" ou "pendant"
- "en mesure de" → "peut"
- "au sein de" → "dans"
- "mettre en place" → "créer", "faire", "lancer"
- "permettre de" (souvent superflu)
- "conçu pour être [adjectif]" → reformuler plus directement
- "pourront faire l'objet de" → reformuler
- "s'inscrit dans la continuité de", "s'inscrit dans" → vérifier si nécessaire
- "tirer parti de" → "utiliser", "profiter de"
- "optimiser son processus", "jouer un rôle clé", "être un levier" → trop corporate
- "garantir", "favoriser", "offrir" (au sens marketing) → des verbes concrets
- "N'hésitez pas à" → "Si c'est plus simple" ou reformuler selon le style

### Enthousiasme creux

- "crucial", "essentiel", "fondamental", "incontournable", "indispensable"
- "captivant", "fascinant", "révolutionnaire", "passionnant"
- "véritable" (comme intensificateur : "un véritable atout")
- Deux adjectifs valorisants d'affilée ("une solution simple et élégante")

### Décors génériques et métaphores recyclées

- "dans un monde en constante évolution", "à l'ère de", "à l'heure de"
- "dans le paysage de", "dans l'univers de", "au cœur de"
- "naviguer dans", "pierre angulaire", "tisser des liens", "cœur battant"

### Connecteurs mécaniques

- "notamment" (fréquence anormalement élevée chez les LLMs)
- "il est important de noter que", "il convient de noter"
- "en effet", "par ailleurs", "en outre", "par conséquent"
- "en somme", "en définitive", "en conclusion", "vous l'aurez compris"
- "autrement dit", "en d'autres termes"
- "dans un premier temps" / "dans un second temps"
- "force est de constater"
- "en toute transparence" (sauf si c'est dans le style de l'utilisateur)

### Calques de l'anglais

- "faire du sens" → "avoir du sens"
- "adresser un problème" → "traiter", "s'attaquer à"
- Virgule avant "et" en fin d'énumération (serial comma, usage anglais)

## AI-isms — anglais

Pour les READMEs, docs et commits en anglais :

- Vocabulaire signature : delve, leverage, seamless, robust, comprehensive, crucial, boasts, showcase, foster, underscore, landscape, navigate, testament, game-changer, unlock, elevate
- "it's important to note", "in today's fast-paced world"
- "serves as", "stands as" → juste "is"
- "not only… but also…", "Whether you're… or…"
- "Let's dive in", "Let's explore"
- Moreover / Furthermore / Additionally en ouverture de phrase
- Title Case Dans Les Headers → sentence case

## Structures rhétoriques

- **Règle de trois** : triades systématiques ("simple, rapide et efficace"). Une ou deux dans un texte, ça passe. À chaque paragraphe, c'est un tell.
- **Parallélismes négatifs** : "Non seulement X, mais aussi Y", "Ce n'est pas X, c'est Y", "It's not about X, it's about Y".
- **Participe présent analytique** en fin de phrase : "..., soulignant l'importance de", "témoignant de", "reflétant", "highlighting", "showcasing". Fausse profondeur d'analyse.
- **Question rhétorique + réponse immédiate** : répétée partout, c'est un tell. Exception : Denis l'utilise volontairement dans ses READMEs ("Ever been bothered by…? There you go"), ne la signaler que si elle revient plusieurs fois.
- **Conclusion enthousiaste** : "En conclusion", "En résumé", "Overall" suivi d'optimisme béat. Un humain finit souvent sec, sur un fait ou une action.

## Rythme et structure

- Phrases toutes de longueur similaire (les LLMs tournent autour de 18-22 mots ; un humain alterne le très court et le long)
- Paragraphes de longueur quasi identique
- Transitions trop lisses entre les paragraphes
- Bullet points trop symétriques (tous commencent par un verbe, tous même longueur)
- Triades "**Gras.** Explication." en tête de puce
- Gras excessif façon "key takeaways" (chaque terme "important" en gras)
- Headers trop polis ("Ce que j'ai compris de votre besoin prioritaire")
- Emojis pour structurer les sections
- Lignes `---` de séparation gratuites
- **Phrases sans verbe** : les LLMs en abusent ("Une approche progressive en deux étapes." au lieu de "Je propose une approche..."). Un humain met un sujet et un verbe.

## Ponctuation

- Em-dashes (—) sauf dans du code → virgules, points, parenthèses, ou rien
- Guillemets courbes “ ” à la place des droits (hors contexte typographique voulu)
- Deux-points systématiques dans les titres ("X : pourquoi Y change tout")
- Abus de points-virgules

## Ton

- Uniformité émotionnelle : tout est édulcoré, aucune prise de position, courbe plate du début à la fin
- Attributions vagues : "des experts estiment que", "il est largement reconnu que", "de nombreuses études montrent"
- Sur-hedging : "il semblerait que", "pourrait potentiellement", double précaution dans la même phrase
- **Vouvoiement/tutoiement** : vérifier la cohérence avec le style de l'utilisateur. Si le style indique tutoiement, signaler tout vouvoiement dans les parties non-juridiques.

## Réécrire, pas juste remplacer

- Varier la longueur des phrases : casser une longue en deux, fusionner deux courtes, laisser une phrase de trois mots de temps en temps.
- Les corrections ne doivent pas introduire de nouveaux AI-isms (remplacer "crucial" par "essentiel" ne corrige rien).
- Test final : lire les phrases corrigées à voix haute (mentalement). Si ça ne se dit pas à l'oral, reformuler.

## Notes

- Les sections juridiques (Conditions, RGPD, clauses légales) peuvent garder un ton formel. Ne pas les tutoyer si elles utilisent "le client" à la troisième personne.
- Ne pas sur-corriger : le but n'est pas de rendre le texte familier, c'est d'enlever ce qui sonne robot.
- Garder la structure et le contenu intact. On change le ton, pas le fond.
- Si le fichier est un devis ou un document professionnel, rester plus formel qu'un email, mais retirer les AI-isms quand même.
- Ces listes sont des indices, pas des règles : un humain écrit parfois "notamment". C'est l'accumulation qui trahit, pas l'occurrence isolée.
