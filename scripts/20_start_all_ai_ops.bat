@echo off
setlocal

set "ROOT=%~dp0"
cd /d "%ROOT%"

set "INTERVAL=%~1"
if "%INTERVAL%"=="" set "INTERVAL=1200"

set "MODE=%~2"
if "%MODE%"=="" set "MODE=payload1m3skip5a"

set "PROBE_SECONDS=%~3"
if "%PROBE_SECONDS%"=="" set "PROBE_SECONDS=6"

set "RUN_PROBE=%~4"
if "%RUN_PROBE%"=="" set "RUN_PROBE=0"

set "WATCH_SCRIPT=%ROOT%work\scripts\watch-mc3-progress.ps1"

echo [MC3 AI OPS]
echo Root: %ROOT%
echo Interval: %INTERVAL%s
echo Mode: %MODE%
echo Probe seconds: %PROBE_SECONDS%
echo Run probe loop: %RUN_PROBE%
echo.

if not exist "%WATCH_SCRIPT%" (
  echo [ERROR] Watch script not found: %WATCH_SCRIPT%
  exit /b 1
)

set "WATCH_ARGS=-NoProfile -ExecutionPolicy Bypass -File ""%WATCH_SCRIPT%"" -IntervalSeconds %INTERVAL% -Mode ""%MODE%"" -ProbeSeconds %PROBE_SECONDS%"
if "%RUN_PROBE%"=="1" set "WATCH_ARGS=%WATCH_ARGS% -RunProbe"

start "MC3 Watch Loop" powershell %WATCH_ARGS%

where ralph.cmd >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  start "MC3 Ralph Slot" powershell -NoExit -NoProfile -Command "cd /d '%ROOT%'; Write-Host 'Ralph slot pronto. Leia BRAIN.md e ataque: sid=44 / ra=0x1f7150 / SIF unhandled.'; ralph --help"
) else (
  echo [WARN] ralph.cmd nao encontrado no PATH.
)

where codex.cmd >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  start "MC3 Codex CLI Slot" powershell -NoExit -NoProfile -Command "cd /d '%ROOT%'; Write-Host 'Codex CLI slot pronto. Prompt sugerido:'; Write-Host 'Leia BRAIN.md checkpoint 2026-07-09 e mapeie 0x1f7150 / sid 44 sem mexer em PCSX2 memory.'; codex"
) else (
  echo [WARN] codex.cmd nao encontrado no PATH.
)

where antigravity >nul 2>nul
if %ERRORLEVEL% EQU 0 (
  start "MC3 Antigravity Slot" powershell -NoExit -NoProfile -Command "cd /d '%ROOT%'; antigravity ."
) else (
  where ag >nul 2>nul
  if %ERRORLEVEL% EQU 0 (
    start "MC3 Antigravity Slot" powershell -NoExit -NoProfile -Command "cd /d '%ROOT%'; ag ."
  ) else (
    echo [WARN] Antigravity CLI nao encontrado como antigravity/ag. Abra manualmente nesse root se precisar.
  )
)

echo.
echo Watch log: %ROOT%work\logs\ai_ops_watch.log
echo Status:    %ROOT%work\boot_probe\latest_status.md
echo.
echo Uso:
echo   20_start_all_ai_ops.bat 1200 payload1m3skip5a 6 0
echo   20_start_all_ai_ops.bat 1200 payload1m3skip5a 6 1  ^(tambem roda probe a cada intervalo^)
echo.
exit /b 0
