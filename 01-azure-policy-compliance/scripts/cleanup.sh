#!/usr/bin/env bash
# Removes everything deploy.sh created (in reverse order).
set -euo pipefail
source "$(dirname "$0")/config.sh"

echo "==> Removing role assignment for the policy identity"
principal_id="$(az policy assignment show --name "${ASSIGNMENT_NAME}" --scope "${SCOPE}" \
  --query identity.principalId -o tsv 2>/dev/null || true)"
if [[ -n "${principal_id}" ]]; then
  az role assignment delete --assignee "${principal_id}" --role "Contributor" --scope "${SCOPE}" || true
fi

echo "==> Removing assignment"
az policy assignment delete --name "${ASSIGNMENT_NAME}" --scope "${SCOPE}" || true

echo "==> Removing initiative"
az policy set-definition delete --name "${INITIATIVE_NAME}" || true

echo "==> Removing policy definitions"
for dir in "${POLICY_DIR}"/*/; do
  az policy definition delete --name "$(basename "$dir")" || true
done

echo "Cleanup finished."
