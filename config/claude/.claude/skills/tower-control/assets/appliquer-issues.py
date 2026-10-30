#!/usr/bin/env python3
"""Crée ou met à jour des issues GitHub depuis un dossier de fichiers Markdown, avec leurs champs de board.

Usage : appliquer-issues.py <owner> <numéro de projet> <owner/repo des issues> <dossier> [--dry-run]

Un fichier par issue, en-tête entre deux lignes `---` puis le corps :
  titre: ...                   obligatoire
  labels: bug, qualité         facultatif
  priorite: P2                 obligatoire (P0..P3)
  points: 3                    obligatoire (1 2 3 5 8 13), ou « parente » pour une issue mère sans points
  depot: platform              méta-dépôt : préfixe « [platform] », ligne « **Dépôt.** platform », label « dépôt: platform »
  parente: 240                 facultatif, numéro de l'issue mère (sous-issue native)
  jalon: Recette fin novembre  facultatif
  numero: 251                  écrit en retour après la création ; présent = mise à jour
  empreinte: <sha256>          écrit en retour ; si le corps GitHub a changé depuis, le fichier est sauté
Idempotent : relancer ne recrée rien. Pourquoi ce script : réécrit trois fois dans trois projets (210 lignes la
dernière), et `gh project item-edit --url` épuise le quota GraphQL dès une dizaine d'issues."""
import hashlib, json, pathlib, re, subprocess, sys, time

FIB = {"1", "2", "3", "5", "8", "13"}


def run(*args, **kw):
    r = subprocess.run(args, capture_output=True, text=True, **kw)
    if r.returncode != 0:
        sys.exit(f"ERREUR {' '.join(args[:3])}… : {r.stderr.strip()[:300]}")
    return r.stdout


def gql(query, **vars):
    args = ["gh", "api", "graphql", "-f", f"query={query}"]
    for k, v in vars.items():
        args += ["-F" if isinstance(v, int) else "-f", f"{k}={v}"]
    return json.loads(run(*args))["data"]


def lire(path):
    texte = path.read_text(encoding="utf-8")
    m = re.match(r"^---\n(.*?)\n---\n(.*)$", texte, re.S)
    if not m:
        sys.exit(f"{path.name} : pas d'en-tête ---")
    tete = {}
    for ligne in m.group(1).splitlines():
        if ":" in ligne:
            k, v = ligne.split(":", 1)
            tete[k.strip()] = v.strip()
    corps = m.group(2).strip() + "\n"
    for k in ("titre", "priorite", "points"):
        if k not in tete:
            sys.exit(f"{path.name} : « {k} » manquant")
    if tete["priorite"] not in {"P0", "P1", "P2", "P3"}:
        sys.exit(f"{path.name} : priorité {tete['priorite']} hors P0..P3")
    if tete["points"] not in FIB | {"parente"}:
        sys.exit(f"{path.name} : points {tete['points']} hors de la suite 1 2 3 5 8 13")
    return tete, corps


def ecrire(path, tete, corps):
    entete = "\n".join(f"{k}: {v}" for k, v in tete.items())
    path.write_text(f"---\n{entete}\n---\n{corps}", encoding="utf-8")


def sha(texte):
    return hashlib.sha256(texte.replace("\r\n", "\n").strip().encode()).hexdigest()


def titre_et_corps(tete, corps):
    titre, texte = tete["titre"], corps
    if d := tete.get("depot"):
        titre = f"[{d}] {titre}"
        texte = f"**Dépôt.** {d}\n\n{corps}"
    return titre, texte


def labels(tete):
    out = [l.strip() for l in tete.get("labels", "").split(",") if l.strip()]
    if d := tete.get("depot"):
        out.append(f"dépôt: {d}")
    return out


