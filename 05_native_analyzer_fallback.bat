@echo off
setlocal EnableExtensions EnableDelayedExpansion

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "BOOT_ELF=%ROOT%\extracted_iso\SLUS_213.55"
set "EXPORTS=%ROOT%\work\exports"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\05_native_analyzer_fallback.log"
set "ANALYZER_EXE="
set "OUT_TOML=%EXPORTS%\SLUS_213.55.native_analyzer.toml"
set "GEN_OUT=%ROOT%\work\generated\native_analyzer"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%EXPORTS%" mkdir "%EXPORTS%"
if not exist "%GEN_OUT%" mkdir "%GEN_OUT%"
> "%LOG%" echo Native analyzer fallback - %DATE% %TIME%

if not exist "%BOOT_ELF%" (
  echo [ERROR] Boot ELF not found: %BOOT_ELF%
  echo Run 01_extract_iso.bat first.
  >> "%LOG%" echo [ERROR] Boot ELF not found.
  exit /b 1
)

for /r "%ROOT%\PS2Recomp\out\build" %%F in (ps2_analyzer.exe) do (
  if exist "%%F" set "ANALYZER_EXE=%%F"
)

if not defined ANALYZER_EXE (
  echo [ERROR] ps2_analyzer.exe not found. Run 03_build_ps2recomp.bat first.
  >> "%LOG%" echo [ERROR] ps2_analyzer.exe not found.
  exit /b 1
)

echo Analyzer: %ANALYZER_EXE%
echo Input ELF: %BOOT_ELF%
echo Output TOML: %OUT_TOML%
echo NOTE: This is a fallback for quick experiments. Ghidra export is preferred for retail stripped games.
>> "%LOG%" echo Analyzer: %ANALYZER_EXE%
>> "%LOG%" echo Input ELF: %BOOT_ELF%
>> "%LOG%" echo Output TOML: %OUT_TOML%

"%ANALYZER_EXE%" "%BOOT_ELF%" "%OUT_TOML%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Analyzer failed. See %LOG%
  exit /b 1
)

powershell -NoProfile -Command "$p=$env:OUT_TOML; $out=($env:GEN_OUT -replace '\\','/'); (Get-Content -LiteralPath $p) -replace '^output = .*', ('output = \"' + $out + '/\"') | Set-Content -LiteralPath $p -Encoding ASCII" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Failed to normalize TOML output path. See %LOG%
  exit /b 1
)

echo [OK] Wrote fallback TOML: %OUT_TOML%
>> "%LOG%" echo [OK] Wrote fallback TOML.
exit /b 0
