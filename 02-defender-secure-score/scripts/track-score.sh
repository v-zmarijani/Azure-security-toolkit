#!/usr/bin/env bash
# Appends today's Secure Score to a CSV, one line per subscription.
# Meant to run once a day from cron.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUT_DIR="${SCRIPT_DIR}/../output"
OUT_FILE="${OUT_DIR}/secure-score-history.csv"
mkdir -p "${OUT_DIR}"

query="$(grep -v '^\s*//' "${SCRIPT_DIR}/../queries/secure-score.kql")"

# Write a header the first time
if [[ ! -f "${OUT_FILE}" ]]; then
  echo "date,subscriptionId,current,max,percent" > "${OUT_FILE}"
fi

today="$(date +%Y-%m-%d)"

az graph query -q "${query}" --first 1000 \
  --query "data[].[subscriptionId, current, max, percent]" -o tsv |
while IFS=$'\t' read -r sub current max percent; do
  echo "${today},${sub},${current},${max},${percent}" >> "${OUT_FILE}"
done

echo "Saved to ${OUT_FILE}"
tail -n 5 "${OUT_FILE}"
