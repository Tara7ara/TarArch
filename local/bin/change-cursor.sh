#!/bin/bash
# Cambia el tema del cursor: ice (blanco, por defecto), classic (negro), amber
# Uso:
#   change-cursor.sh           -> Abre menú interactivo en Rofi
#   change-cursor.sh ice       -> Aplica Bibata-Modern-Ice (Blanco)
#   change-cursor.sh classic   -> Aplica Bibata-Modern-Classic (Negro)
#   change-cursor.sh amber     -> Aplica Bibata-Modern-Amber (Ámbar)
#   change-cursor.sh toggle    -> Alterna entre Ice -> Classic -> Amber
#   change-cursor.sh apply     -> Aplica el cursor guardado en caché

CACHE_FILE="$HOME/.cache/current_cursor_theme"
CURSOR_SIZE=24

apply_cursor() {
    local THEME_ID="$1"
    local THEME_NAME="$2"

    [ -z "$THEME_ID" ] && THEME_ID="Bibata-Modern-Ice"
    [ -z "$THEME_NAME" ] && THEME_NAME="$THEME_ID"

    # 1. Hyprland compositor
    hyprctl setcursor "$THEME_ID" "$CURSOR_SIZE" >/dev/null 2>&1
    hyprctl setenv XCURSOR_THEME "$THEME_ID" >/dev/null 2>&1
    hyprctl setenv XCURSOR_SIZE "$CURSOR_SIZE" >/dev/null 2>&1
    hyprctl setenv HYPRCURSOR_THEME "$THEME_ID" >/dev/null 2>&1
    hyprctl setenv HYPRCURSOR_SIZE "$CURSOR_SIZE" >/dev/null 2>&1

    # 2. DBus / systemd activation
    dbus-update-activation-environment --systemd XCURSOR_THEME XCURSOR_SIZE HYPRCURSOR_THEME HYPRCURSOR_SIZE >/dev/null 2>&1

    # 3. GSettings (GTK)
    gsettings set org.gnome.desktop.interface cursor-theme "$THEME_ID" >/dev/null 2>&1
    gsettings set org.gnome.desktop.interface cursor-size "$CURSOR_SIZE" >/dev/null 2>&1

    # 4. Archivos de configuración
    # GTK 3 & 4
    for ini in "$HOME/.config/gtk-3.0/settings.ini" "$HOME/.config/gtk-4.0/settings.ini"; do
        if [ -f "$ini" ]; then
            sed -i "s/^gtk-cursor-theme-name=.*/gtk-cursor-theme-name=$THEME_ID/" "$ini"
            sed -i "s/^gtk-cursor-theme-size=.*/gtk-cursor-theme-size=$CURSOR_SIZE/" "$ini"
        fi
    done

    # environment.d
    mkdir -p "$HOME/.config/environment.d"
    cat << ENV_EOF > "$HOME/.config/environment.d/cursor.conf"
XCURSOR_THEME=$THEME_ID
XCURSOR_SIZE=$CURSOR_SIZE
HYPRCURSOR_THEME=$THEME_ID
HYPRCURSOR_SIZE=$CURSOR_SIZE
ENV_EOF

    # ~/.icons/default/index.theme y ~/.local/share/icons/default/index.theme
    for theme_dir in "$HOME/.icons/default" "$HOME/.local/share/icons/default"; do
        mkdir -p "$theme_dir"
        cat << IDX_EOF > "$theme_dir/index.theme"
[Icon Theme]
Name=Default
Comment=Default Cursor Theme
Inherits=$THEME_ID
IDX_EOF
    done

    # Guardar en cache
    mkdir -p "$(dirname "$CACHE_FILE")"
    echo "$THEME_ID" > "$CACHE_FILE"

    # 5. Notificar a Kitty y forzar repintado
    pkill -USR1 kitty 2>/dev/null
    
    # Nudge cursor para refrescar Wayland sprite
    pos=$(hyprctl cursorpos 2>/dev/null | tr -d ' ')
    if [ -n "$pos" ]; then
        x=$(echo "$pos" | cut -d',' -f1)
        y=$(echo "$pos" | cut -d',' -f2)
        target_y=$(( y >= 44 ? 15 : 500 ))
        hyprctl dispatch movecursor "$x" "$target_y" >/dev/null 2>&1
        sleep 0.01
        hyprctl dispatch movecursor "$x" "$y" >/dev/null 2>&1
    fi

    notify-send "Tema del Ratón" "Tema activo: $THEME_NAME" -i preferences-desktop-theme
}

case "$1" in
    ice|blanco|white)
        apply_cursor "Bibata-Modern-Ice" "Bibata Modern Ice (Blanco)"
        ;;
    classic|negro|black|dark)
        apply_cursor "Bibata-Modern-Classic" "Bibata Modern Classic (Negro)"
        ;;
    amber|ambar|orange|naranja)
        apply_cursor "Bibata-Modern-Amber" "Bibata Modern Amber (Ámbar)"
        ;;
    apply)
        CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
        [ -z "$CURRENT" ] && CURRENT="Bibata-Modern-Ice"
        case "$CURRENT" in
            *"Amber"*)   apply_cursor "Bibata-Modern-Amber" "Bibata Modern Amber (Ámbar)" ;;
            *"Classic"*) apply_cursor "Bibata-Modern-Classic" "Bibata Modern Classic (Negro)" ;;
            *)           apply_cursor "Bibata-Modern-Ice" "Bibata Modern Ice (Blanco)" ;;
        esac
        ;;
    toggle|next)
        CURRENT=$(cat "$CACHE_FILE" 2>/dev/null)
        case "$CURRENT" in
            *"Ice"*)     apply_cursor "Bibata-Modern-Classic" "Bibata Modern Classic (Negro)" ;;
            *"Classic"*) apply_cursor "Bibata-Modern-Amber" "Bibata Modern Amber (Ámbar)" ;;
            *)           apply_cursor "Bibata-Modern-Ice" "Bibata Modern Ice (Blanco)" ;;
        esac
        ;;
    *)
        # Menú Rofi
        OPT_ICE="<span color='#7aa2f7'>󰍽</span>  <b>Bibata Modern Ice</b>      <span color='#9ece6a'>[Blanco - Default]</span>"
        OPT_CLASSIC="<span color='#bb9af7'>󰍽</span>  <b>Bibata Modern Classic</b>  <span color='#787c99'>[Negro]</span>"
        OPT_AMBER="<span color='#ff9e64'>󰍽</span>  <b>Bibata Modern Amber</b>    <span color='#ff9e64'>[Ámbar / Naranja]</span>"

        CHOICE=$(printf "%b\n%b\n%b" "$OPT_ICE" "$OPT_CLASSIC" "$OPT_AMBER" | \
            rofi -dmenu \
                 -p "󰍽 " \
                 -theme ~/.config/rofi/cursor-menu.rasi \
                 -no-custom \
                 -markup-rows \
                 -hover-select \
                 -me-select-entry '' \
                 -me-accept-entry 'MousePrimary' \
                 -cache-file /dev/null)

        case "$CHOICE" in
            *"Ice"*)     apply_cursor "Bibata-Modern-Ice" "Bibata Modern Ice (Blanco)" ;;
            *"Classic"*) apply_cursor "Bibata-Modern-Classic" "Bibata Modern Classic (Negro)" ;;
            *"Amber"*)   apply_cursor "Bibata-Modern-Amber" "Bibata Modern Amber (Ámbar)" ;;
        esac
        ;;
esac
