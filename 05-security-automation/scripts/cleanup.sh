#!/usr/bin/env bash
# Deletes everything deploy.sh created.
set -euo pipefail
RG="rg-security-automation"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"

echo "==> Removing the Function's Reader role at subscription level"
for app in $(az functionapp list -g "$RG" --query "[].name" -o tsv 2>/dev/null); do
  pid="$(az functionapp identity show -n "$app" -g "$RG" --query principalId -o tsv 2>/dev/null || true)"
  [[ -n "$pid" ]] && az role assignment delete --assignee "$pid" --role Reader \
    --scope "/subscriptions/${SUBSCRIPTION_ID}" || true
done

echo "==> Deleting resource group ${RG} (runs in the background)"
az group delete -n "$RG" --yes --no-wait
echo "Cleanup started."
