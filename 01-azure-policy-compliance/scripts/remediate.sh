#!/usr/bin/env bash
# Remediation task for the inherit-owner-tag policy: resources without an Owner tag
# get it copied from their resource group.
set -euo pipefail
source "$(dirname "$0")/config.sh"

task_name="inherit-owner-tag-$(date +%Y%m%d-%H%M%S)"

echo "==> Starting remediation task: ${task_name}"
az policy remediation create \
  --name "${task_name}" \
  --policy-assignment "${ASSIGNMENT_NAME}" \
  --definition-reference-id "inheritOwnerTag" \
  --resource-discovery-mode ReEvaluateCompliance \
  --output table

echo
echo "Check progress with:"
echo "  az policy remediation show --name ${task_name} -o table"
