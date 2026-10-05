# Shared helpers for the SocialColabz scripts. Dot-sourced, not run directly.
# Works on Windows PowerShell 5.1 and PowerShell 7.

$ErrorActionPreference = "Stop"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Resolve-IgToken([string]$Token) {
  if ($Token) { return $Token }
  if ($env:IG_ACCESS_TOKEN) { return $env:IG_ACCESS_TOKEN }
  throw "No access token. Pass -Token or set the IG_ACCESS_TOKEN environment variable."
}

# Calls the Instagram Graph API and surfaces Meta's error message on failure.
function Invoke-IgApi([string]$Method, [string]$Url, [hashtable]$Body) {
  try {
    if ($Method -eq "GET") {
      return Invoke-RestMethod -Method Get -Uri $Url
    }
    return Invoke-RestMethod -Method Post -Uri $Url -Body $Body
  } catch {
    $detail = $_.ErrorDetails.Message
    if (-not $detail) { $detail = $_.Exception.Message }
    throw "Instagram API $Method $($Url -replace 'access_token=[^&]+', 'access_token=***') failed: $detail"
  }
}

function Read-Post([string]$Path) {
  if (-not (Test-Path $Path)) { throw "Post file not found: $Path" }
  return Get-Content -Raw -Encoding UTF8 -Path $Path | ConvertFrom-Json
}

# UTF-8 without BOM so the files diff cleanly and parse everywhere.
function Save-Post($Post, [string]$Path) {
  $json = $Post | ConvertTo-Json -Depth 5
  $Path = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($Path)
  [IO.File]::WriteAllText($Path, $json + "`n", (New-Object Text.UTF8Encoding $false))
}

# Instagram's own limits for a single-image feed post. Returns problems found.
function Test-PostContent($Post) {
  $problems = @()
  if ($Post.image_url -notmatch '^https://') {
    $problems += "image_url must be a public https:// URL (Meta downloads it at publish time)."
  }
  if ($Post.caption.Length -gt 2200) {
    $problems += "Caption is $($Post.caption.Length) characters; Instagram allows 2,200."
  }
  $tags = ([regex]::Matches($Post.caption, '#\w+')).Count
  if ($tags -gt 30) { $problems += "Caption has $tags hashtags; Instagram allows 30." }
  return $problems
}

# A warning, not a block: some hosts serve JPEGs from URLs without an extension.
function Write-JpegWarning($Post) {
  if ($Post.image_url -notmatch '\.jpe?g($|\?)') {
    Write-Warning "image_url does not end in .jpg/.jpeg. Instagram publishing accepts JPEG only."
  }
}

# Fingerprint of what was approved, so an edit after approval blocks publishing.
function Get-PostHash($Post) {
  $text = "$($Post.image_url)`n$($Post.alt_text)`n$($Post.caption)"
  $sha = [Security.Cryptography.SHA256]::Create()
  $bytes = $sha.ComputeHash([Text.Encoding]::UTF8.GetBytes($text))
  return ($bytes | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Show-Post($Post) {
  Write-Output "Name:     $($Post.name)"
  Write-Output "Status:   $($Post.status)"
  Write-Output "Image:    $($Post.image_url)"
  if ($Post.alt_text) { Write-Output "Alt text: $($Post.alt_text)" }
  Write-Output "Caption:"
  Write-Output "----"
  Write-Output $Post.caption
  Write-Output "----"
}
