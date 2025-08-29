#!/bin/sh

# --- Configuración XMPP ---
XMPP_USER=admin@xmpp.local
XMPP_PASSWORD=Mipassword
XMPP_SERVER=10.0.0.9
RECIPIENTS="admin1@xmpp.local admin2@xmpp.local admin3@xmpp.local"

# --- Archivo donde guardamos el último estado ---
STATE_FILE="/tmp/.ping_last_state"

# --- Dirección IP a monitorizar ---
TARGET_IP="102.197.68.5"

# --- Función para comprobar conectividad ---
check_connectivity() {
    RESPONSES=0
    for i in 1 2 3; do
        ping -c 1 -W 1 "$TARGET_IP" | grep -qi "bytes from"
        if [ $? -eq 0 ]; then
            RESPONSES=$((RESPONSES+1))
        fi
        sleep 1
    done

    if [ $RESPONSES -eq 3 ]; then
        echo "OK"
    elif [ $RESPONSES -eq 0 ]; then
        echo "ERROR"
    else
        echo "FLUCTUA"
    fi
}

# --- Estado actual ---
CURRENT_STATE=$(check_connectivity)

# --- Estado anterior ---
if [ -f "$STATE_FILE" ]; then
    PREV_STATE=$(cat "$STATE_FILE")
else
    PREV_STATE=""
fi

# --- Si hay cambio, enviar mensaje ---
if [ "$CURRENT_STATE" != "$PREV_STATE" ]; then
    TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
    MESSAGE="$TIMESTAMP\nAdmin: $CURRENT_STATE"

    MESSAGE_FILE=$(mktemp)
    echo -e "$MESSAGE" > "$MESSAGE_FILE"

    for R in $RECIPIENTS; do
        go-sendxmpp -u "$XMPP_USER" -p "$XMPP_PASSWORD" -j "$XMPP_SERVER" -n -m "$MESSAGE_FILE" "$R"
    done

    rm -f "$MESSAGE_FILE"
fi

# --- Guardar estado actual ---
echo "$CURRENT_STATE" > "$STATE_FILE"
