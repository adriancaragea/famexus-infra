#!/usr/bin/env bash
# Clones every Famexus repo next to this one. Usage: ./scripts/clone-all.sh [github-owner]
set -euo pipefail

cd "$(dirname "$0")/../.."
[ -f famexus-infra/.env ] && set -a && . famexus-infra/.env && set +a
owner="${1:-${GITHUB_OWNER:-adriancaragea}}"

for repo in famexus-web famexus-gateway famexus-todo famexus-calendar wallit; do
  if [ -d "$repo/.git" ]; then
    echo "✓ $repo already cloned"
  else
    git clone "git@github.com:$owner/$repo.git"
  fi
done
