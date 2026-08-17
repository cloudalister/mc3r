@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "GHIDRA_HEADLESS=%ROOT%\ghidra_12.1_PUBLIC\support\analyzeHeadless.bat"
set "PROJECT_DIR=%ROOT%\work"
set "PROJECT_NAME=mc2recomp"
set "SCRIPT_DIR=%ROOT%\PS2Recomp\ps2xRecomp\tools\ghidra"
set "EXPORTS=%ROOT%\work\exports"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\07_export_ghidra_headless.log"
set "SCRIPTLOG=%LOGDIR%\07_export_ghidra_headless.script.log"
set "TOML=%EXPORTS%\SLUS_213.55.ghidra.toml"
set "CSV=%EXPORTS%\SLUS_213.55.ghidra.csv"
set "RECOMP_OUT=%ROOT%\work\generated\ghidra"
set "GHIDRA_TEMP=%LOCALAPPDATA%\Temp\ghidra"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%EXPORTS%" mkdir "%EXPORTS%"
if not exist "%GHIDRA_TEMP%" mkdir "%GHIDRA_TEMP%"

> "%LOG%" echo Export Ghidra analysis - %DATE% %TIME%

if not exist "%GHIDRA_HEADLESS%" (
  echo [ERROR] analyzeHeadless.bat not found: %GHIDRA_HEADLESS%
  >> "%LOG%" echo [ERROR] analyzeHeadless.bat not found.
  exit /b 1
)

if not exist "%PROJECT_DIR%\%PROJECT_NAME%.gpr" (
  echo [ERROR] Ghidra project not found: %PROJECT_DIR%\%PROJECT_NAME%.gpr
  echo Open Ghidra and save/create the project first.
  >> "%LOG%" echo [ERROR] Ghidra project not found.
  exit /b 1
)

if exist "%PROJECT_DIR%\%PROJECT_NAME%.lock" (
  echo [ERROR] Ghidra project is currently open/locked: %PROJECT_DIR%\%PROJECT_NAME%.lock
  echo Close Ghidra first, then run this .bat again.
  >> "%LOG%" echo [ERROR] Ghidra project is locked.
  exit /b 1
)

echo Project: %PROJECT_DIR%\%PROJECT_NAME%
echo TOML: %TOML%
echo CSV: %CSV%
echo Recompiler output: %RECOMP_OUT%
>> "%LOG%" echo Project: %PROJECT_DIR%\%PROJECT_NAME%
>> "%LOG%" echo TOML: %TOML%
>> "%LOG%" echo CSV: %CSV%
>> "%LOG%" echo Recompiler output: %RECOMP_OUT%

call "%GHIDRA_HEADLESS%" "%PROJECT_DIR%" "%PROJECT_NAME%" -process "SLUS_213.55" -scriptPath "%SCRIPT_DIR%" -postScript ExportPS2Functions.java "%TOML%" "%CSV%" "%RECOMP_OUT%" -scriptlog "%SCRIPTLOG%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Headless Ghidra export failed. See %LOG%
  exit /b 1
)

if not exist "%TOML%" (
  echo [ERROR] TOML was not created: %TOML%
  >> "%LOG%" echo [ERROR] TOML was not created.
  exit /b 1
)

if not exist "%CSV%" (
  echo [ERROR] CSV was not created: %CSV%
  >> "%LOG%" echo [ERROR] CSV was not created.
  exit /b 1
)

echo [OK] Exported Ghidra TOML/CSV.
>> "%LOG%" echo [OK] Exported Ghidra TOML/CSV.
exit /b 0
