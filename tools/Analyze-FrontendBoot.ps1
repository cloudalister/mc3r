param([Parameter(Mandatory=$true)][string]$LogPath)
$ErrorActionPreference = 'Stop'
$lastPosition = $null
$positionSamples = 0
$regressions = 0
$maximumPosition = [int]::MinValue
$writers = @()
$capSamples = 0
$nonzeroCaps = 0
$lastCycles = $null
$lastCaps = $null
foreach ($line in [IO.File]::ReadLines((Resolve-Path -LiteralPath $LogPath).Path)) {
    $m = [regex]::Match($line, 'feView=0x([0-9a-f]+) fe49=(\d+) fe6AC=(-?\d+) fe6B0=(\d+) feAnim=0x([0-9a-f]+)')
    if ($m.Success) {
        $v = [int]$m.Groups[3].Value
        if ($null -ne $lastPosition -and $v -lt $lastPosition) { $regressions++ }
        $lastPosition = $v
        $maximumPosition = [math]::Max($maximumPosition, $v)
        $positionSamples++
    }
    $m = [regex]::Match($line, 'vu1Cycles=(\d+) vu1CapHits=(\d+) delayThreadCalls=(\d+) setTimerAlarmCalls=(\d+)')
    if ($m.Success) {
        $capSamples++
        $lastCycles = [long]$m.Groups[1].Value
        $lastCaps = [long]$m.Groups[2].Value
        if ($lastCaps -gt 0) { $nonzeroCaps++ }
    }
    $m = [regex]::Match($line, '\[mc3-fe-write\] n=(\d+) pc=0x([0-9a-f]+) obj=0x([0-9a-f]+) old=(-?\d+) new=(-?\d+) slot=(\d+) camera=0x([0-9a-f]+) length=(\d+) flag38=(\d+) flag49=(\d+) flag4a=(\d+) timer=(\S+) duration=(\S+) f20=(\S+) ra=0x([0-9a-f]+)')
    if ($m.Success) {
        $writers += [pscustomobject]@{ pc=$m.Groups[2].Value; old=[int]$m.Groups[4].Value; new=[int]$m.Groups[5].Value; object=$m.Groups[3].Value; slot=$m.Groups[6].Value; timer=$m.Groups[12].Value }
    }
}
[ordered]@{
    log = $LogPath
    completePositionSamples = $positionSamples
    positionRegressions = $regressions
    maxPosition = if ($positionSamples) { $maximumPosition } else { $null }
    lastPosition = $lastPosition
    completeCapSamples = $capSamples
    nonzeroCapSamples = $nonzeroCaps
    lastVuCycles = $lastCycles
    lastVuCapHits = $lastCaps
    completeWriteEvents = $writers.Count
    writerCounts = @($writers | Group-Object pc | Select-Object Name,Count)
    lastWrite = $writers | Select-Object -Last 1
    limits = 'Sampled fields can miss changes between samples; corrupt blocks rejected. Cap tally counts reaching budget, including a possible normal exit on the final cycle. No exclusive wall-time attribution.'
} | ConvertTo-Json -Depth 5
