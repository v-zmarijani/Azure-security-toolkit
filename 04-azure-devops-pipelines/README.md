# Azure DevOps pipeline templates

Reusable templates for deploying Bicep with a security scan and a what-if step in front of it.
The idea is that teams reference these instead of each writing their own version, so fixes and
new checks only have to be added in one place.

## Templates

- `templates/steps-security-scan.yml` - installs Checkov, scans the infra folder, publishes the
  results to the Tests tab. `failOnFindings` controls whether findings fail the run.
- `templates/steps-bicep-validate.yml` - `az bicep build` and `az deployment group what-if`.
- `templates/jobs-deploy.yml` - deployment job bound to an Azure DevOps Environment, so approvals
  and checks can be configured on the Environment instead of in YAML.

`azure-pipelines.yml` shows how a team would use them. It has two stages, Validate and Deploy,
and Deploy only runs on `main`.

`infra/main.bicep` is a sample storage account: HTTPS only, TLS 1.2, no public blob access,
shared key access off, network default deny, and an `Owner` tag. So it passes the policies from
project 01.

## Setup

1. Create an Azure DevOps project (free tier is enough).
2. Add a service connection: Project settings > Service connections > Azure Resource Manager,
   workload identity federation. Name it `sc-azure-dev` or change the variable in the pipeline.
3. Create the resource group:
   ```bash
   az group create -n rg-portfolio-demo -l westeurope --tags Owner=<name>
   ```
4. Pipelines > New pipeline > select the repo > Existing YAML file >
   `04-azure-devops-pipelines/azure-pipelines.yml`
5. Optional: Pipelines > Environments > dev > Approvals and checks, to require approval
   before deploying.

## Notes

- The demo pipeline runs Checkov with `failOnFindings: false` so the first run doesn't fail on
  low-priority checks. Once you've looked at the results, set it to `true`.
- New Azure DevOps organizations sometimes have to request the free hosted parallel job before
  pipelines run.
- The storage account costs a few cents. Delete the resource group when you're done.
