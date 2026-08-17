@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "EVIDENCE=%~1"
set "MODE=%~2"
set "SCRIPT=%ROOT%\tools\Update-LiveCompareStatus.ps1"

if "%MODE%"=="" set "MODE=current"

if not exist "%SCRIPT%" (
  echo [ERROR] Live compare script not found: %SCRIPT%
  exit /b 1
)

pushd "%ROOT%" >nul
if "%EVIDENCE%"=="" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Mode "%MODE%"
) else (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -LiveEvidencePath "%EVIDENCE%" -Mode "%MODE%"
)
set "EXITCODE=%ERRORLEVEL%"
popd >nul

exit /b %EXITCODE%
