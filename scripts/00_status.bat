@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "ISO=%ROOT%\Midnight Club 3 - DUB Edition Remix.iso"
set "EXTRACTED=%ROOT%\extracted_iso"
set "BOOT_ELF=%EXTRACTED%\SLUS_213.55"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\00_status.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo MC3 PS2Recomp status - %DATE% %TIME%

call :say "Root: %ROOT%"
call :exists "ISO" "%ISO%"
call :exists "Extracted SYSTEM.CNF" "%EXTRACTED%\SYSTEM.CNF"
call :exists "Boot ELF SLUS_213.55" "%BOOT_ELF%"
call :exists "PS2Recomp source" "%ROOT%\PS2Recomp\CMakeLists.txt"
call :exists "Root BRAIN.md" "%ROOT%\BRAIN.md"
call :exists "Detailed docs BRAIN.md" "%ROOT%\docs\BRAIN.md"
call :find_emotion_engine
call :exists "Ghidra script ExportPS2Functions.java" "%ROOT%\PS2Recomp\ps2xRecomp\tools\ghidra\ExportPS2Functions.java"
call :exists "Ghidra TOML export" "%ROOT%\work\exports\SLUS_213.55.ghidra.toml"
call :exists "Ghidra CSV export" "%ROOT%\work\exports\SLUS_213.55.ghidra.csv"
call :exists "Generated C++ dir" "%ROOT%\work\generated\ghidra"
call :exists "Function index" "%ROOT%\work\index\functions_index.csv"
call :exists "Batch 0001 manifest" "%ROOT%\work\batches\ghidra\batch_0001.csv"
call :exists "Batch compile summary" "%ROOT%\work\compile\ghidra\batch_0001\batch_0001.syntax.summary.csv"
call :exists "Partial MC3 runner exe" "%ROOT%\work\link\partial\mc3_partial.exe"

call :tool bsdtar
call :tool cmake
call :tool ninja
call :tool java
call :tool git

call :find_ghidra
call :find_recomp_exe

call :say "Log: %LOG%"
exit /b 0

:say
echo %~1
>> "%LOG%" echo %~1
exit /b 0

:exists
if exist "%~2" (
  call :say "[OK] %~1: %~2"
) else (
  call :say "[MISS] %~1: %~2"
)
exit /b 0

:tool
where "%~1" >nul 2>nul
if errorlevel 1 (
  call :say "[MISS] tool %~1"
) else (
  for /f "delims=" %%P in ('where "%~1" 2^>nul') do call :say "[OK] tool %~1: %%P"
)
exit /b 0

:find_ghidra
if defined GHIDRA_RUN if exist "%GHIDRA_RUN%" (
  call :say "[OK] GHIDRA_RUN: %GHIDRA_RUN%"
  exit /b 0
)
if defined GHIDRA_HOME if exist "%GHIDRA_HOME%\ghidraRun.bat" (
  call :say "[OK] GHIDRA_HOME ghidraRun: %GHIDRA_HOME%\ghidraRun.bat"
  exit /b 0
)
for /d %%D in ("%ROOT%\ghidra_*_PUBLIC") do (
  if exist "%%~fD\ghidraRun.bat" (
    set "FOUND_GHIDRA=%%~fD\ghidraRun.bat"
  )
)
if defined FOUND_GHIDRA (
  call :say "[OK] bundled ghidraRun: !FOUND_GHIDRA!"
  exit /b 0
)
if exist "%ROOT%\ghidraRun.bat" (
  call :say "[OK] local ghidraRun: %ROOT%\ghidraRun.bat"
  exit /b 0
)
call :say "[MISS] ghidraRun.bat. Set GHIDRA_RUN or install full Ghidra."
exit /b 0

:find_emotion_engine
set "FOUND_EE="
for /d %%D in ("%ROOT%\ghidra_*_PUBLIC") do (
  if exist "%%~fD\Ghidra\Extensions\ghidra-emotionengine-reloaded\extension.properties" set "FOUND_EE=%%~fD\Ghidra\Extensions\ghidra-emotionengine-reloaded\extension.properties"
  if exist "%%~fD\Extensions\ghidra-emotionengine-reloaded\extension.properties" set "FOUND_EE=%%~fD\Extensions\ghidra-emotionengine-reloaded\extension.properties"
)
if defined FOUND_EE (
  call :say "[OK] Ghidra Emotion Engine extension: !FOUND_EE!"
) else (
  call :say "[MISS] Ghidra Emotion Engine extension"
)
exit /b 0

:find_recomp_exe
set "FOUND_RECOMP="
if not exist "%ROOT%\PS2Recomp\out\build" (
  call :say "[MISS] recompiler build dir PS2Recomp\out\build"
  exit /b 0
)
for /r "%ROOT%\PS2Recomp\out\build" %%F in (ps2_recomp.exe ps2xRecomp.exe) do (
  if exist "%%F" set "FOUND_RECOMP=%%F"
)
if defined FOUND_RECOMP (
  call :say "[OK] recompiler exe: %FOUND_RECOMP%"
) else (
  call :say "[MISS] recompiler exe under PS2Recomp\out\build"
)
exit /b 0
