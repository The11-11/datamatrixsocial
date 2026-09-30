# Read-only insights for a campaign, ad set, or ad id.
# Usage:
#   powershell -File get-insights.ps1 -ObjectId '<CAMPAIGN_OR_ADSET_OR_AD_ID>' -Token '<ACCESS_TOKEN>' [-Preset last_30d]
param(
  [Parameter(Mandatory)] [string]$ObjectId,
  [Parameter(Mandatory)] [string]$Token,
  [string]$Preset = "last_30d",
  [string]$Fields = "impressions,reach,spend,clicks,ctr,cpc",
  [string]$ApiVersion = "v25.0"
)

curl.exe -s -G "https://graph.facebook.com/$ApiVersion/$ObjectId/insights" `
  --data-urlencode "fields=$Fields" `
  --data-urlencode "date_preset=$Preset" `
  --data-urlencode "access_token=$Token"
Write-Output ""
