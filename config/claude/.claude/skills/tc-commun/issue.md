# Gabarit de corps d'issue

Titre : le défaut en une phrase, pas la solution. Exemples : « PROTECTION vide
imprime NON », « Index photo à plat et collisions par nom de fichier (bloquant pour
les Antilles) », « README : chemin du lien inexact ».

```markdown
## Why ?
<Le problème, ses raisons et son contexte, en français clair. Le paragraphe se suffit
à lui-même pour quelqu'un qui connaît le code et le projet : il doit comprendre
pourquoi l'issue existe et ce qu'elle implique sans ouvrir autre chose. Le constat
avec son pointeur `fichier:ligne`, et s'il a été vérifié, comment : commande,
chiffres, cas nominatifs. Sinon, dire que c'est une lecture de code non confirmée.>

## What ?
<Ce qu'on va faire et de quelle façon. Les notions techniques expliquées, les pistes
envisagées et celle retenue, ce qu'il ne faut pas faire. Ce qui reste à trancher, et
par qui : « à demander à <personne> ».>

## Must-Have
- [ ] <Ce qui doit être vrai pour valider le ticket, une case par point vérifiable.>
- [ ] <Seulement ce que la PR livre : une vérification d'après merge (instance,
      déploiement, ligne de QA) va dans le How.>

## How ?
<Les sources (docs, blogs, issues et PR liées) et les décisions prises : quoi, qui,
quand. Une décision prise plus tard avec l'utilisateur s'ajoute ici.>
```

Pour un méta-dépôt, `board.ts` ajoute en tête `**Dépôt.** <nom du sous-dépôt>` et le
préfixe `[<nom>]` dans le titre ; ne pas les écrire dans le corps.

La priorité et les points ne vont pas dans le corps : ils vivent sur le board, et
GitHub les affiche sur l'issue. Une copie dans le texte se désynchronise à la première
retouche.

Une issue parente (sous-issues natives) suit le même gabarit ; sa Must-Have est la
liste de ses sous-issues, que la tour coche à chaque fermeture de l'une d'elles.
