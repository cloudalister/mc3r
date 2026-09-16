@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "MODE=%~1"
set "SCRIPT=%ROOT%\tools\New-LiveTraceHandoff.ps1"

if "%MODE%"=="" set "MODE=current"

if not exist "%SCRIPT%" (
  echo [ERROR] Live trace handoff script not found: %SCRIPT%
  exit /b 1
)

pushd "%ROOT%" >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode "%MODE%"
set "EXITCODE=%ERRORLEVEL%"
popd >nul

exit /b %EXITCODE%
