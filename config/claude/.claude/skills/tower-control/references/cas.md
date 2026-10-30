# Situations rares

Des règles vraies mais liées à une pile, une machine ou un type de produit. À lire quand la situation se
présente, pas avant ; `SKILL.md` dit laquelle mène où. Chaque section tient en une dizaine de lignes.

## Plusieurs agents mesurent sur la même machine

Poser un verrou commun avant de lancer, une commande par verrou, règle écrite dans un `MESURES.md` du dossier
des worktrees, seuil d'espace disque avant tout balayage. Deux niveaux : `lourd`, partagé (données entières,
construction de zéro, tests lents ; deux agents peuvent le tenir ensemble) et `chrono`, exclusif (un temps
publié attend que tout le lourd soit fini) ; un script Python `fcntl.flock` fait les deux et reste compatible
avec `lockf`. Toute compilation chronométrée ou partie de zéro passe sous le verrou, comme la mesure. **Le
réseau n'est jamais sous le verrou** : un téléchargement de 11 Go mis sous le verrou a bloqué les mesures
24 min. Le critère de calme se mesure sur la machine au repos avant d'être écrit (la charge moyenne d'un Mac
vaut 5 à 6 à vide, un agent qui l'attendait plus basse a attendu sans fin) : somme des `%CPU` des autres
processus sous 100 %, `pgrep` des outils lourds vide, compilateurs et linters de la pile compris. Un portable
se met en veille pendant une mesure longue même sous `caffeinate -i` : seul le temps CPU est fiable. Une
vérification tuée par son délai laisse des lanceurs de tests orphelins qui font tomber les tests sensibles au
temps des autres worktrees : `pgrep` et charge avant de conclure à un écart, rejouer le fichier tombé seul,
borner chaque passage par `timeout`. Une série lancée par la tour se dimensionne au besoin (à quoi sert chaque
ligne, qui attend le verrou) et se dit avec son coût : un balayage exhaustif a bloqué trois agents une matinée
pour un tableau que sept lignes déjà mesurées suffisaient à remplir.

## Hôte Linux (EL, Rocky) quand le poste est un Mac

Sonder l'amorçage sur la machine qui lance, pas sur celle qui l'a écrit : un script écrit sur Mac a cassé trois
fois sur un serveur EL. `sed -i.bak … && rm -f *.bak` (BSD et GNU) ; repli `ss -ltnH "sport = :<port>"` sans
`lsof` ; sous SELinux `Enforcing` (`getenforce`), `chcon -R -t container_file_t <dossier>` sur chaque dossier
monté par compose, certificats compris, sinon `Permission denied` dans le conteneur ; lire la sortie du pane
quand l'amorçage échoue. Un Chromium Playwright absent du cache s'installe par `pnpm exec playwright install
chromium-headless-shell` depuis le worktree, sans root, jamais par `executablePath`. `/usr/bin/time` est absent
sur Rocky et le `%M` de zsh est en Mo : mesurer sur la machine cible. `find -size -1M` de GNU arrondit au Mo et
ne garde que les fichiers vides : écrire `-size -1024k`.

## Verdicts à l'œil (images, vidéos, maquettes)

Une planche dit quoi regarder : pour chaque cas, la question posée, ce qui change entre les deux images, où
regarder ; carrés autour des détections plutôt que points, image entière sans recadrage. Deux images côte à
côte sans consigne ont été lues « je ne vois rien », pris à tort pour « aucune différence ». Un verdict dépend
des conditions de visionnage (vitesse, zoom) : demander comment l'utilisateur a regardé, consigner par temps de
piste et jamais par numéro, qui change à chaque réglage. Les verdicts d'une planche font une règle mesurable :
« corrige les pires sans défaire les bons, sinon arrête-toi avec les chiffres ». Une issue de maquette se
traite en allers-retours courts avec un rendu en image à chaque passe : c'est l'image qui déclenche les
retouches, pas le compte rendu. Un fichier de plus de 30 Mo ne s'envoie pas : découper par cas ou donner une
commande `scp`, demander lequel avant de produire. Un agent ne capture pas une application du poste (Terminal,
Finder, notification) : rendre le texte par `magick`, laisser les vraies captures à l'utilisateur.

## Données hors git (gros fichiers, dossiers synchronisés, LFS)

