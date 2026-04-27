@echo off
title Phoenix Startup Script

echo ==========================
echo    Phoenix Startup Script
echo ==========================

cd /d "C:\Users\Sebastian\Documents\Proyecto Final\Programacion-3\Azar\azar_app"

echo.
echo 0. Liberando puerto 4000 si esta ocupado...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :4000') do (
    echo Matando proceso %%a en puerto 4000...
    taskkill /PID %%a /F >nul 2>&1
)

echo.
echo 1. Instalando dependencias...
call mix deps.get

echo.
echo 2. Configurando assets...
call mix assets.setup

echo.
echo 3. Compilando proyecto...
call mix compile

echo.
echo 4. Ejecutando migraciones...
call mix ecto.migrate

echo.
echo 5. Abriendo navegador en http://localhost:4000...
:: Esta es la linea clave. "start" lanza el proceso y sigue con el script.
start http://localhost:4000

echo.
echo 6. Levantando servidor Phoenix...
call mix phx.server

pause