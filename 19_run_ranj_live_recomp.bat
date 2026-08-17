@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "CONFIG=%ROOT%\work\exports\SLUS_213.55.ranj_live.toml"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\19_run_ranj_live_recomp.log"
set "RECOMP_EXE="

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Run ranj_live PS2Recomp - %DATE% %TIME%

if not exist "%CONFIG%" (
  echo [ERROR] Missing TOML: %CONFIG%
  >> "%LOG%" echo [ERROR] Missing TOML: %CONFIG%
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

echo Recompiler: %RECOMP_EXE%
echo Config: %CONFIG%
>> "%LOG%" echo Recompiler: %RECOMP_EXE%
>> "%LOG%" echo Config: %CONFIG%

"%RECOMP_EXE%" "%CONFIG%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Recompiler failed. See %LOG%
  exit /b 1
)

echo [OK] ranj_live recomp finished. Output: work\generated\ranj_live
>> "%LOG%" echo [OK] ranj_live recomp finished.
exit /b 0