class Board:
    def __init__(self, owner, numero):
        q = """query($o:String!,$n:Int!){ %s(login:$o){ projectV2(number:$n){ id
          fields(first:30){ nodes{ ... on ProjectV2FieldCommon{ id name } ... on ProjectV2SingleSelectField{ id name options{ id name } } } } } } }"""
        for genre in ("user", "organization"):
            try:
                p = gql(q % genre, o=owner, n=numero)[genre]["projectV2"]
                break
            except SystemExit:
                p = None
        if not p:
            sys.exit(f"projet {numero} introuvable chez {owner}")
        self.id, self.champs = p["id"], {f["name"]: f for f in p["fields"]["nodes"] if f}

    def ajouter(self, owner, url):
        return json.loads(run("gh", "project", "item-add", str(PROJET), "--owner", owner, "--url", url, "--format", "json"))["id"]

    def poser(self, item, nom, valeur):
        champ = self.champs[nom]
        if "options" in champ:
            oid = next(o["id"] for o in champ["options"] if o["name"] == valeur)
            gql("""mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){ updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){ projectV2Item{ id } } }""",
                p=self.id, i=item, f=champ["id"], o=oid)
        else:
            gql("""mutation($p:ID!,$i:ID!,$f:ID!,$n:Float!){ updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{number:$n}}){ projectV2Item{ id } } }""",
                p=self.id, i=item, f=champ["id"], n=int(valeur))
        time.sleep(0.3)


if len(sys.argv) < 5:
    sys.exit(__doc__)
OWNER, PROJET, REPO, DOSSIER = sys.argv[1], int(sys.argv[2]), sys.argv[3], pathlib.Path(sys.argv[4])
DRY = "--dry-run" in sys.argv
fichiers = sorted(DOSSIER.glob("*.md"))
if not fichiers:
    sys.exit(f"aucun fichier .md dans {DOSSIER}")
plans = [(f, *lire(f)) for f in fichiers]
if DRY:
    for f, tete, corps in plans:
        titre, _ = titre_et_corps(tete, corps)
        action = f"mettre à jour #{tete['numero']}" if "numero" in tete else "créer"
        print(f"{f.name}: {action} « {titre} » labels={labels(tete)} prio={tete['priorite']} pts={tete['points']}"
              + (f" parente=#{tete['parente']}" if "parente" in tete else "") + (f" jalon={tete['jalon']}" if "jalon" in tete else ""))
    sys.exit(0)

board = Board(OWNER, PROJET)
for f, tete, corps in plans:
    titre, texte = titre_et_corps(tete, corps)
    if "numero" in tete:
        n = tete["numero"]
        actuel = json.loads(run("gh", "issue", "view", n, "--repo", REPO, "--json", "body"))["body"]
        if tete.get("empreinte") and sha(actuel) not in (tete["empreinte"], sha(texte)):
            print(f"{f.name}: #{n} SAUTÉE, le corps a changé sur GitHub depuis l'export")
            continue
        if sha(actuel) != sha(texte):
            run("gh", "issue", "edit", n, "--repo", REPO, "--title", titre, "--body", texte)
            print(f"{f.name}: #{n} mise à jour")
        else:
            print(f"{f.name}: #{n} inchangée")
    else:
        args = ["gh", "issue", "create", "--repo", REPO, "--title", titre, "--body", texte]
        for l in labels(tete):
            args += ["--label", l]
        if j := tete.get("jalon"):
            args += ["--milestone", j]
        url = run(*args).strip().splitlines()[-1]
        n = url.rsplit("/", 1)[-1]
        tete["numero"] = n
        item = board.ajouter(OWNER, url)
        board.poser(item, "Status", "Backlog")
        board.poser(item, "Priorité", tete["priorite"])
        if tete["points"] != "parente":
            board.poser(item, "Points", tete["points"])
        if p := tete.get("parente"):
            enfant = json.loads(run("gh", "api", f"repos/{REPO}/issues/{n}"))["id"]
            run("gh", "api", "-X", "POST", f"repos/{REPO}/issues/{p}/sub_issues", "-F", f"sub_issue_id={enfant}")
        print(f"{f.name}: #{n} créée au Backlog ({tete['priorite']}, {tete['points']} pts)")
    tete["empreinte"] = sha(texte)
    ecrire(f, tete, corps)
