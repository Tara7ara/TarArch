#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import time

from PIL import Image, ImageStat

THRESHOLD = 128  # luminancia media 0-255, punto de corte oscuro/claro
CURSOR_SIZE = 24


def avg_luminance(path):
    img = Image.open(path).convert("RGB")
    img.thumbnail((64, 64))  # basta para una media fiable, y es rapido
    r, g, b = ImageStat.Stat(img).mean
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def nudge_cursor():
    # En Hyprland/Wayland, forzamos un evento leave->enter rapido para que el
    # compositor repinte el sprite del cursor inmediatamente.
    try:
        out = subprocess.check_output(["hyprctl", "cursorpos"]).decode().strip()
        x_str, y_str = [p.strip() for p in out.split(",")]
        x, y = int(x_str), int(y_str)
    except Exception:
        x, y = 960, 540

    # Si el raton ya estaba sobre Waybar (y < 44), saltamos abajo; si no, saltamos a Waybar
    target_y = 15 if y >= 44 else 500

    subprocess.run(["hyprctl", "dispatch", "movecursor", str(x), str(target_y)], stdout=subprocess.DEVNULL)
    time.sleep(0.01)
    subprocess.run(["hyprctl", "dispatch", "movecursor", str(x), str(y)], stdout=subprocess.DEVNULL)


def update_gtk_ini(file_path, theme, size):
    path = os.path.expanduser(file_path)
    if not os.path.exists(path):
        return
    try:
        with open(path, "r") as f:
            content = f.read()
        content = re.sub(r"gtk-cursor-theme-name=.*", f"gtk-cursor-theme-name={theme}", content)
        content = re.sub(r"gtk-cursor-theme-size=.*", f"gtk-cursor-theme-size={size}", content)
        with open(path, "w") as f:
            f.write(content)
    except Exception:
        pass


def update_default_index_theme(theme):
    path = os.path.expanduser("~/.icons/default/index.theme")
    try:
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as f:
            f.write(f"[Icon Theme]\nName=Default\nComment=Default Cursor Theme\nInherits={theme}\n")
    except Exception:
        pass


def main():
    if len(sys.argv) < 2:
        sys.exit(1)

    try:
        lum = avg_luminance(sys.argv[1])
    except Exception:
        sys.exit(0)

    theme = "Bibata-Modern-Ice" if lum < THRESHOLD else "Bibata-Modern-Classic"
    size_str = str(CURSOR_SIZE)

    # 1. Cambiar tema en el compositor Hyprland
    subprocess.run(["hyprctl", "setcursor", theme, size_str], stdout=subprocess.DEVNULL)

    # 2. Actualizar variables de entorno de Hyprland
    subprocess.run(["hyprctl", "setenv", "XCURSOR_THEME", theme], stdout=subprocess.DEVNULL)
    subprocess.run(["hyprctl", "setenv", "XCURSOR_SIZE", size_str], stdout=subprocess.DEVNULL)
    subprocess.run(["hyprctl", "setenv", "HYPRCURSOR_THEME", theme], stdout=subprocess.DEVNULL)
    subprocess.run(["hyprctl", "setenv", "HYPRCURSOR_SIZE", size_str], stdout=subprocess.DEVNULL)

    # 3. Sincronizar en DBus y Systemd user session
    subprocess.run(
        ["dbus-update-activation-environment", "--systemd", "XCURSOR_THEME", "XCURSOR_SIZE", "HYPRCURSOR_THEME", "HYPRCURSOR_SIZE"],
        stdout=subprocess.DEVNULL
    )

    # 4. Sincronizar en GSettings (GTK3/4)
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-theme", theme], stdout=subprocess.DEVNULL)
    subprocess.run(["gsettings", "set", "org.gnome.desktop.interface", "cursor-size", size_str], stdout=subprocess.DEVNULL)

    # 5. Actualizar archivos de configuracion estaticos
    update_default_index_theme(theme)
    update_gtk_ini("~/.config/gtk-3.0/settings.ini", theme, size_str)
    update_gtk_ini("~/.config/gtk-4.0/settings.ini", theme, size_str)

    # 6. Notificar a las terminales activas (Kitty)
    subprocess.run(["pkill", "-USR1", "kitty"], stdout=subprocess.DEVNULL)


if __name__ == "__main__":
    main()
