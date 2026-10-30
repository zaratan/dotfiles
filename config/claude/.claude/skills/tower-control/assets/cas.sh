#!/usr/bin/env bash
# cas.sh <dépôt des issues> : les sections de references/cas.md à lire pour ce poste et ce projet, détectées sans
# jugement (système, forge, LFS, verrou de mesure). Rien d'imprimé quand aucune ne s'applique. Lecture seule.
set -euo pipefail

REPO=${1:?usage: cas.sh <dépôt des issues>}
# shellcheck source=config-lib.sh
source "$(dirname "$0")/config-lib.sh"

depots=("$REPO"); for p in "${REPO_PATH[@]}"; do depots+=("$p"); done
[ "$(uname -s)" != Linux ] || echo "- Hôte Linux : references/cas.md « Hôte Linux »"
hote_de() {
  local url=$1 h
  case "$url" in
    *://*) h=${url#*://}; h=${h%%/*}; h=${h#*@} ;;
    *:*) h=${url%%:*}; h=${h#*@} ;;
    *) h=$url ;;
  esac
  ssh -G "$h" 2>/dev/null | awk '/^hostname /{print $2; exit}' || echo "$h"
}
for d in "${depots[@]}"; do
  url=$(git -C "$d" remote get-url origin 2>/dev/null || true)
  [ -n "$url" ] || continue
  case "$(hote_de "$url")" in *github.com*) ;; *) echo "- Forge hors GitHub ($url) : references/cas.md « Forge hors GitHub »"; break ;; esac
done
for d in "${depots[@]}"; do
  if git -C "$d" ls-files -z -- '.gitattributes' '*/.gitattributes' 2>/dev/null | xargs -0 grep -ls 'filter=lfs' >/dev/null 2>&1; then
    echo "- Fichiers en LFS dans $d : references/cas.md « Données hors git »"; break
  fi
done
[ ! -f "${WORKTREES_DIR:-/nonexistent}/MESURES.md" ] || echo "- MESURES.md présent : references/cas.md « Plusieurs agents mesurent »"
