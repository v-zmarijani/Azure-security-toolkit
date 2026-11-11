#!/usr/bin/env bash
# Creates the policy definitions and initiative, assigns it to the subscription
# and grants the assignment identity the role it needs for the modify policy.
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "==> Subscription: ${SUBSCRIPTION_ID}"

# ---------------------------------------------------------------------------
# 1. Create each policy definition from its folder
#    (folder name = policy name, e.g. policies/require-owner-tag)
# ---------------------------------------------------------------------------
for dir in "${POLICY_DIR}"/*/; do
  name="$(basename "$dir")"
  echo "==> Creating policy: ${name}"
  az policy definition create \
    --name "${name}" \
    --display-name "[Portfolio] ${name}" \
    --rules "${dir}rules.json" \
    --params "${dir}params.json" \
    --mode Indexed \
    --subscription "${SUBSCRIPTION_ID}" \
    --output none
done

# ---------------------------------------------------------------------------
# 2. Initiative
#    initiative.definitions.json has a placeholder for the subscription ID.
# ---------------------------------------------------------------------------
echo "==> Creating initiative: ${INITIATIVE_NAME}"
tmp_defs="$(mktemp)"
sed "s/__SUBSCRIPTION_ID__/${SUBSCRIPTION_ID}/g" \
  "${INITIATIVE_DIR}/initiative.definitions.json" > "${tmp_defs}"

az policy set-definition create \
  --name "${INITIATIVE_NAME}" \
  --display-name "[Portfolio] Security baseline" \
  --description "Owner tags, auto-tagging, and storage security rules." \
  --definitions "@${tmp_defs}" \
  --subscription "${SUBSCRIPTION_ID}" \
  --output none
rm -f "${tmp_defs}"

# ---------------------------------------------------------------------------
# 3. Assign the initiative to the whole subscription.
#    A system-assigned managed identity is needed for the "modify" (auto-fix) policy.
# ---------------------------------------------------------------------------
echo "==> Assigning initiative to ${SCOPE}"
principal_id="$(az policy assignment create \
  --name "${ASSIGNMENT_NAME}" \
  --display-name "[Portfolio] Security baseline" \
  --policy-set-definition "${INITIATIVE_NAME}" \
  --scope "${SCOPE}" \
  --mi-system-assigned \
  --location "${LOCATION}" \
  --query identity.principalId -o tsv)"

# ---------------------------------------------------------------------------
# 4. Give the assignment's identity permission to add tags (Contributor).
#    Retries a few times because new identities take a moment to appear.
# ---------------------------------------------------------------------------
echo "==> Granting Contributor to the assignment identity (${principal_id})"
for attempt in 1 2 3 4 5; do
  if az role assignment create \
      --assignee-object-id "${principal_id}" \
      --assignee-principal-type ServicePrincipal \
      --role "Contributor" \
      --scope "${SCOPE}" \
      --output none 2>/dev/null; then
    break
  fi
  echo "  identity not ready yet, retrying in 15s (attempt ${attempt}/5)..."
  sleep 15
done

echo "Done. The first compliance scan takes about 15-30 minutes."
echo "Next: ./check-compliance.sh  then  ./remediate.sh"
