@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "SCRIPT=%ROOT%\tools\Compile-GeneratedBatch.ps1"
set "LOGDIR=%ROOT%\work\logs"
set "BATCH=%~1"
set "LIMIT=%~2"
set "MODE=%~3"
set "TIMEOUT_SECONDS=%~4"

if "%BATCH%"=="" set "BATCH=batch_0001"
if "%LIMIT%"=="" set "LIMIT=25"
if "%MODE%"=="" set "MODE=syntax"
if "%TIMEOUT_SECONDS%"=="" set "TIMEOUT_SECONDS=180"

set "LOG=%LOGDIR%\09_compile_generated_%BATCH%_%MODE%.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Compile generated batch - %DATE% %TIME%
>> "%LOG%" echo Batch: %BATCH%
>> "%LOG%" echo Limit: %LIMIT%
>> "%LOG%" echo Mode: %MODE%
>> "%LOG%" echo TimeoutSeconds: %TIMEOUT_SECONDS%

if not exist "%SCRIPT%" (
  echo [ERROR] Missing script: %SCRIPT%
  >> "%LOG%" echo [ERROR] Missing script.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT%" -Batch "%BATCH%" -Limit %LIMIT% -Mode "%MODE%" -TimeoutSeconds %TIMEOUT_SECONDS% >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Batch compile failed. See %LOG%
  exit /b 1
)

type "%LOG%"
exit /b 0
