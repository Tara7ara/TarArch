#!/bin/bash
# ==============================================================================
# LIBRERÍA COMPARTIDA DE ATAJOS Y COMANDOS — TARARCH
# Usada por show-keybindings.sh (Super+A) y rofi-keys-mode.sh (pestaña "Comandos"
# del lanzador unificado Super+Espacio). Un único listado, un único dispatcher.
#
# Formato: "# Sección" para cabeceras, "tecla|descripción" para cada fila.
# La acción se busca por la TECLA exacta (columna izquierda), no por el texto
# de la descripción, así que las descripciones se pueden reescribir sin miedo.
# ==============================================================================

KEYBINDINGS_LIST=(
"# Aplicaciones"
"Super + Enter|Terminal"
"Super + Space|Lanzador de aplicaciones"
"Super + C|Centro de control"
"Super + X|Apagar, reiniciar, suspender"
"Super + A|Esta guía de atajos"
"Super + E|Archivos"
"Super + F|Firefox"
"Super + O|Obsidian"
"Super + K|KeePassXC"
"Super + S|Spotify"
"Super + D|Discord"
"Super + T|Telegram"
"Super + W|WhatsApp"
"Super + P|Nota rápida"
"cursor|Cursor"

"# Herramientas"
"Super + Tab|Panel de estado del sistema"
"Super + R|Conexión SSH al NAS o al servidor"
"Super + V|VPN WireGuard on/off"
"Fn + F10|VPN + escritorio remoto de Windows"
"Super + B|Bluetooth"
"Super + L|SecLists: elegir diccionario y copiar ruta"
"Super + H|Identificar un hash"
"Super + Shift + O|Buscar en el vault"
"Super + Shift + G|Repos git (Alt+Enter abre lazygit)"
"Super + Alt + P|Modo del sistema: uni, normal, gamer"
"Super + Alt + C|Cursor del ratón"
"Super + Alt + L|Bloquear pantalla"

"# Comandos"
"set-target <ip> [nombre]|Fijar el objetivo del lab (\$T)"
"set-target -c|Borrar el objetivo"
"nuevo-lab <nombre> [ip]|Carpeta de máquina nueva en ~/labs"
"tarascan-lab|TaraScan contra el lab Docker local"
"seclists [texto] / -p|SecLists desde la terminal"
"identificar-hash <hash>|Tipo de hash y modo de hashcat/john"
"cheat [nombre] / -e / -l|Chuletas de comandos"
"buscar-vault [texto]|Buscar en el vault"
"repos|Repos git con cambios sin subir"
"cb|Portapapeles: algo | cb copia, cb pega"
"simbolos|Símbolos técnicos para copiar"
"red-auto|Perfil de red según el router"
"red-casa|Perfil de red de casa (DNS AdGuard)"
"red-fuera|Perfil de red de fuera"
"modos / bateria / gamer|Modo del sistema"
"modo-gamer|Modo juego"
"nobloqueo|No bloquear ni suspender"
"wifi|Redes wifi"
"bluetooth|Bluetooth"
"fondos / wallpaper|Fondos de pantalla"
"cambiar-cursor / raton|Cursor del ratón"
"calendario / cal|Calendario"
"taratrack / series|TaraTrack"
"letras|Letra de la canción que suena"
"battery-health / --log|Salud de la batería y su histórico"
"limpiar|Limpieza: capturas viejas, caché, huérfanos, logs"
"codex-acc / codex-auth|Cuentas de Codex"
"xampp-start|Arrancar XAMPP"
"xampp-stop|Parar XAMPP"
"xampp-gui|Panel de XAMPP"
"y / yazi|Explorador de archivos en terminal"
"btop|Monitor del sistema"
"cava|Visualizador de audio"
"fastfetch|Información del sistema"
"ls / ll / lt|Listar con iconos y estado git (eza)"
"cat <archivo>|Ver con resaltado (bat)"
"z <carpeta>|Saltar a carpetas frecuentes (zoxide)"
"ex <archivo>|Descomprimir cualquier formato"

"# Ventanas"
"Super + Q|Cerrar ventana"
"Super + G|Flotante / fija"
"Super + Shift + Space|Flotante / fija"
"Super + J|Cambiar división vertical / horizontal"
"Super + F11|Pantalla completa"
"Super + Shift + F11|Pantalla completa con barra"
"Super + Z|Modo zen"
"Super + Shift + N|Minimizar"
"Super + N|Ver minimizadas"
"Super + Ctrl + N|Restaurar minimizada"
"Super + Ctrl + Flechas|Mover el foco"
"Super + Ctrl + Shift + Flechas|Mover la ventana"
"Super + Alt + Flechas|Redimensionar"
"Super/Alt + Arrastrar|Mover con el ratón"
"Super/Alt + Clic derecho|Redimensionar con el ratón"
"Super + Clic rueda|Enviar a otro escritorio"
"Super + Shift + R|Recargar Hyprland"

"# Escritorios"
"Alt + 1-9|Ir al escritorio"
"Alt + Shift + 1-9|Mover la ventana al escritorio"
"Alt + Izq / Der|Escritorio anterior / siguiente"
"Alt + (Shift) + Tab|Ventana anterior / siguiente"
"Super + Shift + C|Compactar escritorios vacíos"
"Super + Izq / Der|Fondos de pantalla"
"Super + Alt + W|Fondos de pantalla (lista)"

"# Capturas y portapapeles"
"Super + Shift + S|Capturar región"
"Imp Pant|Capturar región"
"Super + Shift + V|Historial del portapapeles"
"Super + Ctrl + V|Vaciar el historial"

"# Terminal"
"Ctrl + Shift + T|Pestaña nueva"
"Ctrl + (Shift) + Tab|Pestaña siguiente / anterior"
"Ctrl + V / Clic derecho|Pegar"
"Ctrl + Shift + W|Cerrar pestaña"
"Ctrl + R|Buscar en el historial (fzf)"
"Ctrl + T|Buscar archivos (fzf)"
"Ctrl + Backspace|Borrar palabra"
"Shift + Arrastrar|Seleccionar texto en TUIs"

"# Audio, brillo y teclado"
"Fn + Volumen|Volumen"
"Fn + Mute|Silenciar"
"Fn + F7 / F8|Brillo"
"Super + Shift + Arr / Ab|Luz del teclado"
"Fn + Izq / Der|Teclado en blanco fijo"
"Bloq Mayús|Aviso de mayúsculas en pantalla"
"Clic derecho en la IP|Copiar la IP de Waybar"
)

