# Local exercise for webhooks/server.js. Requires Node 18+.
#
# Shell 1 (from webhooks/):
#   npm install
#   $env:APP_SECRET = 'test-secret'; $env:TOKEN = 'test-token'; $env:ADMIN_TOKEN = 'test-admin'; node server.js
# Shell 2 (from webhooks/):
#   powershell -File test-local.ps1
#
# Expected: 200 + challenge echo (correct token), 403 (wrong/missing
# token), 200 (valid signature), 401 (bad signature), 200 on redelivery
# with the server console logging the field line exactly once, 401 on
# GET / without the admin token, and GET / listing the receipts with it. Test secrets only — never use real ones here.

$ErrorActionPreference = "Stop"
$base = "http://localhost:3000"
$secret = "test-secret"
$token = "test-token"
$admin = "test-admin"
$challenge = "1158201444"
$failures = 0

function Hmac([string]$body) {
  $h = New-Object System.Security.Cryptography.HMACSHA256
  $h.Key = [Text.Encoding]::UTF8.GetBytes($secret)
  ($h.ComputeHash([Text.Encoding]::UTF8.GetBytes($body)) | ForEach-Object { $_.ToString("x2") }) -join ""
}

function Req([string]$method, [string]$url, [hashtable]$headers, [string]$body) {
  try {
    $r = Invoke-RestMethod -Method $method -Uri $url -Headers $headers -Body $body -ContentType "application/json"
    return @{ status = 200; body = "$r" }
  } catch {
    return @{ status = [int]$_.Exception.Response.StatusCode; body = $null }
  }
}

function Check([string]$name, [bool]$ok, [string]$detail) {
  if ($ok) {
    Write-Output "PASS $name"
  } else {
    Write-Output "FAIL $name -- $detail"
    $script:failures += 1
  }
}

# 1. verification, correct token
$r = Req "GET" "$base/webhooks?hub.mode=subscribe&hub.challenge=$challenge&hub.verify_token=$token" @{} $null
Check "verify-correct-token" ($r.status -eq 200 -and $r.body -eq $challenge) "status=$($r.status) body=$($r.body)"

# 2. verification, wrong token
$r = Req "GET" "$base/webhooks?hub.mode=subscribe&hub.challenge=$challenge&hub.verify_token=wrong" @{} $null
Check "verify-wrong-token-403" ($r.status -eq 403) "status=$($r.status)"

# 3. verification, missing token
$r = Req "GET" "$base/webhooks?hub.mode=subscribe&hub.challenge=$challenge" @{} $null
Check "verify-missing-token-403" ($r.status -eq 403) "status=$($r.status)"

# 4-6. event notifications
$payload = '{"object":"instagram","entry":[{"id":"17841400008460056","time":1759282800,"changes":[{"field":"comments","value":{"media_id":"123"}}]}]}'
$good = @{ "X-Hub-Signature-256" = "sha256=$(Hmac $payload)" }
$bad = @{ "X-Hub-Signature-256" = "sha256=deadbeef" }

$r = Req "POST" "$base/webhooks" $good $payload
Check "notify-valid-signature-200" ($r.status -eq 200) "status=$($r.status)"

$r = Req "POST" "$base/webhooks" $bad $payload
Check "notify-bad-signature-401" ($r.status -eq 401) "status=$($r.status)"

$r = Req "POST" "$base/webhooks" $good $payload
Check "notify-duplicate-200" ($r.status -eq 200) "status=$($r.status)"
Write-Output "CHECK server console: 'field=comments' logged exactly once (dedupe)"

# 7. stored receipts (admin only)
$r = Req "GET" "$base/" @{} $null
Check "get-receipts-noauth-401" ($r.status -eq 401) "status=$($r.status)"

$r = Req "GET" "$base/" @{ "Authorization" = "Bearer $admin" } $null
Check "get-receipts" ($r.status -eq 200) "status=$($r.status)"
Write-Output "receipts: $($r.body)"

if ($failures -gt 0) { exit 1 }
Write-Output "ALL CHECKS PASSED (plus the one manual console check above)"
