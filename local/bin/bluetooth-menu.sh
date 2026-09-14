#!/bin/bash
# =============================================================================
# GESTOR RÁPIDO DE BLUETOOTH EN ROFI — TARARCH
# Conexión / desconexión instantánea de auriculares, mandos y móviles
# =============================================================================

# Comprobar estado de encendido
IS_POWERED=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$IS_POWERED" ]; then
    CHOICE=$(printf "<span color='#9ece6a'>󰂯</span>  <b>Activar Bluetooth</b>\n" | \
        rofi -dmenu -p "󰂯 " -theme ~/.config/rofi/bluetooth.rasi -markup-rows)
    
    if [ -n "$CHOICE" ]; then
        bluetoothctl power on
        notify-send "Bluetooth" "Adaptador activado" -i bluetooth -u low
    fi
    exit 0
fi

# Obtener dispositivos emparejados
DEVICES_RAW=$(bluetoothctl devices Paired)

ITEMS=()
MACS=()

while IFS= read -r line; do
    [ -z "$line" ] && continue
    MAC=$(echo "$line" | awk '{print $2}')
    NAME=$(echo "$line" | cut -d' ' -f3-)
    
    # Comprobar si está conectado
    IS_CONNECTED=$(bluetoothctl info "$MAC" | grep "Connected: yes")
    
    if [ -n "$IS_CONNECTED" ]; then
        # Icono según nombre (auriculares vs móvil vs dispositivo)
        ICON="󰂱"
        [ "$NAME" =~ "Barracuda"|"Headset"|"Audio" ] && ICON="󰋋"
        [ "$NAME" =~ "Iphone"|"Phone"|"Movil" ] && ICON="󰏲"
        
        LABEL="<span color='#9ece6a'>$ICON</span>  <b>$NAME</b>  <span color='#9ece6a'>(Conectado · Clic para desconectar)</span>"
    else
        ICON="󰂯"
        [ "$NAME" =~ "Barracuda"|"Headset"|"Audio" ] && ICON="󰋋"
        [ "$NAME" =~ "Iphone"|"Phone"|"Movil" ] && ICON="󰏲"
        
        LABEL="<span color='#787c99'>$ICON</span>  <b>$NAME</b>  <span color='#787c99'>(Desconectado · Clic para conectar)</span>"
    fi
    
    ITEMS+=("$LABEL")
    MACS+=("$MAC::$NAME::$IS_CONNECTED")
done <<< "$DEVICES_RAW"

ITEMS+=("<span color='#ff9e64'>󰂰</span>  <b>Escanear nuevos dispositivos</b>")
ITEMS+=("<span color='#f7768e'>󰂲</span>  <b>Desactivar Bluetooth</b>")

# Generar lista para Rofi
GEN_MENU=$(printf "%s\n" "${ITEMS[@]}")

SELECTED=$(echo "$GEN_MENU" | rofi -dmenu -p "󰂯 " -theme ~/.config/rofi/bluetooth.rasi -markup-rows -no-custom)
[ -z "$SELECTED" ] && exit 0

if [[ "$SELECTED" == *"Desactivar Bluetooth"* ]]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Adaptador desactivado" -i bluetooth-disabled -u low
    exit 0
fi

if [[ "$SELECTED" == *"Escanear nuevos dispositivos"* ]]; then
    kitty --title "Bluetooth Scan" bash -c "bluetoothctl scan on" &
    exit 0
fi

# Conectar / Desconectar dispositivo seleccionado
for entry in "${MACS[@]}"; do
    MAC=$(echo "$entry" | awk -F'::' '{print $1}')
    NAME=$(echo "$entry" | awk -F'::' '{print $2}')
    CONN=$(echo "$entry" | awk -F'::' '{print $3}')
    
    if [[ "$SELECTED" == *"$NAME"* ]]; then
        if [ -n "$CONN" ]; then
            bluetoothctl disconnect "$MAC"
            notify-send "Bluetooth Desconectado" "$NAME" -i bluetooth -u low
        else
            notify-send "Bluetooth" "Conectando a $NAME..." -i bluetooth -u low
            if bluetoothctl connect "$MAC"; then
                notify-send "Bluetooth Conectado" "$NAME" -i bluetooth -u low
            else
                notify-send "Bluetooth Error" "No se pudo conectar a $NAME" -i dialog-error -u normal
            fi
        fi
        break
    fi
done