# Ancho de la columna de teclas (va en monoespaciada): la tecla más larga + 3.
KB_KEY_WIDTH=0
for _e in "${KEYBINDINGS_LIST[@]}"; do
    [[ $_e == "# "* ]] && continue
    _k=${_e%%|*}; _k=${_k// + /+}; (( ${#_k} > KB_KEY_WIDTH )) && KB_KEY_WIDTH=${#_k}
done
KB_KEY_WIDTH=$((KB_KEY_WIDTH + 3)); unset _e _k

_kb_escape() {
    local s="$1"
    s=${s//&/&amp;}; s=${s//</&lt;}; s=${s//>/&gt;}
    printf '%s' "$s"
}

# Una fila de rofi (markup de Pango) por entrada, en el mismo orden que la
# lista. Las cabeceras van como no seleccionables y cada fila lleva su tecla en
# "info" (rofi la devuelve en $ROFI_INFO en modo script).
render_keybindings() {
    local entry key desc pad sect
    for entry in "${KEYBINDINGS_LIST[@]}"; do
        if [[ $entry == "# "* ]]; then
            sect=${entry#\# }
            printf '<span size="9pt" weight="600" letter_spacing="1500" foreground="#6e6e6e">%s</span>\0nonselectable\x1ftrue\n' \
                "$(_kb_escape "${sect^^}")"
            continue
        fi
        key=${entry%%|*}; desc=${entry#*|}
        # "Super + Shift + S" se ve como "Super+Shift+S" con los + atenuados.
        printf -v pad '%-*s' "$KB_KEY_WIDTH" "${key// + /+}"
        pad=$(_kb_escape "$pad"); pad=${pad//+/<span foreground=\"#5a4a40\">+</span>}
        printf '<span font_family="JetBrainsMono Nerd Font" size="10pt" foreground="#ff9e64">%s</span><span foreground="#d6d6d6">%s</span>\0info\x1f%s\n' \
            "$pad" "$(_kb_escape "$desc")" "$key"
    done
}

# Recibe la TECLA de una entrada (columna izquierda) y ejecuta su acción.
# Las que no tienen acción (atajos de Kitty, de ratón...) no hacen nada.
dispatch_keybinding() {
    local B=$HOME/.local/bin
    case "$1" in
    "Super + Enter")            kitty & ;;
    "Super + Space")            rofi -show drun -theme ~/.config/rofi/launcher.rasi & ;;
    "Super + C")                $B/control-center.py & ;;
    "Super + X")                $B/power-menu.sh ;;
    "Super + E")                thunar & ;;
    "Super + F")                firefox & ;;
    "Super + O")                obsidian & ;;
    "Super + K")                keepassxc & ;;
    "Super + S")                spotify-launcher & ;;
    "Super + D")                discord & ;;
    "Super + T")                telegram-desktop & ;;
    "Super + W")                wasistlos & ;;
    "Super + P")                $B/nota-rapida.sh ;;
    "cursor")                   cursor & ;;
    "Super + Tab")              $B/tararch-dash & ;;
    "Super + R")                $B/ssh-launcher.sh & ;;
    "Super + V")                /usr/local/bin/toggle-vpn.sh ;;
    "Fn + F10")                 kitty --class rdp-console --title "RDP Console" -e $B/toggle-vpn-rdp.sh & ;;
    "Super + B"|"bluetooth")    $B/bluetooth-menu.sh ;;
    "Super + L")                $B/seclists ;;
    "Super + H")                $B/identificar-hash --rofi ;;
    "Super + Shift + O"|"buscar-vault [texto]") $B/buscar-vault ;;
    "Super + Shift + G"|"repos") $B/repos ;;
    "Super + Alt + P"|"modos / bateria / gamer")  $B/set-system-mode.sh ;;
    "Super + Alt + C"|"cambiar-cursor / raton") $B/change-cursor.sh ;;
    "Super + Alt + L")          $B/hyprlock-launch.sh ;;
    "set-target <ip> [nombre]") $B/set-target --rofi ;;
    "set-target -c")            $B/set-target -c ;;
    "seclists [texto] / -p")    $B/seclists ;;
    "identificar-hash <hash>")  $B/identificar-hash --rofi ;;
    "cheat [nombre] / -e / -l")           $B/cheat ;;
    "simbolos")                 $B/simbolos ;;
    "red-auto")                 $B/red-auto ;;
    "red-casa")                 $B/red-casa ;;
    "red-fuera")                $B/red-fuera ;;
    "modo-gamer")               $B/modo-gamer ;;
    "nobloqueo")                $B/nobloqueo ;;
    "wifi")                     $B/wifi-menu.sh ;;
    "fondos / wallpaper"|"Super + Izq / Der") $B/wallpaper-flow ;;
    "Super + Alt + W")          $B/wallpaper-picker.sh ;;
    "calendario / cal")               $B/calendario.sh ;;
    "taratrack / series")                $B/taratrack-app.sh ;;
    "letras")                   kitty -e letras & ;;
    "battery-health / --log")           kitty -e bash -c "battery-health; echo; read -n1 -r -p 'Pulsa una tecla...'" & ;;
    "limpiar")                  kitty -e $B/limpieza-tararch.sh & ;;
    "codex-acc / codex-auth")                $B/codex-acc --rofi ;;
    "xampp-start")              $B/xampp-start ;;
    "xampp-stop")               $B/xampp-stop ;;
    "xampp-gui")                $B/xampp-gui ;;
    "y / yazi")                 kitty -e yazi & ;;
    "btop")                     kitty -e btop & ;;
    "cava")                     kitty -e cava & ;;
    "fastfetch")                kitty -e bash -c "fastfetch-adaptive.sh; echo; read -n1 -r -p 'Pulsa una tecla para cerrar...'" & ;;
    "Super + G"|"Super + Shift + Space")                $B/toggle-floating.sh ;;
    "Super + J")                hyprctl dispatch layoutmsg togglesplit ;;
    "Super + Z")                $B/zen-mode ;;
    "Super + N")                hyprctl dispatch togglespecialworkspace minimized ;;
    "Super + Shift + R")        hyprctl reload && notify-send "Hyprland" "Configuración recargada" -u low & ;;
    "Super + Shift + C")        $B/compact-workspaces.sh ;;
    "Super + Shift + S"|"Imp Pant")        $B/screenshot.sh ;;
    "Super + Shift + V")        cliphist list | rofi -dmenu -p "󰅍 " -theme ~/.config/rofi/clipboard.rasi | cliphist decode | wl-copy ;;
    "Super + Ctrl + V")         cliphist wipe && notify-send "Portapapeles" "Historial vaciado" -u low & ;;
    *) return 0 ;;
    esac
}
