#!/usr/bin/env python3
"""
Obtiene y cachea la carátula de la canción actual desde playerctl / Spotify
para mostrarla en la isla multimedia de Waybar como widget de imagen.
"""
import os
import subprocess
import urllib.request
from PIL import Image

EMPTY_PATH = "/tmp/waybar_art_empty.png"
ART_PATH = "/tmp/waybar_album_art.png"
URL_CACHE_PATH = "/tmp/waybar_art_url.txt"


def ensure_empty():
    if not os.path.exists(EMPTY_PATH):
        img = Image.new("RGBA", (1, 1), (0, 0, 0, 0))
        img.save(EMPTY_PATH)


def main():
    ensure_empty()
    try:
        status = subprocess.check_output(
            ["playerctl", "status"], text=True, stderr=subprocess.DEVNULL
        ).strip()
        if status not in ("Playing", "Paused"):
            print(EMPTY_PATH)
            return

        art_url = subprocess.check_output(
            ["playerctl", "metadata", "mpris:artUrl"], text=True, stderr=subprocess.DEVNULL
        ).strip()

        if not art_url:
            print(EMPTY_PATH)
            return

        if art_url.startswith("file://"):
            local_path = art_url[7:]
            if os.path.exists(local_path):
                print(local_path)
                return

        if art_url.startswith("http://") or art_url.startswith("https://"):
            # Comprobar cache para no descargar en cada ciclo
            last_url = ""
            if os.path.exists(URL_CACHE_PATH):
                with open(URL_CACHE_PATH, "r") as f:
                    last_url = f.read().strip()

            if last_url != art_url or not os.path.exists(ART_PATH):
                urllib.request.urlretrieve(art_url, ART_PATH)
                with open(URL_CACHE_PATH, "w") as f:
                    f.write(art_url)

            print(ART_PATH)
            return

        print(EMPTY_PATH)
    except Exception:
        print(EMPTY_PATH)


if __name__ == "__main__":
    main()
