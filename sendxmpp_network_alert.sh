#!/bin/sh

LOG_FILE="/tmp/network.log"
STATE_FILE="/tmp/.network_last_state"
RECIPIENTS="admin1@xmpp.local admin2@xmpp.local admin3@xmpp.local"
XMPP_USER=admin@xmpp.local
XMPP_PASSWORD=Mipassword
XMPP_SERVER=10.0.0.9

CUR_STATE="/tmp/.network_cur_state"
PREV_STATE="/tmp/.network_prev_state"

# Extraemos el estado actual (sin timestamp)
tail -n +2 "$LOG_FILE" > "$CUR_STATE"

# Preparamos archivo de estado anterior
if [ -f "$STATE_FILE" ]; then
    cp "$STATE_FILE" "$PREV_STATE"
else
    touch "$PREV_STATE"
fi

MESSAGE=""

# --- Comparar línea por línea ---
while read line; do
    DEVICE=$(echo "$line" | awk '{print $1}')
    STATUS=$(echo "$line" | awk '{print $2}')

    PREV_STATUS=$(grep "^$DEVICE:" "$STATE_FILE" | cut -d: -f2)
    PREV_STATUS=${PREV_STATUS:-OK}

    if [ "$STATUS" != "$PREV_STATUS" ]; then
        case "$STATUS" in
            OK)
                MESSAGE="$MESSAGE$DEVICE se ha reestablecido\n"
                ;;
            ERROR)
                MESSAGE="$MESSAGE$DEVICE en ERROR\n"
                ;;
            FLUCTUA)
                MESSAGE="$MESSAGE$DEVICE en estado FLUCTUA\n"
                ;;
        esac
    fi
done < "$CUR_STATE"

# --- Comprobar si antes había errores y ahora todo OK ---
PREV_ERRORS=$(awk -F: '$2=="ERROR"' "$STATE_FILE")
CUR_ERRORS=$(awk '$2=="ERROR"' "$CUR_STATE")
if [ -n "$PREV_ERRORS" ] && [ -z "$CUR_ERRORS" ]; then
    MESSAGE="Todos los servicios se han reestablecido"
fi

# --- Enviar mensaje si hay cambios ---
if [ -n "$MESSAGE" ]; then
    TIMESTAMP=$(head -n1 "$LOG_FILE")
    MESSAGE_FULL="$TIMESTAMP\n$MESSAGE"

    MESSAGE_FILE=$(mktemp)
    echo -e "$MESSAGE_FULL" > "$MESSAGE_FILE"

    for R in $RECIPIENTS; do
        go-sendxmpp -u "$XMPP_USER" -p "$XMPP_PASSWORD" -j "$XMPP_SERVER" -n -m "$MESSAGE_FILE" "$R"
    done
    rm -f "$MESSAGE_FILE"
fi

# --- Guardar estado actual para la próxima ejecución ---
> "$STATE_FILE"
while read line; do
    DEVICE=$(echo "$line" | awk '{print $1}')
    STATUS=$(echo "$line" | awk '{print $2}')
    echo "$DEVICE:$STATUS" >> "$STATE_FILE"
done < "$CUR_STATE"

rm -f "$CUR_STATE" "$PREV_STATE"
