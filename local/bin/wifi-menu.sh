#!/bin/bash
# Menú de WiFi en rofi

# Estado del WiFi (nmcli radio wifi no se traduce, nmcli g sí)
WIFI_STATE=$(nmcli radio wifi)

if [[ "$WIFI_STATE" == "disabled" ]]; then
    CHOICE=$(printf "<span color='#9ece6a'>󰤨</span>  <b>Activar WiFi</b>\n" | \
        rofi -dmenu -p "󰤨 " -theme ~/.config/rofi/wifi.rasi -markup-rows)
    
    if [ -n "$CHOICE" ]; then
        nmcli radio wifi on
        notify-send "WiFi" "Adaptador activado" -i network-wireless -u low
    fi
    exit 0
fi

# Aviso de escaneo
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

    SEC_ICON=""
    [ -n "$security" ] && [ "$security" != "--" ] && SEC_ICON="󰌾 "

    if [ "$in_use" == "*" ]; then
        LABEL="<span color='#9ece6a'>$ICON</span>  <b>$ssid</b>  <span color='#9ece6a'>(Conectada · ${signal}%)</span>"
    else
        LABEL="<span color='#c9c9c9'>$ICON</span>  <b>$ssid</b>  <span color='#787c99'>${SEC_ICON}(${signal}%)</span>"
    fi

    ITEMS+=("$LABEL")
    SSIDS+=("$ssid")
    SECS+=("$security")
done <<< "$WIFI_LIST_RAW"

ITEMS+=("<span color='#ff9e64'>󰤨</span>  <b>Conectar a red oculta / manual</b>")
ITEMS+=("<span color='#f7768e'>󰤮</span>  <b>Desactivar WiFi</b>")

# Mostrar menú Rofi
GEN_MENU=$(printf "%s\n" "${ITEMS[@]}")
SELECTED=$(echo "$GEN_MENU" | rofi -dmenu -p "󰤨 " -theme ~/.config/rofi/wifi.rasi -markup-rows -no-custom)
[ -z "$SELECTED" ] && exit 0

if [[ "$SELECTED" == *"Desactivar WiFi"* ]]; then
    nmcli radio wifi off
    notify-send "WiFi" "Adaptador desactivado" -i network-wireless-offline -u low
    exit 0
fi

if [[ "$SELECTED" == *"Conectar a red oculta"* ]]; then
    MANUAL_SSID=$(rofi -dmenu -p "󰤨 Nombre de la red (SSID):" -theme ~/.config/rofi/wifi.rasi)
    [ -z "$MANUAL_SSID" ] && exit 0
    MANUAL_PASS=$(rofi -dmenu -password -p "󰌾 Contraseña de $MANUAL_SSID:" -theme ~/.config/rofi/wifi.rasi)
    
    notify-send "WiFi" "Conectando a $MANUAL_SSID..." -i network-wireless -u low
    if [ -n "$MANUAL_PASS" ]; then
        nmcli device wifi connect "$MANUAL_SSID" password "$MANUAL_PASS"
    else
        nmcli device wifi connect "$MANUAL_SSID"
    fi
    exit 0
fi

# Conectar a la red seleccionada
for i in "${!SSIDS[@]}"; do
    ssid="${SSIDS[$i]}"
    sec="${SECS[$i]}"
    
    if [[ "$SELECTED" == *"$ssid"* ]]; then
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
                PASS=$(rofi -dmenu -password -p "󰌾 Contraseña de $ssid:" -theme ~/.config/rofi/wifi.rasi)
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
