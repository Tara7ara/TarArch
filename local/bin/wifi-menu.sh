#!/bin/bash
# Menú de WiFi en rofi

source $HOME/.local/bin/rofi-row.sh

# Comprobar estado de WiFi (nmcli radio wifi da siempre "enabled"/"disabled" en inglés,
# a diferencia de "nmcli g" que se localiza a "activado"/"desactivado" en este sistema)
WIFI_STATE=$(nmcli radio wifi)

if [[ "$WIFI_STATE" == "disabled" ]]; then
    CHOICE=$(rofi_row "󰤨" "Activar wifi" | \
        rofi -dmenu -p "󰤨" -theme ~/.config/rofi/wifi.rasi -markup-rows)

    [ -z "$CHOICE" ] && exit 0

    nmcli radio wifi on
    notify-send "WiFi" "Adaptador activado" -i network-wireless -u low

    # Esperar a que el adaptador salga de "unavailable" antes de escanear
    for i in $(seq 1 20); do
        state=$(nmcli -g GENERAL.STATE device show wlan0 2>/dev/null | cut -d' ' -f1)
        [ "$state" != "20" ] && break
        sleep 0.25
    done
fi

# Notificación sutil de escaneo
notify-send "WiFi" "Escaneando redes cercanas..." -i network-wireless -u low -t 1500 &

# Obtener redes WiFi
WIFI_LIST_RAW=$(nmcli --terse --fields "IN-USE,SSID,SIGNAL,SECURITY" device wifi list --rescan yes)

ITEMS=()
SSIDS=()
SECS=()

while IFS=':' read -r in_use ssid signal security; do
    [ -z "$ssid" ] && continue
    
    # Evitar duplicados (quedarse con la de mejor señal)
    already_seen=false
    for s in "${SSIDS[@]}"; do
        if [ "$s" == "$ssid" ]; then
            already_seen=true
            break
        fi
    done
    [ "$already_seen" = true ] && continue

    # Icono según intensidad de señal
    sig_int=${signal:-0}
    if [ "$sig_int" -ge 75 ]; then
        ICON="󰤨"
    elif [ "$sig_int" -ge 50 ]; then
        ICON="󰤥"
    elif [ "$sig_int" -ge 25 ]; then
        ICON="󰤢"
    else
        ICON="󰤟"
    fi

    DETAIL="${signal} %"
    [ -n "$security" ] && [ "$security" != "--" ] && DETAIL="$DETAIL  󰌾"

    if [ "$in_use" == "*" ]; then
        LABEL=$(rofi_row "$ICON" "$ssid" "conectada · $DETAIL" activo)
    else
        LABEL=$(rofi_row "$ICON" "$ssid" "$DETAIL")
    fi

    ITEMS+=("$LABEL")
    SSIDS+=("$ssid")
    SECS+=("$security")
done <<< "$WIFI_LIST_RAW"

N_REDES=${#ITEMS[@]}
ITEMS+=("$(rofi_row "󰤨" "Conectar a una red oculta")")
ITEMS+=("$(rofi_row "󰤮" "Desactivar wifi")")

# Mostrar menú Rofi (se elige por posición: un SSID puede estar contenido en otro)
IDX=$(printf "%s\n" "${ITEMS[@]}" | rofi -dmenu -format i -p "󰤨" -theme ~/.config/rofi/wifi.rasi -markup-rows -no-custom)
[ -z "$IDX" ] && exit 0

if [ "$IDX" -eq $((N_REDES + 1)) ]; then
    nmcli radio wifi off
    notify-send "WiFi" "Adaptador desactivado" -i network-wireless-offline -u low
    exit 0
fi

if [ "$IDX" -eq "$N_REDES" ]; then
    MANUAL_SSID=$(rofi -dmenu -p "󰤨 Nombre de la red" -l 0 -theme ~/.config/rofi/wifi.rasi -theme-str 'entry { placeholder: ""; }' < /dev/null)
    [ -z "$MANUAL_SSID" ] && exit 0
    MANUAL_PASS=$(rofi -dmenu -password -p "󰌾 $MANUAL_SSID:" -theme ~/.config/rofi/wifi.rasi -theme-str 'entry { placeholder: ""; }')
    
    notify-send "WiFi" "Conectando a $MANUAL_SSID..." -i network-wireless -u low
    if [ -n "$MANUAL_PASS" ]; then
        nmcli device wifi connect "$MANUAL_SSID" password "$MANUAL_PASS"
    else
        nmcli device wifi connect "$MANUAL_SSID"
    fi
    exit 0
fi

# Conectar a la red seleccionada
for i in "$IDX"; do
    ssid="${SSIDS[$i]}"
    sec="${SECS[$i]}"
    
    if [ -n "$ssid" ]; then
        # Comprobar si ya está guardada en NetworkManager
        has_connection=$(nmcli -g NAME connection show | grep "^${ssid}$")
        
        if [ -n "$has_connection" ]; then
            notify-send "WiFi" "Conectando a $ssid..." -i network-wireless -u low
            if nmcli connection up "$ssid"; then
                notify-send "WiFi Conectado" "Conexión establecida con $ssid" -i network-wireless -u low
            else
                notify-send "WiFi Error" "No se pudo conectar a $ssid" -i dialog-error -u normal
            fi
        else
            # Si requiere contraseña
            if [ -n "$sec" ] && [ "$sec" != "--" ]; then
                PASS=$(rofi -dmenu -password -p "󰌾 $ssid:" -theme ~/.config/rofi/wifi.rasi -theme-str 'entry { placeholder: ""; }')
                [ -z "$PASS" ] && exit 0
                
                notify-send "WiFi" "Conectando a $ssid..." -i network-wireless -u low
                if nmcli device wifi connect "$ssid" password "$PASS"; then
                    notify-send "WiFi Conectado" "Conexión establecida con $ssid" -i network-wireless -u low
                else
                    notify-send "WiFi Error" "Contraseña incorrecta o fallo al conectar" -i dialog-error -u normal
                fi
            else
                notify-send "WiFi" "Conectando a $ssid..." -i network-wireless -u low
                nmcli device wifi connect "$ssid"
            fi
        fi
        break
    fi
done
