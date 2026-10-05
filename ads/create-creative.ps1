# Step 2b — link creative that sends people to the applicant portal.
# Needs an uploaded image hash (see docs/meta-ads-runbook.md) and the
# Facebook Page id; pass -InstagramUserId to run it on Instagram too.
# Usage:
#   powershell -File create-creative.ps1 -AdAccountId '<AD_ACCOUNT_ID>' -PageId '<PAGE_ID>' -ImageHash '<IMAGE_HASH>' -Token '<ACCESS_TOKEN>'
# Returns JSON including the creative id for step 3.
param(
  [Parameter(Mandatory)] [string]$AdAccountId,
  [Parameter(Mandatory)] [string]$PageId,
  [Parameter(Mandatory)] [string]$ImageHash,
  [Parameter(Mandatory)] [string]$Token,
  [string]$InstagramUserId = "",
  [string]$Link = "https://datamatrix-applicants.tcasepac24.chatgpt.site",
  [string]$Headline = "Your app. Built in 14 days.",
  [string]$Message = "Guaranteed MVP in 14 days. 3 dedicated developers, selective intake. Apply for a project slot.",
  [string]$CallToAction = "APPLY_NOW",
  [string]$Name = "Datamatrix Apply Now",
  [string]$ApiVersion = "v25.0"
)

$spec = @{
  page_id   = $PageId
  link_data = @{
    image_hash     = $ImageHash
    link           = $Link
    name           = $Headline
    message        = $Message
    call_to_action = @{ type = $CallToAction; value = @{ link = $Link } }
  }
}
if ($InstagramUserId) { $spec.instagram_user_id = $InstagramUserId }
# Written to a temp file so the JSON quotes survive any PowerShell version.
$specFile = New-TemporaryFile
($spec | ConvertTo-Json -Depth 6 -Compress) | Set-Content -NoNewline -Encoding ascii $specFile

curl.exe -s -X POST "https://graph.facebook.com/$ApiVersion/act_$AdAccountId/adcreatives" `
  -F "name=$Name" `
  -F "object_story_spec=<$specFile" `
  -F "access_token=$Token"
Remove-Item $specFile
Write-Output ""
