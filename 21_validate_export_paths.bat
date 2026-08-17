@echo off
setlocal
set "ROOT=%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%ROOT%tools\Validate-MC3Export.ps1" %*
exit /b %ERRORLEVEL%
