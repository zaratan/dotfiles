# Installer le poste

Tu suis cette aide quand `~/Dirfyn/outil/VERSION` manque ou quand l'utilisateur colle le
message d'installation de Denis. `~/Dirfyn` est attaché au projet : l'étape 1 du skill
l'a vérifié. Si l'utilisateur n'a rien demandé de tel, dis-lui que le poste n'est pas
encore installé et propose de l'installer ; continue s'il accepte.

Tu parles au tutoiement et tu ne donnes jamais une commande à taper : ce que
l'utilisateur fait se fait dans Cowork, dans le Finder ou par un message à Denis. Les
commandes ci-dessous, c'est toi qui les lances, dans le shell de la machine virtuelle de
Cowork. Chaque commande ouvre un shell neuf. Si le shell répond que l'espace de travail
se télécharge encore, attends une minute et relance.

**Le message de Denis porte la clé du poste.** Ne recopie dans tes réponses ni le lien,
ni une ligne de `cles.env` : tu ne les écris que dans les commandes des sections 3 et 4.
Tu peux citer l'identifiant du poste et la version. Une fois `cles.env` écrit, ne le lis
jamais : ni `cat`, ni `head`, ni `grep`, ni l'outil de transfert.

Fais les sections dans l'ordre. Chacune dit quand t'arrêter.

## 1. Le réseau du compte Claude

```
curl -sS -o /dev/null -w 'code=%{http_code}\n' https://s3.fr-par.scw.cloud
```

- `code=` suivi d'autre chose que `000` : le stockage Dirfyn répond, passe à la section 2.
- `Received HTTP code 403 from proxy after CONNECT`, puis `code=000` : le compte Claude
  n'autorise pas encore le stockage. Guide l'utilisateur dans Cowork : Paramètres →
  Capacités → « Exécution de code et création de fichiers ». Il active « Autoriser
  l'accès réseau sortant », choisit « Gestionnaires de paquets », puis ajoute
  `s3.fr-par.scw.cloud` dans « Domaines supplémentaires autorisés ». Ensuite, propose de
  revérifier par la même commande. Si elle échoue encore, dis-lui d'ouvrir une nouvelle
  session de ce projet et d'y coller à nouveau le message de Denis, puis arrête-toi.
- Autre erreur (`Could not resolve host`, `Failed to connect`, délai dépassé) : dis-lui
  de vérifier que le Mac est connecté à internet, puis de redemander l'installation ; si
  ça dure, de prévenir Denis en lui donnant le message d'erreur.

## 2. Le message de Denis

S'il n'est pas encore dans la conversation, demande-le : Denis l'a envoyé par un lien de
son gestionnaire de mots de passe. L'utilisateur ouvre ce lien, copie tout le message et
le colle ici.

Le message a cette forme :

```
Installation de Dirfyn, poste <poste>, avec le skill dirfyn. Colle ce message tel quel dans Cowork, dans le projet du client.

Version : <X.Y.Z>
Lien du pack, valable jusqu'au <AAAA-MM-JJTHH:MM+00:00> :
<lien>
sha256 du pack : <64 caractères hexadécimaux>

cles.env :
DIRFYN_S3_ENDPOINT=…
DIRFYN_S3_REGION=…
DIRFYN_BUCKET_PACK=…
DIRFYN_BUCKET_RETOURS=…
DIRFYN_PROJET_PACK=…
DIRFYN_PROJET_RETOURS=…
DIRFYN_POSTE=<poste>
S3_ACCESS_KEY_ID=…
S3_SECRET_ACCESS_KEY=…
fin de cles.env
```

- Il manque une de ces lignes, une valeur est vide, ou une ligne de `cles.env` contient
  une espace ou une apostrophe : le message est abîmé. Demande-lui de le recoller en
  entier ; si c'est le même, de demander à Denis un nouveau message.

La date de validité du lien ne compte que pour télécharger le pack : la section 4 la
contrôle.

## 3. `cles.env` et `poste.toml`

Écris `cles.env` avec les neuf lignes du message, dans l'ordre, chacune recopiée telle
quelle entre apostrophes. Un `cles.env` déjà là est remplacé : c'est voulu, le nouveau
message fait foi.

```
umask 077 && printf '%s\n' '<ligne 1>' '<ligne 2>' '<ligne 3>' '<ligne 4>' '<ligne 5>' '<ligne 6>' '<ligne 7>' '<ligne 8>' '<ligne 9>' > ~/mnt/Dirfyn/cles.env && echo écrit
```

Puis `poste.toml`, l'identité du poste, que tu lis : le nom de l'intervenant et son
fuseau. Rien de `cles.env` n'y entre.

```
test -f ~/mnt/Dirfyn/poste.toml && cat ~/mnt/Dirfyn/poste.toml || echo absent
```

S'il existe, montre le nom et le fuseau et demande s'ils sont toujours justes ; s'ils le
sont, ne le réécris pas. Sinon, demande le prénom et le nom de l'intervenant, tels
qu'ils doivent figurer sur les fiches qu'il validera, et propose le fuseau
`Europe/Paris`. Un autre fuseau s'écrit comme dans la base des fuseaux horaires,
`Continent/Ville` (`America/Montreal`). Vérifie que le shell le connaît :

```
test -f /usr/share/zoneinfo/<fuseau> && echo connu || echo inconnu
```

`inconnu` : le fuseau est mal écrit, redemande-le. Si même `Europe/Paris` est
`inconnu`, le shell n'a pas la base des fuseaux et ses dates seraient en UTC : écris
`Europe/Paris` quand même et dis-lui de prévenir Denis. Puis :

