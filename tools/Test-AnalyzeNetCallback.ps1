$ErrorActionPreference = 'Stop'
$analyzer = Join-Path $PSScriptRoot 'Analyze-NetCallback.ps1'
$prefix = '[net-callback] seq=1 object=00000123 target=001f9e20 starts=2 ends=1 wallNs=5000000 maxNs=5000000 active=1 abandoned=0 overflow=0 unmatched=0'
$r = (& $analyzer -Lines @('corrupt [net-callback]', $prefix)) | ConvertFrom-Json
if ($r.completeRecords -ne 1 -or $r.rows[0].meanMilliseconds -ne 5 -or $r.rows[0].active -ne 1) { throw 'Parsing failed' }
$rejected = $false
try { & $analyzer -Lines @('absent') | Out-Null } catch { $rejected = $true }
if (!$rejected) { throw 'Missing records accepted' }
$rejected = $false
try { & $analyzer -Lines @($prefix, $prefix.Replace('starts=2', 'starts=1')) | Out-Null } catch { $rejected = $true }
if (!$rejected) { throw 'Counter regression accepted' }
'PASS: callback parsing, partial line, missing evidence and regression checks'
