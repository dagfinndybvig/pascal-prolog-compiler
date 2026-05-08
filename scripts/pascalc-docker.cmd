@echo off
setlocal enabledelayedexpansion

set "IMAGE=%PASCALC_DOCKER_IMAGE%"
if "%IMAGE%"=="" (
  set /p VERSION=<"%~dp0..\VERSION"
  set "IMAGE=pascal-prolog-compiler:!VERSION!"
)

if "%~1"=="" (
  echo Usage: scripts\pascalc-docker.cmd ^<compiler-command^> [args...]
  echo Example: scripts\pascalc-docker.cmd build-asm examples\comprehensive_test.pas comprehensive_test
  exit /b 1
)

docker run --rm -v "%cd%:/workspace" -w /workspace %IMAGE% %*
if errorlevel 1 exit /b %errorlevel%

endlocal
