# Step 3 — ad under the ad set (always PAUSED).
# CreativeId comes from Ads Manager or the adcreatives endpoint
# (see docs/meta-ads-runbook.md for the image-upload step).
# Usage:
#   powershell -File create-ad.ps1 -AdSetId '<AD_SET_ID>' -CreativeId '<CREATIVE_ID>' -Token '<ACCESS_TOKEN>'
param(
  [Parameter(Mandatory)] [string]$AdSetId,
  [Parameter(Mandatory)] [string]$CreativeId,
  [Parameter(Mandatory)] [string]$Token,
  [string]$Name = "Datamatrix Awareness Ad",
  [string]$ApiVersion = "v25.0",
  [string]$AdAccountId = "<AD_ACCOUNT_ID>"
)

$creative = "{`"creative_id`": `"$CreativeId`"}"
curl.exe -s -X POST "https://graph.facebook.com/$ApiVersion/act_$AdAccountId/ads" `
  -F "name=$Name" `
  -F "adset_id=$AdSetId" `
  -F "creative=$creative" `
  -F "status=PAUSED" `
  -F "access_token=$Token"
Write-Output ""
