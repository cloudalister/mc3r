param(
    [string]$Mode = "current",
    [string]$ConfigPath = "work\config\pcsx2_mcp.local.json"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$ConfigFullPath = Join-Path $Root $ConfigPath
$DocsDir = Join-Path $Root "docs"
$OutputPath = Join-Path $DocsDir "GEMINI_PCSX2_MCP_HANDOFF.md"
$CompareDir = Join-Path $Root "work\live_compare"
$CompareStatusPath = Join-Path $CompareDir "latest_status.md"
$BootStatusPath = Join-Path $Root "work\boot_probe\latest_status.md"

if (-not (Test-Path -LiteralPath $ConfigFullPath)) {
    throw "Missing config: $ConfigFullPath"
}

New-Item -ItemType Directory -Force -Path $DocsDir, $CompareDir | Out-Null

$config = Get-Content -LiteralPath $ConfigFullPath -Raw | ConvertFrom-Json
$targets = $config.liveTraceTargets
$updated = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
$bootStatus = if (Test-Path -LiteralPath $BootStatusPath) {
    Get-Content -LiteralPath $BootStatusPath -Raw
} else {
    "No boot probe status file found yet."
}

$bt = [char]96
$functionList = ($targets.functions | ForEach-Object { "- $bt$($_)$bt" }) -join "`r`n"
$memoryList = ($targets.memory | ForEach-Object { "- $bt$($_)$bt" }) -join "`r`n"
$registerList = ($targets.registers | ForEach-Object { "$bt$($_)$bt" }) -join ", "

$handoff = @"
# Gemini Handoff: MC3 Live PCSX2-MCP Trace

Updated: $updated  
Mode: $Mode  
Workspace: ${bt}$Root${bt}

## Role

Read-only live investigation. Do not edit files. Use PCSX2-MCP to compare the real PS2 game against the native partial runner state.

## Tooling

- PCSX2-MCP root: ${bt}$($config.pcsx2McpRoot)${bt}
- MCP DebugServer: ${bt}$($config.debugServerHost):$($config.debugServerPort)${bt}
- PINE IPC: ${bt}$($config.pineHost):$($config.pinePort)${bt}
- Game serial: ${bt}$($config.gameSerial)${bt}
- ISO: ${bt}$($config.isoPath)${bt}
- ELF: ${bt}$($config.elfPath)${bt}
- Recomp probe command: ${bt}$($config.currentRecompProbeCommand)${bt}

## Current Recomp Facts

- Latest status file: ${bt}work\boot_probe\latest_status.md${bt}
- Current stable PC: ${bt}$($targets.stablePc)${bt}
- Current suspected blocker: ${bt}FUN_005422c8_0x5422c8${bt} still returns ${bt}0${bt} after ${bt}sub_005420C0_0x5420c0${bt} can return ${bt}1${bt}.
- Current useful result: recomp has early render traffic (${bt}dma=2${bt}, ${bt}vif=3${bt}) but no confirmed GIF/GSW yet.

## Live Trace Targets

Set breakpoints or inspect around these function PCs:

$functionList

Inspect these memory locations before and after each hit:

$memoryList

Capture these registers at every hit:

$registerList

Also disassemble a small window around each hit and capture the return value at function exit when practical.

## MCP Command Intent

Use the available PCSX2-MCP tools for:

- connect/status/game info;
- pause/continue;
- register reads;
- memory reads around the listed globals;
- disassembly around the listed PCs;
- breakpoints/watchpoints when available;
- backtrace/threads if the tool reports them reliably.

Avoid writes, save-state mutation, broad scans, and long unattended stepping.

## Questions To Answer

1. On real PCSX2, what makes ${bt}FUN_005422c8_0x5422c8${bt} return ${bt}1${bt}?
2. Which listed global changes immediately before that return?
3. Does real PCSX2 write ${bt}0x0061FC00${bt}, ${bt}0x00620D50${bt}, ${bt}0x00620D80${bt}, or ${bt}0x00621600${bt} differently from the recomp trace?
4. Is the recomp missing an IOP/SIF completion, a semaphore behavior, a return value, or a memory initialization?

## Output Contract

Return only:

- hypothesis;
- exact evidence from PCSX2-MCP output;
- compared recomp evidence path/log line if available;
- next minimal Codex experiment;
- expected trace change if correct.

Do not edit files.

## Current Boot Probe Snapshot

~~~md
$bootStatus
~~~
"@

Set-Content -LiteralPath $OutputPath -Value $handoff -Encoding UTF8

$compareStatus = @"
# MC3 Live Compare Status

Updated: $updated  
Mode: $Mode

## State

- Live PCSX2-MCP handoff generated: ${bt}$OutputPath${bt}
- Recomp probe command: ${bt}$($config.currentRecompProbeCommand)${bt}
- Current target PC: ${bt}$($targets.stablePc)${bt}
- Classification: ${bt}pending-live-trace${bt}

## Next Action

Run the handoff through Gemini/PCSX2-MCP, then paste back the MCP evidence so Codex can classify the delta as ${bt}runtime-stub${bt}, ${bt}missing-function${bt}, ${bt}bad-return${bt}, ${bt}memory-init${bt}, ${bt}render-traffic${bt}, or ${bt}unknown${bt}.
"@

Set-Content -LiteralPath $CompareStatusPath -Value $compareStatus -Encoding UTF8

Write-Host "[OK] Live trace handoff: $OutputPath"
Write-Host "[OK] Live compare status: $CompareStatusPath"
