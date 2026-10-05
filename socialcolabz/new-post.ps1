# Step 1 — write a draft post to socialcolabz/posts/<Name>.json.
# Drafts never publish; approve-post.ps1 must mark them approved first.
# Usage:
#   powershell -File new-post.ps1 -Name '2026-10-launch' -ImageUrl 'https://<host>/post.jpg' -CaptionFile caption.txt [-AltText '...']
#   powershell -File new-post.ps1 -Name '2026-10-launch' -ImageUrl 'https://<host>/post.jpg' -Caption 'Hello'
param(
  [Parameter(Mandatory)] [ValidatePattern('^[a-z0-9][a-z0-9-]*$')] [string]$Name,
  [Parameter(Mandatory)] [string]$ImageUrl,
  [string]$Caption,
  [string]$CaptionFile,
  [string]$AltText,
  [string]$PostsDir = (Join-Path $PSScriptRoot "posts")
)
. (Join-Path $PSScriptRoot "common.ps1")

if ($CaptionFile) { $Caption = Get-Content -Raw -Encoding UTF8 -Path $CaptionFile }
if (-not $Caption) { throw "Give -Caption or -CaptionFile." }
$Caption = $Caption.Trim()

$path = Join-Path $PostsDir "$Name.json"
if (Test-Path $path) { throw "A post named '$Name' already exists: $path" }

$post = [ordered]@{
  name          = $Name
  status        = "draft"
  image_url     = $ImageUrl
  caption       = $Caption
  alt_text      = $AltText
  approved_at   = $null
  approved_hash = $null
  published_at  = $null
  media_id      = $null
  permalink     = $null
}
$problems = Test-PostContent ([pscustomobject]$post)
foreach ($p in $problems) { Write-Warning $p }
Write-JpegWarning ([pscustomobject]$post)

New-Item -ItemType Directory -Force -Path $PostsDir | Out-Null
Save-Post ([pscustomobject]$post) $path
Write-Output "Draft saved: $path"
