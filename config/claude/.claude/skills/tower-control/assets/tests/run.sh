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
mkdir -p "$T/wts/g/apps/api/node_modules"; echo x > "$T/wts/g/apps/api/node_modules/m.js"; echo secret > "$T/wts/g/.env"
printf 'out.bin\nnode_modules/\n.env\n' > "$T/wts/g/.gitignore"; git -C "$T/wts/g" -c user.name=t -c user.email=t@t commit -qam ignore2
out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger refuse un .env hors RANGER_IGNORE" "$?" 3
check "ranger ne compte pas un node_modules de sous-dossier" "$(echo "$out" | grep -c node_modules)" 0
echo "RANGER_IGNORE='^\\.env\$'" >> "$T/wt/.claude/tower-control/config.sh"
out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger passe un .env listé dans RANGER_IGNORE" "$?" 0
echo "" > "$FAKE/merged"; out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run --sans-pr 2>&1); check "ranger --sans-pr passe sans PR" "$?" 0
out=$("$ASSETS/ranger.sh" "$T/wt" g --zz 2>&1); check "ranger refuse une option inconnue" "$?" 2
out=$(cd "$T/wt" && "$ASSETS/ranger.sh" . g --dry-run --sans-pr 2>&1); check "ranger nomme l'agent depuis le chemin absolu" "$(echo "$out" | grep -c 'agent get wt-g')" 1
out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger refuse une branche hors base sans PR" "$?" 3
git -C "$T/wt" -c user.name=t -c user.email=t@t merge -q --no-ff issue/2 -m train; git -C "$T/wt" push -q origin main 2>/dev/null
out=$("$ASSETS/ranger.sh" "$T/wt" g --dry-run 2>&1); check "ranger passe une branche contenue dans la base" "$?" 0
check "ranger dit la branche mergée par un train" "$(echo "$out" | grep -c 'contenue dans')" 1

