#!/usr/bin/env bash
# Prints the current Secure Score and the top open recommendations.
set -euo pipefail

QUERY_DIR="$(cd "$(dirname "$0")/../queries" && pwd)"

run_query () {
  # Reads a .kql file, drops comment lines, and runs it with Resource Graph.
  local file="$1"
  local query
  query="$(grep -v '^\s*//' "${file}")"
  az graph query -q "${query}" --first 1000 --query "data" --output table
}

echo "== Secure Score"
run_query "${QUERY_DIR}/secure-score.kql"

echo
echo "== Where the missing points are"
run_query "${QUERY_DIR}/score-by-control.kql"

echo
echo "== Open recommendations"
run_query "${QUERY_DIR}/open-recommendations.kql"
