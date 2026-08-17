@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "ISO=%ROOT%\Midnight Club 3 - DUB Edition Remix.iso"
set "OUT=%ROOT%\extracted_iso"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\01_extract_iso.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
if not exist "%OUT%" mkdir "%OUT%"

> "%LOG%" echo Extract ISO - %DATE% %TIME%
echo ISO: %ISO%
echo OUT: %OUT%
>> "%LOG%" echo ISO: %ISO%
>> "%LOG%" echo OUT: %OUT%

if not exist "%ISO%" (
  echo [ERROR] ISO not found.
  >> "%LOG%" echo [ERROR] ISO not found.
  exit /b 1
)

where bsdtar >nul 2>nul
if errorlevel 1 (
  echo [ERROR] bsdtar not found in PATH.
  echo Install an ISO extractor or add bsdtar/7z to PATH.
  >> "%LOG%" echo [ERROR] bsdtar not found in PATH.
  exit /b 1
)

echo Extracting with bsdtar...
bsdtar -xf "%ISO%" -C "%OUT%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Extraction failed. See %LOG%
  exit /b 1
)

if not exist "%OUT%\SYSTEM.CNF" (
  echo [ERROR] SYSTEM.CNF not found after extraction. See %LOG%
  >> "%LOG%" echo [ERROR] SYSTEM.CNF not found after extraction.
  exit /b 1
)

if not exist "%OUT%\SLUS_213.55" (
  echo [ERROR] Expected boot ELF SLUS_213.55 not found after extraction. See %LOG%
  >> "%LOG%" echo [ERROR] Expected boot ELF SLUS_213.55 not found after extraction.
  exit /b 1
)

echo [OK] Extracted ISO and found SLUS_213.55.
>> "%LOG%" echo [OK] Extracted ISO and found SLUS_213.55.
exit /b 0