```
printf '%s\n' 'nom = "<prénom et nom>"' 'fuseau = "<fuseau>"' > ~/mnt/Dirfyn/poste.toml && cat ~/mnt/Dirfyn/poste.toml
```

Dans le nom, un guillemet `"` ou une barre `\` s'écrit précédé d'une barre `\` ; une
apostrophe s'écrit `'\''`. Montre ce que la commande affiche.

## 4. Le pack

```
cat ~/mnt/Dirfyn/outil/VERSION 2>/dev/null || echo absent
```

- Une autre version que celle du message : l'outil est déjà installé, ne le remplace
  pas. Passe à la section 5.
- La version du message : l'outil est installé. Si le lien est encore valable (voir
  plus bas), refais l'installation qui suit pour compléter une copie interrompue ; sinon,
  passe à la section 5.
- `absent` : l'outil n'est pas installé, ou sa copie s'est interrompue. Installe-le.

Le lien n'est plus valable quand sa date est passée. Compare-la à l'heure du shell :
`date -u +%Y-%m-%dT%H:%M+00:00`. Si elle est passée et qu'il faut installer, dis-lui de
demander à Denis un nouveau message : le lien vaut 7 jours.

Crée un dossier temporaire neuf pour cette installation :

```
mktemp -d
```

La commande affiche son chemin : recopie-le tel quel entre apostrophes à la place de
`<dossier>` dans les commandes qui suivent. Si elle n'affiche pas de chemin, dis-lui de
prévenir Denis en lui donnant le message. N'en reprends jamais un d'une autre session :
il peut appartenir à un autre utilisateur de la machine virtuelle. Ne quitte pas cette
section sans l'avoir supprimé par sa dernière commande, même sur un échec.

Télécharge le pack par le lien du message, recopié tel quel entre apostrophes :

```
curl -sS -o '<dossier>/pack.zip' -w 'code=%{http_code} proxy=%{http_connect}\n' '<lien>'
```

- `code=200` : continue.
- `proxy=403` : le compte Claude n'autorise pas l'hôte du lien. Supprime le dossier, puis
  reprends la section 1, avec cet hôte dans « Domaines supplémentaires autorisés ».
- `code=403` : le lien est périmé ou la clé refusée. Supprime le dossier, puis dis-lui de
  demander à Denis un nouveau message.
- Un autre code que `000` : dis-lui de prévenir Denis en lui donnant cette ligne.
- `code=000` avec `Could not resolve host`, `Failed to connect` ou un délai dépassé :
  internet, comme en section 1.

Vérifie l'empreinte, avec le sha256 du message et deux espaces avant `pack.zip` :

```
cd '<dossier>' && echo '<sha256 du message>  pack.zip' | sha256sum -c
```

- `pack.zip: OK` : continue.
- `pack.zip: FAILED` : le fichier reçu n'est pas celui que Denis a publié. N'installe
  rien. Relance le téléchargement une fois ; si l'empreinte diffère encore, supprime le
  dossier, puis dis-lui de prévenir Denis.

Ouvre l'archive :

```
cd '<dossier>' && python3 -I -m zipfile -e pack.zip . && ls
```

La commande liste `dirfyn-<version>` et `pack.zip`, où `<version>` est celle du message.
Si le dossier porte une autre version, n'installe rien et dis-lui de prévenir Denis.

Copie l'outil dans `~/Dirfyn/outil`, compare la copie à l'archive, et pose `VERSION` en
dernier : tant qu'il manque, l'outil n'est pas installé.

```
cd '<dossier>' && mv dirfyn-<version>/VERSION VERSION && mkdir -p ~/mnt/Dirfyn/outil && cp -R dirfyn-<version>/. ~/mnt/Dirfyn/outil/ && diff -r -x VERSION -x .DS_Store dirfyn-<version> ~/mnt/Dirfyn/outil && cp VERSION ~/mnt/Dirfyn/outil/VERSION && echo installé
```

- `installé` : l'outil est en place.
- Sinon, la copie s'est interrompue : supprime le dossier, puis reprends depuis
  `mktemp -d`, la copie écrit par-dessus. Si elle échoue encore, dis-lui de prévenir
  Denis en lui donnant le message.

Puis, que l'installation ait réussi ou non, supprime le dossier temporaire :

```
rm -rf '<dossier>'
```

## 5. Le dossier du client

```
ls ~/mnt
```

L'outil lit le dossier du client depuis le shell, et le shell ne lit pas un fichier
OneDrive qui n'est qu'en ligne. Deux gestes, que tu guides :

- **Attacher le dossier du client au projet**, si `ls ~/mnt` ne montre que `Dirfyn` :
  dans Cowork, depuis le sélecteur de dossiers du projet, il ajoute le dossier OneDrive
  du client.
- **Le garder sur le Mac** : dans le Finder, il fait un clic droit sur le dossier du
  client et choisit « Toujours conserver sur cet appareil », puis attend que OneDrive ait
  tout téléchargé. C'est obligatoire : sans cela, l'outil ne lit pas ces fichiers.

S'il vient d'attacher le dossier, dis-lui d'attendre quelques minutes, puis d'ouvrir une
nouvelle session de ce projet et d'y demander de vérifier le poste. Arrête-toi là. Si le
dossier était déjà attaché, passe à la section 6 dans cette session.

## 6. La vérification

Lis `~/mnt/Dirfyn/outil/SKILLS.md` et applique ses règles communes, puis lis
`~/mnt/Dirfyn/outil/skills/initialiser-poste/SKILL.md` et applique-le. Son bilan dit
si le poste est prêt ; c'est lui qui écrit la ligne du journal.
