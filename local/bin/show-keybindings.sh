#!/bin/bash
# Chuleta de atajos y comandos (Super + A), Enter ejecuta lo seleccionado

LIST=(
"=== APLICACIONES Y HERRAMIENTAS PRINCIPALES ==="
"Super + Enter                  Abrir Terminal Kitty (GPU, pestañas Powerline)"
"Super + Space                  Lanzador de aplicaciones (Rofi Spotlight)"
"Super + C                      Centro de Control (Toggles, Sliders, Notis, CalDAV)"
"Super + X                      Menú de Apagado Cinemático (Bloquear, Suspender, Reiniciar, Apagar)"
"Super + A                      Guía interactiva de Atajos y Comandos (CheatSheet)"
"Super + B                      Gestor rápido de Bluetooth (Razer, iPhone...)"
"Super + W                      Abrir WhatsApp (Wasistlos)"
"Super + Alt + W                Selector visual de fondos con miniaturas (Rofi)"
"Super + Alt + C                Selector de tema de ratón / cursor (Ice, Classic, Amber)"
"Super + Alt + P                Selector de Modos del Sistema (Uni 60Hz Silent, Normal, 144Hz Gamer)"
"Super + Alt + L                Bloquear pantalla con fondo desenfocado (Hyprlock)"
"Super + R                      Lanzador rápido SSH (TaraNAS / Servidor)"
"Super + V                      Activar / Desactivar VPN WireGuard (con DNS AdGuard)"
"Fn + F10                       Conexión VPN + RDP a Windows 11 (Workspace 9)"
"Super + E                      Abrir gestor de archivos (Thunar)"
"Super + F                      Abrir navegador Firefox"
"Super + D                      Abrir Discord (tema oscuro)"
"Super + S                      Abrir Spotify (Sleek WarmDark)"
"Super + O                      Abrir Obsidian (Baúl de notas y apuntes)"
"Super + T                      Abrir Telegram Desktop"
"Super + K                      Gestor de contraseñas (KeePassXC)"
"Super + P                      Nota rápida inmediata (ventana flotante · ~/notas.txt)"
""
"=== COMANDOS Y UTILIDADES DE CONSOLA ==="
"calendario / cal               Abrir agenda y gestor de eventos CalDAV (GNOME Calendar)"
"taratrack / series            Abrir plataforma de series y rankings ELO (tara.series)"
"modos / bateria / gamer       Cambiar modo de energía (Uni 60Hz, Normal 144Hz, Gamer Turbo)"
"raton / cursor                 Cambiar tema de cursor de ratón (Ice, Classic, Amber)"
"codex-acc / codex-auth        Gestor multicuenta OpenAI Codex CLI (1-3 / rotar límites)"
"limpiar                        Mantenimiento: purga capturas >14d, pacman/yay, huérfanos y logs"
"wifi                           Abrir selector Spotlight de redes WiFi"
"bluetooth                      Abrir gestor de dispositivos Bluetooth"
"fondos / wallpaper            Abrir galería visual de wallpapers con miniaturas"
"nobloqueo                      Inhibir bloqueo automático y suspensión (Modo Cafeína)"
"modo-gamer                    Activar modo juego (CPU 100%, sin blur/sombras)"
"red-casa                       Perfil de red LAN Casa (DHCP + DNS AdGuard 192.168.1.10)"
"red-fuera                      Perfil de red LAN Fuera (DHCP y DNS automáticos)"
"y / yazi                       Explorador de archivos en Rust con preview GPU de fotos/vídeos"
"btop                           Monitor de recursos del sistema en tiempo real (Warm Dark)"
"cava                           Visualizador de audio reactivo en terminal"
"fastfetch                      Información del sistema y hardware adaptativo"
"letras                         Ver letras sincronizadas de la canción actual de Spotify"
"ls / ll / lt                   Listado moderno con iconos y estado Git (eza)"
"cat <archivo>                  Ver archivos con resaltado de sintaxis (bat)"
"z <carpeta>                    Navegación inteligente a directorios frecuentes (zoxide)"
"ex <archivo>                   Extractor universal multiformato (.zip .tar.gz .rar .7z...)"
""
"=== TERMINAL Y EDICIÓN (KITTY) ==="
"Ctrl + Shift + T               Nueva pestaña en terminal Kitty"
"Ctrl + Tab / Ctrl+Shift+Tab    Cambiar entre pestañas de terminal"
"Ctrl + Shift + W               Cerrar pestaña actual de terminal"
"Ctrl + V / Clic Derecho        Pegar texto en la terminal"
"Shift + Arrastrar Ratón        Seleccionar y copiar texto en TUIs (Claude Code)"
"Ctrl + Backspace               Borrar palabra completa hacia atrás"
"Ctrl + R                       Buscar en historial de comandos interactivo (fzf)"
"Ctrl + T                       Buscar archivos con previsualización en vivo (fzf + bat)"
""
"=== CAPTURAS Y PORTAPAPELES ==="
"Imp Pant / Super + Shift + S   Capturar región (copia ruta al portapapeles y abre Swappy)"
"Super + Shift + V              Abrir historial del portapapeles (Spotlight)"
"Super + Ctrl + V               Vaciar y limpiar historial del portapapeles"
""
"=== GESTIÓN DE VENTANAS Y RATÓN ==="
"Super + Q                      Cerrar ventana activa"
"Super + G / Super+Shift+Space  Alternar ventana flotante (compacta 800x520) / fija"
"Super + Shift + R              Recargar configuración de Hyprland y Waybar"
"Super + F11                    Pantalla completa pura (sin barra superior)"
"Super + Shift + F11            Pantalla completa (con barra superior)"
"Super + Shift + N              Ocultar ventana activa (minimizar suave)"
"Super + N                      Ver ventanas ocultas / minimizadas (overlay)"
"Super + Ctrl + N               Restaurar ventana minimizada al workspace anterior"
"Super + Shift + C              Compactar escritorios vacíos"
"Super + Ctrl + Flechas         Mover foco entre ventanas"
"Super + Ctrl + Shift + Flechas Mover ventana activa de posición"
"Super + Alt + Flechas          Redimensionar tamaño de ventana"
"Super/Alt + Clic Izquierdo     Mover ventana libremente con el ratón"
"Super/Alt + Clic Derecho       Redimensionar ventana con el ratón"
"Super + Clic Rueda             Enviar ventana a otro escritorio (selector Rofi)"
""
"=== WORKSPACES Y FONDOS ==="
"Alt + [1 - 9]                  Ir al escritorio 1 - 9"
"Alt + Shift + [1 - 9]          Mover ventana activa al escritorio 1 - 9"
"Alt + Flecha Izq / Der         Cambiar entre escritorios (slidefade 15%)"
"Alt + Tab / Alt + Shift + Tab  Alternar entre ventanas recientes"
"Super + Flecha Derecha         Siguiente fondo de pantalla (144 FPS)"
"Super + Flecha Izquierda       Anterior fondo de pantalla (144 FPS)"
""
"=== AUDIO, BRILLO Y TECLADO ROG (SWAYOSD) ==="
"Fn + Volumen Arr/Ab            Subir / Bajar volumen con OSD flotante"
"Fn + Mute                      Silenciar / Reactivar audio con OSD"
"Fn + F7 / F8                   Subir / Bajar brillo de pantalla con OSD"
"Bloq Mayús (Caps Lock)         Indicador visual flotante de mayúsculas (OSD)"
"Super + Shift + Flechas Arr/Ab Subir / Bajar brillo de LEDs del teclado ROG"
"Fn + Flechas Izq/Der           Restablecer teclado ROG a blanco puro fijo"
)

