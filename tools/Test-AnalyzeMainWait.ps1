$ErrorActionPreference = 'Stop'
$parser = Join-Path $PSScriptRoot 'Analyze-MainWait.ps1'
$sample = '[main-wait] kind=WaitSema argument=13 entryPc=005469e0 entryRa=00398b28 ageMs=123 tokenWaitMs=0 owner=7 dispatchPc=001a5fc0 semaPhase=cv-wait'
$result = (& $parser -Lines @('partial [main-wait]', $sample)) | ConvertFrom-Json
if ($result.completeRecords -ne 1 -or $result.last.argument -ne 13 -or $result.groups[0].maxObservedAgeMs -ne 123) { throw 'Wrong parsed snapshot' }
$caught = $false
try { & $parser -Lines @('absent') | Out-Null } catch { $caught = $true }
if (!$caught) { throw 'Missing evidence silently accepted' }
'PASS: main wait complete/partial/absent records'