Le LFS gratuit de GitHub vaut 10 Gio de stockage et 10 Gio de bande passante par mois pour tout le compte, et un
budget à 0 $ bloque tout le LFS au dépassement, CI comprise : les gros fichiers vont dans un seau S3, le reste
dans un dépôt privé. Un fichier passé en LFS hors d'une branche casse la CI de la base si la tâche ne récupère
pas les objets : lire la CI de la base après ce push. Un fichier d'un dossier synchronisé annoncé « à jour »
peut ne pas être enregistré (copie identique, aucun verrou) : md5 et horodatage avant d'écrire une consigne
dessus. Tout test qui lit un dossier hors git le fait dans le test et sous `skipIf`, jamais au chargement du
module. Une clé de CI vers le stockage distant ne se relit pas : prévoir dès l'installation du canal de release
une seconde clé pour le poste de l'utilisateur.

## Code tiers redistribué (binaire, paquet, image)

La consigne demande de vérifier d'abord les licences réellement embarquées (chaînes des bibliothèques, pas le
fichier de licences du paquet, qui peut mentir) et de s'arrêter si elles changent celle du livrable : c'est une
décision de l'utilisateur, et la tour revérifie elle-même (`strings` sur la bibliothèque).

## Forge hors GitHub (Azure DevOps, GitLab)

Avant de dire qu'un outil ne peut pas, chercher celui de la forge et l'essayer : `az repos pr show --id <N>
--org <url>` et `az repos pr list --status active` (extension `azure-devops`), `glab`. Un pipeline peut être
rouge sans la branche (étape de recette cassée depuis des semaines, audit nocturne, agent de build à 60 min) et
une politique de build peut bloquer un merge : lire la timeline (`az devops invoke … timeline`) et le journal
de l'étape, jamais le résultat global ni `mergeStatus`.

## Réglages du dépôt qui coûtent

L'exigence « branche à jour » d'un ruleset coûte une mise à jour et une CI de plus à presque chaque merge en
parallèle ; la file de fusion GitHub n'existe que pour un dépôt d'organisation ; décision de l'utilisateur.
Quand le ruleset exige des contrôles nommés, `paths-ignore` seul laisse une PR de docs « en attente » à
jamais : il faut un second workflow aux mêmes noms qui réussit sans rien faire, ou un merge administrateur. Un
hook pre-push nouvellement posé se teste par un vrai push : git exporte `GIT_DIR` dans les hooks, et un test
« hors d'un dépôt » y voit le dépôt. Un `index.lock` périmé bloque tout git dans le worktree : la tour le
signale avec le chemin, l'utilisateur le retire.

## Rebase en cours de l'utilisateur

La tour lit les hunks (garder les deux côtés si additif, réordonner quand un bloc est une méthode, isoler le
test d'une option neuve plutôt que changer son attendu), vérifie lint, types et tests sans formater un fichier
que le commit suivant du rebase corrige, et laisse `git add` et `rebase --continue` à l'utilisateur, commandes
écrites.

## Piles Docker et dépendances

Une copie d'un worktree garde son nom de projet compose : `docker compose` depuis la copie recrée la pile de
l'original en plein run ; poser `COMPOSE_PROJECT_NAME`, ou pas de compose du tout. Dependabot ne monte pas une
peer installée automatiquement par pnpm : un override temporaire force la résolution, à retirer une fois le
lockfile écrit. Un spec nouveau qui nettoie des tables se joue dans la même commande que ses voisins qui
écrivent dans ces tables : seul, il passe sur une table parente vide et tombe en CI.

## Réécriture dans un autre langage

Demander la date de la prochaine publication avant d'ordonner : ce que personne ne verra avant elle (ergonomie
de l'ancien code, raccord temporaire) est du travail jeté. Une issue dédiée, lancée en premier, enregistre la
référence de l'ancienne version (sorties, tirages aléatoires, sommes des entrées) : elle supprime les
exécutions croisées et survit à la suppression de l'ancien code.

## Livraison sur des instances

Avant d'écrire une livraison, demander l'état réel de chaque instance (ou la commande de lecture qui le donne),
jamais le déduire des heures de merge ni d'un résumé de session : une doc de migration hors ordre a été écrite
sur un « déjà appliqué » faux.

## QA d'un outil sans API, menée avec l'utilisateur

La tour prépare un script d'installation (export de la base, dossiers de test séparés, rien de supprimé) et un
cahier ordonné qui modifie les données en dernier ; l'utilisateur colle chaque réponse, la tour vérifie chaque
étape sur le disque (empreintes, heures, journal). Quand la porte de release est une passe manuelle d'une heure,
prévoir dès la première version la voie d'un correctif : statut « non rejoué » ligne par ligne, accepté sur un
numéro de correctif, avec ce que le correctif change.
