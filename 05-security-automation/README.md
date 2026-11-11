# Storage security check (Function + Logic App)

A daily check of every storage account in a subscription. The Azure Function does the actual
checking and returns JSON. A Logic App calls it every morning and posts to a webhook (Teams
Workflow, Slack, whatever you use) if anything comes back.

I split it this way so the notification part can be changed in the Logic App designer without
redeploying code.

```
Logic App (07:00 daily) --GET--> Function --> list storage accounts, check settings
        |                            |
        |<-------- JSON -------------+
        |
        +-- findingsCount > 0 --> POST to webhook
```

The Function uses a system-assigned managed identity with Reader on the subscription. No keys
or secrets in the code, and it can't change anything.

## Checks

- HTTPS-only disabled
- public blob access allowed
- minimum TLS below 1.2
- network default action is Allow
- shared key access allowed

## Layout

```
function-app/   Python function (v2 programming model)
logic-app/      workflow definition
scripts/        deploy.sh, cleanup.sh
```

## Deploy

Needs Azure CLI, Azure Functions Core Tools v4 and Python 3.11.

```bash
az login
export ALERT_WEBHOOK_URL="https://..."   # optional
cd scripts
chmod +x *.sh
./deploy.sh
```

At the end the script prints the function URL. Treat it like a password, it contains the
function key.

Example response:

```json
{
  "checkedAt": "2026-11-11T07:00:02+00:00",
  "storageAccountsChecked": 4,
  "findingsCount": 1,
  "findings": [
    {
      "name": "stdemo123",
      "resourceGroup": "rg-test",
      "location": "westeurope",
      "issues": ["Public blob access allowed"]
    }
  ]
}
```

## Running locally

```bash
cd function-app
cp local.settings.sample.json local.settings.json   # add your subscription ID
pip install -r requirements.txt
func start
curl http://localhost:7071/api/check-storage
```

Locally it uses your `az login` session instead of the managed identity.

## Cost

Consumption plan, one execution a day, so effectively free. `cleanup.sh` removes the role
assignment and deletes the resource group.
