#!/usr/bin/env python3
"""
Lógica de sistema del Centro de Control de TarArch: estado (volumen, brillo,
notificaciones, toggles, red, bluetooth) y sincronización indexada CalDAV.
Sin GTK — nada aquí construye UI, solo lee/escribe estado real del sistema.
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
import time
from concurrent.futures import ThreadPoolExecutor

PID_FILE = "/tmp/tararch_control_center.pid"
CALDAV_BASE = "https://tara.calendario/tara/"
CALDAV_USER = "tara"
CALDAV_PASS = "tara"
NOTIF_CACHE_FILE = os.path.expanduser("~/.cache/tararch_notifications.json")
MODE_FILE = os.path.expanduser("~/.cache/current_system_mode")
NETWORK_PROFILE_FILE = os.path.expanduser("~/.cache/current_network_profile")
CALENDAR_INDEX_FILE = os.path.expanduser("~/.cache/tararch_calendar_index.json")


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


def is_network_connected():
    try:
        eth = subprocess.check_output(["ip", "route", "show", "default"], text=True, stderr=subprocess.DEVNULL)
        return len(eth.strip()) > 0
    except Exception:
        return False


def is_wifi_enabled():
    try:
        out = subprocess.check_output(["nmcli", "radio", "wifi"], text=True, stderr=subprocess.DEVNULL).strip()
        return out == "enabled"
    except Exception:
        return False


def is_bluetooth_powered():
    try:
        out = subprocess.check_output(["bluetoothctl", "show"], text=True, stderr=subprocess.DEVNULL)
        return "Powered: yes" in out
    except Exception:
        return False


def is_lanmouse_running():
    if subprocess.run(["systemctl", "--user", "is-active", "--quiet", "lan-mouse.service"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0:
        return True
    return subprocess.run(["pgrep", "-f", "lan-mouse"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def is_nobloqueo_active():
    return subprocess.run(["pgrep", "-f", "nobloqueo-marcador"], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def is_casa_active():
    """Devuelve True si el perfil activo es Casa (DNS local / perfil casa)."""
    if os.path.exists(NETWORK_PROFILE_FILE):
        try:
            with open(NETWORK_PROFILE_FILE, "r") as f:
                val = f.read().strip().lower()
                if val == "fuera":
                    return False
                if val == "casa":
                    return True
        except Exception:
            pass
    try:
        out = subprocess.check_output(["nmcli", "-t", "-f", "NAME", "connection", "show", "--active"], text=True, stderr=subprocess.DEVNULL)
        active_conns = [line.strip() for line in out.splitlines() if line.strip()]
        for c in active_conns:
            if "Casa Cable" in c or c == "Casa":
                return True
    except Exception:
        pass
    return False


def toggle_casa_profile():
    """Alterna entre red-casa y red-fuera."""
    if is_casa_active():
        subprocess.Popen(["/home/tara/.local/bin/red-fuera"], start_new_session=True)
    else:
        subprocess.Popen(["/home/tara/.local/bin/red-casa"], start_new_session=True)


def get_system_mode():
    """'normal' | 'uni' | 'gamer', según ~/.cache/current_system_mode."""
    if os.path.exists(MODE_FILE):
        try:
            with open(MODE_FILE, "r") as f:
                return f.read().strip()
        except Exception:
            pass
    return "normal"


def toggle_system_mode():
    """Alterna cíclicamente entre uni -> normal -> gamer -> uni."""
    subprocess.Popen(["/home/tara/.local/bin/set-system-mode.sh", "toggle"], start_new_session=True)


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


def get_cached_events():
    """Carga eventos indexados en 0ms desde la caché local en disco."""
    if not os.path.exists(CALENDAR_INDEX_FILE):
        return []
    try:
        with open(CALENDAR_INDEX_FILE, "r", encoding="utf-8") as f:
            raw = json.load(f)
        events = []
        for item in raw.get("events", []):
            d_obj = datetime.date.fromisoformat(item["date"])
            events.append({
                "summary": item["summary"],
                "time": item.get("time", ""),
                "date": d_obj,
                "yearly": item.get("yearly", False)
            })
        return events
    except Exception:
        return []


def save_calendar_index(events):
    """Guarda los eventos en el índice local en disco."""
    try:
        serializable = []
        for ev in events:
            serializable.append({
                "summary": ev["summary"],
                "time": ev.get("time", ""),
                "date": ev["date"].isoformat(),
                "yearly": ev.get("yearly", False)
            })
        os.makedirs(os.path.dirname(CALENDAR_INDEX_FILE), exist_ok=True)
        with open(CALENDAR_INDEX_FILE, "w", encoding="utf-8") as f:
            json.dump({"updated_at": time.time(), "events": serializable}, f, indent=2, ensure_ascii=False)
    except Exception:
        pass


def fetch_all_events():
    """
    Descarga eventos de CalDAV en paralelo con ThreadPool y añade los locales.
    Actualiza el índice local en disco automáticamente.
    """
    events = []
    seen_keys = set()

    def add_unique(ev_list):
        for ev in ev_list:
            key = (ev["summary"], ev["date"].month, ev["date"].day)
            if key not in seen_keys:
                seen_keys.add(key)
                events.append(ev)

    # 1. Eventos del Servidor CalDAV (Radicale) en paralelo
    try:
        ctx = ssl.create_default_context()
        ctx.check_hostname = False
        ctx.verify_mode = ssl.CERT_NONE

        auth_header = "Basic " + base64.b64encode(f"{CALDAV_USER}:{CALDAV_PASS}".encode()).decode()

        req = urllib.request.Request(CALDAV_BASE, method="PROPFIND")
        req.add_header("Authorization", auth_header)
        req.add_header("Depth", "1")

        with urllib.request.urlopen(req, context=ctx, timeout=2.5) as resp:
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

        all_ics_urls = []
        for c_url in col_urls:
            if not c_url.endswith("/"):
                c_url += "/"
            req_col = urllib.request.Request(c_url, method="PROPFIND")
            req_col.add_header("Authorization", auth_header)
            req_col.add_header("Depth", "1")

            with urllib.request.urlopen(req_col, context=ctx, timeout=2.5) as c_resp:
                c_xml = c_resp.read().decode()

            for ics_h in re.findall(r"<href>([^<]+\.ics)</href>", c_xml):
                all_ics_urls.append(urllib.parse.urljoin(c_url, ics_h))

        def fetch_single_ics(url):
            try:
                ics_req = urllib.request.Request(url, method="GET")
                ics_req.add_header("Authorization", auth_header)
                with urllib.request.urlopen(ics_req, context=ctx, timeout=2.5) as ics_resp:
                    return ics_resp.read().decode(errors="ignore")
            except Exception:
                return None

        if all_ics_urls:
            with ThreadPoolExecutor(max_workers=8) as executor:
                ics_contents = list(executor.map(fetch_single_ics, all_ics_urls))
            for content in ics_contents:
                if content:
                    add_unique(parse_vevents_from_ics(content))

    except Exception:
        pass

    # 2. Eventos Locales de Evolution
    for fpath in glob.glob(os.path.expanduser("~/.local/share/evolution/calendar/**/*.ics"), recursive=True):
        try:
            with open(fpath, "r", errors="ignore") as f:
                add_unique(parse_vevents_from_ics(f.read()))
        except Exception:
            pass

    # Guardar en índice local persistente
    if events:
        save_calendar_index(events)

    return events
