# Step 1 — campaign (always PAUSED; spend stays your decision).
# -Objective OUTCOME_TRAFFIC for ads that link to the applicant portal.
# Usage:
#   powershell -File create-campaign.ps1 -AdAccountId '<AD_ACCOUNT_ID>' -Token '<ACCESS_TOKEN>'
# Returns JSON including the campaign id for step 2.
param(
  [Parameter(Mandatory)] [string]$AdAccountId,
  [Parameter(Mandatory)] [string]$Token,
  [ValidateSet("OUTCOME_AWARENESS", "OUTCOME_TRAFFIC")] [string]$Objective = "OUTCOME_AWARENESS",
  [string]$Name = "Datamatrix Awareness",
  [string]$ApiVersion = "v25.0"
)

curl.exe -s -X POST "https://graph.facebook.com/$ApiVersion/act_$AdAccountId/campaigns" `
  -F "name=$Name" `
  -F "objective=$Objective" `
  -F "status=PAUSED" `
  -F "access_token=$Token"
Write-Output ""
