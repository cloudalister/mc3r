@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "JAVA_HOME=%ROOT%\jdk-21.0.12+8"
set "GHIDRA_HEADLESS=%ROOT%\ghidra_12.1_PUBLIC\support\analyzeHeadless.bat"
set "PROJECT_DIR=%ROOT%\work"
set "PROJECT_NAME=mc2recomp"
set "ALPHA_DIR=%ROOT%\MIDNIGHT CLUB 3 DUB PS2 ALPHA BUILD 102404"
set "ALPHA_ELF=%ALPHA_DIR%\SLUS_123.45"
set "ALPHA_MAP=%ALPHA_DIR%\MC.MAP"
set "SCRIPT_DIR=%ROOT%\tools\ghidra"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\22_alpha_symbols.log"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"

if "%~1"=="check" (
  call "%JAVA_HOME%\bin\java.exe" -version
  exit /b %ERRORLEVEL%
)

if not exist "%ALPHA_ELF%" (
  echo [ERRO] ELF do alpha nao encontrado: %ALPHA_ELF%
  exit /b 1
)
if exist "%PROJECT_DIR%\%PROJECT_NAME%.lock" (
  echo [ERRO] projeto Ghidra aberto/travado. Feche o Ghidra antes.
  exit /b 1
)

> "%LOG%" echo 22_alpha_symbols - %DATE% %TIME%
call "%GHIDRA_HEADLESS%" "%PROJECT_DIR%" "%PROJECT_NAME%" -import "%ALPHA_ELF%" -scriptPath "%SCRIPT_DIR%" -postScript ImportMc3Map.java "%ALPHA_MAP%" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERRO] import headless falhou. Ver %LOG%
  exit /b 1
)
echo [OK] alpha importado com simbolos. Log: %LOG%
exit /b 0
