@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "EXPORTS=%ROOT%\work\exports"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\04_run_recomp.log"
set "RECOMP_EXE="
set "CONFIG=%~1"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%ROOT%\work\generated" mkdir "%ROOT%\work\generated"
> "%LOG%" echo Run PS2Recomp - %DATE% %TIME%

if not exist "%ROOT%\PS2Recomp\out\build" (
  echo [ERROR] Build directory not found. Run 03_build_ps2recomp.bat first.
  >> "%LOG%" echo [ERROR] Build directory not found.
  exit /b 1
)

for /r "%ROOT%\PS2Recomp\out\build" %%F in (ps2_recomp.exe ps2xRecomp.exe) do (
  if exist "%%F" set "RECOMP_EXE=%%F"
)

if not defined RECOMP_EXE (
  echo [ERROR] Recompiler executable not found. Run 03_build_ps2recomp.bat first.
  >> "%LOG%" echo [ERROR] Recompiler executable not found.
  exit /b 1
)

if not exist "%EXPORTS%" mkdir "%EXPORTS%"
if not defined CONFIG (
  if exist "%EXPORTS%\SLUS_213.55.ghidra.toml" set "CONFIG=%EXPORTS%\SLUS_213.55.ghidra.toml"
)
if not defined CONFIG (
  for /f "delims=" %%F in ('dir /b /a:-d /o:-d "%EXPORTS%\*.toml" 2^>nul') do (
    if not defined CONFIG set "CONFIG=%EXPORTS%\%%F"
  )
)

if not defined CONFIG (
  echo [ERROR] No TOML config found in %EXPORTS%.
  echo Export one from Ghidra with ExportPS2Functions.java first.
  >> "%LOG%" echo [ERROR] No TOML config found in exports.
  exit /b 1
)

echo Recompiler: %RECOMP_EXE%
echo Config: %CONFIG%
>> "%LOG%" echo Recompiler: %RECOMP_EXE%
>> "%LOG%" echo Config: %CONFIG%

"%RECOMP_EXE%" "%CONFIG%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Recompiler failed. See %LOG%
  exit /b 1
)

echo [OK] Recompiler finished. Check work\generated and %LOG%.
>> "%LOG%" echo [OK] Recompiler finished.
exit /b 0
