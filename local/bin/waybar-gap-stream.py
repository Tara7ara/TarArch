#!/usr/bin/env python3
"""
Waybar dynamic spacer module (streaming JSON).
Calcula y emite el ancho exacto del gap entre workspaces y el bloque derecho
utilizando espacios indivisibles (\u00a0) para centrado exacto.
"""
import json
import os
import socket
import subprocess
import threading
import time

BAR_WIDTH = 1896
RIGHT_BASE = 847  # px medidos en la barra
CHAR_WIDTH = 9.18  # ancho de un espacio en JetBrainsMono 13px

has_updates = False
emit_event = threading.Event()

def check_updates_loop():
    global has_updates
    while True:
        try:
            t1 = int(subprocess.check_output("checkupdates 2>/dev/null | wc -l", shell=True).strip() or 0)
            t2 = int(subprocess.check_output("yay -Qu --aur 2>/dev/null | wc -l", shell=True).strip() or 0)
            new_has = (t1 + t2) > 0
            if new_has != has_updates:
                has_updates = new_has
                emit_event.set()
        except Exception:
            pass
        time.sleep(60)

threading.Thread(target=check_updates_loop, daemon=True).start()

def hyprland_socket_listener():
    his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE", "")
    sock_path = f"/run/user/{os.getuid()}/hypr/{his}/.socket2.sock"
    while True:
        try:
            if not os.path.exists(sock_path):
                time.sleep(1)
                continue
            with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as s:
                s.connect(sock_path)
                while True:
                    data = s.recv(1024)
                    if not data:
                        break
                    emit_event.set()
        except Exception:
            time.sleep(1)

threading.Thread(target=hyprland_socket_listener, daemon=True).start()

def get_n_ws():
    try:
        data = json.loads(subprocess.check_output(["hyprctl", "workspaces", "-j"], text=True))
        return max(1, sum(1 for w in data if w.get("id", 0) > 0))
    except Exception:
        return 1

def is_vpn_up():
    try:
        res = subprocess.run(["ip", "link", "show", "Portatil"], capture_output=True, text=True)
        return "UP" in res.stdout
    except Exception:
        return False

def get_media_info():
    """Devuelve (is_active, width_in_px)"""
    try:
        raw = subprocess.check_output(
            ["playerctl", "metadata", "--format", "{{status}};{{artist}};{{title}}"],
            text=True, stderr=subprocess.DEVNULL
        ).strip()
        if not raw:
            return False, 0
        parts = raw.split(";", 2)
        status = parts[0]
        if status not in ("Playing", "Paused"):
            return False, 0
        artist = parts[1] if len(parts) > 1 else ""
        title = parts[2] if len(parts) > 2 else ""

        if artist and title:
            text = f"♫  {artist} · {title}"
        elif title:
            text = f"♫  {title}"
        elif artist:
            text = f"♫  {artist}"
        else:
            text = "♫  Reproduciendo"

        visible_len = min(35, len(text))
        # Ancho texto medido en GTK + botones prev y next
        w_media = round(visible_len * 7.8 + 36)
        return True, w_media
    except Exception:
        return False, 0

_last_output = None

def emit_gap():
    global _last_output
    active, w_media = get_media_info()
    if not active:
        out = json.dumps({"text": "", "class": "hidden"})
    else:
        n_ws = get_n_ws()
        vpn_on = is_vpn_up()

        # Workspaces: 8px container padding + 28px por botón
        w_ws = 8 + (n_ws * 28)
        w_vpn = 161 if vpn_on else 75
        w_up = 51 if has_updates else 0
        w_right = RIGHT_BASE + w_vpn + w_up

        gap = BAR_WIDTH - w_right - w_ws
        margin_px = max(0, round((gap - w_media) / 2))
        num_spaces = max(0, round(margin_px / CHAR_WIDTH))

        # Usamos espacios indivisibles (\u00a0) para que Pango no colapse espacios consecutivos
        out = json.dumps({"text": "\u00a0" * num_spaces, "class": "gap"})

    if out != _last_output:
        print(out, flush=True)
        _last_output = out

def main():
    while True:
        try:
            emit_gap()
        except Exception:
            pass
        emit_event.wait(timeout=0.3)
        emit_event.clear()

if __name__ == "__main__":
    main()
