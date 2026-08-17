param(
    [string]$LiveEvidencePath = "",
    [string]$Mode = "current"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$CompareDir = Join-Path $Root "work\live_compare"
$StatusPath = Join-Path $CompareDir "latest_status.md"
$BootStatusPath = Join-Path $Root "work\boot_probe\latest_status.md"
$HandoffPath = Join-Path $Root "docs\GEMINI_PCSX2_MCP_HANDOFF.md"
$updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$bt = [char]96

New-Item -ItemType Directory -Force -Path $CompareDir | Out-Null

function Get-Classification {
    param([string]$Text)

    if ([string]::IsNullOrWhiteSpace($Text)) {
        return "pending-live-trace"
    }
    if ($Text -match "(?i)gif|gsw|vif|render traffic|gs packet|gif packet") {
        return "render-traffic"
    }
    if ($Text -match "(?i)missing function|function not found|uncompiled") {
        return "missing-function"
    }
    if ($Text -match "(?i)bad return|wrong return|return value|v0") {
        return "bad-return"
    }
    if ($Text -match "(?i)memory init|uninitialized|global|0x0061|0x0062|write") {
        return "memory-init"
    }
    if ($Text -match "(?i)sif|iop|sema|semaphore|callback|dma") {
        return "runtime-stub"
    }
    return "unknown"
}

$liveEvidenceFullPath = $null
$liveEvidence = ""
if (-not [string]::IsNullOrWhiteSpace($LiveEvidencePath)) {
    $liveEvidenceFullPath = if ([System.IO.Path]::IsPathRooted($LiveEvidencePath)) {
        $LiveEvidencePath
    } else {
        Join-Path $Root $LiveEvidencePath
    }

    if (-not (Test-Path -LiteralPath $liveEvidenceFullPath)) {
        throw "Live evidence file not found: $liveEvidenceFullPath"
    }

    $liveEvidence = Get-Content -LiteralPath $liveEvidenceFullPath -Raw
}

$classification = Get-Classification -Text $liveEvidence
$bootSummary = if (Test-Path -LiteralPath $BootStatusPath) {
    $lines = Get-Content -LiteralPath $BootStatusPath
    ($lines | Select-String -Pattern "Classification|Stable PC|Function|Render counters" | ForEach-Object { $_.Line }) -join "`r`n"
} else {
    "No boot probe status found."
}

$evidenceNote = if ($liveEvidenceFullPath) {
    "Live evidence: ${bt}$liveEvidenceFullPath${bt}"
} else {
    "Live evidence: pending"
}

$excerpt = if ([string]::IsNullOrWhiteSpace($liveEvidence)) {
    "No live evidence has been imported yet."
} else {
    $liveEvidence.Trim()
    if ($liveEvidence.Length -gt 6000) {
        $liveEvidence.Substring(0, 6000).Trim() + "`r`n`r`n[truncated]"
    } else {
        $liveEvidence.Trim()
    }
}

$status = @"
# MC3 Live Compare Status

Updated: $updated  
Mode: $Mode

## State

- Handoff: ${bt}$HandoffPath${bt}
- $evidenceNote
- Classification: ${bt}$classification${bt}

## Recomp Snapshot

~~~text
$bootSummary
~~~

## Live Evidence Excerpt

~~~text
$excerpt
~~~

## Next Action

If classification is ${bt}pending-live-trace${bt}, run ${bt}17_live_trace_handoff.bat current${bt} and give ${bt}docs\GEMINI_PCSX2_MCP_HANDOFF.md${bt} to Gemini with PCSX2-MCP enabled.

If classification is not pending, Codex should turn the single strongest live delta into one env-gated runtime experiment, rebuild, relink fast, and verify with ${bt}15_auto_boot_probe.bat 8 595${bt}.
"@

Set-Content -LiteralPath $StatusPath -Value $status -Encoding UTF8

Write-Host "[OK] Live compare status: $StatusPath"
Write-Host "[OK] Classification: $classification"
