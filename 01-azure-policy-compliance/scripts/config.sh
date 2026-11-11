#!/usr/bin/env bash
# Shared settings for all scripts in this project.
# Adjust names / region here.

INITIATIVE_NAME="security-baseline"
ASSIGNMENT_NAME="security-baseline-assignment"
LOCATION="westeurope"   # needed because the assignment gets a managed identity

# Uses the subscription currently selected in az cli
SUBSCRIPTION_ID="$(az account show --query id -o tsv)"
SCOPE="/subscriptions/${SUBSCRIPTION_ID}"

# Folder paths (relative to this script)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICY_DIR="${SCRIPT_DIR}/../policies"
INITIATIVE_DIR="${SCRIPT_DIR}/../initiative"
