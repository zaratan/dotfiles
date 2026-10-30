#!/usr/bin/env bash
# Banc des scripts : faux herdr et gh pilotés par des fichiers, vrais dépôts git jetables. `bash tests/run.sh` depuis assets/.
set -uo pipefail
ASSETS=$(cd "$(dirname "$0")/.." && pwd)
T=$(mktemp -d); trap 'rm -rf "$T"' EXIT
export FAKE="$T/fake"; mkdir -p "$FAKE/bin"
cp "$ASSETS/tests/fake-herdr" "$FAKE/bin/herdr"; cp "$ASSETS/tests/fake-gh" "$FAKE/bin/gh"; chmod +x "$FAKE/bin/"*
export PATH="$FAKE/bin:$PATH" HOME="$T/home"; mkdir -p "$HOME"
ok=0; ko=0
check() { if [ "$2" = "$3" ]; then ok=$((ok+1)); else ko=$((ko+1)); echo "KO $1 : attendu « $3 », obtenu « $2 »"; fi; }

# --- envoyer.sh
echo bonjour > "$T/c.md"
echo blocked > "$FAKE/etat"; out=$("$ASSETS/envoyer.sh" a1 "$T/c.md"); check "envoyer refuse blocked" "$?" 3
printf 'idle\nworking\n' > "$FAKE/etats"; : > "$FAKE/ecran"; out=$("$ASSETS/envoyer.sh" a1 "$T/c.md"); check "envoyer passe à working" "$?" 0
check "envoyer a bien prompté" "$(grep -c '^prompt a1 bonjour' "$FAKE/journal")" 1
printf 'idle\nidle\nidle\nidle\nidle\nidle\nidle\nidle\nidle\nworking\n' > "$FAKE/etats"; echo "Teach auto mode about your environment?" > "$FAKE/ecran"; : > "$FAKE/journal"
out=$("$ASSETS/envoyer.sh" a1 "$T/c.md"); check "envoyer ferme la boîte et renvoie" "$?" 0
check "envoyer a fait esc" "$(grep -c '^send-keys a1 esc' "$FAKE/journal")" 1
rm -f "$FAKE/etats"; echo nope > "$FAKE/etat"; out=$("$ASSETS/envoyer.sh" zz "$T/c.md" 2>/dev/null); check "envoyer agent introuvable" "$?" 2

# --- dépôts git jetables : origin nu, clone, branche d'issue
git init -q --bare "$T/origin.git"
git clone -q "$T/origin.git" "$T/wt" 2>/dev/null
git -C "$T/wt" -c user.name=t -c user.email=t@t config commit.gpgsign false
git -C "$T/wt" checkout -q -b main 2>/dev/null || true
echo a > "$T/wt/a.txt"; echo "l1" > "$T/wt/shared.txt"; git -C "$T/wt" add -A; git -C "$T/wt" -c user.name=t -c user.email=t@t commit -qm init; git -C "$T/wt" push -q origin main 2>/dev/null
# la base avance sur shared.txt
echo "l1 base" > "$T/wt/shared.txt"; git -C "$T/wt" -c user.name=t -c user.email=t@t commit -qam base; git -C "$T/wt" push -q origin main 2>/dev/null
git -C "$T/wt" reset -q --hard HEAD~1

# --- branche-suivante.sh
echo x > "$T/wt/sale.txt"; out=$("$ASSETS/branche-suivante.sh" "$T/wt" issue/1 origin/main); check "branche-suivante refuse un arbre sale" "$?" 3; rm "$T/wt/sale.txt"
out=$("$ASSETS/branche-suivante.sh" "$T/wt" issue/1 origin/main --dry-run); check "branche-suivante dry-run" "$?" 0
out=$("$ASSETS/branche-suivante.sh" "$T/wt" issue/1 origin/main); check "branche-suivante crée" "$?" 0
check "branche-suivante HEAD" "$(git -C "$T/wt" rev-parse --abbrev-ref HEAD)" issue/1
git -C "$T/wt" rev-parse --abbrev-ref '@{upstream}' >/dev/null 2>&1; check "branche-suivante sans amont" "$?" 128
check "branche-suivante part de la base distante" "$(git -C "$T/wt" rev-parse HEAD)" "$(git -C "$T/wt" rev-parse origin/main)"

# --- retard.sh : travail non commité en conflit avec la base
git -C "$T/wt" reset -q --hard origin/main~1
echo "l1 branche" > "$T/wt/shared.txt"
out=$("$ASSETS/retard.sh" "$T/wt" origin/main); check "retard voit le conflit non commité" "$?" 1
check "retard nomme le fichier" "$(echo "$out" | grep -c '^  shared.txt$')" 1
check "retard n'a pas touché l'index" "$(git -C "$T/wt" diff --cached --name-only | wc -l | tr -d ' ')" 0
echo "l1" > "$T/wt/shared.txt"; echo b > "$T/wt/b.txt"
out=$("$ASSETS/retard.sh" "$T/wt" origin/main); check "retard sans conflit avec un fichier nouveau" "$?" 0
check "retard compte le retard" "$(echo "$out" | grep -c '1 derrière')" 1

