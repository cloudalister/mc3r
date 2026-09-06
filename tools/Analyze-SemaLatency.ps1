param([Parameter(Mandatory=$true)][string]$LogPath)
$ErrorActionPreference = 'Stop'
# Run against a closed log. Absolute monotonic timestamps are not durations.
$rows = @(foreach ($line in [IO.File]::ReadLines((Resolve-Path -LiteralPath $LogPath).Path)) {
    if ($line -notmatch '^\[sema-latency\] ') { continue }
    $fields = @{}
    foreach ($m in [regex]::Matches($line, '(\w+)=(\w+)')) { $fields[$m.Groups[1].Value] = $m.Groups[2].Value }
    $notifyDelta = $null
    if ([int]$fields.attempts -eq 1 -and [long]$fields.notifyNs -gt 0 -and [long]$fields.cvOutNs -ge [long]$fields.notifyNs) {
        $notifyDelta = ([long]$fields.cvOutNs - [long]$fields.notifyNs) / 1e6
    }
    [pscustomobject]@{
        sid=[int]$fields.sid; ra=$fields.ra; attempts=[int]$fields.attempts
        totalMs=[long]$fields.totalNs / 1e6; cvMs=[long]$fields.cvNs / 1e6
        tokenMs=[long]$fields.tokenNs / 1e6; mutexMs=[long]$fields.mutexNs / 1e6
        postMs=[long]$fields.postNs / 1e6; suspendMs=[long]$fields.suspendNs / 1e6
        notifyToCvOutMs=$notifyDelta
    }
})
[ordered]@{
    log=$LogPath
    completedWaits=$rows.Count
    blockedWaits=@($rows | Where-Object attempts -gt 0).Count
    timerWaits=@($rows | Where-Object ra -eq '005476b0')
    longestWaits=@($rows | Sort-Object totalMs -Descending | Select-Object -First 12)
    caveats='Only completed main-TLS waits; notify delta only for single-attempt waits. Logging overhead unmeasured. Phases are not an exhaustive additive partition.'
} | ConvertTo-Json -Depth 5
