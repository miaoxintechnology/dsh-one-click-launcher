@echo off
setlocal
title DSH One-Click Launcher

rem Domestic npm mirror for faster updates
set "NPM_REGISTRY=https://registry.npmmirror.com"

echo ============================================
echo    DeepSeek Harness  One-Click Launcher
echo ============================================
echo.

rem ============ Step 0: ensure DSH is installed ============
where dsh >nul 2>nul
if not errorlevel 1 goto :haveDsh
echo [INFO] DSH not found. Installing DSH via mirror...
call npm install -g @deepseek-ai/dsh@latest --registry=%NPM_REGISTRY%
if errorlevel 1 goto :instFail
echo [OK] DSH installed.
goto :haveDsh
:instFail
echo [ERROR] DSH install failed. Check your network and try again.
pause
exit /b 1
:haveDsh

rem ============ Step 1: check for updates ============
set "CURRENT="
for /f "delims=" %%V in ('dsh --version 2^>nul') do set "CURRENT=%%V"
echo Current version : %CURRENT%

set "LATEST="
for /f "delims=" %%V in ('npm view @deepseek-ai/dsh version --registry=%NPM_REGISTRY% 2^>nul') do set "LATEST=%%V"
if not defined LATEST goto :noLatest

echo Latest version  : %LATEST%
echo.

rem Locate node so we can use its bundled semver to compare versions
for /f "delims=" %%N in ('where node 2^>nul') do set "NODEDIR=%%~dpN"
if not defined NODEDIR goto :noNode
set "NODE_PATH=%NODEDIR%node_modules\npm\node_modules"

rem Compare: 3=newer  0=up-to-date  2=bad version  other=compare failed
node -e "const s=require('semver'); const c=process.argv[1], l=process.argv[2]; if(!s.valid(c)||!s.valid(l)){process.exit(2);} process.exit(s.gt(l,c)?3:0);" "%CURRENT%" "%LATEST%"
set "RC=%errorlevel%"
if "%RC%"=="3" goto :update
if "%RC%"=="2" goto :badver
if "%RC%"=="0" goto :uptodate
echo [INFO] Version compare failed, code %RC%. Starting with current version.
goto :detect

:noLatest
echo [INFO] Could not get the latest version, possibly offline. Skipping update.
goto :detect

:noNode
echo [INFO] node not found. Skipping update check.
goto :detect

:uptodate
echo [OK] Already up to date.
goto :detect

:badver
echo [INFO] Odd version string. Starting with current version.
goto :detect

:update
echo [UPDATE] New version found. Updating DSH via mirror...
echo.
call npm install -g @deepseek-ai/dsh@latest --registry=%NPM_REGISTRY%
if errorlevel 1 goto :updateFailed
echo [OK] Update complete.
for /f "delims=" %%V in ('dsh --version 2^>nul') do set "CURRENT=%%V"
echo Updated version : %CURRENT%
goto :detect

:updateFailed
echo [WARN] Update failed. Starting with current version.
goto :detect

:detect
rem ============ Step 2: auto-detect a free port ============
set "PORT="
for /f %%P in ('powershell -NoProfile -ExecutionPolicy Bypass -Command "$p=3080;for(;$p -lt 4000;$p++){$l=[System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback,$p);try{$l.Start();$l.Stop();$p;break}catch{}}"') do set "PORT=%%P"
if not defined PORT set "PORT=0"

echo.
echo Port : %PORT%
echo URL  : http://127.0.0.1:%PORT%
echo Opening the browser...
echo.

rem ============ Step 3: launch ============
dsh web --port %PORT%

echo.
echo Service exited.
pause