# --- pousser.sh
git -C "$T/wt" checkout -q -b issue/2 origin/main 2>/dev/null; git -C "$T/wt" branch -q --unset-upstream 2>/dev/null || true
rm -f "$T/wt/b.txt"
out=$("$ASSETS/pousser.sh" "$T/wt" origin/main --dry-run); check "pousser refuse HEAD égal à la base" "$?" 3
echo c > "$T/wt/c.txt"; git -C "$T/wt" add -A; git -C "$T/wt" -c user.name=t -c user.email=t@t commit -qm c
out=$("$ASSETS/pousser.sh" "$T/wt" origin/main --dry-run); check "pousser dry-run" "$?" 0
check "pousser refspec explicite" "$(echo "$out" | grep -c 'refs/heads/issue/2:refs/heads/issue/2')" 1
out=$("$ASSETS/pousser.sh" "$T/wt" origin/main 2>/dev/null); check "pousser pousse" "$?" 0
git -C "$T/wt" ls-remote --exit-code --heads origin issue/2 >/dev/null; check "pousser : branche sur origin" "$?" 0
check "pousser : main inchangée" "$(git -C "$T/wt" ls-remote origin refs/heads/main | cut -f1)" "$(git -C "$T/wt" rev-parse origin/main)"

# --- board.sh assigner (faux gh)
mkdir -p "$T/repo/.claude/tower-control"; printf 'ISSUES_REPO="o/r"\nPROJECT_OWNER="o"\nPROJECT_NUMBER=1\nWORKTREES_DIR="%s"\n' "$T/wts" > "$T/repo/.claude/tower-control/config.sh"
echo "moi" > "$FAKE/assignees"; out=$("$ASSETS/board.sh" assigner "$T/repo" 7); check "assigner seul" "$?" 0
echo "moi autre" > "$FAKE/assignees"; out=$("$ASSETS/board.sh" assigner "$T/repo" 7); check "assigner co-assignée se retire" "$?" 3
check "assigner a fait --remove-assignee" "$(grep -c 'remove-assignee' "$FAKE/journal")" 1
echo "" > "$FAKE/assignees"; out=$("$ASSETS/board.sh" assigner "$T/repo" 7); check "assigner n'a pas pris" "$?" 4

# --- ranger.sh --dry-run (faux gh : PR mergée ; vrai git, le clone est le dépôt des issues)
mkdir -p "$T/wts" "$T/wt/.claude/tower-control"
printf 'ISSUES_REPO="o/r"\nPROJECT_OWNER="o"\nPROJECT_NUMBER=1\nWORKTREES_DIR="%s"\n' "$T/wts" > "$T/wt/.claude/tower-control/config.sh"
printf 'declare -A GRAPPES=([g]="issue/2")\n' > "$T/wt/.claude/tower-control/lot-moi.sh"
git -C "$T/wt" checkout -q main; git -C "$T/wt" worktree add -q "$T/wts/g" issue/2 2>/dev/null
git -C "$T/wt" remote set-url origin "git@github.com:o/r.git"
echo "" > "$FAKE/merged"; out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger refuse sans PR mergée" "$?" 3
echo "12" > "$FAKE/merged"; echo proto > "$T/wts/g/out.bin"; echo 'out.bin' > "$T/wts/g/.gitignore"; git -C "$T/wts/g" add .gitignore; git -C "$T/wts/g" -c user.name=t -c user.email=t@t commit -qm ignore
out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger refuse un ignoré hors build" "$?" 3
rm "$T/wts/g/out.bin"; out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger dry-run passe" "$?" 0
check "ranger imprime la ligne de lot" "$(echo "$out" | grep -c 'GRAPPES\[g\]')" 1

# --- appliquer-issues.py --dry-run (aucun appel à gh)
: > "$FAKE/journal"
out=$(python3 -I "$ASSETS/../../tc-commun/appliquer-issues.py" o 1 o/r "$ASSETS/tests/issues" --dry-run); check "appliquer dry-run" "$?" 0
check "appliquer dry-run annonce la création préfixée" "$(echo "$out" | grep -c 'créer « \[app\] Le compteur')" 1
check "appliquer dry-run n'appelle pas gh" "$(wc -l < "$FAKE/journal" | tr -d ' ')" 0
out=$(python3 -I "$ASSETS/../../tc-commun/appliquer-issues.py" o 1 o/r "$ASSETS/tests/issues-fausse" --dry-run 2>&1); check "appliquer refuse 4 points" "$?" 1

echo "$ok OK, $ko KO"; [ "$ko" = 0 ]
