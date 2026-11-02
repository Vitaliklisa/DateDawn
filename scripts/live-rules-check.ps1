# Live serving rules: what the deployed project is enforcing right now.
# Compares the live ruleset hash with the repo file so "deployed" is a fact,
# not an assumption.
$ErrorActionPreference = 'Stop'
$token = gcloud auth print-access-token
if (-not $token) { Write-Output 'NO_GCLOUD_AUTH'; exit 2 }
$h = @{ Authorization = "Bearer $token" }
$rel = Invoke-RestMethod -Uri 'https://firebaserules.googleapis.com/v1/projects/datedawn/releases' -Headers $h |
Where-Object { $_.releases } | ForEach-Object { $_.releases } |
Where-Object { $_.name -like '*cloud.firestore*' } | Select-Object -First 1
$rs = Invoke-RestMethod -Uri "https://firebaserules.googleapis.com/v1/$($rel.rulesetName)" -Headers $h
$live = ($rs.source.files | ForEach-Object { $_.content }) -join "`n"
$repo = (Get-Content firestore.rules -Raw)
function Norm([string]$t) { ($t -replace "`r`n", "`n").Trim() }
$sha = { param($t) $s = [System.Security.Cryptography.SHA256]::Create(); $b = [Text.Encoding]::UTF8.GetBytes((Norm $t)); ([BitConverter]::ToString($s.ComputeHash($b)) -replace '-', '') }
Write-Output ("released ruleset : " + $rel.rulesetName)
Write-Output ("released at      : " + $rel.updateTime)
Write-Output ("live sha256      : " + (& $sha $live))
Write-Output ("repo sha256      : " + (& $sha $repo))
Write-Output ("MATCH            : " + ((& $sha $live) -eq (& $sha $repo)))
Write-Output ("live has isEventCreatorAfter : " + ($live -match 'function isEventCreatorAfter'))
Write-Output ("live roleChange allows peer  : " + (-not ($live -match 'myRank\(eventId\) > rank\(previousRole\(\)\)')))