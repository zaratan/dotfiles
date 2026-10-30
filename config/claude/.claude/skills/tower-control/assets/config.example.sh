# shellcheck shell=bash disable=SC2034
# Exemple de .claude/tower-control/config.sh : les faits du projet, versionné quand le dépôt est privé.
# Lu par config-lib.sh, donc par lancer.sh et demarrer-prod.sh. REPO (chemin du dépôt des issues) est posé avant.

# Dépôt unique : issues, board et code au même endroit.
ISSUES_REPO="owner/monprojet"
PROJECT_OWNER="owner"
PROJECT_NUMBER=1
WORKTREES_DIR="$HOME/Projects/monprojet-wt"
BASE_BRANCH="origin/main"                     # les branches d'issue en partent ; git fetch avant de lancer
BOOTSTRAP='pnpm install --frozen-lockfile'    # joué dans le worktree neuf, dans le pane de l'agent
declare -A REPO_CHECK=([_]='test -d node_modules')   # contrôle de l'amorçage ; `_` est la clé du dépôt unique
PROD_START='pnpm build && pnpm start'          # pour demarrer-prod.sh
# MODEL="claude-opus-5-5"                      # modèle des agents, défaut dans lancer.sh
# BOOTSTRAP_TIMEOUT=900000                     # ms

# Méta-dépôt : les issues ici, le code dans des sous-dépôts, chacun avec sa branche de base et son amorçage.
# WORKTREES_DIR="$REPO/wt"                     # sous le méta (wt/ dans son .gitignore) : l'agent démarre à la racine du méta
# declare -A REPO_PATH=([app]="$HOME/Projects/meta/app" [infra]="$HOME/Projects/meta/infra")
# declare -A REPO_BASE=([app]="origin/develop" [infra]="main")
# declare -A REPO_BOOTSTRAP=([app]='pnpm install --frozen-lockfile' [infra]='true')
# declare -A REPO_CHECK=([app]='test -d node_modules')
# declare -A REPO_PROD_START=([app]='pnpm build && pnpm start')

# Les grappes du lot vont dans lot-<login GitHub>.sh, à côté, ignoré par git (propre à la personne et au poste) :
#   declare -A GRAPPES=([p0-controle]="p0/4-couleur" [p0-photos]="p0/5-credit")          # dépôt unique
#   declare -A GRAPPES=([irn]="app p0/2-echelle" [keys]="infra p1/62-cles")              # méta-dépôt
#   REPO_PATH[app]="$HOME/code/app"      # correction de poste, élément par élément : un `declare -A` effacerait les autres
#   declare -A ISSUES=([p0-controle]="4" [p0-photos]="5")   # issue en cours par grappe, tenue par la tour (avancement.sh)
