# Step 3 — publish an approved post to Instagram (Instagram API with
# Instagram Login). Refuses drafts, already-published posts, and posts
# edited after approval. Writes media_id + permalink back to the file.
# Usage:
#   $env:IG_ACCESS_TOKEN = '<INSTAGRAM_USER_ACCESS_TOKEN>'
#   powershell -File publish-post.ps1 -Post posts\2026-10-launch.json
param(
  [Parameter(Mandatory)] [string]$Post,
  [string]$Token,
  [string]$ApiVersion = "v25.0",
  [string]$ApiBase = "https://graph.instagram.com",
  [int]$PollSeconds = 10,
  [int]$MaxPolls = 30
)
. (Join-Path $PSScriptRoot "common.ps1")

$Token = Resolve-IgToken $Token
$p = Read-Post $Post

if ($p.status -eq "published") { throw "Already published: $($p.permalink)" }
if ($p.status -ne "approved") { throw "Post is '$($p.status)', not approved. Run approve-post.ps1 first." }
if ($p.approved_hash -ne (Get-PostHash $p)) {
  throw "Post changed after it was approved. Run approve-post.ps1 again."
}
$problems = Test-PostContent $p
if ($problems.Count) { $problems | ForEach-Object { Write-Warning $_ }; throw "Post failed checks." }

$api = "$ApiBase/$ApiVersion"
$t = [uri]::EscapeDataString($Token)

$me = Invoke-IgApi GET "$api/me?fields=user_id,username&access_token=$t"
$igId = $me.user_id
Write-Output "Account: @$($me.username) ($igId)"

$limit = Invoke-IgApi GET "$api/$igId/content_publishing_limit?fields=quota_usage,config&access_token=$t"
$usage = $limit.data[0].quota_usage
$total = $limit.data[0].config.quota_total
Write-Output "Publishing quota used in last 24h: $usage of $total"
if ($total -and $usage -ge $total) { throw "Publishing limit reached; try again later." }

$body = @{ image_url = $p.image_url; caption = $p.caption; access_token = $Token }
if ($p.alt_text) { $body.alt_text = $p.alt_text }
$container = Invoke-IgApi POST "$api/$igId/media" $body
Write-Output "Container: $($container.id)"

$status = $null
for ($i = 0; $i -lt $MaxPolls; $i++) {
  $status = (Invoke-IgApi GET "$api/$($container.id)?fields=status_code&access_token=$t").status_code
  if ($status -eq "FINISHED") { break }
  if ($status -in @("ERROR", "EXPIRED")) { throw "Container $($container.id) is $status; nothing was published." }
  Start-Sleep -Seconds $PollSeconds
}
if ($status -ne "FINISHED") { throw "Container $($container.id) still $status; nothing was published." }

$published = Invoke-IgApi POST "$api/$igId/media_publish" @{ creation_id = $container.id; access_token = $Token }

# Record the publish before anything else can fail, so a rerun never double-posts.
$p.status = "published"
$p.published_at = (Get-Date).ToUniversalTime().ToString("o")
$p.media_id = $published.id
Save-Post $p $Post

try {
  $p.permalink = (Invoke-IgApi GET "$api/$($published.id)?fields=permalink&access_token=$t").permalink
  Save-Post $p $Post
} catch {
  Write-Warning "Published, but could not fetch the permalink: $_"
}
Write-Output "Published: $($p.permalink) (media $($p.media_id))"
