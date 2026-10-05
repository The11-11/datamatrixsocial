# Long-lived Instagram tokens last 60 days. Refresh one that is at least
# 24 hours old and still valid; prints the new token and its lifetime.
# Usage:
#   powershell -File refresh-token.ps1 [-Token '<INSTAGRAM_USER_ACCESS_TOKEN>']
param(
  [string]$Token,
  [string]$ApiBase = "https://graph.instagram.com"
)
. (Join-Path $PSScriptRoot "common.ps1")

$Token = Resolve-IgToken $Token
$t = [uri]::EscapeDataString($Token)
$r = Invoke-IgApi GET "$ApiBase/refresh_access_token?grant_type=ig_refresh_token&access_token=$t"
Write-Output "New token (store it as IG_ACCESS_TOKEN; never commit it):"
Write-Output $r.access_token
Write-Output "Expires in $([math]::Floor($r.expires_in / 86400)) days."
