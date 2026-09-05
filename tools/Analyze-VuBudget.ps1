param([Parameter(Mandatory=$true)][string]$LogPath)
$ErrorActionPreference = 'Stop'
# Read-only; Select-String also permits inspecting a log still owned by the runner.
$events = @()
foreach ($match in (Select-String -LiteralPath $LogPath -Pattern '\[vu1-budget\] idx=')) {
    $m = [regex]::Match($match.Line, '\[vu1-budget\] idx=(\d+) entry=([0-9a-f]+) final=([0-9a-f]+) cycles=(\d+) budget=(\d+) reason=([a-z-]+) ebit=(\d+) pending=(\d+) target=([0-9a-f]+) codeFnv=([0-9a-f]+) itop=(\d+)')
    if (!$m.Success) { continue }
    $events += [pscustomobject]@{
        index=[int]$m.Groups[1].Value; entry=$m.Groups[2].Value; final=$m.Groups[3].Value
        cycles=[long]$m.Groups[4].Value; budget=[long]$m.Groups[5].Value
        reason=$m.Groups[6].Value; ebit=[int]$m.Groups[7].Value
        pending=[int]$m.Groups[8].Value; target=$m.Groups[9].Value
        codeFnv=$m.Groups[10].Value; itop=[int]$m.Groups[11].Value
    }
}
$steps = @()
foreach ($match in (Select-String -LiteralPath $LogPath -Pattern '\[vu1-budget-step\]')) {
    $m = [regex]::Match($match.Line, '\[vu1-budget-step\] idx=(\d+) cycle=(\d+) pc=([0-9a-f]+) lower=([0-9a-f]+) upper=([0-9a-f]+) pending=(\d+) target=([0-9a-f]+) ebit=(\d+)')
    if (!$m.Success) { continue }
    $steps += [pscustomobject]@{
        index=[int]$m.Groups[1].Value; cycle=[long]$m.Groups[2].Value
        pc=$m.Groups[3].Value; lower=$m.Groups[4].Value; upper=$m.Groups[5].Value
        pending=[int]$m.Groups[6].Value; target=$m.Groups[7].Value; ebit=[int]$m.Groups[8].Value
    }
}
[ordered]@{
    log=$LogPath; capturedEvents=$events.Count
    events=$events
    tails=@($events | ForEach-Object {
        $event = $_
        $tail = @($steps | Where-Object index -eq $event.index)
        [ordered]@{ index=$event.index; capturedSteps=$tail.Count
            uniquePCs=@($tail.pc | Select-Object -Unique)
            orderedPCs=($tail.pc -join ',') }
    })
    limits='First eight boundary events only; tail covers final 32 budget slots. Code hash identifies whole code memory, not necessarily a unique entry program. Budget is not proof of an infinite loop.'
} | ConvertTo-Json -Depth 6
