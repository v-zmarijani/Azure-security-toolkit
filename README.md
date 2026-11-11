# azure-security-portfolio

A few Azure security projects I put together to show how I usually work: lock things down
with policy, keep an eye on Defender, report on it with KQL, and automate whatever I'd
otherwise end up doing by hand every week.

Everything here is meant to run in a normal Azure subscription. Each folder has its own
README with setup steps.

## Projects

- **[01-azure-policy-compliance](01-azure-policy-compliance)**
  Custom policies + an initiative for tagging and storage security, with a remediation task
  that fixes missing tags on existing resources.

- **[02-defender-secure-score](02-defender-secure-score)**
  Resource Graph queries for Secure Score and open recommendations, a small script to log the
  score daily, and the notes I use when deciding what to fix first.

- **[03-kql-compliance-reporting](03-kql-compliance-reporting)**
  A set of KQL queries plus a Python script that runs them all and writes CSVs and an HTML report.
  There's also a NiFi setup for when the data needs to go into a database on a schedule.

- **[04-azure-devops-pipelines](04-azure-devops-pipelines)**
  Reusable YAML templates: Checkov scan, Bicep what-if, and a deployment job. Comes with a
  Bicep storage account that's locked down by default.

- **[05-security-automation](05-security-automation)**
  An Azure Function that checks storage account settings, called once a day by a Logic App
  that posts to a webhook if it finds anything.

The projects share a few conventions. For example, 01 enforces an `Owner` tag, 04 deploys
resources with that tag already set, and 03 has a query that lists anything still missing it.

## Requirements

- Azure subscription with Owner rights (or Contributor + User Access Administrator)
- Azure CLI, logged in with `az login`
- Python 3.10+ (projects 03 and 05)
- Azure DevOps organization (project 04, free tier is fine)

Most of this costs nothing or close to it. The paid Defender plans are not enabled anywhere;
project 02 only uses the free tier.

## About me

Cloud security engineer working mostly with Azure governance, Defender for Cloud, KQL and
Azure DevOps.

Certs: AZ-104, AZ-700, AZ-900, CompTIA Security+

## License

MIT
