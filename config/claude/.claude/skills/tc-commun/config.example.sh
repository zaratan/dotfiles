# shellcheck shell=bash disable=SC2034
# Exemple de .claude/tower-control/config.sh : les faits du projet, versionné quand le dépôt est privé.
# Lu par config-lib.sh, donc par tous les scripts de tower-control/assets/. REPO (chemin du dépôt des issues) est posé avant.

# Dépôt unique : issues, board et code au même endroit.
ISSUES_REPO="owner/monprojet"
PROJECT_OWNER="owner"
PROJECT_NUMBER=1
WORKTREES_DIR="$HOME/Projects/monprojet-wt"
BASE_BRANCH="origin/main"                     # les branches d'issue en partent ; git fetch avant de lancer
BOOTSTRAP='pnpm install --frozen-lockfile'    # joué dans le worktree neuf, dans le pane de l'agent
declare -A REPO_CHECK=([_]='test -d node_modules')   # contrôle de l'amorçage ; `_` est la clé du dépôt unique
PROD_START='pnpm build && pnpm start'          # pour demarrer-prod.sh
# RANGER_IGNORE='^\.env$|^certs/'             # ERE : ignorés propres au projet que ranger.sh ne compte pas comme sorties
# MODEL="claude-opus-5-5"                      # modèle des agents, défaut dans lancer.sh
# BOOTSTRAP_TIMEOUT=900000                     # ms

# Méta-dépôt : les issues ici, le code dans des sous-dépôts, chacun avec sa branche de base et son amorçage.
# WORKTREES_DIR="$REPO/wt"                     # sous le méta (wt/ dans son .gitignore) : l'agent démarre à la racine du méta
# declare -A REPO_PATH=([app]="$HOME/Projects/meta/app" [infra]="$HOME/Projects/meta/infra")
# declare -A REPO_BASE=([app]="origin/develop" [infra]="main")
# declare -A REPO_BOOTSTRAP=([app]='pnpm install --frozen-lockfile' [infra]='true')
# declare -A REPO_CHECK=([app]='test -d node_modules')
# declare -A REPO_PROD_START=([app]='pnpm build && pnpm start')

# Trains et convois (tower-control/references/trains.md). verif-train.sh joue ces étapes dans l'ordre, une ligne
# `nom: commande` chacune, la remise à zéro de la base en tête ; l'étape `e2e` reçoit les specs. Une étape test… ou
# e2e… est rouge sur une sortie non nulle, et aussi quand elle n'affiche pas VERIF_PASSE.
# VERIF=$'install: pnpm install --frozen-lockfile\ndb: bin/db-reset\nbuild: pnpm build\nlint: pnpm lint\ntest: pnpm test\ne2e: pnpm exec playwright test'
# declare -A REPO_VERIF=([app]=$'install: pnpm install --frozen-lockfile\ntest: pnpm test')   # méta-dépôt
# VERIF_PASSE='[1-9][0-9]* passed'             # défaut, « 0 passed » est rouge ; `go test` n'imprime pas « passed » : '^ok '
# REFS_INTERDITES='monprojet-prive|Claude'     # ERE refusée par train.sh dans le diff et le titre ; défaut en méta : le nom du dépôt des issues

# Les grappes du lot vont dans lot-<login GitHub>.sh, à côté, ignoré par git (propre à la personne et au poste) :
#   declare -A GRAPPES=([p0-controle]="p0/4-couleur" [p0-photos]="p0/5-credit")          # dépôt unique
#   declare -A GRAPPES=([irn]="app p0/2-echelle" [keys]="infra p1/62-cles")              # méta-dépôt
#   REPO_PATH[app]="$HOME/code/app"      # correction de poste, élément par élément : un `declare -A` effacerait les autres
#   declare -A ISSUES=([p0-controle]="4" [p0-photos]="5")   # issue en cours par grappe, tenue par la tour (avancement.sh)
