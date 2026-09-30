# Update an ad's status (pause or, by your call, enable).
# Defaults to PAUSED. Pass the ad id returned at creation.
# Usage:
#   powershell -File update-status.ps1 -AdId '<AD_ID>' -Token '<ACCESS_TOKEN>' [-Status ACTIVE]
param(
  [Parameter(Mandatory)] [string]$AdId,
  [Parameter(Mandatory)] [string]$Token,
  [ValidateSet("PAUSED", "ACTIVE")] [string]$Status = "PAUSED",
  [string]$ApiVersion = "v25.0"
)

curl.exe -s -X POST "https://graph.facebook.com/$ApiVersion/$AdId" `
  -F "status=$Status" `
  -F "access_token=$Token"
Write-Output ""
