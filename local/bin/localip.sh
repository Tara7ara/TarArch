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

echo "{\"text\": \"IP: $IP\", \"tooltip\": \"󰈀 Interfaz: $INTERFACE\n󰛴 Bajada: $DOWN\n󰛶 Subida: $UP\"}"
