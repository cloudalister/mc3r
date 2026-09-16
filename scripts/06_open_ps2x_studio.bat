@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\06_open_ps2x_studio.log"
set "STUDIO_EXE="

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Open ps2xStudio - %DATE% %TIME%

for /r "%ROOT%\PS2Recomp\out\build" %%F in (ps2xStudio.exe) do (
  if exist "%%F" set "STUDIO_EXE=%%F"
)

if not defined STUDIO_EXE (
  echo [ERROR] ps2xStudio.exe not found. Run 03_build_ps2recomp.bat first.
  >> "%LOG%" echo [ERROR] ps2xStudio.exe not found.
  exit /b 1
)

echo Studio: %STUDIO_EXE%
echo Suggested ELF: %ROOT%\extracted_iso\SLUS_213.55
echo Suggested exports: %ROOT%\work\exports
>> "%LOG%" echo Studio: %STUDIO_EXE%

start "" "%STUDIO_EXE%"
exit /b 0

