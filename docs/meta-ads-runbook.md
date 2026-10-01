# Meta ads runbook — awareness, no link yet

Hierarchy: **campaign** (objective) → **ad set** (budget + targeting) →
**ad** (creative). Build in that order; each step returns the id the
next step needs. Everything ships `PAUSED` — nothing here can spend.

## 0. Prerequisites (yours)

- Ad account ID (`act_<AD_ACCOUNT_ID>`), with billing set up.
- Access token with `ads_management` (+ `ads_read`).
- Creative: a Page + uploaded image produce the `CREATIVE_ID`.
  Upload the image first (returns `images` hashes):

```powershell
curl.exe -s -X POST "https://graph.facebook.com/v25.0/act_<AD_ACCOUNT_ID>/adimages" `
  -F "filename=@./creative.png" `
  -F "access_token=<ACCESS_TOKEN>"
```

Then create the creative in Ads Manager (or the `adcreatives` edge)
from your Page + image hash — awareness needs no destination URL.

## 1. Campaign

```powershell
cd ads
powershell -File create-campaign.ps1 -AdAccountId '<AD_ACCOUNT_ID>' -Token '<ACCESS_TOKEN>'
```

Objective is `OUTCOME_AWARENESS`, status `PAUSED`. Save the campaign id.

## 2. Ad set

```powershell
powershell -File create-adset.ps1 -AdAccountId '<AD_ACCOUNT_ID>' -CampaignId '<CAMPAIGN_ID>' -Token '<ACCESS_TOKEN>' -DailyBudget 1000 -Country ZA
```

Budget is in the account currency's smallest subunit. Default geo is
South Africa (`ZA`) — override `-Country` per market. Save the ad set id.

## 3. Ad

```powershell
powershell -File create-ad.ps1 -AdAccountId '<AD_ACCOUNT_ID>' -AdSetId '<AD_SET_ID>' -CreativeId '<CREATIVE_ID>' -Token '<ACCESS_TOKEN>'
```

Status `PAUSED`. Review everything in Ads Manager, and only flip to
active there when budget and creative are approved.

## Component map

| Component   | Campaign | Ad set | Ad |
| ----------- | -------- | ------ | -- |
| Objective   | ✓        |        |    |
| Schedule    |          | ✓      |    |
| Budget      |          | ✓      |    |
| Bidding     |          | ✓      |    |
| Audience    |          | ✓      |    |
| Ad creative |          |        | ✓  |

One objective per campaign (it validates everything under it); one
audience + bid per ad set (spend control and per-audience metrics);
multiple ads per ad set to optimize across images, text, and
placements. Creatives are immutable once created and live in the
account's creative library for reuse.

## 4. Manage

Pause (or enable, your call — default is pause):

```powershell
powershell -File update-status.ps1 -AdId '<AD_ID>' -Token '<ACCESS_TOKEN>'
```

Delete permanently (refuses without the switch):

```powershell
powershell -File delete-ad.ps1 -AdId '<AD_ID>' -Token '<ACCESS_TOKEN>' -ConfirmDelete
```

## 5. Insights (read-only)

```powershell
powershell -File get-insights.ps1 -ObjectId '<CAMPAIGN_OR_ADSET_OR_AD_ID>' -Token '<ACCESS_TOKEN>'
```

Works on any level's id. Default window `last_30d`, default fields
impressions, reach, spend, clicks, CTR, CPC — override `-Preset` /
`-Fields` as needed.

## Notes

- Awareness carries no link by your choice; switching to traffic later
  means a new campaign with a link-click objective, not an edit here.
- Never commit real account IDs or tokens — all three create scripts
  require `-AdAccountId` and `-Token` as parameters.
