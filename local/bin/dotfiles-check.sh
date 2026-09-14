#!/bin/bash
# Compara los configs/scripts en uso contra la última copia en Dotfiles/ del NAS
# (la que deja sync.sh) para saber si hay cambios locales sin respaldar.
# No incluye ~/.claude ni ~/.gemini (cambian constantemente con el uso normal,
# darían ruido) ni contraseñas/claves privadas (nunca viven en Dotfiles).

DOT="$HOME/TaraNAS/Recuperacion_parcial_arch/Dotfiles"

if [ ! -d "$DOT" ]; then
    echo "No encuentro Dotfiles en $DOT (¿NAS montado?)"
    exit 1
fi

PAIRS=(
    "$HOME/.config/hypr:$DOT/config/hypr"
    "$HOME/.config/kitty/kitty.conf:$DOT/config/kitty/kitty.conf"
    "$HOME/.config/waybar/config.jsonc:$DOT/config/waybar/config.jsonc"
    "$HOME/.config/waybar/style.css:$DOT/config/waybar/style.css"
    "$HOME/.config/rofi:$DOT/config/rofi"
    "$HOME/.config/fastfetch/config.jsonc:$DOT/config/fastfetch/config.jsonc"
    "$HOME/.config/dunst/dunstrc:$DOT/config/dunst/dunstrc"
    "$HOME/.config/waypaper/config.ini:$DOT/config/waypaper/config.ini"
    "$HOME/.config/btop:$DOT/config/btop"
    "$HOME/.config/wlogout:$DOT/config/wlogout"
    "$HOME/.config/gtk-3.0/settings.ini:$DOT/config/gtk-3.0/settings.ini"
    "$HOME/.config/gtk-3.0/gtk.css:$DOT/config/gtk-3.0/gtk.css"
    "$HOME/.config/gtk-4.0/settings.ini:$DOT/config/gtk-4.0/settings.ini"
    "$HOME/.config/swappy/config:$DOT/config/swappy/config"
    "$HOME/.config/lan-mouse/config.toml:$DOT/config/lan-mouse/config.toml"
    "$HOME/.config/networkmanager-dmenu/config.ini:$DOT/config/networkmanager-dmenu/config.ini"
    "$HOME/.config/keepassxc/keepassxc.ini:$DOT/config/keepassxc/keepassxc.ini"
    "$HOME/.config/systemd/user/cliphist-clear.service:$DOT/systemd-user/cliphist-clear.service"
    "$HOME/.config/systemd/user/lan-mouse.service:$DOT/systemd-user/lan-mouse.service"
    "$HOME/.config/systemd/user/bt-proximity-lock.service:$DOT/systemd-user/bt-proximity-lock.service"
    "$HOME/.zshrc:$DOT/.zshrc"
    "$HOME/.zprofile:$DOT/.zprofile"
    "$HOME/.local/bin:$DOT/local/bin"
    "/usr/local/bin/toggle-vpn.sh:$DOT/usr-local-bin/toggle-vpn.sh"
    "/usr/local/bin/toggle-vpn-rdp.sh:$DOT/usr-local-bin/toggle-vpn-rdp.sh"
    "/usr/local/bin/toggle-network.sh:$DOT/usr-local-bin/toggle-network.sh"
    "/usr/local/bin/toggle-firewall.sh:$DOT/usr-local-bin/toggle-firewall.sh"
    "/usr/local/bin/restic-backup.sh:$DOT/usr-local-bin/restic-backup.sh"
    "/usr/local/bin/luks-header-backup.sh:$DOT/usr-local-bin/luks-header-backup.sh"
    "/usr/local/bin/rogauracore:$DOT/usr-local-bin/rogauracore"
    "/etc/systemd/system/restic-backup.service:$DOT/systemd-system/restic-backup.service"
    "/etc/systemd/system/restic-backup.timer:$DOT/systemd-system/restic-backup.timer"
    "/etc/systemd/system/rogauracore.service:$DOT/systemd-system/rogauracore.service"
    "/etc/systemd/system/alc294-speaker-fix.service:$DOT/systemd-system/alc294-speaker-fix.service"
    "/etc/udev/rules.d/91-alc294-speaker-fix.rules:$DOT/udev-rules/91-alc294-speaker-fix.rules"
    "/etc/pacman.d/hooks/95-luks-header-backup.hook:$DOT/pacman-hooks/95-luks-header-backup.hook"
    "/etc/systemd/system-sleep/asus-kbd-backlight:$DOT/systemd-sleep/asus-kbd-backlight"
    "/etc/asusd/aura_1866.ron:$DOT/asusd/aura_1866.ron"
    "$HOME/img/wallpapers:$DOT/wallpapers"
)

missing_in_dot=0
changed=0
checked=0

for pair in "${PAIRS[@]}"; do
    src="${pair%%:*}"
    dst="${pair#*:}"

    [ -e "$src" ] || continue
    checked=$((checked + 1))

    if [ ! -e "$dst" ]; then
        echo "[NUEVO, no está en Dotfiles] $src"
        missing_in_dot=$((missing_in_dot + 1))
        continue
    fi

    if [ -d "$src" ]; then
        result=$(diff -rq "$src" "$dst" 2>&1)
    else
        result=$(diff -q "$src" "$dst" 2>&1)
    fi

    if [ -n "$result" ]; then
        echo "[CAMBIADO] $src"
        echo "$result" | sed 's/^/    /'
        changed=$((changed + 1))
    fi
done

echo ""
if [ "$changed" -eq 0 ] && [ "$missing_in_dot" -eq 0 ]; then
    echo "Todo sincronizado ($checked rutas comprobadas) — Dotfiles al día."
else
    echo "$changed ruta(s) con cambios + $missing_in_dot ruta(s) nueva(s) sin copia, de $checked comprobadas."
    echo "Ejecuta sync.sh cuando quieras respaldarlo:"
    echo "  bash \"$HOME/TaraNAS/Recuperacion_parcial_arch/Instalacion/sync.sh\""
fi
