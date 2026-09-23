#!/usr/bin/env python3
"""
Script unificado y profesional para el widget de música en Hyprlock.
Muestra título, artista y barra de progreso fina y elegante con colores Warm Dark.
Si no hay música sonando, no muestra nada.
"""
import subprocess
import html


def fmt_time(seconds):
    mins = int(seconds) // 60
    secs = int(seconds) % 60
    return f"{mins}:{secs:02d}"


def main():
    try:
        status = subprocess.check_output(
            ["playerctl", "status"], text=True, stderr=subprocess.DEVNULL
        ).strip()
        if status not in ("Playing", "Paused"):
            print("")
            return

        raw_title = subprocess.check_output(
            ["playerctl", "metadata", "title"], text=True, stderr=subprocess.DEVNULL
        ).strip()
        raw_artist = subprocess.check_output(
            ["playerctl", "metadata", "artist"], text=True, stderr=subprocess.DEVNULL
        ).strip()
        pos_s = float(
            subprocess.check_output(
                ["playerctl", "position"], text=True, stderr=subprocess.DEVNULL
            ).strip()
            or 0
        )
        dur_us = float(
            subprocess.check_output(
                ["playerctl", "metadata", "mpris:length"],
                text=True,
                stderr=subprocess.DEVNULL,
            ).strip()
            or 0
        )
        dur_s = dur_us / 1000000.0

        if not raw_title:
            print("")
            return

        # Escapar para Pango
        title = html.escape(raw_title)
        artist = html.escape(raw_artist)

        # Icono de estado
        icon = "󰐊" if status == "Playing" else "󰏤"

        # Truncar título largo si excede 36 caracteres
        if len(title) > 36:
            title = title[:33] + "..."

        # Barra de progreso
        width = 18
        if dur_s > 0:
            frac = min(1.0, max(0.0, pos_s / dur_s))
            idx = int(round(frac * (width - 1)))
            bar_left = "━" * idx
            dot = "●"
            bar_right = "━" * (width - 1 - idx)
            time_info = (
                f"<span color='#a9b1d6'>{fmt_time(pos_s)}</span>  "
                f"<span color='#ff9e64'>{bar_left}</span>"
                f"<span color='#ffffff'>{dot}</span>"
                f"<span color='#414868'>{bar_right}</span>  "
                f"<span color='#787c99'>{fmt_time(dur_s)}</span>"
            )
        else:
            time_info = ""

        line1 = f"<span font_weight='bold' color='#ffffff'>{icon}  {title}</span>"
        line2 = f"<span color='#ff9e64'>{artist}</span>" if artist else ""
        
        output_lines = [line1]
        if line2:
            output_lines.append(line2)
        if time_info:
            output_lines.append(time_info)

        print("\n".join(output_lines))
    except Exception:
        print("")


if __name__ == "__main__":
    main()
