"""
Daily storage security check.

GET /api/check-storage
  Checks every storage account in the subscription and returns findings as JSON.

Auth to Azure: managed identity in the cloud, your `az login` when running locally.
Required setting: SUBSCRIPTION_ID
"""

import json
import logging
import os
from datetime import datetime, timezone

import azure.functions as func
from azure.identity import DefaultAzureCredential
from azure.mgmt.storage import StorageManagementClient

app = func.FunctionApp(http_auth_level=func.AuthLevel.FUNCTION)


def check_storage_account(account) -> list[str]:
    """Return a list of plain-English problems for one storage account."""
    issues = []

    if account.enable_https_traffic_only is False:
        issues.append("HTTP allowed")

    if account.allow_blob_public_access:
        issues.append("Public blob access allowed")

    if account.minimum_tls_version not in ("TLS1_2", "TLS1_3"):
        issues.append(f"TLS older than 1.2 ({account.minimum_tls_version or 'not set'})")

    rules = account.network_rule_set
    if rules is None or str(rules.default_action).lower().endswith("allow"):
        issues.append("Open to all networks")

    if account.allow_shared_key_access is not False:  # None means 'allowed' by default
        issues.append("Shared key access allowed")

    return issues


def scan_subscription(subscription_id: str) -> dict:
    client = StorageManagementClient(DefaultAzureCredential(), subscription_id)

    findings = []
    checked = 0
    for account in client.storage_accounts.list():
        checked += 1
        issues = check_storage_account(account)
        if issues:
            resource_group = account.id.split("/")[4]
            findings.append({
                "name": account.name,
                "resourceGroup": resource_group,
                "location": account.location,
                "issues": issues,
            })

    return {
        "checkedAt": datetime.now(timezone.utc).isoformat(timespec="seconds"),
        "subscriptionId": subscription_id,
        "storageAccountsChecked": checked,
        "findingsCount": len(findings),
        "findings": findings,
    }


@app.route(route="check-storage", methods=["GET"])
def check_storage(req: func.HttpRequest) -> func.HttpResponse:
    subscription_id = os.environ.get("SUBSCRIPTION_ID")
    if not subscription_id:
        return func.HttpResponse(
            json.dumps({"error": "SUBSCRIPTION_ID setting is missing"}),
            status_code=500, mimetype="application/json")

    try:
        result = scan_subscription(subscription_id)
    except Exception as exc:  # return the error as JSON instead of a bare 500
        logging.exception("Storage scan failed")
        return func.HttpResponse(
            json.dumps({"error": str(exc)}), status_code=500, mimetype="application/json")

    logging.info("Checked %s storage accounts, %s with findings",
                 result["storageAccountsChecked"], result["findingsCount"])
    return func.HttpResponse(json.dumps(result, indent=2), mimetype="application/json")
