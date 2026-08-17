@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "EXE=%ROOT%\work\link\partial\mc3_partial.exe"
set "ELF=%ROOT%\extracted_iso\SLUS_213.55"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\14_run_boot_trace.log"
set "SECONDS=%~1"

if "%SECONDS%"=="" set "SECONDS=30"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo MC3 boot trace - %DATE% %TIME%

set "DETERMINISTIC=no"
set "DISPATCH_BUDGET=n/a"
if "%MC3_DETERMINISTIC%"=="1" (
  powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\Boot-Probe.ps1" -ValidateDeterministicBudget
  if errorlevel 1 exit /b 2
  set "DETERMINISTIC=yes"
  set "DISPATCH_BUDGET=%MC3_DISPATCH_BUDGET%"
) else (
  rem Keep the legacy wall-clock probe even if a caller left a budget behind.
  set "MC3_DISPATCH_BUDGET="
)

if not exist "%EXE%" (
  echo [ERROR] Partial runner not found: %EXE%
  >> "%LOG%" echo [ERROR] Partial runner missing.
  exit /b 1
)

if not exist "%ELF%" (
  echo [ERROR] ELF not found: %ELF%
  >> "%LOG%" echo [ERROR] ELF missing.
  exit /b 1
)

echo EXE: %EXE%
echo ELF: %ELF%
echo Timeout: %SECONDS%s
echo Deterministic: %DETERMINISTIC%
echo Dispatch budget: %DISPATCH_BUDGET%
>> "%LOG%" echo EXE: %EXE%
>> "%LOG%" echo ELF: %ELF%
>> "%LOG%" echo Timeout: %SECONDS%s
>> "%LOG%" echo [boot-trace-driver] deterministic=%DETERMINISTIC% dispatch-budget=%DISPATCH_BUDGET%
>> "%LOG%" echo [boot-trace-driver] MC3_DETERMINISTIC=%MC3_DETERMINISTIC% MC3_DISPATCH_BUDGET=%MC3_DISPATCH_BUDGET%

"powershell.exe" -NoProfile -ExecutionPolicy Bypass -Command ^
  "$env:MC3_BOOT_TRACE='1';" ^
  "$quotedElf = '\"%ELF%\"';" ^
  "$p = Start-Process -FilePath '%EXE%' -ArgumentList $quotedElf -NoNewWindow -PassThru -RedirectStandardOutput '%LOG%.stdout' -RedirectStandardError '%LOG%.stderr';" ^
  "if (-not $p.WaitForExit([int]%SECONDS% * 1000)) { '[boot-trace-driver] timeout reached; stopping process id=' + $p.Id | Add-Content -LiteralPath '%LOG%'; Stop-Process -Id $p.Id -Force; Start-Sleep -Milliseconds 250; }" ^
  "else { '[boot-trace-driver] exit code=' + $p.ExitCode | Add-Content -LiteralPath '%LOG%'; }" ^
  "Get-Content -LiteralPath '%LOG%.stdout','%LOG%.stderr' -ErrorAction SilentlyContinue | Add-Content -LiteralPath '%LOG%';"

echo [OK] Boot trace written: %LOG%
exit /b 0
