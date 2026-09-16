@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "SCRIPT=%ROOT%\tools\Trace-DrivenCompile.ps1"
set "MAX_BATCHES=%~1"
set "LIMIT=%~2"
set "TIMEOUT_SECONDS=%~3"

if "%MAX_BATCHES%"=="" set "MAX_BATCHES=2"
if "%LIMIT%"=="" set "LIMIT=250"
if "%TIMEOUT_SECONDS%"=="" set "TIMEOUT_SECONDS=120"

if not exist "%SCRIPT%" (
  echo [ERROR] Missing script: %SCRIPT%
  exit /b 1
)

echo Trace-driven compile
echo Root: %ROOT%
echo Max batches this run: %MAX_BATCHES%
echo Functions per batch limit: %LIMIT%
echo Timeout per file: %TIMEOUT_SECONDS%s
echo.

pushd "%ROOT%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -MaxBatches %MAX_BATCHES% -Limit %LIMIT% -TimeoutSeconds %TIMEOUT_SECONDS%
set "EXITCODE=%ERRORLEVEL%"
popd

echo.
echo Exit code: %EXITCODE%
echo Latest status:
echo   %ROOT%\work\trace_driven\latest_status.md
echo Logs:
echo   %ROOT%\work\logs\12_trace_driven_compile_*.log
exit /b %EXITCODE%
