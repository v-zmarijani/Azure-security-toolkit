#!/usr/bin/env bash
# Creates the Function App + Logic App and wires them together.
# Optional: export ALERT_WEBHOOK_URL="https://..." before running to get alerts.
set -euo pipefail

# ---- Settings (change if you like) ----------------------------------------
RG="rg-security-automation"
LOCATION="westeurope"
SUFFIX="$RANDOM"
STORAGE="stsecauto${SUFFIX}"          # needed by the Function App runtime
FUNC_APP="func-sec-check-${SUFFIX}"
LOGIC_APP="logic-sec-check"
ALERT_WEBHOOK_URL="${ALERT_WEBHOOK_URL:-}"
# ---------------------------------------------------------------------------

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
OWNER="$(az account show --query user.name -o tsv)"

echo "==> Resource group"
az group create -n "$RG" -l "$LOCATION" --tags Owner="$OWNER" -o none

echo "==> Storage account for the Function runtime"
az storage account create -n "$STORAGE" -g "$RG" -l "$LOCATION" \
  --sku Standard_LRS --https-only true --min-tls-version TLS1_2 \
  --allow-blob-public-access false --tags Owner="$OWNER" -o none

echo "==> Function App (Linux, Python 3.11, Consumption plan)"
az functionapp create -n "$FUNC_APP" -g "$RG" \
  --storage-account "$STORAGE" \
  --consumption-plan-location "$LOCATION" \
  --os-type Linux --runtime python --runtime-version 3.11 \
  --functions-version 4 --tags Owner="$OWNER" -o none

echo "==> Managed identity with Reader access"
PRINCIPAL_ID="$(az functionapp identity assign -n "$FUNC_APP" -g "$RG" --query principalId -o tsv)"
for attempt in 1 2 3 4 5; do
  if az role assignment create --assignee-object-id "$PRINCIPAL_ID" \
       --assignee-principal-type ServicePrincipal \
       --role Reader --scope "/subscriptions/${SUBSCRIPTION_ID}" -o none 2>/dev/null; then
    break
  fi
  echo "  identity not ready yet, retrying in 15s (attempt ${attempt}/5)..."; sleep 15
done

az functionapp config appsettings set -n "$FUNC_APP" -g "$RG" \
  --settings SUBSCRIPTION_ID="$SUBSCRIPTION_ID" -o none

echo "==> Publishing the function code"
( cd "${SCRIPT_DIR}/../function-app" && func azure functionapp publish "$FUNC_APP" --python )

FUNC_KEY="$(az functionapp function keys list -n "$FUNC_APP" -g "$RG" \
  --function-name check_storage --query default -o tsv)"
FUNC_URL="https://${FUNC_APP}.azurewebsites.net/api/check-storage?code=${FUNC_KEY}"

echo "==> Logic App (daily schedule + alert)"
az extension add --name logic --upgrade -o none 2>/dev/null || true
PARAMS_FILE="$(mktemp)"
cat > "$PARAMS_FILE" <<EOF
{
  "functionUrl":     { "value": "${FUNC_URL}" },
  "alertWebhookUrl": { "value": "${ALERT_WEBHOOK_URL}" }
}
EOF
# Merge the parameter values into the workflow file
python3 - "$SCRIPT_DIR/../logic-app/workflow.json" "$PARAMS_FILE" > "${PARAMS_FILE}.wf" <<'PY'
import json, sys
wf = json.load(open(sys.argv[1]))
wf["parameters"] = json.load(open(sys.argv[2]))
print(json.dumps(wf))
PY
az logic workflow create -g "$RG" -n "$LOGIC_APP" -l "$LOCATION" \
  --definition "${PARAMS_FILE}.wf" --tags Owner="$OWNER" -o none
rm -f "$PARAMS_FILE" "${PARAMS_FILE}.wf"

echo
echo "Done."
echo "Function URL (keep it private, it contains a key):"
echo "${FUNC_URL}"
echo "Test now:  curl \"${FUNC_URL}\""
[[ -z "$ALERT_WEBHOOK_URL" ]] && echo "   (No ALERT_WEBHOOK_URL set, so the Logic App runs but won't send alerts.)"
