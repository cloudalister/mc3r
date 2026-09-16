<#
.SYNOPSIS
  One-command refresh + publish of the MC3 code atlas (progress/) as a static
  snapshot under docs/atlas/, then stages and commits it in this repo.

.DESCRIPTION
  1. Runs `node scripts/refresh.mjs` inside progress/ to regenerate
     progress/public/progress-data.json from ../work/exports and ../work/index.
  2. Copies progress-data.json (and favicon.svg, if present) into docs/atlas/,
     next to the static index.html snapshot.
  3. Stages docs/atlas/ with git and creates a commit. It never pushes -
     run `git push origin main` yourself when you're ready.

  Uses only paths relative to the repo root, so it works regardless of where
  the repo is cloned.

.USAGE
  powershell -ExecutionPolicy Bypass -File tools\Publish-Atlas.ps1
#>

$ErrorActionPreference = 'Stop'

$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

Write-Host '[1/3] Refreshing progress-data.json from work/exports and work/index...'
Push-Location (Join-Path $repoRoot 'progress')
try {
    node scripts/refresh.mjs
} finally {
    Pop-Location
}

Write-Host '[2/3] Copying the snapshot into docs/atlas/...'
$src = Join-Path $repoRoot 'progress\public\progress-data.json'
$dstDir = Join-Path $repoRoot 'docs\atlas'
New-Item -ItemType Directory -Force -Path $dstDir | Out-Null
Copy-Item -Path $src -Destination (Join-Path $dstDir 'progress-data.json') -Force

$favicon = Join-Path $repoRoot 'progress\public\favicon.svg'
if (Test-Path $favicon) {
    Copy-Item -Path $favicon -Destination (Join-Path $dstDir 'favicon.svg') -Force
}

Write-Host '[3/3] Staging and committing docs/atlas/...'
git add docs/atlas
$staged = git diff --cached --name-only -- docs/atlas
if (-not $staged) {
    Write-Host 'No changes to commit (docs/atlas/ already up to date).'
} else {
    git commit -m "Refresh published code atlas snapshot"
    Write-Host ''
    Write-Host 'Commit created. Push it yourself when ready:'
    Write-Host '  git push origin main'
}
