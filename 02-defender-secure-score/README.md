# Defender for Cloud: Secure Score tracking

Defender for Cloud gives you a lot of recommendations, but in most environments I've seen,
nobody really works through them. This folder is the small toolkit I use to get a clear
picture and track progress over time.

## What's here

- `queries/` - Resource Graph queries
  - `secure-score.kql`: current score per subscription
  - `score-by-control.kql`: which controls are losing the most points
  - `open-recommendations.kql`: unhealthy recommendations, sorted by severity and count
  - `top-affected-resources.kql`: resources with the most open issues
- `scripts/enable-free-cspm.sh` - registers the provider and lists which plans are on
- `scripts/show-status.sh` - prints score, controls and recommendations in the terminal
- `scripts/track-score.sh` - appends the current score to `output/secure-score-history.csv`
- `TRIAGE-PLAYBOOK.md` - how I prioritise what to fix

## Usage

```bash
az login
az extension add --name resource-graph

cd scripts
chmod +x *.sh
./enable-free-cspm.sh
./show-status.sh
./track-score.sh
```

I run `track-score.sh` once a day from cron. After a few weeks the CSV is enough to make a
simple chart of the score going up (or not), which is usually what people want to see in a
status meeting.

The queries also work directly in Resource Graph Explorer in the portal if you just want to
look at the results.

## Example output

```
subscriptionId                         current  max  percent
-------------------------------------  -------  ---  -------
00000000-0000-0000-0000-000000000000   24.5     42   58.3
```

## Cost

Only the free tier (Foundational CSPM) is used. Paid plans like Defender for Servers or
Storage are billed per resource and are not touched by these scripts.

A new subscription can take up to a day before a Secure Score shows up.
