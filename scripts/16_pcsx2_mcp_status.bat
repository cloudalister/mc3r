@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "SCRIPT=%ROOT%\tools\PCSX2-MCP-Status.ps1"

if not exist "%SCRIPT%" (
  echo [ERROR] PCSX2-MCP status script not found: %SCRIPT%
  exit /b 1
)

pushd "%ROOT%" >nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%"
set "EXITCODE=%ERRORLEVEL%"
popd >nul

exit /b %EXITCODE%
