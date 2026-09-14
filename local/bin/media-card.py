#!/usr/bin/env python3
"""
TarArch Glassmorphic Media Player Popup con Visualizador CAVA Integrado.
Muestra una tarjeta flotante cinematica debajo de Waybar con caratula,
titulo, artista, ecualizador Cava en tiempo real a 60 FPS y controles.

La lógica de sistema (playerctl, procesado de carátula) vive en
media_card_backend.py — este archivo solo construye la UI.
"""
import os
import subprocess
import sys
import threading
import math

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GdkPixbuf, GtkLayerShell, GLib
import cairo

import media_card_backend as backend

CSS_FILE = os.path.expanduser("~/.config/tararch/media-card.css")
CAVA_CONF = "/tmp/cava_media_card.conf"


class CavaVisualizer(Gtk.DrawingArea):
    def __init__(self, bars=20):
        super().__init__()
        self.num_bars = bars
        self.bar_values = [0.0] * self.num_bars
        self.target_values = [0.0] * self.num_bars
        self.running = True
        self.cava_proc = None
        self.set_size_request(200, 22)
        self.connect("draw", self.on_draw)

        self.start_cava()
        GLib.timeout_add(16, self.smooth_tick)  # ~60 FPS animacion

    def start_cava(self):
        conf_content = f"""[general]
bars = {self.num_bars}
framerate = 60
autosens = 1
overshoot = 20
[input]
method = pulse
source = auto
[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 100
bar_delimiter = 59
frame_delimiter = 10
[smoothing]
monstercat = 1
integral = 75
"""
        with open(CAVA_CONF, "w") as f:
            f.write(conf_content)

        def read_cava():
            try:
                self.cava_proc = subprocess.Popen(
                    ["cava", "-p", CAVA_CONF],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.DEVNULL,
                    text=True,
                    bufsize=1,
                )
                for line in self.cava_proc.stdout:
                    if not self.running:
                        break
                    parts = line.strip().split(";")
                    vals = []
                    for p in parts[:self.num_bars]:
                        if p.isdigit():
                            vals.append(float(p) / 100.0)
                    if len(vals) == self.num_bars:
                        self.target_values = vals
            except Exception:
                pass

        t = threading.Thread(target=read_cava, daemon=True)
        t.start()

    def smooth_tick(self):
        if not self.running:
            return False
        # Interpolacion suave
        for i in range(self.num_bars):
            self.bar_values[i] += (self.target_values[i] - self.bar_values[i]) * 0.35
        self.queue_draw()
        return True

    def on_draw(self, widget, cr):
        width = self.get_allocated_width()
        height = self.get_allocated_height()

        bar_spacing = 3
        total_spacing = bar_spacing * (self.num_bars - 1)
        bar_width = max(2.0, (width - total_spacing) / self.num_bars)

        for i in range(self.num_bars):
            val = max(0.06, min(1.0, self.bar_values[i]))
            bar_h = val * height
            x = i * (bar_width + bar_spacing)
            y = height - bar_h

            # Degradado Warm Dark: Morado (#bb9af7) a Naranja Calido (#ff9e64)
            pat = cairo.LinearGradient(x, height, x, y)
            pat.add_color_stop_rgba(0.0, 0.73, 0.60, 0.97, 0.85)  # #bb9af7
            pat.add_color_stop_rgba(1.0, 1.0, 0.62, 0.39, 1.0)   # #ff9e64

            cr.set_source(pat)
            # Dibujar rectangulo con esquinas redondeadas
            radius = min(bar_width / 2.0, 2.0)
            cr.new_sub_path()
            cr.arc(x + radius, y + radius, radius, math.pi, 3 * math.pi / 2)
            cr.arc(x + bar_width - radius, y + radius, radius, 3 * math.pi / 2, 2 * math.pi)
            cr.arc(x + bar_width - radius, height - radius, radius, 0, math.pi / 2)
            cr.arc(x + radius, height - radius, radius, math.pi / 2, math.pi)
            cr.close_path()
            cr.fill()

        return False

    def stop(self):
        self.running = False
        if self.cava_proc:
            try:
                self.cava_proc.terminate()
            except Exception:
                pass


