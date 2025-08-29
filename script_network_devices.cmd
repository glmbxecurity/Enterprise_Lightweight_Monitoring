@echo off
setlocal enabledelayedexpansion

REM === Directorios de logs ===
set "LOGDIR=%TEMP%"
set "CURLOG=%LOGDIR%\network.log"
set "PREVLOG=%LOGDIR%\network_prev.log"
set "FULLLOG=%LOGDIR%\network_full.log"

REM === Timestamp ===
for /f "tokens=1-4 delims=/ " %%a in ("%date%") do (
    set DD=%%a
    set MM=%%b
    set YY=%%c
)
set "TS=%YY%-%MM%-%DD%_%time:~0,2%-%time:~3,2%-%time:~6,2%"

REM === Crear log actual ===
echo Conectividad %TS% > "%CURLOG%"

REM === Lista de dispositivos ===
REM Formato: IP Nombre

call :check 192.168.1.254 GATEWAY
call :check 192.168.1.1 SERVIDOR_1
call :check 192.168.1.2 SERVIDOR_2


REM === Comparar con ejecución anterior solo las líneas de estado ===
if exist "%PREVLOG%" (
    REM extraemos todas las líneas menos la primera (timestamp)
    more +1 "%CURLOG%" > "%LOGDIR%\cur_state.tmp"
    more +1 "%PREVLOG%" > "%LOGDIR%\prev_state.tmp"

    fc "%LOGDIR%\prev_state.tmp" "%LOGDIR%\cur_state.tmp" >nul
    if errorlevel 1 (
        echo Cambio detectado >> "%FULLLOG%"
        type "%CURLOG%" >> "%FULLLOG%"
        echo. >> "%FULLLOG%"
    )

    del "%LOGDIR%\cur_state.tmp"
    del "%LOGDIR%\prev_state.tmp"
)

REM === Guardar copia actual como anterior ===
copy /Y "%CURLOG%" "%PREVLOG%" >nul

REM === Subir logs al servidor remoto ===
echo Subiendo logs al servidor remoto...
scp "%CURLOG%" admin@102.197.68.60:/tmp/network.log
if errorlevel 1 echo ERROR al subir "%CURLOG%"
scp "%FULLLOG%" admin@102.197.68.60:/tmp/network_full.log
if errorlevel 1 echo ERROR al subir "%FULLLOG%"
scp "%PREVLOG%" admin@102.197.68.60:/tmp/network_prev.log
if errorlevel 1 echo ERROR al subir "%PREVLOG%"
echo Listo.
goto :eof

REM === Función para comprobar un dispositivo ===
:check
echo Comprobando conectividad a %1 (%2)...

set "RESPONSES=0"
for /l %%i in (1,1,3) do (
    ping -n 1 -w 1000 %1 | findstr /i "Reply" >nul
    if !errorlevel! equ 0 (
        set /a RESPONSES+=1
    )
    timeout /nobreak /t 1 >nul
)

if !RESPONSES! EQU 3 (
    echo  %2 OK >> "%CURLOG%"
) else if !RESPONSES! EQU 0 (
    echo  %2 ERROR >> "%CURLOG%"
) else (
    echo  %2 FLUCTUA >> "%CURLOG%"
)
exit /b
