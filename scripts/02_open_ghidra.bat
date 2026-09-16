@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\02_open_ghidra.log"
set "BOOT_ELF=%ROOT%\extracted_iso\SLUS_213.55"
set "GHIDRA_SCRIPT=%ROOT%\PS2Recomp\ps2xRecomp\tools\ghidra\ExportPS2Functions.java"
set "GHIDRA_TEMP=%LOCALAPPDATA%\Temp\ghidra"
set "GHIDRA_RUN_FOUND="

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%GHIDRA_TEMP%" mkdir "%GHIDRA_TEMP%"
> "%LOG%" echo Open Ghidra - %DATE% %TIME%

if defined GHIDRA_RUN if exist "%GHIDRA_RUN%" set "GHIDRA_RUN_FOUND=%GHIDRA_RUN%"
if not defined GHIDRA_RUN_FOUND if defined GHIDRA_HOME if exist "%GHIDRA_HOME%\ghidraRun.bat" set "GHIDRA_RUN_FOUND=%GHIDRA_HOME%\ghidraRun.bat"
if not defined GHIDRA_RUN_FOUND for /d %%D in ("%ROOT%\ghidra_*_PUBLIC") do if exist "%%~fD\ghidraRun.bat" set "GHIDRA_RUN_FOUND=%%~fD\ghidraRun.bat"
if not defined GHIDRA_RUN_FOUND if exist "%ROOT%\ghidraRun.bat" set "GHIDRA_RUN_FOUND=%ROOT%\ghidraRun.bat"

if not defined GHIDRA_RUN_FOUND (
  echo [ERROR] ghidraRun.bat not found.
  echo Set GHIDRA_RUN to the full path of ghidraRun.bat or install a full Ghidra distribution.
  echo Existing Emotion Engine extension path:
  echo   %ROOT%\ghidra_11.4.1_PUBLIC\Extensions\ghidra-emotionengine-reloaded
  >> "%LOG%" echo [ERROR] ghidraRun.bat not found.
  exit /b 1
)

if not exist "%BOOT_ELF%" (
  echo [WARN] Boot ELF not extracted yet: %BOOT_ELF%
  echo Run 01_extract_iso.bat before importing the game ELF.
  >> "%LOG%" echo [WARN] Boot ELF not extracted yet: %BOOT_ELF%
)

echo Ghidra: %GHIDRA_RUN_FOUND%
echo Suggested project dir: %ROOT%\work\ghidra
echo Boot ELF: %BOOT_ELF%
echo Export script: %GHIDRA_SCRIPT%
echo Temp dir: %GHIDRA_TEMP%
>> "%LOG%" echo Ghidra: %GHIDRA_RUN_FOUND%
>> "%LOG%" echo Suggested project dir: %ROOT%\work\ghidra
>> "%LOG%" echo Boot ELF: %BOOT_ELF%
>> "%LOG%" echo Export script: %GHIDRA_SCRIPT%
>> "%LOG%" echo Temp dir: %GHIDRA_TEMP%

start "" "%GHIDRA_RUN_FOUND%"
exit /b 0
