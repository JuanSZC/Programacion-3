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
set "CLOUDFLARED=C:\cloudfared\cloudflared-windows-amd64.exe"

:: =====================================================
:: VALIDACIONES
:: =====================================================

if not exist "%PROYECTO%" (
    echo [ERROR] No existe la carpeta del proyecto
    pause
    exit /b
)

if not exist "%CLOUDFLARED%" (
    echo [ERROR] No se encontro cloudflared
    echo Ruta esperada:
    echo %CLOUDFLARED%
    pause
    exit /b
)

cd /d "%PROYECTO%"

echo =====================================================
echo          AZAR S.A. - CLOUD SERVER
echo =====================================================
echo.

:: =====================================================
:: [1/5] POSTGRESQL
:: =====================================================

echo [1/5] Verificando PostgreSQL...

sc query "%PG_SERVICE%" | find "RUNNING" >nul

if errorlevel 1 (
    echo [RUN] Iniciando PostgreSQL...
    net start "%PG_SERVICE%" >nul 2>&1

    if errorlevel 1 (
        echo [ERROR] No se pudo iniciar PostgreSQL
        pause
        exit /b
    )
)

echo [OK] PostgreSQL listo.
echo.

:: =====================================================
:: [2/5] LIBERAR PUERTO
:: =====================================================

echo [2/5] Liberando puerto %APP_PORT%...

for /f "tokens=5" %%a in ('netstat -ano ^| findstr "LISTENING" ^| findstr ":%APP_PORT% "') do (
    taskkill /PID %%a /F >nul 2>&1
)

echo [OK] Puerto %APP_PORT% libre.
echo.

:: =====================================================
:: [3/5] DEPENDENCIAS
:: =====================================================

echo [3/5] Verificando dependencias...

if not exist "deps" (
    echo [RUN] Descargando dependencias...
    call mix deps.get

    if errorlevel 1 (
        echo [ERROR] Fallo al descargar dependencias
        pause
        exit /b
    )
)

echo [OK] Dependencias listas.
echo.

:: =====================================================
:: [4/5] INICIAR PHOENIX
:: =====================================================

echo [4/5] Iniciando Phoenix...

start "Phoenix Server" cmd /k "cd /d %PROYECTO% && mix phx.server"

echo [WAIT] Esperando a que Phoenix inicie...

:waitPhoenix
timeout /t 2 >nul

netstat -ano | findstr ":%APP_PORT%" >nul

if errorlevel 1 (
    goto waitPhoenix
)

echo [OK] Phoenix iniciado.
echo.

:: Abrir navegador
start "" "%APP_URL%"

:: =====================================================
:: [5/5] CLOUDFLARE TUNNEL
:: =====================================================

echo [5/5] Iniciando Cloudflare Tunnel...
echo.

start "Cloudflare Tunnel" cmd /k ""%CLOUDFLARED%" tunnel --url http://localhost:%APP_PORT% "

echo =====================================================
echo         SERVIDOR PUBLICO INICIADO
echo =====================================================
echo.
echo Local:
echo %APP_URL%
echo.
echo Esperando URL publica de Cloudflare...
echo.

pause
endlocal