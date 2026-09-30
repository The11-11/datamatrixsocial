# Permanently delete an ad. Destructive — requires the confirmation switch.
# Usage:
#   powershell -File delete-ad.ps1 -AdId '<AD_ID>' -Token '<ACCESS_TOKEN>' -ConfirmDelete
param(
  [Parameter(Mandatory)] [string]$AdId,
  [Parameter(Mandatory)] [string]$Token,
  [switch]$ConfirmDelete,
  [string]$ApiVersion = "v25.0"
)

if (-not $ConfirmDelete) {
  Write-Output "Refusing: re-run with -ConfirmDelete to delete ad $AdId."
  exit 1
}

curl.exe -s -X DELETE "https://graph.facebook.com/$ApiVersion/$AdId" `
  -F "access_token=$Token"
Write-Output ""
