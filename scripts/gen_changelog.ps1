<#
Generate a simple changelog between previous tag and current tag.
Usage:
  powershell -File scripts\gen_changelog.ps1 -TagName v1.2.3 -OutFile changelog.txt
If TagName is omitted the script tries to read from CI env vars (GITHUB_REF_NAME, APPVEYOR_REPO_TAG_NAME).
This script is cross-platform (pwsh or powershell).
#>

param(
  [string]$TagName = $null,
  [string]$OutFile = "changelog.txt"
)

function Get-EnvTag {
  if ($env:GITHUB_REF_NAME) { return $env:GITHUB_REF_NAME }
  if ($env:APPVEYOR_REPO_TAG_NAME) { return $env:APPVEYOR_REPO_TAG_NAME }
  if ($env:GITHUB_REF) {
    # refs/tags/<tag>
    if ($env:GITHUB_REF -match 'refs/tags/(.+)') { return $matches[1] }
  }
  return $null
}

if (-not $TagName) { $TagName = Get-EnvTag }

if (-not $TagName) {
  Write-Host "No tag name provided and no CI tag env found. Skipping changelog generation.";
  exit 0
}

Write-Host "Generating changelog for tag: $TagName -> $OutFile"

# Ensure tags are available
git fetch --tags --prune 2>$null

# get tags sorted by creatordate
$tags = git for-each-ref --sort=creatordate --format='%(refname:strip=2)' refs/tags | ForEach-Object { $_.Trim() }

if (-not $tags) {
  Write-Host "No tags found in repository.";
  exit 0
}

$idx = $tags.IndexOf($TagName)
if ($idx -lt 0) {
  Write-Host "Tag $TagName not found in tag list; attempting to continue using $TagName as single reference.";
  $range = $TagName
} else {
  if ($idx -gt 0) {
    $prev = $tags[$idx - 1]
    Write-Host "Previous tag found: $prev"
    $range = "$prev..$TagName"
  } else {
    Write-Host "No previous tag found. Using only $TagName for changelog.";
    $range = $TagName
  }
}

# produce a simple bullet list
$log = git --no-pager log --pretty=format:"- %h %s (%an)" $range 2>$null

if (-not $log) {
  Write-Host "No commits found for range $range";
  "No changes." | Out-File -FilePath $OutFile -Encoding utf8
} else {
  $header = "Changelog for $TagName`n`n"
  $header | Out-File -FilePath $OutFile -Encoding utf8
  $log | Out-File -FilePath $OutFile -Encoding utf8 -Append
}

Write-Host "Wrote $OutFile"
