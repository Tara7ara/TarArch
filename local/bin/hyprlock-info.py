#!/usr/bin/env python3
"""
Textos de la pantalla de bloqueo.
  hyprlock-info.py         próximo evento
  hyprlock-info.py fecha   "MIÉRCOLES 7 OCTUBRE" espaciada (date no sube los acentos)
  hyprlock-info.py clima   "Barcelona  22°  nublado"
El evento sale de la caché que mantiene el Centro de Control
(~/.cache/tararch_calendar_index.json), sin red, para que el bloqueo no espere.
El clima igual: se pinta lo que haya en caché y, si tiene más de media hora,
se pide a Open-Meteo (sin clave) en segundo plano para la próxima vez.
"""
import datetime
import sys
import html
import json
import os
import subprocess
import time
import urllib.request

DIM = "#6e6e6e"
TEXT = "#c9c9c9"
ACCENT = "#ff9e64"
CACHE = os.path.expanduser("~/.cache/tararch_calendar_index.json")
DIAS = ["lun", "mar", "mié", "jue", "vie", "sáb", "dom"]
CIUDAD, LAT, LON = "Barcelona", 41.39, 2.17
CLIMA_CACHE = os.path.expanduser("~/.cache/tararch_weather.json")
# Códigos WMO de Open-Meteo, agrupados
CIELO = [((0,), "despejado"), ((1, 2), "algo nublado"), ((3,), "nublado"),
         ((45, 48), "niebla"), ((51, 53, 55, 56, 57), "llovizna"),
         ((61, 63, 65, 66, 67, 80, 81, 82), "lluvia"), ((71, 73, 75, 77, 85, 86), "nieve"),
         ((95, 96, 99), "tormenta")]
MESES = ["ene", "feb", "mar", "abr", "may", "jun", "jul", "ago", "sep", "oct", "nov", "dic"]


def cuando(fecha, hora):
    hoy = datetime.date.today()
    if fecha == hoy:
        dia = "hoy"
    elif fecha == hoy + datetime.timedelta(days=1):
        dia = "mañana"
    else:
        dia = f"{DIAS[fecha.weekday()]} {fecha.day} {MESES[fecha.month - 1]}"
    return f"{dia} {hora}".strip()


def proximo_evento():
    try:
        eventos = json.load(open(CACHE))["events"]
    except (OSError, ValueError, KeyError):
        return None
    ahora = datetime.datetime.now()
    candidatos = []
    for ev in eventos:
        try:
            fecha = datetime.date.fromisoformat(ev["date"])
        except (KeyError, ValueError):
            continue
        if ev.get("yearly"):
            fecha = fecha.replace(year=ahora.year)
            if fecha < ahora.date():
                fecha = fecha.replace(year=ahora.year + 1)
        hora = ev.get("time") or ""
        try:
            momento = datetime.datetime.combine(
                fecha, datetime.time.fromisoformat(hora) if hora else datetime.time.max
            )
        except ValueError:
            momento = datetime.datetime.combine(fecha, datetime.time.max)
        if momento >= ahora:
            candidatos.append((momento, fecha, hora, ev.get("summary", "").strip()))
    if not candidatos:
        return None
    _, fecha, hora, titulo = min(candidatos)
    if len(titulo) > 40:
        titulo = titulo[:39] + "…"
    return (
        f"<span color='{ACCENT}'>{cuando(fecha, hora)}</span>"
        f"  <span color='{TEXT}'>{html.escape(titulo)}</span>"
    )


def actualizar_clima():
    url = (f"https://api.open-meteo.com/v1/forecast?latitude={LAT}&longitude={LON}"
           "&current=temperature_2m,weather_code&timezone=auto")
    try:
        with urllib.request.urlopen(url, timeout=10) as r:
            actual = json.load(r)["current"]
    except (OSError, ValueError, KeyError):
        return
    tmp = CLIMA_CACHE + ".tmp"
    with open(tmp, "w") as f:
        json.dump({"temp": actual["temperature_2m"], "code": actual["weather_code"]}, f)
    os.replace(tmp, CLIMA_CACHE)


def clima():
    try:
        edad = time.time() - os.path.getmtime(CLIMA_CACHE)
    except OSError:
        edad = None
    if edad is None or edad > 1800:
        subprocess.Popen([sys.executable, __file__, "clima-actualizar"],
                         stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                         start_new_session=True)
    if edad is None or edad > 3 * 3600:  # muy viejo: mejor no enseñar nada
        return None
    try:
        datos = json.load(open(CLIMA_CACHE))
    except (OSError, ValueError):
        return None
    cielo = next((t for codigos, t in CIELO if datos.get("code") in codigos), "")
    return (
        f"<span color='{DIM}'>{CIUDAD}</span>"
        f"  <span color='{TEXT}'>{round(datos['temp'])}°</span>"
        f"  <span color='{DIM}'>{cielo}</span>"
    )


if sys.argv[1:] == ["clima-actualizar"]:
    actualizar_clima()
    sys.exit(0)

if sys.argv[1:] == ["clima"]:
    print(clima() or "")
    sys.exit(0)

if sys.argv[1:] == ["fecha"]:
    hoy = datetime.date.today()
    nombres = ["lunes", "martes", "miércoles", "jueves", "viernes", "sábado", "domingo"]
    meses = ["enero", "febrero", "marzo", "abril", "mayo", "junio", "julio",
             "agosto", "septiembre", "octubre", "noviembre", "diciembre"]
    texto = f"{nombres[hoy.weekday()]} {hoy.day} {meses[hoy.month - 1]}".upper()
    print(f"<span letter_spacing='3000'>{texto}</span>")
    sys.exit(0)

print(proximo_evento() or "")
