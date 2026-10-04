#!/bin/bash
# Menú de Bluetooth en rofi: conectar/desconectar dispositivos emparejados

source $HOME/.local/bin/rofi-row.sh

# Icono según el tipo de dispositivo (auriculares, móvil u otro)
icono_bt() {
    case "$1" in
        *Barracuda*|*Headset*|*Audio*|*Buds*|*Auricular*) echo "󰋋" ;;
        *iPhone*|*Iphone*|*Phone*|*Movil*|*Móvil*) echo "󰏲" ;;
        *) echo "󰂯" ;;
    esac
}

# Comprobar estado de encendido
IS_POWERED=$(bluetoothctl show | grep "Powered: yes")

if [ -z "$IS_POWERED" ]; then
    CHOICE=$(rofi_row "󰂯" "Activar bluetooth" | \
        rofi -dmenu -p "󰂯" -theme ~/.config/rofi/bluetooth.rasi -markup-rows)
    
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
        LABEL=$(rofi_row "$(icono_bt "$NAME")" "$NAME" "conectado · Enter desconecta" activo)
    else
        LABEL=$(rofi_row "$(icono_bt "$NAME")" "$NAME" "desconectado")
    fi
    
    ITEMS+=("$LABEL")
    MACS+=("$MAC::$NAME::$IS_CONNECTED")
done <<< "$DEVICES_RAW"

N_DISP=${#ITEMS[@]}
ITEMS+=("$(rofi_row "󰂰" "Buscar dispositivos nuevos")")
ITEMS+=("$(rofi_row "󰂲" "Desactivar bluetooth")")

# Se elige por posición: un nombre puede estar contenido en otro
IDX=$(printf "%s\n" "${ITEMS[@]}" | rofi -dmenu -format i -p "󰂯" -theme ~/.config/rofi/bluetooth.rasi -markup-rows -no-custom)
[ -z "$IDX" ] && exit 0

if [ "$IDX" -eq $((N_DISP + 1)) ]; then
    bluetoothctl power off
    notify-send "Bluetooth" "Adaptador desactivado" -i bluetooth-disabled -u low
    exit 0
fi

if [ "$IDX" -eq "$N_DISP" ]; then
    kitty --title "Bluetooth Scan" bash -c "bluetoothctl scan on" &
    exit 0
fi

# Conectar / Desconectar dispositivo seleccionado
for entry in "${MACS[$IDX]}"; do
    MAC=$(echo "$entry" | awk -F'::' '{print $1}')
    NAME=$(echo "$entry" | awk -F'::' '{print $2}')
    CONN=$(echo "$entry" | awk -F'::' '{print $3}')
    
    if [ -n "$MAC" ]; then
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
