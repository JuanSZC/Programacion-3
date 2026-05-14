@echo off
setlocal enabledelayedexpansion
title AzarApp - Iniciando...
color 0A
cls


:: [CONFIGURACIÓN]
set "PROYECTO=C:\Users\Sebastian\Documents\Proyecto Final\Programacion-3\Azar\azar_app"
set "PG_SERVICE=postgresql-x64-18"
set "APP_PORT=4000"
set "APP_URL=http://localhost:4000/"

cd /d "%PROYECTO%" || (echo [ERROR] No existe la ruta & pause & exit /b)

echo =====================================================
echo    AZAR S.A. - Modo Ultra-Rápido 🚀
echo =====================================================

:: [1/4] POSTGRESQL - Solo intenta iniciar si no está corriendo
echo [1/4] Verificando PostgreSQL...
sc query %PG_SERVICE% | find "RUNNING" >nul
if errorlevel 1 (
    net start %PG_SERVICE% >nul 2>&1
)

:: [2/4] PUERTO - Solo mata si el puerto está ocupado
for /f "tokens=5" %%a in ('netstat -ano ^| findstr ":%APP_PORT% "') do (
    taskkill /PID %%a /F >nul 2>&1
)
echo [OK] Puerto %APP_PORT% listo.

:: [3/4] DEPENDENCIAS - Sistema de Check Simplificado
:: En lugar de comparar strings de fecha complejos, comparamos el tamaño del archivo mix.lock
echo [3/4] Verificando dependencias...
set "LOCK_FILE=mix.lock"
for %%A in ("%LOCK_FILE%") do set "CURRENT_SIZE=%%~zA"

if exist "%TEMP%\azar_last_size.txt" (
    set /p LAST_SIZE=<"%TEMP%\azar_last_size.txt"
    if "!CURRENT_SIZE!"=="!LAST_SIZE!" (
        echo [SKIP] Sin cambios en mix.lock.
        goto :skip_deps
    )
)

echo [RUN] Actualizando mix deps...
call mix deps.get
echo %CURRENT_SIZE%>"%TEMP%\azar_last_size.txt"

:skip_deps

:: [4/4] MIGRACIONES Y ARRANQUE - El truco del "Silent Check"
echo [4/4] Iniciando Phoenix...

:: Lanzar el navegador antes de mix para que no bloquee
start "" powershell -WindowStyle Hidden -Command "for($i=0;$i -lt 30;$i++){try{$t=New-Object Net.Sockets.TcpClient;$t.Connect('localhost',%APP_PORT%);$t.Close();Start-Process '%APP_URL%';break}catch{Start-Sleep 1}}"

:: Ejecutamos mix phx.server directamente. 
:: Phoenix ya hace un chequeo de migraciones pendientes por defecto en dev.
title AzarApp - localhost:%APP_PORT%
call mix phx.server

endlocal