# --- train.sh : dépôt unique jetable, train poussé, faux gh et faux python3 (board-field)
git init -q --bare "$T/o2.git"; git clone -q "$T/o2.git" "$T/m2" 2>/dev/null
for kv in user.name=t user.email=t@t commit.gpgsign=false; do git -C "$T/m2" config "${kv%%=*}" "${kv#*=}"; done
git -C "$T/m2" checkout -q -b main 2>/dev/null || true
echo a > "$T/m2/a.txt"; git -C "$T/m2" add -A; git -C "$T/m2" commit -qm init; git -C "$T/m2" push -q origin main 2>/dev/null
git -C "$T/m2" push -q origin main:refs/heads/train/16-ds 2>/dev/null
mkdir -p "$T/m2/.claude/tower-control" "$T/wts2" "$FAKE/py"
printf 'ISSUES_REPO="o/m2"\nPROJECT_OWNER="o"\nPROJECT_NUMBER=1\nWORKTREES_DIR="%s"\nBASE_BRANCH="origin/main"\nREFS_INTERDITES="secret-prive"\n' "$T/wts2" > "$T/m2/.claude/tower-control/config.sh"
echo "VERIF=\$'build: echo construit\ntest: echo Tests 3 passed\ne2e: echo 2 passed'" >> "$T/m2/.claude/tower-control/config.sh"
printf 'declare -A GRAPPES=([ds]="issue/10")\n' > "$T/m2/.claude/tower-control/lot-moi.sh"
git -C "$T/m2" fetch -q origin; git -C "$T/m2" worktree add -q -b issue/10 "$T/wts2/ds" origin/train/16-ds 2>/dev/null
git -C "$T/wts2/ds" branch -q --unset-upstream 2>/dev/null || true
printf '#!/usr/bin/env bash\necho "python3 $*" >> "$FAKE/journal"\n' > "$FAKE/py/python3"; chmod +x "$FAKE/py/python3"
printf '#!/bin/sh\nexit 1\n' > "$(git -C "$T/m2" rev-parse --path-format=absolute --git-common-dir)/hooks/pre-push"; chmod +x "$(git -C "$T/m2" rev-parse --path-format=absolute --git-common-dir)/hooks/pre-push"
porter() { TRAIN_PAUSE=0 PATH="$FAKE/py:$PATH" "$ASSETS/train.sh" "$T/m2" ds 10 "$@" 2>&1; }
lignes() { grep -c "^| #10 |" "$T/m2/.claude/tower-control/lot-16/trains.md"; }
out=$(porter train/16-ds "Un titre" --dry-run); check "train refuse un arbre sans travail" "$?" 3
echo b > "$T/wts2/ds/b.txt"
out=$(porter train/ds "Un titre" --dry-run); check "train refuse un train sans numéro de lot" "$?" 3
out=$(porter train/16-ds "$(printf 'x%.0s' {1..101})" --dry-run); check "train refuse un titre de 101 caractères" "$?" 3
out=$(porter train/16-zz "Un titre" --dry-run); check "train refuse un train absent d'origin" "$?" 3
check "train donne la commande qui crée le train" "$(echo "$out" | grep -c 'push origin refs/remotes/origin/main:refs/heads/train/16-zz')" 1
echo "voir secret-prive" > "$T/wts2/ds/c.txt"; out=$(porter train/16-ds "Un titre" --dry-run); check "train refuse une référence interdite non suivie" "$?" 3
rm "$T/wts2/ds/c.txt"; echo "secret-prive" >> "$T/wts2/ds/a.txt"; out=$(porter train/16-ds "Un titre" --dry-run); check "train refuse une référence interdite suivie" "$?" 3
git -C "$T/wts2/ds" checkout -q -- a.txt; out=$(porter train/16-ds "Titre secret-prive" --dry-run); check "train refuse une référence interdite dans le titre" "$?" 3
out=$(porter train/16-ds "Un titre" --dry-run); check "train dry-run" "$?" 0
check "train dry-run ne commite pas" "$(git -C "$T/wts2/ds" log -1 --format=%s)" init
: > "$FAKE/journal"; out=$(porter train/16-ds "Un titre"); check "train porte l'issue malgré un hook pre-push rouge" "$?" 0
git -C "$T/m2" ls-remote --exit-code --heads origin issue/10 >/dev/null; check "train : branche d'issue sur origin" "$?" 0
git -C "$T/wts2/ds" push -q origin HEAD:refs/heads/essai-hook 2>/dev/null; check "le hook pre-push du banc refuse un push ordinaire" "$?" 1
check "train : base intacte" "$(git -C "$T/m2" ls-remote origin refs/heads/main | cut -f1)" "$(git -C "$T/m2" rev-parse origin/main)"
check "train : PR vers le train" "$(grep -c 'pr create.*--base train/16-ds --head issue/10' "$FAKE/journal")" 1
check "train : merge commit au sujet neutre" "$(grep -c "pr merge 55 .*--merge --subject Merge branch 'issue/10'" "$FAKE/journal")" 1
check "train : issue en Review" "$(grep -c 'board-field.py o 1 Status Review 10' "$FAKE/journal")" 1
check "train : ligne du lot avec le push sans hook" "$(grep -c '^| #10 .*| --no-verify |$' "$T/m2/.claude/tower-control/lot-16/trains.md")" 1
git -C "$T/m2" push -q --no-verify origin issue/10:train/16-ds 2>/dev/null; git -C "$T/m2" fetch -q origin
echo "55 MERGED" > "$FAKE/pr_train"; : > "$FAKE/journal"; out=$(porter train/16-ds "Un titre"); check "train rejoue une PR déjà mergée" "$?" 0
check "train ne rouvre pas de PR" "$(grep -c 'pr create' "$FAKE/journal")" 0
check "train n'écrit pas deux fois la ligne" "$(lignes)" 1
echo fix > "$T/wts2/ds/fix.txt"; : > "$FAKE/journal"; out=$(porter train/16-ds "Correctif"); check "train porte un correctif après une PR mergée" "$?" 0
check "train ouvre une nouvelle PR pour le correctif" "$(grep -c 'pr create' "$FAKE/journal")" 1
check "train a commité le correctif" "$(git -C "$T/wts2/ds" status --short | wc -l | tr -d ' ')" 0
git -C "$T/m2" push -q --no-verify origin issue/10:train/16-ds 2>/dev/null
git -C "$T/m2" fetch -q origin; git -C "$T/m2" checkout -q --detach origin/train/16-ds
echo t > "$T/m2/t.txt"; git -C "$T/m2" add t.txt; git -C "$T/m2" commit -qm autre; git -C "$T/m2" push -q --no-verify origin HEAD:refs/heads/train/16-ds; git -C "$T/m2" checkout -q main
: > "$FAKE/pr_train"; echo d > "$T/wts2/ds/d.txt"
out=$(porter train/16-ds "Deux"); check "train refuse une branche en retard sur le train" "$?" 3
git -C "$T/wts2/ds" fetch -q origin; git -C "$T/wts2/ds" merge -q --no-edit origin/train/16-ds
echo CONFLICTING > "$FAKE/pr_vue"; out=$(porter train/16-ds "Deux"); check "train refuse une PR en conflit" "$?" 3
echo "55 OPEN" > "$FAKE/pr_train"; rm -f "$FAKE/pr_vue"; echo 2 > "$FAKE/pr_checks"
out=$(porter train/16-ds "Deux"); check "train refuse une PR vers le train qui a des checks" "$?" 3
check "train renvoie les checks à l'utilisateur" "$(echo "$out" | grep -c "À revoir avec l'utilisateur")" 1
check "train reprend un commit déjà fait" "$(echo "$out" | grep -c 'déjà faits')" 1
rm -f "$FAKE/pr_checks"; echo UNKNOWN > "$FAKE/pr_vue"; out=$(porter train/16-ds "Deux"); check "train ne merge pas une PR à l'état inconnu" "$?" 1
rm -f "$FAKE/pr_vue"; echo OPEN > "$FAKE/pr_etat"; out=$(porter train/16-ds "Deux"); check "train dit une PR restée non mergée" "$?" 1
rm -f "$FAKE/pr_etat"; : > "$FAKE/journal"
git -C "$T/wts2/ds" merge -q --no-edit origin/train/16-ds 2>/dev/null; out=$(porter train/16-ds "Deux"); check "train reprend après une fusion du train" "$?" 0
check "train reprend la PR ouverte" "$(grep -c 'pr create' "$FAKE/journal")" 0
echo e > "$T/wts2/ds/e.txt"; out=$(porter train/16-ds "Deux"); check "train refuse un second commit au même titre" "$?" 3
rm "$T/wts2/ds/e.txt"; : > "$FAKE/pr_train"
git -C "$T/wts2/ds" switch -q -c train/16-ds; out=$(porter train/16-ds "Trois" --dry-run); check "train refuse HEAD sur le train" "$?" 3
git -C "$T/wts2/ds" switch -q issue/10

