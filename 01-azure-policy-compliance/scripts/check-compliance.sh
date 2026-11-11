#!/usr/bin/env bash
# Compliance summary for the security baseline assignment.
# Pass --scan to force a fresh evaluation first (takes a few minutes).
set -euo pipefail
source "$(dirname "$0")/config.sh"

if [[ "${1:-}" == "--scan" ]]; then
  echo "==> Triggering a fresh compliance scan (this can take a few minutes)..."
  az policy state trigger-scan --output none
fi

echo "==> Compliance per rule:"
az policy state summarize \
  --policy-assignment "${ASSIGNMENT_NAME}" \
  --query "results.policyDetails[].{rule:policyDefinitionReferenceId, compliance:complianceState, resources:count}" \
  --output table 2>/dev/null || true

echo
echo "==> Non-compliant resources:"
az policy state list \
  --policy-assignment "${ASSIGNMENT_NAME}" \
  --filter "complianceState eq 'NonCompliant'" \
  --query "[].{rule:policyDefinitionReferenceId, resource:resourceId}" \
  --output table
