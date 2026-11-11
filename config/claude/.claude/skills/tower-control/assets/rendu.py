#!/usr/bin/env python3
"""rendu.py <transcript.jsonl> <sortie.md> <titre> [ligne sous le titre] : écrit le dernier rendu d'un sous-agent (SubagentHandback, sinon son dernier texte)."""
import json, sys

if len(sys.argv) < 4:
    sys.exit(__doc__)
src, out, titre = sys.argv[1:4]
chapeau = sys.argv[4] if len(sys.argv) > 4 else ""
try:
    lignes = open(src, encoding="utf-8", errors="replace").readlines()
except OSError as e:
    sys.exit(f"transcript illisible : {e}")
handback, dernier_texte = None, None
for ligne in lignes:
    try:
        o = json.loads(ligne)
    except ValueError:
        continue
    m = o.get("message") or {}
    if m.get("role") != "assistant" or not isinstance(m.get("content"), list):
        continue
    for b in m["content"]:
        if b.get("type") == "tool_use" and "andback" in b.get("name", ""):
            textes = [v for v in (b.get("input") or {}).values() if isinstance(v, str)]
            handback = max(textes, key=len, default=None) or handback
        elif b.get("type") == "text" and b.get("text", "").strip():
            dernier_texte = b["text"]
corps = handback or dernier_texte
if not corps:
    sys.exit("aucun rendu trouvé")
try:
    with open(out, "w", encoding="utf-8") as f:
        f.write(f"# {titre}\n\n" + (f"{chapeau}\n\n" if chapeau else "") + corps.strip() + "\n")
except OSError as e:
    sys.exit(f"sortie impossible : {e}")
print(out.rsplit("/", 1)[-1], len(corps), "signes", corps.count("\n") + 1, "lignes", "handback" if handback else "texte")
