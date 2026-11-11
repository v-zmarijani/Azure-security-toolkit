# Azure Policy compliance

Four custom policies grouped into one initiative, assigned at subscription level.
The goal is to stop the most common misconfigurations at deploy time and clean up
the ones that already exist.

## Policies

| Policy | Checks | Default effect |
|--------|--------|----------------|
| `require-owner-tag` | Resource has an `Owner` tag | Audit |
| `inherit-owner-tag-from-rg` | Copies `Owner` from the resource group if the resource doesn't have it | Modify |
| `storage-https-only` | Storage account only accepts HTTPS | Audit |
| `storage-no-public-blob` | Anonymous blob access is disabled | Audit |

Everything starts on Audit on purpose. Switching straight to Deny tends to break other people's
deployments, so I prefer to look at the compliance results for a while first and then
tighten it. To change it, edit the `effect` values in `initiative/initiative.definitions.json`.

## Layout

```
policies/<name>/rules.json      policy rule
policies/<name>/params.json     policy parameters
initiative/                     initiative definition (groups the four policies)
scripts/                        deploy, remediate, check, cleanup
```

## Running it

```bash
az login
az account set --subscription "<subscription-id>"

cd scripts
chmod +x *.sh

./deploy.sh            # definitions, initiative, assignment, role for the managed identity
./check-compliance.sh  # first evaluation takes 15-30 min after assigning
./remediate.sh         # adds missing Owner tags from the resource group
./cleanup.sh           # removes everything again
```

`check-compliance.sh --scan` triggers a new evaluation instead of waiting for the next cycle.

## Quick test

```bash
az group create -n rg-policy-demo -l westeurope --tags Owner=zackaria
az storage account create -n stpolicydemo$RANDOM -g rg-policy-demo -l westeurope --sku Standard_LRS
```

The storage account is created without tags, so it shows up as non-compliant. After running
`remediate.sh` it should get `Owner=zackaria` from the resource group.

## Notes

- The Modify policy only works if the assignment has a managed identity with permission to
  write tags. `deploy.sh` assigns Contributor at subscription scope. For a real environment
  I'd narrow that down to Tag Contributor.
- New role assignments sometimes take a few seconds before the identity is usable, which is
  why the script retries.
- Azure Policy itself is free.
