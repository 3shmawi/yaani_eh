#!/usr/bin/env bash
# Publishes a demo's screenshots to the `demo-media` branch (one commit,
# through the GitHub API: no git credentials on disk) and prints them as a
# Markdown grid for the PR comment, so they show without downloading.
#   GH_TOKEN=… REPO=owner/name scripts/publish_demo_shots.sh <dir of .jpg> <path on the branch>
# The token needs `contents: write`. The branch is created empty (an orphan
# with a README) the first time; nothing runs on pushes to it.
set -euo pipefail
dir=$1
dest=$2
branch=demo-media
: "${REPO:?REPO=owner/name}"

files=()
for f in "$dir"/*.jpg; do [ -e "$f" ] && files+=("$f"); done
[ "${#files[@]}" -gt 0 ] || { echo "No screenshots in $dir." >&2; exit 0; }

api() { gh api "repos/$REPO/$1" "${@:2}"; }

if ! head=$(api "git/ref/heads/$branch" --jq .object.sha 2>/dev/null); then
  readme=$(jq -n '{tree: [{path: "README.md", mode: "100644", type: "blob",
    content: "Screenshots from the Demo video workflow, one folder per PR. Safe to prune.\n"}]}')
  tree=$(printf '%s' "$readme" | api git/trees --input - --jq .sha)
  head=$(jq -n --arg t "$tree" '{message: "Demo screenshots", tree: $t}' |
    api git/commits --input - --jq .sha)
  jq -n --arg s "$head" --arg r "refs/heads/$branch" '{ref: $r, sha: $s}' |
    api git/refs --input - >/dev/null
fi

entries='[]'
for f in "${files[@]}"; do
  blob=$(jq -n --rawfile c <(base64 < "$f" | tr -d '\n') '{content: $c, encoding: "base64"}' |
    api git/blobs --input - --jq .sha)
  entries=$(jq --arg p "$dest/$(basename "$f")" --arg s "$blob" \
    '. + [{path: $p, mode: "100644", type: "blob", sha: $s}]' <<<"$entries")
done

# Another PR may publish at the same time: re-read the head and retry.
for attempt in 1 2 3; do
  base_tree=$(api "git/commits/$head" --jq .tree.sha)
  tree=$(jq -n --arg b "$base_tree" --argjson e "$entries" '{base_tree: $b, tree: $e}' |
    api git/trees --input - --jq .sha)
  commit=$(jq -n --arg t "$tree" --arg p "$head" --arg m "Screenshots: $dest" \
    '{message: $m, tree: $t, parents: [$p]}' | api git/commits --input - --jq .sha)
  if jq -n --arg s "$commit" '{sha: $s, force: false}' |
    api "git/refs/heads/$branch" -X PATCH --input - >/dev/null 2>&1; then
    break
  fi
  [ "$attempt" -lt 3 ] || { echo "Couldn't update $branch." >&2; exit 1; }
  sleep $((attempt * 2))
  head=$(api "git/ref/heads/$branch" --jq .object.sha)
done

# Three a row, in the order the demo took them.
echo "**Screens** (one per step of the demo; tap to enlarge)"
echo
echo "<table>"
for i in "${!files[@]}"; do
  if [ $((i % 3)) -eq 0 ]; then printf '<tr>'; fi
  name=$(basename "${files[$i]}")
  printf '<td><img src="https://github.com/%s/blob/%s/%s/%s?raw=true" width="240" alt="Step %d"></td>' \
    "$REPO" "$branch" "$dest" "$name" $((i + 1))
  if [ $((i % 3)) -eq 2 ]; then printf '</tr>\n'; fi
done
if [ $(( ${#files[@]} % 3 )) -ne 0 ]; then printf '</tr>\n'; fi
echo "</table>"
