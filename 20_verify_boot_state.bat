@echo off
setlocal EnableExtensions
:: Guarda de regressao do boot. Uso:
::   20_verify_boot_state.bat                      -> so reporta
::   20_verify_boot_state.bat 0x5a8908             -> falha se PC != esperado
::   20_verify_boot_state.bat - 0x5a8908           -> falha se PC AINDA FOR o antigo (teste de progresso)
::   20_verify_boot_state.bat 0x5a8908 - trace-tag -> valida string do exe tambem
set "ROOT=%~dp0"
set "EXPECT=%~1"
set "FAILIF=%~2"
set "EXPECTSTR=%~3"
set "ARGS="
if not "%EXPECT%"=="" if not "%EXPECT%"=="-" set "ARGS=-ExpectedStablePC %EXPECT%"
if not "%FAILIF%"=="" set "ARGS=%ARGS% -FailIfStablePC %FAILIF%"
if not "%EXPECTSTR%"=="" set "ARGS=%ARGS% -ExpectExeString %EXPECTSTR%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\Verify-BootState.ps1" %ARGS%
exit /b %ERRORLEVEL%
