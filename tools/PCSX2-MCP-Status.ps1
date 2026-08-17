param(
    [string]$ConfigPath = "work\config\pcsx2_mcp.local.json"
)

$ErrorActionPreference = "Stop"

$Root = (Resolve-Path ".").Path
$ConfigFullPath = Join-Path $Root $ConfigPath

function Test-TcpPort {
    param(
        [string]$HostName,
        [int]$Port
    )

    try {
        $client = [System.Net.Sockets.TcpClient]::new()
        $async = $client.BeginConnect($HostName, $Port, $null, $null)
        $connected = $async.AsyncWaitHandle.WaitOne(500)
        if ($connected) {
            $client.EndConnect($async)
        }
        $client.Close()
        return $connected
    }
    catch {
        return $false
    }
}

function Get-NodeStatus {
    $node = Get-Command node -ErrorAction SilentlyContinue
    if (-not $node) {
        return [pscustomobject]@{
            Ok = $false
            Detail = "node not found"
            Version = "n/a"
        }
    }

    $versionText = (& node --version 2>$null)
    $version = [version]($versionText.TrimStart("v"))

    return [pscustomobject]@{
        Ok = ($version.Major -ge 18)
        Detail = $node.Source
        Version = $versionText
    }
}

if (-not (Test-Path -LiteralPath $ConfigFullPath)) {
    throw "Missing config: $ConfigFullPath"
}

$config = Get-Content -LiteralPath $ConfigFullPath -Raw | ConvertFrom-Json
$nodeStatus = Get-NodeStatus

$pcsx2Root = $config.pcsx2McpRoot
$skillRoot = $config.agentSkillRoot
$pcsx2Exe = Join-Path $pcsx2Root "pcsx2-qt.exe"
$mcpServerDir = Join-Path $pcsx2Root "pcsx2-mcp-server"
$mcpServerPackage = Join-Path $mcpServerDir "package.json"
$mcpServerDist = Join-Path $mcpServerDir "dist"
$skillFile = Join-Path $skillRoot "SKILL.md"

$debugPortOpen = Test-TcpPort -HostName $config.debugServerHost -Port ([int]$config.debugServerPort)
$pinePortOpen = Test-TcpPort -HostName $config.pineHost -Port ([int]$config.pinePort)
$pcsx2Processes = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
    $_.ProcessName -like "pcsx2*" -or $_.ProcessName -like "PCSX2*"
})

$checks = @(
    [pscustomobject]@{ Check = "Node >= 18"; Ok = $nodeStatus.Ok; Detail = "$($nodeStatus.Version) ($($nodeStatus.Detail))" },
    [pscustomobject]@{ Check = "PCSX2-MCP root"; Ok = (Test-Path -LiteralPath $pcsx2Root); Detail = $pcsx2Root },
    [pscustomobject]@{ Check = "PCSX2 MCP executable"; Ok = (Test-Path -LiteralPath $pcsx2Exe); Detail = $pcsx2Exe },
    [pscustomobject]@{ Check = "MCP server package"; Ok = (Test-Path -LiteralPath $mcpServerPackage); Detail = $mcpServerPackage },
    [pscustomobject]@{ Check = "MCP server dist"; Ok = (Test-Path -LiteralPath $mcpServerDist); Detail = $mcpServerDist },
    [pscustomobject]@{ Check = "ps2-recomp skill"; Ok = (Test-Path -LiteralPath $skillFile); Detail = $skillFile },
    [pscustomobject]@{ Check = "ISO path"; Ok = (Test-Path -LiteralPath $config.isoPath); Detail = $config.isoPath },
    [pscustomobject]@{ Check = "ELF path"; Ok = (Test-Path -LiteralPath $config.elfPath); Detail = $config.elfPath },
    [pscustomobject]@{ Check = "Partial runner"; Ok = (Test-Path -LiteralPath $config.partialRunnerPath); Detail = $config.partialRunnerPath },
    [pscustomobject]@{ Check = "DebugServer TCP $($config.debugServerPort)"; Ok = $debugPortOpen; Detail = "$($config.debugServerHost):$($config.debugServerPort)" },
    [pscustomobject]@{ Check = "PINE TCP $($config.pinePort)"; Ok = $pinePortOpen; Detail = "$($config.pineHost):$($config.pinePort)" },
    [pscustomobject]@{ Check = "PCSX2 process"; Ok = ($pcsx2Processes.Count -gt 0); Detail = (($pcsx2Processes | ForEach-Object { "$($_.ProcessName):$($_.Id)" }) -join ", ") }
)

Write-Host "MC3 PCSX2-MCP status"
Write-Host "Root: $Root"
Write-Host "Config: $ConfigFullPath"
Write-Host ""

foreach ($check in $checks) {
    $mark = if ($check.Ok) { "[OK]" } else { "[PENDING]" }
    Write-Host ("{0} {1}: {2}" -f $mark, $check.Check, $check.Detail)
}

Write-Host ""
Write-Host "Notes:"
Write-Host "- This script does not launch PCSX2."
Write-Host "- Ports are expected to be open only after the PCSX2-MCP build is running with a game loaded."
Write-Host "- If PCSX2-MCP is missing, extract its release into: $pcsx2Root"

$required = @("Node >= 18", "ISO path", "ELF path", "Partial runner")
$hardFailures = @($checks | Where-Object { $required -contains $_.Check -and -not $_.Ok })
if ($hardFailures.Count -gt 0) {
    exit 1
}

exit 0
