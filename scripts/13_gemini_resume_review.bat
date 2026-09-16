@echo off
setlocal EnableExtensions

set "ROOT=%~dp0"
set "ROOT=%ROOT:~0,-1%"
set "PROMPT=%ROOT%\docs\GEMINI_HANDOFF_2026-06-17.md"
set "LOGDIR=%ROOT%\work\logs"
set "LOG=%LOGDIR%\13_gemini_resume_review.log"

if not exist "%PROMPT%" (
  echo [ERROR] Missing prompt: %PROMPT%
  exit /b 1
)

where gemini >nul 2>nul
if errorlevel 1 (
  echo [ERROR] gemini CLI not found in PATH.
  exit /b 1
)

pushd "%ROOT%"
if not exist "%LOGDIR%" mkdir "%LOGDIR%"
echo Running Gemini read-only resume review...
echo Prompt: %PROMPT%
echo Log: %LOG%
echo.
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-Content -Raw '%PROMPT%' | gemini --approval-mode plan --skip-trust --output-format text -p 'Read this handoff and return the requested report. Do not edit files.' *>&1 | Tee-Object -FilePath '%LOG%'"
set "EXITCODE=%ERRORLEVEL%"
popd

exit /b %EXITCODE%