GEN_LIST=$(printf "%s\n" "${LIST[@]}")

# Mostrar selector Rofi
SELECTED=$(echo "$GEN_LIST" | rofi -dmenu -i -p "󰌌 " -theme ~/.config/rofi/keybindings.rasi)
[ -z "$SELECTED" ] && exit 0

# Ejecutar la acción correspondiente si es ejecutable
case "$SELECTED" in
    *"Abrir Terminal Kitty"*)       kitty & ;;
    *"Lanzador de aplicaciones"*)   rofi -show drun -theme ~/.config/rofi/launcher.rasi & ;;
    *"Centro de Control"*)          /home/tara/.local/bin/control-center.py & ;;
    *"Menú de Apagado"*)            /home/tara/.local/bin/power-menu.sh ;;
    *"Gestor rápido de Bluetooth"*|*"bluetooth"*) /home/tara/.local/bin/bluetooth-menu.sh ;;
    *"Selector visual de fondos"*|*"wallpaper"*|*"fondos"*) /home/tara/.local/bin/wallpaper-picker.sh ;;
    *"Selector de tema de ratón"*|*"raton"*|*"cursor"*) /home/tara/.local/bin/change-cursor.sh ;;
    *"Selector de Modos del Sistema"*|*"modos"*|*"bateria"*|*"rendimiento"*|*"gamer"*) /home/tara/.local/bin/set-system-mode.sh ;;
    *"Bloquear pantalla"*|*"hyprlock"*) /home/tara/.local/bin/hyprlock-launch.sh ;;
    *"Lanzador rápido SSH"*)        /home/tara/.local/bin/ssh-launcher.sh & ;;
    *"Activar / Desactivar VPN"*)   /usr/local/bin/toggle-vpn.sh ;;
    *"Conexión VPN + RDP"*|*"rdp"*|*"windows"*) kitty --class rdp-console --title "RDP Console" -e /usr/local/bin/toggle-vpn-rdp.sh & ;;
    *"Abrir gestor de archivos"*)   thunar & ;;
    *"Abrir navegador Firefox"*)    firefox & ;;
    *"Abrir Discord"*)              discord & ;;
    *"Abrir Spotify"*)              spotify & ;;
    *"Abrir Obsidian"*)             obsidian & ;;
    *"Abrir Telegram"*)             telegram-desktop & ;;
    *"Gestor de contraseñas"*|*"KeePassXC"*) keepassxc & ;;
    *"Abrir WhatsApp"*)             wasistlos & ;;
    *"Nota rápida"*)                /home/tara/.local/bin/nota-rapida.sh ;;
    *"Abrir agenda y gestor"*|*"calendario"*|*"cal"*) /home/tara/.local/bin/calendario.sh ;;
    *"Abrir plataforma de series"*|*"taratrack"*|*"series"*) /home/tara/.local/bin/taratrack-app.sh ;;
    *"Gestor multicuenta OpenAI"*|*"codex-acc"*|*"codex-auth"*) /home/tara/.local/bin/codex-acc --rofi ;;
    *"Mantenimiento"*|*"limpiar"*)  kitty -e /home/tara/.local/bin/limpieza-tararch.sh & ;;
    *"Abrir selector Spotlight de redes"*|*"wifi"*) /home/tara/.local/bin/wifi-menu.sh ;;
    *"nobloqueo"*)                  /home/tara/.local/bin/nobloqueo ;;
    *"modo-gamer"*)                 /home/tara/.local/bin/modo-gamer ;;
    *"red-casa"*)                   /home/tara/.local/bin/red-casa ;;
    *"red-fuera"*)                  /home/tara/.local/bin/red-fuera ;;
    *"y / yazi"*)                   kitty -e yazi & ;;
    *"btop"*)                       kitty -e btop & ;;
    *"cava"*)                       kitty -e cava & ;;
    *"fastfetch"*)                  kitty -e bash -c "fastfetch-adaptive.sh; echo; read -n1 -r -p 'Pulsa una tecla para cerrar...'" & ;;
    *"letras"*)                     kitty -e letras & ;;
    *"Capturar región"*)            /home/tara/.local/bin/screenshot.sh ;;
    *"Abrir historial del portapapeles"*) /home/tara/.local/bin/cliphist-menu.sh ;;
    *"Vaciar y limpiar historial"*) cliphist wipe && notify-send "Portapapeles" "Historial vaciado" -u low & ;;
    *"Recargar configuración de Hyprland"*) hyprctl reload && notify-send "Hyprland" "Configuración recargada" -u low & ;;
    *"Compactar escritorios"*)      /home/tara/.local/bin/compact-workspaces.sh ;;
    *"Siguiente fondo"*)            /home/tara/.local/bin/wallpaper-cycle.sh next ;;
    *"Anterior fondo"*)             /home/tara/.local/bin/wallpaper-cycle.sh prev ;;
    *"Alternar ventana flotante"*)  /home/tara/.local/bin/toggle-floating.sh ;;
    *"Ver ventanas ocultas"*)       hyprctl dispatch togglespecialworkspace minimized ;;
    *) exit 0 ;;
esac
