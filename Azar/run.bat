@echo off
title Phoenix Startup Script - Azar S.A.

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
echo 4. Abriendo navegador en http://localhost:4000/admin/sorteos...
:: Lanzamos directo a la ruta del administrador para que pruebes más rápido
start http://localhost:4000

echo.
echo 5. Levantando servidor Phoenix (Procesos Concurrentes Activos)...
call mix phx.server

pause