# Step 2 — ad set under the campaign (always PAUSED).
# DailyBudget is in the ad account currency's smallest subunit
# (e.g. cents, so 1000 = 10.00).
# Usage:
#   powershell -File create-adset.ps1 -CampaignId '<CAMPAIGN_ID>' -Token '<ACCESS_TOKEN>' -DailyBudget 1000 -Country ZA
param(
  [Parameter(Mandatory)] [string]$CampaignId,
  [Parameter(Mandatory)] [string]$Token,
  [Parameter(Mandatory)] [string]$DailyBudget,
  [string]$Country = "ZA",
  [string]$Name = "Datamatrix Awareness ZA",
  [string]$ApiVersion = "v25.0",
  [string]$AdAccountId = "<AD_ACCOUNT_ID>"
)

$targeting = "{`"geo_locations`":{`"countries`":[ `"$Country`" ]}}"
curl.exe -s -X POST "https://graph.facebook.com/$ApiVersion/act_$AdAccountId/adsets" `
  -F "name=$Name" `
  -F "campaign_id=$CampaignId" `
  -F "daily_budget=$DailyBudget" `
  -F "targeting=$targeting" `
  -F "status=PAUSED" `
  -F "access_token=$Token"
Write-Output ""