class MediaCardWindow(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)
        self.set_app_paintable(True)

        # Guardar PID
        with open(backend.PID_FILE, "w") as f:
            f.write(str(os.getpid()))

        # Configurar Layer Shell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "media-card")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 6)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.set_title("TarArch Media Player")
        self.set_default_size(460, 150)
        self.set_resizable(False)

        # CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_path(CSS_FILE)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_APPLICATION,
        )

        # Layout Principal
        main_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=14)
        main_box.get_style_context().add_class("media-card")
        self.add(main_box)

        # Imagen de caratula
        self.cover_image = Gtk.Image()
        self.cover_image.set_size_request(105, 105)
        main_box.pack_start(self.cover_image, False, False, 0)

        # Contenedor Derecho (Textos + Cava + Progreso + Controles)
        right_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        main_box.pack_start(right_box, True, True, 0)

        # Cabecera con Titulo y Visualizador Cava en paralelo
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        right_box.pack_start(header_box, False, False, 0)

        meta_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        header_box.pack_start(meta_box, True, True, 0)

        self.title_label = Gtk.Label(label="Cancion", xalign=0)
        self.title_label.set_ellipsize(3)  # PANGO_ELLIPSIZE_END
        self.title_label.get_style_context().add_class("title-label")
        meta_box.pack_start(self.title_label, False, False, 0)

        self.artist_label = Gtk.Label(label="Artista", xalign=0)
        self.artist_label.set_ellipsize(3)
        self.artist_label.get_style_context().add_class("artist-label")
        meta_box.pack_start(self.artist_label, False, False, 0)

        self.album_label = Gtk.Label(label="", xalign=0)
        self.album_label.set_ellipsize(3)
        self.album_label.get_style_context().add_class("album-label")
        meta_box.pack_start(self.album_label, False, False, 0)

        # Visualizador Cava embebido (20 barras)
        self.visualizer = CavaVisualizer(bars=18)
        right_box.pack_start(self.visualizer, False, False, 2)

        # Barra de progreso
        self.progress_bar = Gtk.ProgressBar()
        right_box.pack_start(self.progress_bar, False, False, 2)

        # Tiempos
        time_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=0)
        right_box.pack_start(time_box, False, False, 0)

        self.time_pos = Gtk.Label(label="0:00", xalign=0)
        self.time_pos.get_style_context().add_class("time-label")
        time_box.pack_start(self.time_pos, True, True, 0)

        self.time_dur = Gtk.Label(label="0:00", xalign=1)
        self.time_dur.get_style_context().add_class("time-label")
        time_box.pack_start(self.time_dur, True, True, 0)

        # Controles
        ctrl_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        ctrl_box.set_halign(Gtk.Align.CENTER)
        right_box.pack_start(ctrl_box, False, False, 2)

        btn_prev = Gtk.Button(label="󰒮")
        btn_prev.get_style_context().add_class("btn-ctrl")
        btn_prev.connect("clicked", lambda w: self.on_cmd("previous"))
        ctrl_box.pack_start(btn_prev, False, False, 0)

        self.btn_play = Gtk.Button(label="󰏤")
        self.btn_play.get_style_context().add_class("btn-ctrl")
        self.btn_play.get_style_context().add_class("btn-play")
        self.btn_play.connect("clicked", lambda w: self.on_cmd("play-pause"))
        ctrl_box.pack_start(self.btn_play, False, False, 0)

        btn_next = Gtk.Button(label="󰒭")
        btn_next.get_style_context().add_class("btn-ctrl")
        btn_next.connect("clicked", lambda w: self.on_cmd("next"))
        ctrl_box.pack_start(btn_next, False, False, 0)

        # Cerrar con Escape o clic fuera
        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", self.on_destroy)

        # Actualizar datos
        self.current_art_url = None
        self.update_data()
        GLib.timeout_add(1000, self.update_data)

    def on_cmd(self, cmd):
        subprocess.run(["playerctl", cmd], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        GLib.timeout_add(100, self.update_data)

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def on_destroy(self, widget):
        self.visualizer.stop()
        if os.path.exists(backend.PID_FILE):
            try:
                os.remove(backend.PID_FILE)
            except Exception:
                pass

    def update_data(self):
        meta = backend.get_player_metadata()
        if not meta:
            self.title_label.set_text("Sin reproductor")
            self.artist_label.set_text("Spotify / MPRIS inactivo")
            self.album_label.set_text("")
            self.time_pos.set_text("0:00")
            self.time_dur.set_text("0:00")
            self.progress_bar.set_fraction(0.0)
            self.btn_play.set_label("󰐊")
            return True

        self.title_label.set_text(meta["title"])
        self.artist_label.set_text(meta["artist"])
        self.album_label.set_text(meta["album"] if meta["album"] else "")

        # Icono play/pausa
        if meta["status"] == "Playing":
            self.btn_play.set_label("󰏤")
        else:
            self.btn_play.set_label("󰐊")

        # Progreso y tiempos
        pos = meta["position"]
        length = meta["length"]
        self.time_pos.set_text(backend.format_time(pos))
        self.time_dur.set_text(backend.format_time(length) if length > 0 else "--:--")

        if length > 0:
            fraction = max(0.0, min(1.0, pos / length))
            self.progress_bar.set_fraction(fraction)
        else:
            self.progress_bar.set_fraction(0.0)

        # Caratula redondeada
        if meta["art_url"] != self.current_art_url:
            self.current_art_url = meta["art_url"]
            rounded_path = backend.process_album_art(meta["art_url"])
            if rounded_path and os.path.exists(rounded_path):
                pixbuf = GdkPixbuf.Pixbuf.new_from_file_at_scale(rounded_path, 105, 105, True)
                self.cover_image.set_from_pixbuf(pixbuf)
            else:
                self.cover_image.set_from_icon_name("audio-x-generic", Gtk.IconSize.DIALOG)

        return True


def main():
    if backend.is_running():
        sys.exit(0)

    win = MediaCardWindow()
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
