#!/usr/bin/env python3
"""
fastfetch con entrada animada (solo en Kitty):
  1. el logo entra girando y creciendo, con frenada al final (14 fotogramas)
  2. la información se escribe a su derecha fila a fila

La info sale de `fastfetch --logo none` con el mismo config.jsonc, así que las
filas se cambian allí. El logo se pinta con el protocolo gráfico de Kitty
reutilizando el mismo id, así cada fotograma sustituye al anterior.
"""
import base64
import fcntl
import io
import os
import re
import struct
import subprocess
import sys
import termios
import time

from PIL import Image

LOGO = os.path.expanduser("~/.config/fastfetch/logo.png")
LOGO_COLS = 24          # ancho del logo en celdas (el alto sale de la proporción)
PAD_TOP, PAD_LEFT, PAD_RIGHT = 1, 2, 4
FRAMES, FRAME_S = 14, 0.028
LINE_S = 0.025
IMG_ID = 4242

out = sys.stdout


def cell_size():
    """Píxeles por celda (ancho, alto) según el tamaño real de la ventana."""
    try:
        rows, cols, xpix, ypix = struct.unpack(
            "HHHH", fcntl.ioctl(sys.stdout.fileno(), termios.TIOCGWINSZ, b"\0" * 8))
        if xpix and ypix:
            return xpix / cols, ypix / rows
    except OSError:
        pass
    return 10, 22


def kitty_png(data, cols, rows):
    """Transmite y muestra un PNG en el cursor sin moverlo (C=1), en trozos de 4 KB."""
    b64 = base64.standard_b64encode(data)
    first = True
    while b64:
        chunk, b64 = b64[:4096], b64[4096:]
        more = 1 if b64 else 0
        if first:
            ctl = f"a=T,f=100,i={IMG_ID},c={cols},r={rows},C=1,q=2,m={more}"
            first = False
        else:
            ctl = f"m={more}"
        out.write(f"\033_G{ctl};{chunk.decode()}\033\\")


def frames(cols, rows, cw, ch):
    """Entrada del logo: gira desde -120°, crece del 55 % al 100 % y pasa de
    transparente a sólido, frenando al final (ease-out cúbico)."""
    w, h = int(cols * cw), int(rows * ch)
    img = Image.open(LOGO).convert("RGBA").resize((w, h), Image.LANCZOS)
    for k in range(1, FRAMES + 1):
        t = 1 - (1 - k / FRAMES) ** 3
        size = max(1, int(w * (0.55 + 0.45 * t))), max(1, int(h * (0.55 + 0.45 * t)))
        f = img.resize(size, Image.LANCZOS).rotate(-120 * (1 - t), Image.BICUBIC, expand=True)
        f.putalpha(f.getchannel("A").point(lambda a, t=t: int(a * min(1, 0.2 + t))))
        canvas = Image.new("RGBA", (w, h))
        canvas.alpha_composite(f, ((w - f.width) // 2, (h - f.height) // 2)) if f.width <= w and f.height <= h \
            else canvas.alpha_composite(f.crop(((f.width - w) // 2, (f.height - h) // 2,
                                                (f.width + w) // 2, (f.height + h) // 2)))
        buf = io.BytesIO()
        canvas.save(buf, "PNG")
        yield buf.getvalue()


ANSI = re.compile(r"\033\[[0-9;]*m")
CHA = re.compile(r"\033\[(\d+)G")


def relativa(line):
    """fastfetch alinea los valores saltando a una columna absoluta (ESC[nG).
    Aquí el texto va desplazado a la derecha del logo, así que esos saltos se
    cambian por los espacios equivalentes."""
    res = ""
    for i, part in enumerate(CHA.split(line)):
        if i % 2:
            visible = len(ANSI.sub("", res))
            res += " " * max(1, int(part) - 1 - visible)
        else:
            res += part
    return res


def main():
    info = subprocess.run(["fastfetch", "--logo", "none", "--pipe", "false"],
                          capture_output=True, text=True).stdout.rstrip("\n").split("\n")
    info = [relativa(l) for l in info]

    cw, ch = cell_size()
    img = Image.open(LOGO)
    rows = max(1, round(LOGO_COLS * cw * img.height / img.width / ch))
    text_col = PAD_LEFT + LOGO_COLS + PAD_RIGHT + 1
    height = PAD_TOP + max(rows, len(info))

    # Reserva el hueco primero, para que un scroll no descoloque nada después.
    out.write("\n" * height + f"\033[{height}A")
    # El logo va centrado en vertical respecto a la info: se guarda el cursor
    # en la primera fila de texto (ESC 7), se baja a pintar y se vuelve (ESC 8).
    offset = max(0, (len(info) - rows) // 2)
    out.write("\n" * PAD_TOP + "\0337" + "\n" * offset + f"\033[{PAD_LEFT}C")

    for png in frames(LOGO_COLS, rows, cw, ch):
        out.write(f"\033_Ga=d,d=i,i={IMG_ID},q=2\033\\")   # quita el fotograma anterior
        kitty_png(png, LOGO_COLS, rows)
        out.flush()
        time.sleep(FRAME_S)

    out.write("\0338")
    for line in info:
        out.write(f"\033[{text_col}G{line}\033[0m\n")
        out.flush()
        time.sleep(LINE_S)

    if rows > len(info):
        out.write("\n" * (rows - len(info)))
    out.flush()


if __name__ == "__main__":
    try:
        main()
    except Exception:
        # Si algo falla, fastfetch normal, sin animación.
        os.execvp("fastfetch", ["fastfetch"])