# --- verif-train.sh
verifier() { JOURNAUX="$T/j" "$ASSETS/verif-train.sh" "$T/m2" _ verif-1 "$@" 2>&1; }
out=$(JOURNAUX="$T/j" "$ASSETS/verif-train.sh" "$T/m2" _ ds train/16-ds 2>&1); check "verif refuse un worktree qui n'est pas verif-*" "$?" 3
out=$(verifier train/16-ds); check "verif refuse un worktree absent" "$?" 2
check "verif donne la commande de création" "$(echo "$out" | grep -c 'worktree add --detach')" 1
git -C "$T/m2" worktree add -q --detach "$T/wts2/verif-1" origin/main 2>/dev/null
out=$(verifier train/16-ds a.spec.ts --tout); check "verif refuse --tout avec des specs" "$?" 2
out=$(verifier train/16-ds); check "verif d'un train vert" "$?" 0
check "verif dit vert sans e2e" "$(echo "$out" | tail -1 | grep -c 'sans e2e$')" 1
check "verif compte les tests" "$(echo "$out" | grep -c 'test OK en .*3 passed')" 1
check "verif se détache sur le train" "$(git -C "$T/wts2/verif-1" rev-parse HEAD)" "$(git -C "$T/m2" rev-parse origin/train/16-ds)"
out=$(verifier train/16-ds a.spec.ts); check "verif avec des specs" "$?" 0
check "verif passe les specs à l'e2e" "$(grep -c 'a.spec.ts' "$T/j/verif-1-e2e.log")" 1
out=$(verifier train/16-ds --tout); check "verif d'un convoi entier" "$?" 0
check "verif --tout joue l'e2e" "$(echo "$out" | grep -c '^e2e OK')" 1
out=$(verifier "$(git -C "$T/m2" rev-parse --short origin/main)"); check "verif d'un SHA présent sur origin" "$?" 0
git -C "$T/m2" branch -q train/16-local main; out=$(verifier train/16-local); check "verif refuse une branche absente d'origin" "$?" 3
git -C "$T/m2" checkout -q --detach main; echo l > "$T/m2/l.txt"; git -C "$T/m2" add l.txt; git -C "$T/m2" commit -qm local
out=$(verifier "$(git -C "$T/m2" rev-parse --short HEAD)"); check "verif refuse un SHA absent d'origin" "$?" 3
git -C "$T/m2" checkout -q main
out=$(verifier train/16-nope); check "verif refuse une réf inconnue" "$?" 3
git -C "$T/wts2/verif-1" switch -q -c tmp; out=$(verifier train/16-ds); check "verif refuse un worktree à branche" "$?" 3
git -C "$T/wts2/verif-1" checkout -q --detach; git -C "$T/m2" branch -q -D tmp
echo f > "$T/wts2/verif-1/f.txt"; git -C "$T/wts2/verif-1" add f.txt; git -C "$T/wts2/verif-1" commit -qm local
out=$(verifier train/16-ds); check "verif refuse un commit absent d'origin" "$?" 3
git -C "$T/wts2/verif-1" checkout -q --detach origin/main
mkdir "$(git -C "$T/wts2/verif-1" rev-parse --absolute-git-dir)/verif-train.lock"
out=$(verifier train/16-ds); check "verif refuse une seconde vérification en cours" "$?" 3
rmdir "$(git -C "$T/wts2/verif-1" rev-parse --absolute-git-dir)/verif-train.lock"
echo "VERIF='test: echo Tests 0 passed'" >> "$T/m2/.claude/tower-control/config.sh"
out=$(verifier train/16-ds); check "verif rouge sur 0 test passé" "$?" 1
echo "VERIF=\$'build: false\ntest: echo 3 passed'" >> "$T/m2/.claude/tower-control/config.sh"
out=$(verifier train/16-ds); check "verif rouge sur une étape en échec" "$?" 1
check "verif s'arrête à l'étape rouge" "$(echo "$out" | grep -c '^test ')" 0
echo "VERIF='test: echo rien'" >> "$T/m2/.claude/tower-control/config.sh"
out=$(verifier train/16-ds); check "verif rouge sur des tests qui ne comptent rien" "$?" 1
echo "VERIF='test: echo 3 passed 1 failed'" >> "$T/m2/.claude/tower-control/config.sh"
out=$(verifier train/16-ds); check "verif rouge sur un test en échec en sortie 0" "$?" 1
echo "VERIF='test: sleep 47.$$; echo 3 passed'" >> "$T/m2/.claude/tower-control/config.sh"
JOURNAUX="$T/j" "$ASSETS/verif-train.sh" "$T/m2" _ verif-1 train/16-ds >/dev/null 2>&1 & vpid=$!
for _ in 1 2 3 4 5 6 7 8 9 10; do pgrep -f "sleep 47.$$" >/dev/null && break; sleep 0.3; done
kill -TERM "$vpid"; wait "$vpid"; check "verif tuée sort en 143" "$?" 143
sleep 0.3; check "verif tuée arrête son étape" "$(pgrep -fc "sleep 47.$$")" 0
check "verif tuée rend le verrou" "$(test -e "$(git -C "$T/wts2/verif-1" rev-parse --absolute-git-dir)/verif-train.lock"; echo $?)" 1

# --- appliquer-issues.py --dry-run (aucun appel à gh)
: > "$FAKE/journal"
out=$(python3 -I "$ASSETS/../../tc-commun/appliquer-issues.py" o 1 o/r "$ASSETS/tests/issues" --dry-run); check "appliquer dry-run" "$?" 0
check "appliquer dry-run annonce la création préfixée" "$(echo "$out" | grep -c 'créer « \[app\] Le compteur')" 1
check "appliquer dry-run n'appelle pas gh" "$(wc -l < "$FAKE/journal" | tr -d ' ')" 0
out=$(python3 -I "$ASSETS/../../tc-commun/appliquer-issues.py" o 1 o/r "$ASSETS/tests/issues-fausse" --dry-run 2>&1); check "appliquer refuse 4 points" "$?" 1

echo "$ok OK, $ko KO"; [ "$ko" = 0 ]
