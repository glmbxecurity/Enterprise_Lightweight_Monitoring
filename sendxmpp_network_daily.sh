#!/bin/sh

XMPP_USER=admin@xmpp.local
XMPP_PASSWORD=Mipassword
XMPP_SERVER=10.0.0.9
RECIPIENTS="admin1@xmpp.local admin2@xmpp.local admin3@xmpp.local"
LOG_FILE="/tmp/network.log"

# Extraer timestamp y estados
TIMESTAMP=$(head -n1 "$LOG_FILE")
ERROR_LINES=$(grep "ERROR" "$LOG_FILE")
FLUCTUA_LINES=$(grep "FLUCTUA" "$LOG_FILE")

if [ -z "$ERROR_LINES" ] && [ -z "$FLUCTUA_LINES" ]; then
    MESSAGE="$TIMESTAMP Prueba de conectividad OK"
else
    MESSAGE="$TIMESTAMP"
    if [ -n "$ERROR_LINES" ]; then
        MESSAGE="$MESSAGE\n$ERROR_LINES"
    fi
    if [ -n "$FLUCTUA_LINES" ]; then
        MESSAGE="$MESSAGE\n$FLUCTUA_LINES"
    fi
fi

# Crear archivo temporal con el mensaje
MESSAGE_FILE=$(mktemp)
echo -e "$MESSAGE" > "$MESSAGE_FILE"

# Enviar mensaje a cada destinatario
for R in $RECIPIENTS; do
    go-sendxmpp -u "$XMPP_USER" -p "$XMPP_PASSWORD" -j "$XMPP_SERVER" -n -m "$MESSAGE_FILE" "$R"
done

# Borrar archivo temporal
rm -f "$MESSAGE_FILE"
