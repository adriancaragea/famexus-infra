#!/usr/bin/env bash
# Pulls the checked-out branch of every Famexus repo. Fast-forward only, so it
# never creates a merge commit. Repos with uncommitted changes, missing repos
# and branches with no upstream are skipped and reported.
# Exits 1 if any pull failed; skipped repos don't count as failures.
#
# Usage: ./scripts/pull-all.sh
set -euo pipefail

for arg in "$@"; do
  case "$arg" in
    -h|--help) sed -n '2,7p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "Unknown option: $arg (see --help)" >&2; exit 1 ;;
  esac
done

cd "$(dirname "$0")/../.."

pulled=0
current=0
skipped=0
failed=0

skip() {
  echo "- $1: skipped, $2"
  skipped=$((skipped + 1))
}

# famexus-infra goes last: pulling it can rewrite this script while bash is still reading it.
for repo in famexus-web famexus-gateway famexus-todo famexus-calendar wallit famexus-docs famexus-infra; do
  if [ ! -d "$repo/.git" ]; then
    skip "$repo" "not cloned (run ./scripts/clone-all.sh)"
    continue
  fi

  if ! branch=$(git -C "$repo" symbolic-ref --short -q HEAD); then
    skip "$repo" "detached HEAD"
    continue
  fi

  # Untracked files don't count: git refuses the pull if one would be overwritten.
  if [ -n "$(git -C "$repo" status --porcelain --untracked-files=no)" ]; then
    skip "$repo ($branch)" "uncommitted changes"
    continue
  fi

  if ! git -C "$repo" rev-parse -q --verify '@{upstream}' >/dev/null 2>&1; then
    skip "$repo ($branch)" "no upstream branch"
    continue
  fi

  before=$(git -C "$repo" rev-parse HEAD)
  if ! output=$(git -C "$repo" pull --ff-only 2>&1); then
    echo "✗ $repo ($branch): pull failed"
    echo "$output" | sed 's/^/    /'
    failed=$((failed + 1))
    continue
  fi

  count=$(git -C "$repo" rev-list --count "$before..HEAD")
  if [ "$count" -eq 0 ]; then
    echo "✓ $repo ($branch): already up to date"
    current=$((current + 1))
  else
    echo "✓ $repo ($branch): pulled $count commit(s)"
    pulled=$((pulled + 1))
  fi
done

echo
echo "$pulled pulled, $current already up to date, $skipped skipped, $failed failed."
[ "$failed" -eq 0 ]
