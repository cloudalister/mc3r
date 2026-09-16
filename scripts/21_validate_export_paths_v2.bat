@echo off
setlocal
set "ROOT=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\Validate-MC3Export.v2.ps1" %*
exit /b %ERRORLEVEL%
