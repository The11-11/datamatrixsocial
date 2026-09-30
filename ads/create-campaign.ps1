# Step 1 — awareness campaign (always PAUSED; spend stays your decision).
# Usage:
#   powershell -File create-campaign.ps1 -AdAccountId '<AD_ACCOUNT_ID>' -Token '<ACCESS_TOKEN>'
# Returns JSON including the campaign id for step 2.
param(
  [Parameter(Mandatory)] [string]$AdAccountId,
  [Parameter(Mandatory)] [string]$Token,
  [string]$Name = "Datamatrix Awareness",
  [string]$ApiVersion = "v25.0"
)

curl.exe -s -X POST "https://graph.facebook.com/$ApiVersion/act_$AdAccountId/campaigns" `
  -F "name=$Name" `
  -F "objective=OUTCOME_AWARENESS" `
  -F "status=PAUSED" `
  -F "access_token=$Token"
Write-Output ""
