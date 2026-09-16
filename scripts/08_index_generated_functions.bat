@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "SCRIPT=%ROOT%\tools\Index-GhidraExport.ps1"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\08_index_generated_functions.log"
set "BATCH_SIZE=%~1"

if "%BATCH_SIZE%"=="" set "BATCH_SIZE=250"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Index generated functions - %DATE% %TIME%

if not exist "%SCRIPT%" (
  echo [ERROR] Missing script: %SCRIPT%
  >> "%LOG%" echo [ERROR] Missing script.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -BatchSize %BATCH_SIZE% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Index generation failed. See %LOG%
  exit /b 1
)

type "%LOG%"
exit /b 0
