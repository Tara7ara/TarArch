#!/usr/bin/env python3
"""
Daemon de captura y registro continuo de notificaciones para TarArch.
Escucha eventos de org.freedesktop.Notifications y los guarda de forma persistente
en ~/.cache/tararch_notifications.json para el Centro de Control.
"""
import subprocess
import json
import os
import time
import re
import sys

NOTIF_FILE = os.path.expanduser("~/.cache/tararch_notifications.json")
os.makedirs(os.path.dirname(NOTIF_FILE), exist_ok=True)

def append_notification(app_name, title, body, icon=""):
    notifs = []
    if os.path.exists(NOTIF_FILE):
        try:
            with open(NOTIF_FILE, "r", encoding="utf-8") as f:
                notifs = json.load(f)
        except Exception:
            notifs = []

    clean_app = app_name.strip() if app_name else "Sistema"
    clean_title = title.strip() if title else ""
    clean_body = body.strip() if body else ""

    if not clean_title and not clean_body:
        return

    # Evitar duplicados idénticos en los últimos 2 segundos
    if notifs:
        last = notifs[0]
        if last.get("title") == clean_title and last.get("body") == clean_body:
            return

    entry = {
        "id": int(time.time() * 1000),
        "app": clean_app,
        "title": clean_title or clean_app,
        "body": clean_body,
        "icon": icon.strip() or "dialog-information",
        "time": time.strftime("%H:%M")
    }
    notifs.insert(0, entry)
    notifs = notifs[:40]

    try:
        with open(NOTIF_FILE, "w", encoding="utf-8") as f:
            json.dump(notifs, f, indent=2, ensure_ascii=False)
    except Exception:
        pass

def run_monitor():
    cmd = ["dbus-monitor", "interface=org.freedesktop.Notifications,member=Notify"]
    while True:
        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1)
            in_notify = False
            strings = []

            for line in iter(proc.stdout.readline, ''):
                line_clean = line.strip()
                if "member=Notify" in line_clean:
                    in_notify = True
                    strings = []
                    continue

                if in_notify:
                    m = re.match(r'^string "(.*)"$', line_clean)
                    if m:
                        strings.append(m.group(1))
                        if len(strings) >= 4:
                            app_name = strings[0]
                            app_icon = strings[1]
                            summary = strings[2]
                            body = strings[3]
                            append_notification(app_name, summary, body, app_icon)
                            in_notify = False
                            strings = []
                    elif line_clean.startswith("method return") or line_clean.startswith("error") or "member=" in line_clean:
                        if in_notify and len(strings) >= 3:
                            app_name = strings[0]
                            summary = strings[2]
                            body = strings[3] if len(strings) > 3 else ""
                            append_notification(app_name, summary, body)
                        in_notify = False
                        strings = []
        except Exception:
            time.sleep(2)

if __name__ == "__main__":
    run_monitor()
