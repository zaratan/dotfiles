#!/usr/bin/env python3
"""Pose ou efface un champ du board pour plusieurs issues, en GraphQL direct (une lecture du projet, une mutation par issue).
Usage : board-field.py <owner> <numéro de projet> <Champ> <valeur|clear> <issue>...
Champ à option unique (Status, Priorité) : la valeur est le nom de l'option. Champ numérique (Points) : un entier.
Pourquoi : `gh project item-edit --url` relit tous les items à chaque appel et épuise le quota GraphQL en points."""
import json, subprocess, sys, time

if len(sys.argv) < 6:
    print(__doc__); raise SystemExit(2)
OWNER, PROJECT, FIELD = sys.argv[1], int(sys.argv[2]), sys.argv[3]
value, numbers = sys.argv[4], [int(n) for n in sys.argv[5:]]


def gql(query, **vars):
    args = ["gh", "api", "graphql", "-f", f"query={query}"]
    for k, v in vars.items():
        args += ["-F" if isinstance(v, int) else "-f", f"{k}={v}"]
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        print("ERR", r.stderr.strip()[:200]); raise SystemExit(1)
    return json.loads(r.stdout)


project = gql("""query($o:String!,$n:Int!){ user(login:$o){ projectV2(number:$n){ id
  fields(first:30){ nodes{ ... on ProjectV2FieldCommon{ id name } ... on ProjectV2SingleSelectField{ id name options{ id name } } } } } } }""", o=OWNER, n=PROJECT)["data"]["user"]["projectV2"]
pid = project["id"]
field = next(f for f in project["fields"]["nodes"] if f.get("name") == FIELD)
items, cursor = {}, None
while True:
    page = gql("""query($o:String!,$n:Int!,$a:String){ user(login:$o){ projectV2(number:$n){ items(first:100, after:$a){ pageInfo{ hasNextPage endCursor } nodes{ id content{ ... on Issue{ number } } } } } } }""", o=OWNER, n=PROJECT, **({"a": cursor} if cursor else {}))["data"]["user"]["projectV2"]["items"]
    for it in page["nodes"]:
        if it["content"] and "number" in it["content"]:
            items[it["content"]["number"]] = it["id"]
    if not page["pageInfo"]["hasNextPage"]:
        break
    cursor = page["pageInfo"]["endCursor"]

for n in numbers:
    item = items[n]
    if value == "clear":
        gql("""mutation($p:ID!,$i:ID!,$f:ID!){ clearProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f}){ projectV2Item{ id } } }""", p=pid, i=item, f=field["id"])
    elif "options" in field:
        oid = next(o["id"] for o in field["options"] if o["name"] == value)
        gql("""mutation($p:ID!,$i:ID!,$f:ID!,$o:String!){ updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{singleSelectOptionId:$o}}){ projectV2Item{ id } } }""", p=pid, i=item, f=field["id"], o=oid)
    else:
        gql("""mutation($p:ID!,$i:ID!,$f:ID!,$n:Float!){ updateProjectV2ItemFieldValue(input:{projectId:$p,itemId:$i,fieldId:$f,value:{number:$n}}){ projectV2Item{ id } } }""", p=pid, i=item, f=field["id"], n=int(value))
    print(f"#{n} {FIELD} → {value}")
    time.sleep(0.4)
