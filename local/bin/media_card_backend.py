#!/usr/bin/env python3
"""
Lógica de sistema de la tarjeta multimedia de TarArch: estado del reproductor
(playerctl) y procesado de carátula. Sin GTK — ver media-card.py para la
ventana que consume estas funciones.
"""
import os
import signal
import subprocess
import urllib.request
from PIL import Image

PID_FILE = "/tmp/tararch_media_card.pid"
ART_CACHE = "/tmp/tararch_media_card_art.png"
ART_ROUNDED = "/tmp/tararch_media_card_rounded.png"


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


def get_player_metadata():
    try:
        raw = subprocess.check_output(
            [
                "playerctl",
                "metadata",
                "--format",
                "{{status}};{{playerName}};{{artist}};{{title}};{{album}};{{mpris:artUrl}};{{position}};{{mpris:length}}",
            ],
            text=True,
            stderr=subprocess.DEVNULL,
        ).strip()
        if not raw:
            return None
        parts = raw.split(";", 7)
        if len(parts) < 8:
            return None
        return {
            "status": parts[0],
            "player": parts[1],
            "artist": parts[2] or "Artista desconocido",
            "title": parts[3] or "Cancion desconocida",
            "album": parts[4] or "",
            "art_url": parts[5] or "",
            "position": float(parts[6]) / 1000000.0 if parts[6].isdigit() else 0.0,
            "length": float(parts[7]) / 1000000.0 if parts[7].isdigit() else 0.0,
        }
    except Exception:
        return None


def format_time(seconds):
    mins = int(seconds) // 60
    secs = int(seconds) % 60
    return f"{mins}:{secs:02d}"


def process_album_art(url):
    if not url:
        return None
    try:
        raw_path = ART_CACHE
        if url.startswith("file://"):
            raw_path = url[7:]
        elif url.startswith("http"):
            urllib.request.urlretrieve(url, raw_path)

        if not os.path.exists(raw_path):
            return None

        # Redondear esquinas con PIL
        img = Image.open(raw_path).convert("RGBA")
        img = img.resize((105, 105), Image.Resampling.LANCZOS)

        # Crear mascara redondeada
        mask = Image.new("L", (105, 105), 0)
        from PIL import ImageDraw
        draw = ImageDraw.Draw(mask)
        draw.rounded_rectangle((0, 0, 105, 105), radius=12, fill=255)
        img.putalpha(mask)
        img.save(ART_ROUNDED)
        return ART_ROUNDED
    except Exception:
        return None
