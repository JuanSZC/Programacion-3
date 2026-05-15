@echo off
setlocal enabledelayedexpansion
title AzarApp - Cloudflare Server
color 0A
cls

:: =====================================================
:: CONFIGURACION
:: =====================================================

set "PROYECTO=C:\Users\Sebastian\Documents\Proyecto Final\Programacion-3\Azar\azar_app"
set "PG_SERVICE=postgresql-x64-18"
set "APP_PORT=4000"
set "APP_URL=http://localhost:4000/"

:: Ruta de Cloudflare Tunnel
set "CLOUDFLARED=C:\cloudfared\cloudflared-windows-amd64.exe"

:: =====================================================
:: ENTRAR AL PROYECTO
:: =====================================================

cd /d "%PROYECTO%" || (
echo [ERROR] No existe la ruta del proyecto
pause
exit /b
)

echo =====================================================
echo        AZAR S.A. - CLOUD SERVER 🚀
echo =====================================================

:: =====================================================
:: [1/5] POSTGRESQL
:: =====================================================

echo [1/5] Verificando PostgreSQL...

sc query %PG_SERVICE% | find "RUNNING" >nul

if errorlevel 1 (
echo [RUN] Iniciando PostgreSQL...
net start %PG_SERVICE% >nul 2>&1
)

echo [OK] PostgreSQL listo.

:: =====================================================
:: [2/5] LIBERAR PUERTO
:: =====================================================

echo [2/5] Liberando puerto %APP_PORT%...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%APP_PORT% "') do (
taskkill /PID %%a /F >nul 2>&1
)

echo [OK] Puerto %APP_PORT% listo.

:: =====================================================
:: [3/5] DEPENDENCIAS
:: =====================================================

echo [3/5] Verificando dependencias...

call mix deps.get >nul 2>&1

echo [OK] Dependencias listas.

:: =====================================================
:: [4/5] INICIAR PHOENIX
:: =====================================================

echo [4/5] Iniciando Phoenix...

start "Phoenix Server" cmd /k "cd /d %PROYECTO% && mix phx.server"

:: Esperar a que Phoenix arranque
timeout /t 8 >nul

:: Abrir localhost
start "" "%APP_URL%"

:: =====================================================
:: [5/5] INICIAR CLOUDFLARE TUNNEL
:: =====================================================

echo [5/5] Iniciando Cloudflare Tunnel...

start "Cloudflare Tunnel" cmd /k "%CLOUDFLARED% tunnel --url http://localhost:%APP_PORT%"

echo.
echo =====================================================
echo          SERVIDOR PUBLICO INICIADO
echo =====================================================
echo.

pause

endlocal
