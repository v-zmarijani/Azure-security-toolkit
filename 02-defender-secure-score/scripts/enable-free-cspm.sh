#!/usr/bin/env bash
# Registers Microsoft.Security and lists the Defender plans.
# The free tier (Foundational CSPM) is enough for Secure Score and recommendations.
# Does not enable any paid plans.
set -euo pipefail

echo "==> Registering the Microsoft.Security provider (safe to run more than once)"
az provider register --namespace Microsoft.Security --wait

echo "==> Current Defender plans (Free = no cost, Standard = paid):"
az security pricing list \
  --query "value[].{plan:name, tier:pricingTier}" \
  --output table

echo
echo "The free tier is active by default once the provider is registered."
echo "Secure Score can take up to 24 hours to appear on a brand-new subscription."
