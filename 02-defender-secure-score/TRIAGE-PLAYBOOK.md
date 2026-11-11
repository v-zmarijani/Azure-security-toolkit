# Triage notes

How I usually go through a long list of Defender recommendations.

## Order

1. High severity on anything reachable from the internet: open 22/3389, public storage,
   VMs with public IPs.
2. Other high severity items.
3. Medium severity items that affect a lot of resources. These are often one policy away
   from being fixed everywhere.
4. The rest.

`open-recommendations.kql` and `top-affected-resources.kql` give you most of this ordering.

## For each recommendation

I put every item into one of four buckets:

- **Fix** - small change, low risk, just do it.
- **Policy** - the same issue keeps coming back, so it needs a rule (see project 01).
- **Plan** - needs a maintenance window or another team. Ticket with an owner and a date.
- **Exempt** - doesn't apply to this environment. Create an exemption and write down why.

I'd rather have an exemption with a reason than a recommendation that everyone silently ignores.
It also makes audits a lot easier.

## Owners

Recommendations without an owner don't get fixed. The `Owner` tag from project 01 is how I
know who to talk to.

## Reporting

Once a month: score trend from `track-score.sh` and the top three open items. Short is better,
nobody reads a 40-row table in a meeting.

## Usual quick wins

- Storage network access: firewall rules or private endpoints
- Secure transfer for storage: HTTPS only (covered by the policy in 01)
- Management ports on VMs: remove 22/3389 from NSGs, use Bastion or JIT instead
- MFA for owners: Conditional Access
- Diagnostic logs: diagnostic settings pointing to a Log Analytics workspace
