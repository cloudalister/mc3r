@echo off
setlocal EnableExtensions
:: Roda o boot probe N vezes e agrega (Stable PC unico? renderizou?).
:: Uso:
::   21_probe_repeat.bat                      -> 5 corridas, modo 595, label baseline
::   21_probe_repeat.bat 8 595 baseline       -> 8 corridas
::   21_probe_repeat.bat 5 595 exp MC3_X=1    -> 5 corridas com env setada
set "ROOT=%~dp0"
set "RUNS=%~1"
set "MODE=%~2"
set "LABEL=%~3"
set "ENVV=%~4"
if "%RUNS%"=="" set "RUNS=5"
if "%MODE%"=="" set "MODE=595"
if "%LABEL%"=="" set "LABEL=baseline"
set "ARGS=-Runs %RUNS% -Mode %MODE% -Label %LABEL%"
if not "%ENVV%"=="" set "ARGS=%ARGS% -Env %ENVV%"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\Probe-Repeat.ps1" %ARGS%
exit /b %ERRORLEVEL%
