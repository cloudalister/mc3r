@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "SRC=%ROOT%\PS2Recomp"
set "BUILD=%SRC%\out\build"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\03_build_ps2recomp.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Build PS2Recomp - %DATE% %TIME%

where cmake >nul 2>nul
if errorlevel 1 (
  echo [ERROR] cmake not found in PATH.
  >> "%LOG%" echo [ERROR] cmake not found in PATH.
  exit /b 1
)

if not exist "%SRC%\CMakeLists.txt" (
  echo [ERROR] PS2Recomp source not found: %SRC%
  >> "%LOG%" echo [ERROR] PS2Recomp source not found: %SRC%
  exit /b 1
)

where ninja >nul 2>nul
if errorlevel 1 (
  set "GENERATOR="
) else (
  set "GENERATOR=-G Ninja"
)

echo Configuring...
cmake -S "%SRC%" -B "%BUILD%" %GENERATOR% -DFETCHCONTENT_UPDATES_DISCONNECTED=ON >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] CMake configure failed. See %LOG%
  exit /b 1
)

echo Building...
cmake --build "%BUILD%" --config Debug >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Build failed. See %LOG%
  exit /b 1
)

echo [OK] PS2Recomp build finished.
>> "%LOG%" echo [OK] PS2Recomp build finished.
exit /b 0
