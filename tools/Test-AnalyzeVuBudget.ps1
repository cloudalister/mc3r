$ErrorActionPreference = 'Stop'
$fixture = Join-Path $PSScriptRoot 'diagnostics\vu_budget_parser_fixture.txt'
$result = (& (Join-Path $PSScriptRoot 'Analyze-VuBudget.ps1') -LogPath $fixture) | ConvertFrom-Json
if ($result.capturedEvents -ne 3) { throw 'Incomplete event must be rejected' }
if ($result.events[0].reason -ne 'end-bit' -or $result.events[0].ebit -ne 1) { throw 'Normal end at boundary lost' }
if ($result.events[1].reason -ne 'budget' -or $result.events[1].ebit -ne 0) { throw 'Exhaustion confused with normal end' }
if ($result.events[2].reason -ne 'budget' -or $result.events[2].ebit -ne 1) { throw 'Pending end-bit delay lost' }
if ($result.tails[0].orderedPCs -ne '0000,0008' -or $result.tails[1].capturedSteps -ne 2) { throw 'Tail ordering/grouping broken' }
if ($result.tails[2].capturedSteps -ne 0) { throw 'Missing steps must not be invented' }
'PASS: boundary reasons, ordered tails, incomplete records, missing data'
