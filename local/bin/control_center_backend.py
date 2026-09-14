#!/usr/bin/env python3
"""
Lógica de sistema del Centro de Control de TarArch: estado (volumen, brillo,
notificaciones, toggles) y sincronización CalDAV. Sin GTK — nada aquí construye
UI, solo lee/escribe estado real del sistema. Ver control-center.py para la
ventana que consume estas funciones.
"""
import os
import signal
import subprocess
import datetime
import urllib.request
import urllib.parse
import base64
import ssl
import re
import glob
import json

PID_FILE = "/tmp/tararch_control_center.pid"
CALDAV_BASE = "https://tara.calendario/tara/"
CALDAV_USER = "tara"
CALDAV_PASS = "tara"
NOTIF_CACHE_FILE = os.path.expanduser("~/.cache/tararch_notifications.json")
MODE_FILE = os.path.expanduser("~/.cache/current_system_mode")


def is_running():
    """Si ya hay una instancia corriendo, la mata (toggle) y devuelve True."""
    if os.path.exists(PID_FILE):
        try:
            with open(PID_FILE, "r") as f:
                pid = int(f.read().strip())
            os.kill(pid, signal.SIGTERM)
            os.remove(PID_FILE)
            return True
        except Exception:
            pass
    return False


def get_volume():
    try:
        out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True).strip()
        parts = out.split()
        if len(parts) >= 2:
            return float(parts[1])
    except Exception:
        pass
    return 0.5


def set_volume(value):
    subprocess.run(["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", f"{value:.2f}"], stdout=subprocess.DEVNULL)


def get_brightness():
    try:
        out = subprocess.check_output(["brightnessctl", "get"], text=True).strip()
        max_out = subprocess.check_output(["brightnessctl", "max"], text=True).strip()
        return float(out) / float(max_out)
    except Exception:
        pass
    return 0.5


def set_brightness(value):
    pct = int(value * 100)
    subprocess.run(["brightnessctl", "set", f"{pct}%"], stdout=subprocess.DEVNULL)


def get_noti_count():
    try:
        out = subprocess.check_output(["swaync-client", "-c"], text=True, stderr=subprocess.DEVNULL).strip()
        if out.isdigit():
            return int(out)
    except Exception:
        pass
    return 0


def is_lanmouse_running():
    return subprocess.run(["pgrep", "-x", "lan-mouse"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def is_nobloqueo_active():
    return subprocess.run(["pgrep", "-f", "nobloqueo-marcador"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def get_system_mode():
    """'normal' | 'uni' | 'gamer', según ~/.cache/current_system_mode."""
    if os.path.exists(MODE_FILE):
        try:
            with open(MODE_FILE, "r") as f:
                return f.read().strip()
        except Exception:
            pass
    return "normal"


def load_notifications():
    if not os.path.exists(NOTIF_CACHE_FILE):
        return []
    try:
        with open(NOTIF_CACHE_FILE, "r") as f:
            return json.load(f)
    except Exception:
        return []


def clear_notifications():
    try:
        with open(NOTIF_CACHE_FILE, "w") as f:
            json.dump([], f)
    except Exception:
        pass
    subprocess.run(["swaync-client", "-C"], stdout=subprocess.DEVNULL)


def delete_notification(notif_id):
    if not notif_id or not os.path.exists(NOTIF_CACHE_FILE):
        return
    try:
        notifs = load_notifications()
        notifs = [n for n in notifs if n.get("id") != notif_id]
        with open(NOTIF_CACHE_FILE, "w") as f:
            json.dump(notifs, f, indent=2)
    except Exception:
        pass


def parse_vevents_from_ics(ics_text):
    """Extrae eventos VEVENT de cualquier texto ICS (CalDAV o local)."""
    parsed = []
    vevents = re.findall(r"BEGIN:VEVENT(.*?)END:VEVENT", ics_text, re.DOTALL)
    for v in vevents:
        summary_m = re.search(r"SUMMARY:(.+)", v)
        dtstart_m = re.search(r"DTSTART[^:]*:(\d{8})", v)
        time_m = re.search(r"DTSTART[^:]*:\d{8}T(\d{2})(\d{2})", v)
        rrule_m = re.search(r"RRULE:.*FREQ=YEARLY", v)

        if summary_m and dtstart_m:
            summary = summary_m.group(1).strip()
            dt_str = dtstart_m.group(1).strip()
            time_str = f"{time_m.group(1)}:{time_m.group(2)}" if time_m else ""
            d_obj = datetime.datetime.strptime(dt_str, "%Y%m%d").date()
            parsed.append({
                "summary": summary,
                "time": time_str,
                "date": d_obj,
                "yearly": bool(rrule_m)
            })
    return parsed


def fetch_all_events():
    """Descarga eventos de CalDAV y añade los locales de Evolution."""
    events = []
    seen_keys = set()

    def add_unique(ev_list):
        for ev in ev_list:
            key = (ev["summary"], ev["date"].month, ev["date"].day)
            if key not in seen_keys:
                seen_keys.add(key)
                events.append(ev)

    # 1. Eventos del Servidor CalDAV (Radicale)
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        auth_header = "Basic " + base64.b64encode(f"{CALDAV_USER}:{CALDAV_PASS}".encode()).decode()

        req = urllib.request.Request(CALDAV_BASE, method="PROPFIND")
        req.add_header("Authorization", auth_header)
        req.add_header("Depth", "1")

        with urllib.request.urlopen(req, context=ctx, timeout=3) as resp:
            xml_data = resp.read().decode()

        hrefs = re.findall(r"<href>([^<]+)</href>", xml_data)
        col_urls = []
        for h in hrefs:
            clean_h = h.strip("/")
            if clean_h != "tara" and "/" in clean_h:
                full_url = urllib.parse.urljoin(CALDAV_BASE, h)
                if full_url not in col_urls and full_url != CALDAV_BASE:
                    col_urls.append(full_url)

        if not col_urls:
            col_urls = [CALDAV_BASE]

        for c_url in col_urls:
            if not c_url.endswith("/"):
                c_url += "/"
            req_col = urllib.request.Request(c_url, method="PROPFIND")
            req_col.add_header("Authorization", auth_header)
            req_col.add_header("Depth", "1")

            with urllib.request.urlopen(req_col, context=ctx, timeout=3) as c_resp:
                c_xml = c_resp.read().decode()

            ics_hrefs = re.findall(r"<href>([^<]+\.ics)</href>", c_xml)
            for ics_h in ics_hrefs:
                ics_url = urllib.parse.urljoin(c_url, ics_h)
                ics_req = urllib.request.Request(ics_url, method="GET")
                ics_req.add_header("Authorization", auth_header)

                with urllib.request.urlopen(ics_req, context=ctx, timeout=3) as ics_resp:
                    ics_text = ics_resp.read().decode(errors="ignore")

                add_unique(parse_vevents_from_ics(ics_text))
    except Exception:
        pass

    # 2. Eventos Locales de Evolution
    for fpath in glob.glob(os.path.expanduser("~/.local/share/evolution/calendar/**/*.ics"), recursive=True):
        try:
            with open(fpath, "r", errors="ignore") as f:
                add_unique(parse_vevents_from_ics(f.read()))
        except Exception:
            pass

    return events
