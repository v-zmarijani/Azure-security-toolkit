# Uploading to GitHub

Notes for myself on getting this repo online and linked from Upwork.

## 1. Create the repo

github.com > New repository > name `azure-security-portfolio`, public, no README
(there's already one).

## 2. Push

Without the terminal: on the empty repo page click "uploading an existing file", then drag in
everything from the unzipped folder. On macOS, `.gitignore` is hidden by default, press
Cmd+Shift+. in Finder to show it.

With git:

```bash
cd ~/Downloads/azure-security-portfolio
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/<username>/azure-security-portfolio.git
git push -u origin main
```

## 3. Repo settings

In the About section on the repo page:

- Description: Azure security projects: Policy, Defender for Cloud, KQL, Azure DevOps, Functions
- Topics: azure, cloud-security, azure-policy, defender-for-cloud, kql, azure-devops, bicep,
  azure-functions, devsecops

Pin it on the profile (Profile > Customize your pins).

## 4. Images

Add screenshots to `docs/images/` and reference them from each README, e.g.

```markdown
![Compliance view](../docs/images/01-policy-compliance.png)
```

Only from a personal subscription or local runs. Blur subscription IDs and emails.

Things that work without Azure:
- `checkov -d 04-azure-devops-pipelines/infra --framework bicep` on the laptop
- `az bicep build --file 04-azure-devops-pipelines/infra/main.bicep`
- VS Code screenshots of the policies, queries and pipeline templates

## 5. Upwork links

| Portfolio item | Link |
|----------------|------|
| Azure Policy compliance | `/tree/main/01-azure-policy-compliance` |
| Defender Secure Score | `/tree/main/02-defender-secure-score` |
| KQL reporting | `/tree/main/03-kql-compliance-reporting` |
| DevOps pipelines | `/tree/main/04-azure-devops-pipelines` |
| Security automation | `/tree/main/05-security-automation` |

## Before running anything in Azure

- Personal subscription only, never work
- Budget alert set (Cost Management > Budgets)
- Run `cleanup.sh` afterwards
- Never commit `local.settings.json` or URLs containing `?code=`
