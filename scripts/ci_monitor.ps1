# Monitor GitHub Actions run for a tag and download logs
param(
  [string]$Owner = 'wangyan-life',
  [string]$Repo = 'freepiano',
  [string]$Tag = 'ci-trigger-20251031-113026',
  [int]$PollIntervalSec = 10,
  [int]$MaxAttempts = 360
)

$apiBase = "https://api.github.com/repos/$Owner/$Repo/actions/runs"
Write-Host "Searching runs for tag $Tag..."

$foundRun = $null
$attempt = 0
while ($attempt -lt $MaxAttempts) {
  $attempt++
  try {
    $resp = Invoke-RestMethod -Uri "$apiBase?per_page=100" -UseBasicParsing -Headers @{ 'User-Agent' = 'CI-monitor' }
  } catch {
    Write-Host "Failed to query GitHub API: $_"
    Start-Sleep -Seconds $PollIntervalSec
    continue
  }

  foreach ($run in $resp.workflow_runs) {
    # check possible fields that reference tag
    if ($null -ne $run.head_branch -and $run.head_branch -eq $Tag) { $foundRun = $run; break }
    if ($null -ne $run.head_ref -and $run.head_ref -eq $Tag) { $foundRun = $run; break }
    # sometimes refs/tags/<tag> appears in head_branch
    if ($null -ne $run.head_branch -and $run.head_branch -eq "refs/tags/$Tag") { $foundRun = $run; break }
    # check workflow_run head_commit message could include tag, skip
  }

  if ($foundRun) { Write-Host "Found run id $($foundRun.id) status=$($foundRun.status) conclusion=$($foundRun.conclusion)"; break }

  Write-Host "Attempt $($attempt)/$($MaxAttempts): run not found yet. Sleeping $PollIntervalSec seconds..."
  Start-Sleep -Seconds $PollIntervalSec
}

if (-not $foundRun) { Write-Host "No run found for tag $Tag after polling."; exit 2 }

$runId = $foundRun.id
Write-Host "Monitoring run id $runId..."

$attempt = 0
$r = $null
while ($attempt -lt $MaxAttempts) {
  $attempt++
  try {
    $r = Invoke-RestMethod -Uri "$apiBase/$runId" -UseBasicParsing -Headers @{ 'User-Agent' = 'CI-monitor' }
  } catch {
    Write-Host "Failed to query run status: $_"
    Start-Sleep -Seconds $PollIntervalSec
    continue
  }
  if ($r.status -eq 'completed') { Write-Host "Run completed with conclusion: $($r.conclusion)"; break }
  Write-Host "Attempt $($attempt): status=$($r.status). Sleeping $PollIntervalSec sec..."
  Start-Sleep -Seconds $PollIntervalSec
}

if ($null -eq $r -or $r.status -ne 'completed') { Write-Host "Run did not complete in time."; exit 3 }

# download logs
$logsUrl = "$apiBase/$runId/logs"
$outZip = "actions_run_${runId}_logs.zip"
Write-Host "Downloading logs to $outZip..."
try {
  Invoke-WebRequest -Uri $logsUrl -OutFile $outZip -Headers @{ 'User-Agent' = 'CI-monitor' } -UseBasicParsing
} catch {
  Write-Host "Failed to download logs: $_"; exit 4
}

$dest = "actions-logs-$runId"
if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
New-Item -ItemType Directory -Path $dest | Out-Null
try {
  Expand-Archive -Path $outZip -DestinationPath $dest -Force
} catch {
  Write-Host "Expand-Archive failed: $_"; exit 5
}

Write-Host "Logs extracted to: $dest"
Get-ChildItem -Recurse -Path $dest | Select-Object -First 40 | Format-Table -AutoSize
Write-Host "Summary: run conclusion = $($r.conclusion)"
if ($r.conclusion -ne 'success') { Write-Host "Run not successful. Inspect logs in $dest" }

Write-Host "Done."
