@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "EXE=%ROOT%\work\link\partial\mc3_partial.exe"
set "ELF=%ROOT%\extracted_iso\SLUS_213.55"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\11_run_partial_runner.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Run partial MC3 runner - %DATE% %TIME%

if not exist "%EXE%" (
  echo [ERROR] Partial runner not found: %EXE%
  echo Run 10_link_partial_runner.bat first.
  >> "%LOG%" echo [ERROR] Partial runner missing.
  exit /b 1
)

if not exist "%ELF%" (
  echo [ERROR] ELF not found: %ELF%
  echo Run 01_extract_iso.bat first.
  >> "%LOG%" echo [ERROR] ELF missing.
  exit /b 1
)

echo EXE: %EXE%
echo ELF: %ELF%
echo This runner is partial: uncompiled functions are temporary stop stubs.
>> "%LOG%" echo EXE: %EXE%
>> "%LOG%" echo ELF: %ELF%

"%EXE%" "%ELF%" >> "%LOG%" 2>&1
set "EXITCODE=%ERRORLEVEL%"
echo Exit code: %EXITCODE%
>> "%LOG%" echo Exit code: %EXITCODE%
exit /b %EXITCODE%
