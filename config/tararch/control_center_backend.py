#!/usr/bin/env python3
"""
Lógica de sistema del Centro de Control de TarArch: estado (volumen, brillo,
notificaciones, toggles, red, bluetooth) y sincronización indexada de Google Calendar.
Sin GTK — nada aquí construye UI, solo lee/escribe estado real del sistema.
"""
import os
import signal
import subprocess
import datetime
import urllib.request
import urllib.parse
import re
import glob
import json
import time
from concurrent.futures import ThreadPoolExecutor

PID_FILE = "/tmp/tararch_control_center.pid"
GOOGLE_DIR = os.path.expanduser("~/.config/tararch/google")
GOOGLE_CLIENT_FILE = os.path.join(GOOGLE_DIR, "client_secret.json")
GOOGLE_TOKEN_FILE = os.path.join(GOOGLE_DIR, "token.json")
GOOGLE_API = "https://www.googleapis.com/calendar/v3"
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


def _google_access_token():
    """Pide un access token nuevo con el refresh token guardado por google-calendar-auth.py."""
    with open(GOOGLE_CLIENT_FILE, "r", encoding="utf-8") as f:
        client = json.load(f)["installed"]
    with open(GOOGLE_TOKEN_FILE, "r", encoding="utf-8") as f:
        refresh_token = json.load(f)["refresh_token"]
    body = urllib.parse.urlencode({
        "client_id": client["client_id"],
        "client_secret": client["client_secret"],
        "refresh_token": refresh_token,
        "grant_type": "refresh_token",
    }).encode()
    with urllib.request.urlopen(client["token_uri"], data=body, timeout=8) as resp:
        return json.load(resp)["access_token"]


def _google_get(path, token, params=None):
    url = GOOGLE_API + path
    if params:
        url += "?" + urllib.parse.urlencode(params)
    req = urllib.request.Request(url, headers={"Authorization": "Bearer " + token})
    with urllib.request.urlopen(req, timeout=8) as resp:
        return json.load(resp)


def _google_calendar_events(token, cal_id, time_min, time_max):
    """Eventos de un calendario con las recurrencias ya expandidas en instancias."""
    parsed = []
    params = {
        "timeMin": time_min, "timeMax": time_max,
        "singleEvents": "true", "orderBy": "startTime", "maxResults": "2500",
    }
    while True:
        data = _google_get("/calendars/%s/events" % urllib.parse.quote(cal_id, safe=""), token, params)
        for item in data.get("items", []):
            if item.get("status") == "cancelled":
                continue
            start = item.get("start", {})
            if "dateTime" in start:
                dt = datetime.datetime.fromisoformat(start["dateTime"]).astimezone()
                d_obj, time_str = dt.date(), dt.strftime("%H:%M")
            elif "date" in start:
                d_obj, time_str = datetime.date.fromisoformat(start["date"]), ""
            else:
                continue
            parsed.append({
                "summary": item.get("summary", "(sin título)"),
                "time": time_str,
                "date": d_obj,
                "yearly": False
            })
        if not data.get("nextPageToken"):
            return parsed
        params["pageToken"] = data["nextPageToken"]


def fetch_google_events():
    """Todos los calendarios visibles de la cuenta, de 2 meses atrás a 1 año vista."""
    token = _google_access_token()
    calendars = [
        c["id"] for c in _google_get("/users/me/calendarList", token).get("items", [])
        if c.get("selected", True)
    ]
    now = datetime.datetime.now(datetime.timezone.utc)
    time_min = (now - datetime.timedelta(days=62)).isoformat()
    time_max = (now + datetime.timedelta(days=366)).isoformat()
    with ThreadPoolExecutor(max_workers=6) as executor:
        results = executor.map(lambda c: _google_calendar_events(token, c, time_min, time_max), calendars)
    return [ev for evs in results for ev in evs]


def fetch_all_events():
    """
    Descarga eventos de Google Calendar y añade los locales de Evolution.
    Actualiza el índice local en disco automáticamente; si Google falla
    (sin red, sin token) devuelve [] y la UI se queda con la caché.
    """
    events = []
    seen_keys = set()

    def add_unique(ev_list):
        for ev in ev_list:
            key = (ev["summary"], ev["date"], ev["time"])
            if key not in seen_keys:
                seen_keys.add(key)
                events.append(ev)

    # 1. Google Calendar
    try:
        add_unique(fetch_google_events())
    except Exception:
        return []

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

# =============================================================================
# ACTIVIDAD DE GITHUB (heatmap del Centro de Control)
# Lee el grafo de contribuciones publico del perfil, sin token ni terceros.
# =============================================================================
GITHUB_USER = "Tara7ara"
GITHUB_CACHE_FILE = os.path.expanduser("~/.cache/tararch_github_activity.json")
GITHUB_CACHE_TTL = 3 * 3600  # 3 horas: la actividad no cambia tan rapido


def _fetch_github_activity(user):
    """Descarga y parsea el grafo de contribuciones publico. Devuelve dict o None."""
    url = "https://github.com/users/%s/contributions" % urllib.parse.quote(user)
    req = urllib.request.Request(url, headers={
        "User-Agent": "Mozilla/5.0",
        "X-Requested-With": "XMLHttpRequest",
    })
    try:
        with urllib.request.urlopen(req, timeout=12) as resp:
            html = resp.read().decode("utf-8", "replace")
    except Exception:
        return None

    # Un <td> por dia: data-date antes, data-level despues, dentro de la misma etiqueta.
    days = [
        {"date": m.group(1), "level": int(m.group(2))}
        for m in re.finditer(r'data-date="(\d{4}-\d{2}-\d{2})"[^>]*data-level="(\d)"', html)
    ]
    # Total real desde los tooltips ("N contributions on ..."; "No contributions" = 0).
    total = 0
    for m in re.finditer(r'for="contribution-day-component-[^"]*"[^>]*>([^<]*)</tool-tip>', html):
        mm = re.match(r'([\d,]+)\s+contribution', m.group(1))
        if mm:
            total += int(mm.group(1).replace(",", ""))

    if not days:
        return None
    return {"days": days, "total": total, "fetched": time.time()}


def get_github_activity(user=GITHUB_USER, ttl=GITHUB_CACHE_TTL):
    """Actividad de GitHub con cache en disco. Nunca lanza: en fallo total
    devuelve la cache vieja si existe, o {'days': [], 'total': 0, 'error': True}."""
    try:
        st = os.stat(GITHUB_CACHE_FILE)
        if time.time() - st.st_mtime < ttl:
            with open(GITHUB_CACHE_FILE) as f:
                return json.load(f)
    except (OSError, ValueError):
        pass

    data = _fetch_github_activity(user)
    if data:
        try:
            os.makedirs(os.path.dirname(GITHUB_CACHE_FILE), exist_ok=True)
            with open(GITHUB_CACHE_FILE, "w") as f:
                json.dump(data, f)
        except OSError:
            pass
        return data

    # Fetch fallido: intentar cache vieja aunque haya caducado.
    try:
        with open(GITHUB_CACHE_FILE) as f:
            return json.load(f)
    except (OSError, ValueError):
        return {"days": [], "total": 0, "error": True}
