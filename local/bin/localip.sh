#!/bin/bash
ROUTE=$(ip route get 1.1.1.1 2>/dev/null)
INTERFACE=$(echo "$ROUTE" | grep -oP 'dev \K\S+')
IP=$(echo "$ROUTE" | grep -oP 'src \K\S+')

if [ -z "$INTERFACE" ]; then
    echo '{"text": "Offline", "tooltip": "Desconectado"}'
    exit 0
fi

# Archivo temporal para guardar la última lectura
STATS_FILE="/tmp/localip_net_stats"

# Obtener bytes actuales
RX_CUR=$(cat /sys/class/net/$INTERFACE/statistics/rx_bytes 2>/dev/null || echo 0)
TX_CUR=$(cat /sys/class/net/$INTERFACE/statistics/tx_bytes 2>/dev/null || echo 0)
TIME_CUR=$(date +%s)

# Inicializar velocidades
RX_SPEED=0
TX_SPEED=0

if [ -f "$STATS_FILE" ]; then
    # Leer datos anteriores
    read -r RX_PREV TX_PREV TIME_PREV < "$STATS_FILE"
    
    # Calcular intervalo de tiempo
    INTERVAL=$((TIME_CUR - TIME_PREV))
    if [ $INTERVAL -le 0 ]; then INTERVAL=1; fi
    
    # Calcular bytes por segundo
    RX_SPEED=$(( (RX_CUR - RX_PREV) / INTERVAL ))
    TX_SPEED=$(( (TX_CUR - TX_PREV) / INTERVAL ))
    
    # Prevenir valores negativos
    [ $RX_SPEED -lt 0 ] && RX_SPEED=0
    [ $TX_SPEED -lt 0 ] && TX_SPEED=0
fi

# Guardar lectura actual
echo "$RX_CUR $TX_CUR $TIME_CUR" > "$STATS_FILE"

# Formatear la velocidad a unidades legibles
format_speed() {
    local bytes=$1
    if [ $bytes -ge 1048576 ]; then
        awk -v b="$bytes" 'BEGIN { printf "%.1f MB/s", b / 1048576 }'
    elif [ $bytes -ge 1024 ]; then
        awk -v b="$bytes" 'BEGIN { printf "%.1f KB/s", b / 1024 }'
    else
        echo "$bytes B/s"
    fi
}

DOWN=$(format_speed $RX_SPEED)
UP=$(format_speed $TX_SPEED)

# Con objetivo fijado (set-target) el bloque alterna: 5 s tu IP y 10 s el objetivo,
# con "IP" en rojo. En un lab tu IP útil es la de tun0 (LHOST), así que manda sobre la LAN.
TARGET=$(cat "$HOME/.local/state/target" 2>/dev/null)
SHOWN_FILE="${XDG_RUNTIME_DIR:-/tmp}/localip-shown"
LABEL="IP"
SHOWN="$IP"

if [ -n "$TARGET" ]; then
    TUN_IP=$(ip -4 addr show tun0 2>/dev/null | grep -oP 'inet \K[0-9.]+')
    OWN="${TUN_IP:-$IP}"
    if (( $(date +%s) % 15 < 5 )); then
        SHOWN="$OWN"
    else
        SHOWN="$TARGET"
        LABEL="<span color='#f7768e'>IP</span>"
    fi
    # Fuente monoespaciada: rellenar hasta la más larga de las dos evita que la isla cambie de ancho.
    # El relleno se reparte a ambos lados para que la más corta quede centrada.
    WIDTH=$(( ${#OWN} > ${#TARGET} ? ${#OWN} : ${#TARGET} ))
    PAD=$(( WIDTH - ${#SHOWN} ))
    PAD_L=$(printf "%$(( PAD / 2 ))s" "")
    PAD_R=$(printf "%$(( PAD - PAD / 2 ))s" "")
else
    PAD_L=""
    PAD_R=""
fi

echo "$SHOWN" > "$SHOWN_FILE"
echo "{\"text\": \"$PAD_L$LABEL: $SHOWN$PAD_R\", \"tooltip\": \"󰈀 Interfaz: $INTERFACE\n󰛴 Bajada: $DOWN\n󰛶 Subida: $UP\"}"
