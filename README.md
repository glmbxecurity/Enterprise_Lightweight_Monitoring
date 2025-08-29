# Enterprise_Lightweight_Monitoring

## Introducción

Este proyecto implementa un sistema de **monitorización y notificaciones de servicios** a nivel empresarial o para un servidor “home”.  
El objetivo principal es disponer de un script de comprobación adaptable a tus necesidades, por ejemplo:

- Controlar que un **Domain Controller (DC)** esté activo.
- Verificar un servidor **NGINX** o **Mail Server**.
- Monitorizar túneles **VPN** o cualquier otro servicio crítico.

El sistema consta de varias fases:

1. **Comprobación de servicios** desde un equipo o servidor de la red interna.
2. **Implantación de notificaciones** vía Email, Telegram o XMPP (el servidor de notificaciones se puede ubicar en la DMZ).
3. **Verificación de funcionamiento del servicio de notificaciones**, ya que sin él no se puede monitorizar correctamente.

> Este proyecto no cubre la instalación de MV’s, sistemas operativos, software u otras configuraciones de infraestructura.

---

## Requisitos

- Sistema operativo: **Unix/Linux** (el laboratorio se centra en UNIX).
- Servidor de notificaciones: MV o LXC **Alpine**.
- Comprobador de servicios: Puede ser el mismo Alpine, otro servidor o un equipo de la red.
- Cuenta en [Healthchecks.io](https://healthchecks.io/) u otro servicio similar para verificar que el servidor de notificaciones está “UP”.
- Prosody y sendxmpp instalado y configurado en alpine
- cron
- Tareas programadas (opcional, si tenemos cliente windows)

---

## Verificar que Alpine está activo

1. Crear una cuenta en [Healthchecks.io](https://healthchecks.io/).
2. Crear un nuevo check y configurar las notificaciones (Email, WhatsApp, Telegram).
3. Configurar el check para que se ejecute cada 5 minutos, con 1 minuto de periodo de gracia.
4. Copiar la URL del ping generado por Healthchecks.
5. En Alpine, agregar el ping al `crontab`:

```bash
crontab -e

# Instalar curl si es necesario
apk add curl

# Agregar la tarea
*/5 * * * * curl -fsS https://hc-ping.com/8b9658d1-ce33-4b3d-97c3-73d32a536441 > /dev/null 2>&1
```
Esto asegura que recibas alertas si el servidor de notificaciones cae.

## Comprobación de servicios   
**script_network_devices.cmd**
El script de comprobación tiene las siguientes características:  
  
* Realiza 3 pings a cada dispositivo y genera un log (network.log) con el resultado: OK, ERROR o FLUCTUA.  
* Crea un log de cambios (network_full.log) solo cuando hay variaciones respecto a la ejecución anterior.  
* Los logs se suben al servidor Alpine vía scp usando acceso por claves públicas.
* Los dispositivos y sus IPs se pueden personalizar según la red.

Se recomienda tener una tarea programada que periódicamente realize esta comprobación.  
Editar el script de comprobación para indicar a quien subimos el log y que direcciones IP vamos a comprobar de la siguiente manera:  
```cmd

REM === Lista de dispositivos ===
REM Formato: IP Nombre

call :check 192.168.1.100 MI_PUERTA_DE_ENLACE
call :check 192.168.1.110 MI_SERVICIO_DC
...

REM === Subir logs al servidor remoto ===
echo Subiendo logs al servidor remoto...
scp "%CURLOG%" admin@102.197.68.60:/tmp/network.log
if errorlevel 1 echo ERROR al subir "%CURLOG%"
scp "%FULLLOG%" admin@102.197.68.60:/tmp/network_full.log
if errorlevel 1 echo ERROR al subir "%FULLLOG%"
scp "%PREVLOG%" admin@102.197.68.60:/tmp/network_prev.log
if errorlevel 1 echo ERROR al subir "%PREVLOG%"
```

## Envío de notificaciones

Se utiliza XMPP (Prosody) en Alpine para enviar alertas y reportes a tu dispositivo:  

* sendxmpp_network_daily.sh: envía un resumen diario de conectividad.
* sendxmpp_network_alert.sh: envía alertas en caso de cambios de estado.
* sendxmpp_network_alert_admin_connection.sh (opcional): notifica pérdida de conectividad con el equipo que envía las novedades.

Para ello se debe instalar y configurar previamente prosody y sendxmpp y luego editar los scripts para elegir a quien se envía la notificación, además de configurar tareas cron para realizar esto de manera periódica.  
  
#### Ejemplo para modificar los contactos que recibirán notificaciones
```bash

XMPP_USER=admin@xmpp.local
XMPP_PASSWORD=Mipassword
XMPP_SERVER=192.168.1.1
RECIPIENTS="admin1@xmpp.local admin2@xmpp.local admin3@xmpp.local"
LOG_FILE="/tmp/network.log"
```
#### Ejemplo de tarea cron
```bash

# La tarea para comprobar con healthchecks que Alpine está corriendo bien
*/5 * * * * curl -fsS https://hc-ping.com/8b9658d1-ce33-4b3d-97c3-73d32a5362cf >/dev/null 2>&1

# Tarea para enviar novedades de los servicios a las 7AM
0 7 * * * /home/admin/sendxmpp_network_daily.sh >> /home/admin/cron_daily_log.txt 2>&1

# Tarea para enviar alertas si hay cambios en la conectividad
*/5 * * * * /bin/bash /home/admin/sendxmpp_network_alert.sh >> /home/admin/cron_alert_log.txt 2>&1

# Tarea opcional para notificar si se ha perdido conectividad con el cliente que nos envía las novedades
*/5 * * * * /home/admin/sendxmpp_network_alert_admin_connection.sh >> /home/admin/cron_admin_conn_log.txt
```

## Resumen

* Clonar repo con scripts y alamcenar donde queramos
* Creación cuenta healthchecks
* Instalar y configurar prosody y sendxmpp
* Configurar los scripts:
  * script_network_devices.cmd: configurar ip's a monitorizar, ip y ruta de donde subiremos los logs
  * sendxmpp_network_daily.sh: credenciales de cliente xmpp, destinatarios, fichero de log
  * sendxmpp_network_alert.sh: credenciales de cliente xmpp, destinatarios, fichero de log
  * sendxmpp_network_alert_admin_connection.sh: ip del equipo que queremos comprobar, credenciales de cliente xmpp, destinatarios, fichero de log
 
* Configurar tareas programadas (windows) y tareas cron (alpine)





