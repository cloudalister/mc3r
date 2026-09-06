$ErrorActionPreference='Stop'
$analyzer=Join-Path $PSScriptRoot 'Analyze-WaitProfile.ps1'
$lines=@(
 '[wait-profile] seq=1 tid=1 initialNs=1000000000 reacquireNs=0 holdNs=2000000000 blocksMainNs=0 holds=3',
 '[wait-profile] seq=1 tid=5 initialNs=0 reacquireNs=0 holdNs=3000000000 blocksMainNs=800000000 holds=2',
 'corrupt [wait-profile] seq=2 tid=1 initialNs=999',
 '[wait-profile] seq=2 tid=1 initialNs=3000000000 reacquireNs=1000000000 holdNs=4000000000 blocksMainNs=0 holds=5',
 '[wait-profile] seq=2 tid=5 initialNs=0 reacquireNs=0 holdNs=7000000000 blocksMainNs=2800000000 holds=4'
)
$r=(& $analyzer -Lines $lines -StartSequence 1) | ConvertFrom-Json
if($r.completeRecords -ne 4 -or $r.rows[0].tid -ne 5 -or $r.rows[0].blocksMainSeconds -ne 2){throw 'Delta/ranking/corrupt-line test failed'}
try { & $analyzer -Lines @('absent') | Out-Null; throw 'Unexpected acceptance' } catch { if($_.Exception.Message -notlike 'No complete*'){throw} }
try { & $analyzer -Lines @('[wait-profile] seq=1 tid=5 initialNs=0 reacquireNs=0 holdNs=1 blocksMainNs=2 holds=1') | Out-Null; throw 'Unexpected acceptance' } catch { if($_.Exception.Message -ne 'Attributed overlap exceeds hold time'){throw} }
try { & $analyzer -Lines @($lines[3],$lines[0]) | Out-Null; throw 'Unexpected acceptance' } catch { if($_.Exception.Message -notlike 'Counter regression*'){throw} }
'PASS: wait-profile deltas, ranking, corrupt-line rejection, regressions and absent/invalid counters'
