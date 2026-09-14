#!/usr/bin/env python3
"""Genera un PNG cuadrado con un glifo de Nerd Font perfectamente centrado por su
bounding box de tinta real (no por métricas de fuente, que varían de un glifo a otro).

Uso: make-rofi-icon.py <nombre_salida> <codepoint_hex> <color_hex> [--out DIR] [--target PX] [--canvas PX]
Ejemplo: make-rofi-icon.py nightlight f0594 '#c9a0ff'
"""
import argparse
from PIL import Image, ImageFont, ImageDraw

FONT_PATH = "/usr/share/fonts/TTF/JetBrainsMonoNerdFont-Regular.ttf"
RENDER_SIZE = 220

def hex_to_rgba(h):
    h = h.lstrip('#')
    return (int(h[0:2], 16), int(h[2:4], 16), int(h[4:6], 16), 255)

def main():
    p = argparse.ArgumentParser()
    p.add_argument("name")
    p.add_argument("codepoint", help="hex, ej. f05a9 (sin 0x)")
    p.add_argument("color", help="hex, ej. #82c8ff")
    p.add_argument("--out", default=f"{__import__('os').path.expanduser('~')}/.config/rofi/icons")
    p.add_argument("--target", type=int, default=130, help="tamaño de la dimensión mayor tras escalar")
    p.add_argument("--canvas", type=int, default=160, help="lienzo cuadrado final")
    args = p.parse_args()

    cp = int(args.codepoint, 16)
    color = hex_to_rgba(args.color)
    font = ImageFont.truetype(FONT_PATH, RENDER_SIZE)
    ch = chr(cp)

    scratch = Image.new("L", (RENDER_SIZE*2, RENDER_SIZE*2), 0)
    d = ImageDraw.Draw(scratch)
    d.text((RENDER_SIZE//2, RENDER_SIZE//2), ch, font=font, fill=255)
    bbox = scratch.getbbox()
    if bbox is None:
        raise SystemExit(f"Glifo vacío para codepoint {args.codepoint} — ¿existe en la fuente?")
    ink = scratch.crop(bbox)
    iw, ih = ink.size

    scale = args.target / max(iw, ih)
    new_w, new_h = round(iw*scale), round(ih*scale)
    ink_scaled = ink.resize((new_w, new_h), Image.LANCZOS)

    canvas = Image.new("RGBA", (args.canvas, args.canvas), (0, 0, 0, 0))
    colorlayer = Image.new("RGBA", (new_w, new_h), color)
    px = (args.canvas - new_w)//2
    py = (args.canvas - new_h)//2
    canvas.paste(colorlayer, (px, py), ink_scaled)

    import os
    os.makedirs(args.out, exist_ok=True)
    out_path = f"{args.out}/{args.name}.png"
    canvas.save(out_path)
    print(f"{args.name}: ink {iw}x{ih} -> escalado {new_w}x{new_h} -> {out_path}")

if __name__ == "__main__":
    main()
