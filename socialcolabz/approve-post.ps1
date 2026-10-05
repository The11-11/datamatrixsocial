# Step 2 — you review a draft and approve it. Only approved posts publish,
# and editing the image, caption or alt text afterwards voids the approval.
# Usage:
#   powershell -File approve-post.ps1 -Post posts\2026-10-launch.json
param(
  [Parameter(Mandatory)] [string]$Post
)
. (Join-Path $PSScriptRoot "common.ps1")

$p = Read-Post $Post
if ($p.status -eq "published") { throw "Already published: $($p.permalink)" }

Show-Post $p
$problems = Test-PostContent $p
if ($problems.Count) {
  $problems | ForEach-Object { Write-Warning $_ }
  throw "Fix the problems above, then approve again."
}
Write-JpegWarning $p

$answer = Read-Host "Type APPROVE to allow this post to be published"
if ($answer -cne "APPROVE") {
  Write-Output "Not approved. Nothing changed."
  return
}

$p.status = "approved"
$p.approved_at = (Get-Date).ToUniversalTime().ToString("o")
$p.approved_hash = Get-PostHash $p
Save-Post $p $Post
Write-Output "Approved: $Post"
