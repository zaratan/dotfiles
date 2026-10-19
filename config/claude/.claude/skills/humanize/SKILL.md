---
name: humanize
description: Réécrire un texte (message, doc, README, PR, commit) pour retirer ce qui trahit une IA et coller au style d'écriture de l'utilisateur
user-invocable: true
arguments:
  - name: file
    description: Chemin du fichier à humaniser (optionnel, utilise le dernier fichier édité dans la session si absent)
    required: false
---

# Humanize

Réécrire un texte pour qu'il sonne humain et colle au style d'écriture de l'utilisateur.

Ce qui agace et trahit le plus n'est presque jamais un mot isolé : c'est un geste répété (remplir, opposer, annoncer, résumer, souligner l'importance).
Chercher les gestes avant les mots : une liste de mots ne retrouve qu'une petite part des passages fautifs.
Le style de l'utilisateur, tiré de ses propres textes, prime sur toutes les listes ci-dessous.

## Étapes

1. **Charger le style de l'utilisateur** : Lire `~/.claude/memory/user_writing_style.md` (mémoire globale). S'il n'existe pas, vérifier dans la mémoire du projet (`~/.claude/projects/*/memory/user_writing_style.md`). Si aucun fichier de style n'est trouvé, demander à l'utilisateur de décrire son style ou proposer d'analyser ses messages pour en construire un. Un trait noté comme le sien ne se signale jamais, même s'il figure dans une liste ci-dessous.

2. **Identifier la cible** :
   - Fichier passé en argument → le lire.
   - Pas d'argument mais un fichier a été édité dans la session → prendre le dernier fichier édité (confirmer d'une phrase que c'est bien lui).
   - Texte collé dans la conversation → travailler dessus directement, en mode « réécriture proposée » (pas d'Edit).
   - Sinon, demander quoi humaniser.

3. **Détecter la langue, le genre et le lecteur** : Français ou anglais ? Message, email, devis, article, README, doc, PR, commit, commentaire de code ? Qui lit, et que sait-il déjà ? Choisir le registre correspondant dans le fichier de style (messages, prose longue, README anglais, commits).

4. **Scanner, dans cet ordre** : d'abord les gestes (section 1), puis la structure et le rythme (2), la mise en forme (3), la ponctuation (4), le lexique (5 et 6). Ajouter la section 7 pour un README, une doc, une PR, un commit ou un commentaire de code.

5. **Présenter les trouvailles** : Item par item, trié par gravité (ce qui agace le plus d'abord, simple raideur ensuite), avec :
   - La ligne et le texte original
   - La correction proposée
   - La raison (la catégorie de la section)
   Les coupes forment un groupe à part, « Coupes proposées » : chaque passage cité, avec sa raison (redit la ligne N, évident pour ce lecteur, paraphrase le code). Quand un détail manque (chiffre, nom, exemple, pourquoi), poser la question au lieu de l'inventer. Une affirmation invérifiable se signale.

6. **Demander confirmation** : L'utilisateur choisit d'appliquer tout, certaines corrections, ou aucune ; les coupes se valident à part.

7. **Appliquer** : Faire les corrections validées via Edit (ou donner le texte réécrit si la cible était du texte inline). Relire ensuite le résultat contre « Interdits du réécrivain » : une correction ne doit pas créer un nouveau tic.

## 1. Ce qui agace le plus

### Vide et remplissage

- **Vide abstrait** : des noms qu'on ne peut pas se représenter (écosystème, dynamique, enjeux, cadre, dispositif, acteurs, levier, paysage). Test : voit-on quelque chose ? Sinon, le détail vérifiable (nom, chiffre, date, fichier, exemple) ; s'il manque, le demander.
- **Généralité passe-partout** : « une solution moderne et évolutive » vaut pour n'importe quel sujet. Dire ce que la chose fait, pour qui, avec quelle limite.
- **Remplissage** : une idée redite deux ou trois fois, introduction qui tourne avant d'entrer, paragraphe dont seule une phrase porte quelque chose. Proposer la coupe ; un premier jet d'IA perd souvent un tiers sans rien perdre.
- **Expliquer l'évident** : phrase qui n'apprend rien à ce lecteur, défense d'un point que personne ne conteste. Proposer la coupe.
- **Conclusion qui redit** : dernière phrase ou dernier paragraphe qui reformule la thèse, annoncé (« En résumé », « Au final », « In summary ») ou non. Finir sur le dernier fait ou l'action attendue.
- **Résumés à chaque niveau** : fin de section qui résume la section, puis fin de texte qui résume tout.
- **Plan et comptage annoncés** : « Deux contraintes guident ce choix. », « Voici trois points à retenir. », « Three things stand out. ». Entrer directement dans la première idée.

Exceptions à garder si le fichier de style les donne comme siennes : le but posé en première phrase d'un article (« Cet article a pour but de… ») et la conclusion de blog qui dit ce que le lecteur sait faire maintenant (« Voilà, vous devriez pouvoir… »).

### L'opposition « ce n'est pas X, c'est Y »

Le tic le plus cité par les lecteurs, et le plus stable d'un modèle à l'autre. Toutes ses formes :

- « Ce n'est pas X, c'est Y », « It's not X, it's Y », et en deux phrases : « Il ne brille pas. Il illumine. »
- « Non seulement X, mais aussi Y », « pas seulement X, mais Y », « not just X, but Y »
- « Y plutôt que X », « au lieu de X », « rather than (merely) », « not simply »
- « Moins X, plus Y », « less like X and more like Y »
- « Pas X. Pas Y. Juste Z. » et les négations en cascade
- « X ? Non. Y. », et la version en trois temps : « Ce n'est pas X. C'est Y. » suivi d'une chute

À la place : affirmer Y. Garder le contraste seulement si quelqu'un soutient vraiment X, et le nommer.

### Formules de chat

- **Ouverture flagorneuse** : « Excellente question », « Tu as raison de soulever ce point », « Bien sûr ! Voici… », « You're absolutely right ». Commencer par le contenu ; si l'on concède, dire sur quoi.
- **Relance finale** : « Souhaitez-vous que je… », « Dites-moi si… », « J'espère que cela vous aide », « Would you like me to… », « Let me know if… ». S'arrêter après la réponse ; une étape restante se dit comme un fait (« La section 3 n'a pas encore de source. »).
- **Ton de guichet** : « Je comprends votre préoccupation », « Je vous prie de nous excuser pour la gêne occasionnée », « n'hésitez pas à nous contacter ». Le « n'hésitez pas à m'écrire » chaleureux, à la première personne, peut être celui de l'utilisateur.
- **Restes de l'outil** : « En tant que modèle de langage », « selon les informations disponibles à ce jour », « bien que les détails soient limités ».

### Tics de Claude (2026)

C'est Claude qui réécrit : se méfier d'abord des siens.

- **Honnêteté affichée** : « honnêtement », « pour être franc », « la réponse honnête », « The honest caveat », « honest take ». Supprimer ; la réserve se dit telle quelle, sous un titre plat (« Limites »).
- **Intensifs** : « vraiment », « sincèrement », « véritablement », « réellement », « discrètement », « en silence », « genuinely », « quietly », « the X is real », « fundamentally », « every single ».
- **Souligner l'importance** : « ce qui compte », « c'est là que tout se joue », « point clé », « il faut le dire clairement », « This matters. », « X matters because », « worth naming ». Donner la conséquence concrète, ou rien.
- **Verdict annoncé** : « La réponse courte : », « point final », « full stop », « The thing to internalize: ». Dire le verdict.
- **Teasers** : « Voici le hic », « Et c'est là que ça devient intéressant », « Le résultat ? », « Here's the thing », « Here's the kicker ». Dire la chose.
- **Métaphores de chantier** et leurs calques : porteur (load-bearing), couture (seam), atterrir (land), faire remonter (surface), câbler (wire), garde (gate), la forme du problème (shape), substrat, ceinture et bretelles, rayon d'impact (blast radius), preuve irréfutable (smoking gun), mériter sa place (earn its keep), « là où vit X ». Le mot plat : nécessaire, fusionné, relie, condition, la cause.
- **Objets qui agissent** : « le risque vit dans », « ce fichier porte », « le sujet gagne sa place à l'ordre du jour ». Un sujet humain ou un système réel, un verbe littéral.
- **Fragments en rafale** : « Pas un détail. Une décision. », « Il l'a publié. Ouvertement. Dans un livre. ». Une phrase courte porte une information, pas un effet ; pas plus de trois courtes d'affilée.
- **Phrase qui tourne autour du point** puis le livre comme une révélation. Dire le point d'abord.

### La session qui fuit dans le texte

- **Jargon inventé** pendant le travail : raccourcis forgés, termes jamais définis, composés à rallonge venus du plan. Écrire pour un lecteur qui n'a pas vu la session : le nom usuel, ou une définition à la première apparition.
- **Renvois à un état passé** : « désormais », « contrairement à l'ancienne version », « comme on l'a vu », « previously X, now Y ». Le présent seul.
- **« L'utilisateur » dans un document** : l'interlocuteur de l'agent n'est pas un personnage du texte (« l'utilisateur a jugé fausses les six pistes »). Dire le fait ou le choix sans lui (« Six pistes qui étaient fausses ne ressortent plus. »). Une personne nommée reste nommée si le texte parle d'elle.
- **Raisonnement narré** : « Réfléchissons », « Let me think about this ».

### Assurance non vérifiée

- **Promesse sans preuve** : « prêt pour la production », « robuste », « tous les cas sont gérés », « cause racine », « j'ai maintenant toute l'image », « définitif ». Dire ce qui a été vérifié, comment, et ce qui ne l'a pas été.
- **Pourquoi inventé** : une raison plausible que l'auteur n'a pas donnée (« conçu pour faciliter la maintenance »). Demander.
- **Fausse intimité** : souvenir, émotion ou intention prêtés à l'auteur (« Je ne compte plus les fois où… »). Supprimer, ou demander.

### Ton

- **Publicité** : vendre au lieu de décrire (« offre une expérience fluide », « nouvelle génération », « de pointe », « niché au cœur de »). Un fait daté et précis.
- **Importance gonflée** : « marque un tournant », « témoigne de », « reflète une tendance plus large », « pose les jalons ».
- **Équilibre de principe** : chaque avantage suivi d'un inconvénient, « tout dépend du contexte », fin qui ne tranche pas. Prendre position ; une réserve seulement si elle change la décision.
- **Sandwich « défis puis avenir »** : « Malgré ces défis, l'avenir s'annonce prometteur. ». Dire la limite et s'arrêter.
- **Sur-hedging** : « il semblerait que », « pourrait potentiellement », deux précautions dans la même phrase.
- **Attributions vagues** : « les experts estiment », « de nombreuses études montrent ».
- **Morale non demandée** : l'appel final à la prudence ou à l'éthique.
- **Vouvoiement ou tutoiement** : vérifier la cohérence avec le registre choisi dans le fichier de style.

## 2. Structure et rythme

- **Longueur des phrases** : ce qui trahit n'est pas une moyenne, c'est l'absence de phrases très courtes et très longues. Compter : si presque toutes tiennent entre 12 et 25 mots, varier. Varier parce que le contenu l'appelle, pas pour battre un détecteur.
- **Phrases soudées par des virgules (surtout en français)** : une idée, puis une incise, une précision entre parenthèses, une conséquence accrochée par « , et … », le tout en une phrase. Compter les virgules par phrase et les « ), » (parenthèse suivie d'une virgule) et comparer aux textes de l'utilisateur ; en français, au-delà d'environ une virgule par phrase, la phrase empile. Mesuré sur un blog humain contre une doc écrite par Claude : 0,3 contre 1,95 virgule par phrase, 0,5 contre 8,4 « ), » pour 1 000 mots, 59 % contre 19 % de phrases sans virgule ni subordonnée, à nombre de subordonnées égal. Casser en phrases d'une idée ; une précision qui compte devient sa propre phrase, une précision qui ne compte pas part. En anglais, les modèles mettent plutôt moins de virgules que les humains : là, c'est la ponctuation pauvre qui trahit (section 4).
- **Paragraphes de même gabarit** : idée, explication, mini-conclusion, partout, de même longueur. Ouvrir un paragraphe par l'exemple, un autre par l'objection.
- **Transitions trop lisses** entre les paragraphes.
- **Une phrase par paragraphe**, ligne vide entre chaque (format LinkedIn). Ne pas confondre avec une source Markdown coupée en fin de phrase à l'intérieur d'un paragraphe.
- **Phrases sans verbe** dans la prose qui explique (« Une approche progressive en deux étapes. »). Elles ont leur place dans un titre, une puce, une chute.
- **Règle de trois** : triade d'adjectifs abstraits (« simple, rapide et efficace »), une par paragraphe. Une énumération de trois choses concrètes reste.
- **Paires réflexes « X et Y »** : « simple et robuste », « clair et concis », « défis et opportunités ». Garder le mot qui dit quelque chose.
- **Anaphore** : le même début de phrase trois fois de suite.
- **Fausse étendue** : « de X à Y » dont les bornes ne sont pas sur une même échelle (« de l'innovation à la transformation culturelle »).
- **Rotation de synonymes** : « le tableau de bord… l'interface… le portail » pour une seule chose. Toujours le même nom ; en doc technique, la répétition est une qualité.
- **Question rhétorique et sa réponse**, en série. Une ou deux par texte peuvent être celles de l'utilisateur.

## 3. Mise en forme

- **Puces là où la prose suffit** : un avis de deux lignes en trois puces. Une liste pour des étapes, ou pour au moins trois éléments parallèles.
- **Puces symétriques** : même verbe d'ouverture, même longueur, même gabarit.
- **Puce « **Terme** : explication »** sur toute une liste, et triade « **Gras.** Explication. ». Accepter seulement quand le fichier de style la donne comme habitude, avec des puces inégales.
- **Gras mécanique** façon « key takeaways ». Le gras sert un avertissement.
- **Titres** : un titre dans un message ou sous ~300 mots ; titres polis ou en question (« Pourquoi est-ce important ? », « Why it matters ») ; Title Case, en anglais comme en français (« Négociations Stratégiques ») ; « X : pourquoi Y change tout ».
- **Emojis de structure** : 🚀, ✅, ✨, 👉 en tête de titre, de puce, de paragraphe ou de ligne de log. Les émoticônes de l'utilisateur, s'il en a, restent.
- **Tableaux gratuits** : deux ou trois lignes, colonnes ✅/❌. Un tableau compare au moins trois choses sur au moins deux critères.
- **Décor** : `---` entre chaque section ; flèches et symboles dans la prose (→, ≈, ✓, •).
- **Markdown dans un contexte qui ne le rend pas** : mail, Slack sans rendu, formulaire.
- **Restes de copier-coller** (preuve directe) : `:contentReference[oaicite:0]`, `turn0search0`, `utm_source=chatgpt.com`, `[cite: 1]`, gabarits « [Prénom Nom] » ou « [Nom de l'entreprise] », caractères invisibles U+200B et U+200D. Supprimer ; garder les espaces insécables U+00A0 et U+202F.

## 4. Ponctuation et typographie

- **Tiret cadratin** hors code : indice en recul, mais Claude en met encore plus que les humains et les lecteurs le remarquent. Le remplacer selon le sens : virgule, parenthèse, deux-points, point-virgule, point, ou reformuler.
- **Remplacement uniforme** : un texte où chaque tiret est devenu une virgule ou un point, haché en phrases moyennes, est devenu un indice à son tour. Varier le signe.
- **Ponctuation pauvre** : une page sans parenthèse, sans point-virgule, sans point d'exclamation. Une parenthèse quand elle sert.
- **Deux-points de mise en scène** : « La clé : … », « Le verdict : spectaculaire. ».
- **Point-virgule** : en anglais, les modèles en mettent plutôt moins que les humains. En français, une doc de Claude en met sept fois plus que l'auteur mesuré, qui fait deux phrases. Suivre le fichier de style. Si l'utilisateur n'en écrit pas, chaque point-virgule devient un point. Signaler aussi « X ; en pratique, Y » qui remplace « mais » ou « parce que ».
- **Guillemets** : suivre la typographie de l'utilisateur et du document ; « » est la norme française, pas un indice. Ce qui trahit, c'est le mélange (“ ” et "…", ’ et ') dans un même texte, ou des “ ” anglais dans du français.
- **Virgule avant « et » final** en français : calque de l'anglais. En anglais, la virgule d'Oxford est normale, ne pas la signaler.

## 5. Lexique français

Plus faible que les gestes : un mot seul ne prouve rien, la série trahit.

### Mesurés sur corpus

- « également » pour « aussi » : dix fois plus fréquent chez les modèles. → « aussi ».
- « défi(s) », « relever les défis », « face aux défis ».
- « on », « il faut », « bien », « même », « dire » absents d'un long texte : il sonne communiqué. Remettre « on » quand le registre le permet.
- **Participes présents**, partout, pas seulement en fin de phrase : « …, soulignant l'importance de », « permettant de », « ouvrant la voie à ». Une proposition conjuguée ou une nouvelle phrase.
- **Nominalisations** : « la vérification de la cohérence est effectuée » → « on vérifie que… ».
- **Copule évitée** : « constitue », « représente », « fait office de », « se positionne comme », « dispose de » → « est », « a ».

### Corporate et dissertation

- « afin de » → « pour » ; « le présent document » → « ce document » ; « au sein de » → « dans » ; « en mesure de » → « peut ».
- « il convient de », « dans le cadre de », « mettre en place », « tirer parti de », « capitaliser sur ».
- « jouer un rôle clé », « être un levier », « plusieurs leviers se dessinent », « dans une large mesure », « au cœur du débat ».
- « garantir », « favoriser », « offrir » au sens marketing ; « dispositif », « acteurs », « enjeux » hors administration. Des verbes concrets.
- « permettre de » : signaler quand il cache le sujet (« Cela permet de garantir » → « On garantit »). La définition « X est un Y qui permet de Z » peut être celle de l'utilisateur.

### Enthousiasme, décors, connecteurs

- « crucial », « essentiel », « fondamental », « incontournable », « indispensable », « captivant », « fascinant », « révolutionnaire », « véritable » comme intensif ; deux adjectifs valorisants d'affilée.
- « dans un monde en constante évolution », « à l'ère de », « dans le paysage de », « au cœur de », « plonger dans », « naviguer dans les complexités », « tapisserie », « pierre angulaire », « tisser des liens ».
- « notamment », « en effet », « par ailleurs », « en outre », « par conséquent », « autrement dit », « dans un premier temps », « force est de constater » (contesté) : normaux à l'unité en français écrit, indices en série.
- Datés (2023-2024), à couper sans en faire le cœur du diagnostic : « il est important de noter que », « en conclusion », « en somme », « en définitive », « vous l'aurez compris ».

### Calques

- « faire du sens » → « avoir du sens » ; « adresser un problème » → « traiter » ; « délivrer » un projet → « livrer ».
- Doublets inclusifs ajoutés à une source qui n'en avait pas.

## 6. Lexique anglais

- Les tics de Claude de la section 1 d'abord : honest, genuinely, quietly, real, load-bearing, seam, land, surface, wire, gate, shape, substrate, matters.
- **Copule évitée** : « serves as », « stands as », « marks », « represents », « features », « offers », « boasts », « refers to » → « is », « has ».
- **Participes d'analyse** : « highlighting », « showcasing », « ensuring », « reflecting », « underscoring ».
- **Mots latins et nominalisations** : « utilize » → « use », « facilitate », « commence » ; « notes », « explains » → « says ».
- **Pitch** : « blazing fast », « production-ready », « enterprise-grade », « supercharge », « effortless », « seamless », « robust ».
- **Prudence empilée** : « may », « can », « not necessarily » dans chaque phrase.
- « Whether you're… or… », « not only… but also… ».
- **Contractions** : les remettre (« it's », « don't ») quand le registre le permet.
- Title Case dans les titres → sentence case.
- Datés (2023-2024), indices faibles aujourd'hui : delve, tapestry, testament, intricate, pivotal, vibrant, landscape, underscore, foster, leverage, game-changer, unlock, elevate ; « it's important to note », « in today's fast-paced world », « Let's dive in » ; Moreover, Furthermore, Additionally en tête de phrase (encore fréquents chez Gemini).

## 7. README, docs, PR, commits

### README

- La première phrase dit ce que fait l'outil, pour qui, sur quelle entrée ; aucun adjectif de vitesse ou de qualité sans chiffre.
- Dire pourquoi le projet existe, à la première personne si c'est le projet d'une personne.
- Chaque commande vient d'un vrai terminal, chaque chiffre est mesuré : signaler une fonctionnalité ou une commande que le réécrivain ne peut pas vérifier.
- Ce que l'outil ne fait pas, sous un titre plat (« Limites »).
- Des sections nommées d'après leur contenu ; le squelette habituel de l'utilisateur (voir le fichier de style) reste. Ce qui trahit : « Features » en pitch, titres « Why X? », « What we do differently ».
- Ni arborescence de dossiers, ni diagramme ASCII (souvent mal aligné chez Claude), ni rangée de badges décoratifs.
- Contributing et licence : une ligne chacun, avec le lien.
- Un README qui demande une table des matières est trop long : le signaler.
- L'état présent seulement ; l'historique va dans le changelog et git.

### Docs

- La doc dit ce que le code ne dit pas : pourquoi, contrat externe, piège, limite. Proposer de couper la prose qui paraphrase le code.
- Remplacer plutôt qu'ajouter : une décision abandonnée sort de la doc.
- La réponse ou la commande en première ligne.

### PR et issues

- La description ne redit pas le diff (« What changed », une puce par fichier) : le pourquoi, ce qui a été écarté, comment c'est testé, ce que le relecteur doit regarder.
- Remplir le gabarit du projet, rien de plus ; ne pas lister les tests un par un ; pas de tableau pour un petit changement.
- Chaque phrase se vérifie contre le diff : signaler un changement annoncé qui n'y est pas.
- Titre : un verbe et son objet, sans adjectif ni emoji.
- Rapport de bug : ce que j'ai fait, ce que j'attendais, ce qui est arrivé, la version.

### Commits et commentaires de code

- Un commit dit pourquoi, il ne raconte pas le diff ; si le pourquoi manque, le demander.
- Court, lisible dans `git blame` : suivre le style de commit du fichier de style, ou la convention du projet.
- Lignes d'attribution (Co-Authored-By, Generated with) : décision de l'utilisateur, ne pas y toucher.
- Commentaires : narration du quoi, mots temporels (« désormais », « previously », « no longer »), renvois à un plan, prose défensive (« this is not cosmetic »), emojis dans les logs. Appliquer la règle des commentaires du CLAUDE.md global.

## Interdits du réécrivain

- Ne jamais ajouter de fautes, de coquilles ni de familiarités pour « faire humain ». Les fautes déjà présentes se listent à part ; l'utilisateur décide.
- Ne pas faire tourner des synonymes pour éviter une répétition.
- Ne pas remplacer un tic par un autre : « crucial » par « essentiel », chaque tiret par une virgule, une liste par trois fragments.
- Ne rien couper sans accord : proposer.
- Ne rien inventer : ni chiffre, ni exemple, ni anecdote, ni pourquoi.
- Ne pas chasser par principe le passif, le registre soutenu ou une grammaire parfaite : rien de cela ne prouve une IA.
- Ne pas bruiter un texte technique, scientifique ou écrit par un non-natif, naturellement plat.

## Réécrire, pas juste remplacer

- Réécrire la structure avant les mots : changer les mots laisse l'empreinte, et les lecteurs exercés voient la structure.
- Varier la longueur des phrases : casser une longue en deux, fusionner deux courtes, laisser une phrase de trois mots quand elle dit quelque chose.
- Test final : lire les phrases corrigées à voix haute (mentalement). Si ça ne se dit pas à l'oral, reformuler.

## Notes

- Les sections juridiques (Conditions, RGPD, clauses légales) peuvent garder un ton formel. Ne pas les tutoyer si elles utilisent « le client » à la troisième personne.
- Un devis ou un document professionnel reste plus formel qu'un email, sans ses AI-isms ; un registre demandé pour un public nommé passe avant le style par défaut.
- Ne pas sur-corriger : le but n'est pas de rendre le texte familier, c'est d'enlever ce qui sonne robot.
- Garder le fond. Les coupes de remplissage se proposent ; rien d'autre ne disparaît.
- Ce skill améliore le style, il ne garantit pas qu'un texte passe pour humain : un texte sorti de Claude peut porter un filigrane statistique qu'une retouche n'efface pas. Ne pas le promettre.
- Les tics changent à chaque génération de modèle ; les textes de l'utilisateur restent la meilleure référence.
- Ces listes sont des indices, pas des règles : un humain écrit parfois « notamment ». C'est l'accumulation qui trahit, pas l'occurrence isolée.
