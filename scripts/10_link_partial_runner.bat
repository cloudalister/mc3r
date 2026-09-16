@echo off
setlocal EnableExtensions

set "PATH=C:\msys64\ucrt64\bin;%PATH%"

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\10_link_partial_runner_driver.log"
set "MODE=%~1"
set "REGISTER=%ROOT%\work\link\partial\register_functions.partial.cpp"
set "STUBS=%ROOT%\work\link\partial\missing_functions.partial.cpp"

if not exist "%LOGDIR%" mkdir "%LOGDIR%"
> "%LOG%" echo Link partial MC3 runner - %DATE% %TIME%

rem Guarda: nao linkar por cima de falha de compilacao.
rem O parallel_compile.py deixa os .o antigos no lugar quando a compilacao falha,
rem entao o link passava e produzia um exe que mistura objetos novos com objetos
rem da build anterior. Ele roda, e mede como se fosse valido -- foi assim que uma
rem instrumentacao que nem compilava acabou "linkada" em 2026-08-31.
set "FAILLOG=%ROOT%\work\exports\parallel_compile_failures.log"
if exist "%FAILLOG%" (
  for %%F in ("%FAILLOG%") do if %%~zF GTR 0 (
    echo [ERROR] Ha falhas de compilacao em %FAILLOG% - recompile antes de linkar.
    echo [ERROR] Ha falhas de compilacao em %FAILLOG% >> "%LOG%"
    type "%FAILLOG%"
    exit /b 1
  )
)

if /I "%MODE%"=="fast" (
  if exist "%REGISTER%" if exist "%STUBS%" (
    echo [OK] Fast relink: using existing partial register/stubs. >> "%LOG%"
    goto LINK_ONLY
  )
  echo [WARN] Fast relink requested, but register/stubs are missing. Regenerating. >> "%LOG%"
)

:GENERATE
node "%ROOT%\tools\Generate-PartialRegister.js" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Failed to generate partial register. See %LOG%
  exit /b 1
)

:LINK_ONLY
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%\tools\Link-PartialRunner.ps1" >> "%LOG%" 2>&1
if errorlevel 1 (
  echo [ERROR] Failed to link partial runner. See %LOG% and work\logs\10_link_partial_runner.log
  exit /b 1
)

type "%LOG%"
exit /b 0
