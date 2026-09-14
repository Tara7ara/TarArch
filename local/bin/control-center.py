#!/usr/bin/env python3
"""
TarArch Unified Control Center, Notifications & CalDAV Sync Calendar.
Panel lateral estilo r/unixporn con Quick Toggles Icon-Only de 21px,
Sliders modernos con %, Notificaciones en vivo y Calendario CalDAV 0ms indexado.
"""
import os
import subprocess
import sys
import datetime
import threading

import gi
gi.require_version("Gtk", "3.0")
gi.require_version("GtkLayerShell", "0.1")
from gi.repository import Gtk, Gdk, GtkLayerShell, GLib

# Importar backend modular
sys.path.insert(0, os.path.expanduser("~/.config/tararch"))
import control_center_backend as backend

CSS_FILE = os.path.expanduser("~/.config/tararch/control-center.css")


class ControlCenterWindow(Gtk.Window):
    def __init__(self):
        super().__init__(type=Gtk.WindowType.TOPLEVEL)

        # Cargar eventos inmediatamente desde el índice en disco (0ms)
        self.all_events = backend.get_cached_events()
        self.selected_date = datetime.date.today()

        screen = self.get_screen()
        visual = screen.get_rgba_visual()
        if visual is not None:
            self.set_visual(visual)
        self.set_app_paintable(True)

        with open(backend.PID_FILE, "w") as f:
            f.write(str(os.getpid()))

        # Configurar GtkLayerShell
        GtkLayerShell.init_for_window(self)
        GtkLayerShell.set_namespace(self, "control-center")
        GtkLayerShell.set_layer(self, GtkLayerShell.Layer.OVERLAY)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.RIGHT, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.TOP, True)
        GtkLayerShell.set_anchor(self, GtkLayerShell.Edge.BOTTOM, True)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.TOP, 8)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.BOTTOM, 8)
        GtkLayerShell.set_margin(self, GtkLayerShell.Edge.RIGHT, 12)
        GtkLayerShell.set_keyboard_mode(self, GtkLayerShell.KeyboardMode.ON_DEMAND)

        self.set_size_request(420, -1)

        # CSS
        css_provider = Gtk.CssProvider()
        css_provider.load_from_path(CSS_FILE)
        Gtk.StyleContext.add_provider_for_screen(
            Gdk.Screen.get_default(),
            css_provider,
            Gtk.STYLE_PROVIDER_PRIORITY_USER,
        )

        # Contenedor Vertical Principal
        main_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=12)
        main_box.get_style_context().add_class("main-panel")
        self.add(main_box)

        # 1. Cabecera (Fecha y Reloj)
        now = datetime.datetime.now()
        header_box = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        main_box.pack_start(header_box, False, False, 0)

        title_vbox = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
        header_box.pack_start(title_vbox, True, True, 0)

        self.lbl_clock = Gtk.Label(label=now.strftime("%H:%M:%S"), xalign=0)
        self.lbl_clock.get_style_context().add_class("header-title")
        title_vbox.pack_start(self.lbl_clock, False, False, 0)

        dias = ["Lunes", "Martes", "Miércoles", "Jueves", "Viernes", "Sábado", "Domingo"]
        meses = ["Enero", "Febrero", "Marzo", "Abril", "Mayo", "Junio", "Julio", "Agosto", "Septiembre", "Octubre", "Noviembre", "Diciembre"]
        fecha_txt = f"{dias[now.weekday()]}, {now.day} de {meses[now.month-1]}"
        self.lbl_date = Gtk.Label(label=fecha_txt, xalign=0)
        self.lbl_date.get_style_context().add_class("header-subtitle")
        title_vbox.pack_start(self.lbl_date, False, False, 0)

        btn_close = Gtk.Button(label="✕")
        btn_close.get_style_context().add_class("flat")
        btn_close.get_style_context().add_class("btn-close")
        btn_close.set_valign(Gtk.Align.START)
        btn_close.connect("clicked", lambda w: self.close())
        header_box.pack_start(btn_close, False, False, 0)

        # 2. Grid de Botones Rápidos Icon-Only (4 Columnas x 2 Filas, Iconos 21px)
        grid = Gtk.Grid()
        grid.set_column_spacing(8)
        grid.set_row_spacing(8)
        grid.set_column_homogeneous(True)
        main_box.pack_start(grid, False, False, 0)

        # Fila 0: Red, Bluetooth, SSH, LanMouse
        self.btn_wifi = Gtk.Button(label="󰤨")
        self.btn_wifi.get_style_context().add_class("flat")
        self.btn_wifi.get_style_context().add_class("btn-toggle")
        self.btn_wifi.set_tooltip_text("Red / WiFi")
        self.btn_wifi.connect("clicked", lambda w: self.run_action("/home/tara/.local/bin/wifi-menu.sh", close_panel=True))
        grid.attach(self.btn_wifi, 0, 0, 1, 1)

        self.btn_bt = Gtk.Button(label="󰂯")
        self.btn_bt.get_style_context().add_class("flat")
        self.btn_bt.get_style_context().add_class("btn-toggle")
        self.btn_bt.set_tooltip_text("Bluetooth")
        self.btn_bt.connect("clicked", lambda w: self.run_action("/home/tara/.local/bin/bluetooth-menu.sh", close_panel=True))
        grid.attach(self.btn_bt, 1, 0, 1, 1)

        self.btn_ssh = Gtk.Button(label="󰒋")
        self.btn_ssh.get_style_context().add_class("flat")
        self.btn_ssh.get_style_context().add_class("btn-toggle")
        self.btn_ssh.set_tooltip_text("SSH Rápido (TaraNAS / Servidor)")
        self.btn_ssh.connect("clicked", lambda w: self.run_action("/home/tara/.local/bin/ssh-launcher.sh", close_panel=True))
        grid.attach(self.btn_ssh, 2, 0, 1, 1)

        self.btn_lanmouse = Gtk.Button(label="󰍽")
        self.btn_lanmouse.get_style_context().add_class("flat")
        self.btn_lanmouse.get_style_context().add_class("btn-toggle")
        self.btn_lanmouse.set_tooltip_text("LanMouse (KVM)")
        self.btn_lanmouse.connect("clicked", lambda w: self.on_toggle_lanmouse())
        grid.attach(self.btn_lanmouse, 3, 0, 1, 1)

        # Fila 1: TaraTrack, Modos, Bloqueo/Cafeína, Limpiar
        self.btn_taratrack = Gtk.Button(label="󰿎")
        self.btn_taratrack.get_style_context().add_class("flat")
        self.btn_taratrack.get_style_context().add_class("btn-toggle")
        self.btn_taratrack.set_tooltip_text("TaraTrack (Series & Rankings ELO)")
        self.btn_taratrack.connect("clicked", lambda w: self.run_action("/home/tara/.local/bin/taratrack-app.sh", close_panel=True))
        grid.attach(self.btn_taratrack, 0, 1, 1, 1)

        self.btn_modos = Gtk.Button(label="󰓅")
        self.btn_modos.get_style_context().add_class("flat")
        self.btn_modos.get_style_context().add_class("btn-toggle")
        self.btn_modos.set_tooltip_text("Modos de Sistema (Uni, Normal, Gamer)")
        self.btn_modos.connect("clicked", lambda w: self.on_click_modos())
        grid.attach(self.btn_modos, 1, 1, 1, 1)

        self.btn_bloqueo = Gtk.Button(label="󰈈")
        self.btn_bloqueo.get_style_context().add_class("flat")
        self.btn_bloqueo.get_style_context().add_class("btn-toggle")
        self.btn_bloqueo.set_tooltip_text("Bloqueo Pantalla / Modo Cafeína")
        self.btn_bloqueo.connect("clicked", lambda w: self.on_toggle_bloqueo())
        grid.attach(self.btn_bloqueo, 2, 1, 1, 1)

        self.btn_limpiar = Gtk.Button(label="󰆴")
        self.btn_limpiar.get_style_context().add_class("flat")
        self.btn_limpiar.get_style_context().add_class("btn-toggle")
        self.btn_limpiar.set_tooltip_text("Mantenimiento y Limpieza TarArch")
        self.btn_limpiar.connect("clicked", lambda w: self.run_action("kitty -e /home/tara/.local/bin/limpieza-tararch.sh", close_panel=True))
        grid.attach(self.btn_limpiar, 3, 1, 1, 1)

        # 3. Deslizadores (Sliders) Modernos de Volumen y Brillo con % en tiempo real
        slider_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        slider_box.get_style_context().add_class("section-box")
        main_box.pack_start(slider_box, False, False, 0)

        # Fila Volumen
        vol_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        slider_box.pack_start(vol_row, False, False, 0)

        lbl_vol_ic = Gtk.Label(label="󰕾")
        lbl_vol_ic.get_style_context().add_class("slider-icon")
        vol_row.pack_start(lbl_vol_ic, False, False, 0)

        vol_val = backend.get_volume()
        self.scale_vol = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0.0, 1.0, 0.02)
        self.scale_vol.set_value(vol_val)
        self.scale_vol.set_draw_value(False)
        self.scale_vol.connect("value-changed", self.on_vol_changed)
        vol_row.pack_start(self.scale_vol, True, True, 0)

        self.lbl_vol_pct = Gtk.Label(label=f"{int(vol_val * 100)}%", xalign=1)
        self.lbl_vol_pct.get_style_context().add_class("slider-val-label")
        vol_row.pack_start(self.lbl_vol_pct, False, False, 0)

        # Fila Brillo
        bri_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=10)
        slider_box.pack_start(bri_row, False, False, 0)

        lbl_bri_ic = Gtk.Label(label="󰃟")
        lbl_bri_ic.get_style_context().add_class("slider-icon")
        bri_row.pack_start(lbl_bri_ic, False, False, 0)

        bri_val = backend.get_brightness()
        self.scale_bri = Gtk.Scale.new_with_range(Gtk.Orientation.HORIZONTAL, 0.05, 1.0, 0.02)
        self.scale_bri.set_value(bri_val)
        self.scale_bri.set_draw_value(False)
        self.scale_bri.connect("value-changed", self.on_bri_changed)
        bri_row.pack_start(self.scale_bri, True, True, 0)

        self.lbl_bri_pct = Gtk.Label(label=f"{int(bri_val * 100)}%", xalign=1)
        self.lbl_bri_pct.get_style_context().add_class("slider-val-label")
        bri_row.pack_start(self.lbl_bri_pct, False, False, 0)

        # 4. PESTAÑAS (TABS): [ 󰸗 CALENDARIO ] Y [ 󰂚 NOTIFICACIONES ]
        tab_header = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=8)
        main_box.pack_start(tab_header, False, False, 0)

        self.btn_tab_cal = Gtk.Button(label="󰸗")
        self.btn_tab_cal.get_style_context().add_class("flat")
        self.btn_tab_cal.get_style_context().add_class("btn-tab")
        self.btn_tab_cal.get_style_context().add_class("btn-tab-active")
        self.btn_tab_cal.set_tooltip_text("Calendario y Agenda")
        self.btn_tab_cal.connect("clicked", lambda w: self.switch_tab("cal"))
        tab_header.pack_start(self.btn_tab_cal, True, True, 0)

        self.btn_tab_noti = Gtk.Button(label="󰂚")
        self.btn_tab_noti.get_style_context().add_class("flat")
        self.btn_tab_noti.get_style_context().add_class("btn-tab")
        self.btn_tab_noti.set_tooltip_text("Notificaciones")
        self.btn_tab_noti.connect("clicked", lambda w: self.switch_tab("noti"))
        tab_header.pack_start(self.btn_tab_noti, True, True, 0)

        # Stack
        self.stack = Gtk.Stack()
        self.stack.set_transition_type(Gtk.StackTransitionType.CROSSFADE)
        self.stack.set_transition_duration(150)
        main_box.pack_start(self.stack, True, True, 0)

        # VISTA A: CALENDARIO INTERACTIVO CON EVENTOS
        cal_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        cal_box.get_style_context().add_class("section-box")

        cal_top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        cal_box.pack_start(cal_top, False, False, 0)

        cal_lbl = Gtk.Label(label="󰸗 Agenda Sincronizada", xalign=0)
        cal_lbl.get_style_context().add_class("cal-header-label")
        cal_top.pack_start(cal_lbl, True, True, 0)

        btn_sync = Gtk.Button(label="󰑐")
        btn_sync.get_style_context().add_class("flat")
        btn_sync.get_style_context().add_class("btn-action-icon")
        btn_sync.set_tooltip_text("Sincronizar CalDAV")
        btn_sync.connect("clicked", lambda w: self.start_bg_sync())
        cal_top.pack_start(btn_sync, False, False, 0)

        btn_open_full = Gtk.Button(label="󰌷")
        btn_open_full.get_style_context().add_class("flat")
        btn_open_full.get_style_context().add_class("btn-action-icon")
        btn_open_full.set_tooltip_text("Abrir Aplicación de Calendario")
        btn_open_full.connect("clicked", lambda w: self.run_action("/home/tara/.local/bin/calendario.sh"))
        cal_top.pack_start(btn_open_full, False, False, 0)

        self.calendar = Gtk.Calendar()
        self.calendar.set_display_options(
            Gtk.CalendarDisplayOptions.SHOW_HEADING |
            Gtk.CalendarDisplayOptions.SHOW_DAY_NAMES |
            Gtk.CalendarDisplayOptions.SHOW_WEEK_NUMBERS |
            Gtk.CalendarDisplayOptions.SHOW_DETAILS
        )
        self.calendar.connect("day-selected", self.on_day_selected)
        self.calendar.connect("month-changed", self.on_month_changed)
        cal_box.pack_start(self.calendar, False, False, 0)

        # Área de eventos de la fecha seleccionada
        self.events_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=4)
        cal_box.pack_start(self.events_box, True, True, 2)

        self.lbl_selected_header = Gtk.Label(label="Eventos:", xalign=0)
        self.lbl_selected_header.get_style_context().add_class("header-subtitle")
        self.events_box.pack_start(self.lbl_selected_header, False, False, 0)

        self.lbl_event_item = Gtk.Label(label="Cargando eventos...", xalign=0)
        self.lbl_event_item.set_line_wrap(True)
        self.lbl_event_item.set_use_markup(True)
        self.lbl_event_item.get_style_context().add_class("event-item-text")
        self.events_box.pack_start(self.lbl_event_item, False, False, 0)

        self.stack.add_named(cal_box, "cal")

        # VISTA B: NOTIFICACIONES REALES
        noti_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=8)
        noti_box.get_style_context().add_class("section-box")

        noti_top = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
        noti_box.pack_start(noti_top, False, False, 0)

        self.lbl_noti_title = Gtk.Label(label="Centro de Notificaciones", xalign=0)
        self.lbl_noti_title.get_style_context().add_class("cal-header-label")
        noti_top.pack_start(self.lbl_noti_title, True, True, 0)

        btn_dnd = Gtk.Button(label="󰒲")
        btn_dnd.get_style_context().add_class("flat")
        btn_dnd.get_style_context().add_class("btn-action-icon")
        btn_dnd.set_tooltip_text("Modo No Molestar / Silenciar")
        btn_dnd.connect("clicked", lambda w: self.run_action("swaync-client -d -sw"))
        noti_top.pack_start(btn_dnd, False, False, 0)

        btn_clear_notis = Gtk.Button(label="󰆴")
        btn_clear_notis.get_style_context().add_class("flat")
        btn_clear_notis.get_style_context().add_class("btn-action-icon")
        btn_clear_notis.set_tooltip_text("Vaciar Notificaciones")
        btn_clear_notis.connect("clicked", self.on_clear_notis)
        noti_top.pack_start(btn_clear_notis, False, False, 0)

        self.noti_scrolled = Gtk.ScrolledWindow()
        self.noti_scrolled.set_policy(Gtk.PolicyType.NEVER, Gtk.PolicyType.AUTOMATIC)
        self.noti_scrolled.set_min_content_height(350)
        noti_box.pack_start(self.noti_scrolled, True, True, 0)

        self.noti_list_box = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=6)
        self.noti_scrolled.add(self.noti_list_box)

        self.stack.add_named(noti_box, "noti")

        self.connect("key-press-event", self.on_key_press)
        self.connect("destroy", self.on_destroy)

        # Aplicar eventos en caché de inmediato (0ms) y lanzar sync en segundo plano
        self.apply_synced_events(self.all_events)
        self.start_bg_sync()

        self.update_data()
        GLib.timeout_add(1000, self.update_data)

    def start_bg_sync(self):
        def worker():
            evs = backend.fetch_all_events()
            GLib.idle_add(self.apply_synced_events, evs)
        threading.Thread(target=worker, daemon=True).start()

    def apply_synced_events(self, events):
        if not events:
            return
        self.all_events = events
        self.calendar.clear_marks()

        year, month, _ = self.calendar.get_date()
        current_m = month + 1

        for ev in self.all_events:
            d = ev["date"]
            if (d.month == current_m and (d.year == year or ev.get("yearly"))):
                self.calendar.mark_day(d.day)

        self.update_events_ui()

    def on_day_selected(self, cal):
        year, month, day = cal.get_date()
        self.selected_date = datetime.date(year, month + 1, day)
        self.update_events_ui()

    def on_month_changed(self, cal):
        self.apply_synced_events(self.all_events)

    def update_events_ui(self):
        d = self.selected_date
        self.lbl_selected_header.set_text(f"📌 {d.day}/{d.month}/{d.year}:")

        matched = [
            ev for ev in self.all_events
            if (ev["date"].month == d.month and ev["date"].day == d.day and (ev["date"].year == d.year or ev.get("yearly")))
        ]

        if matched:
            lines = []
            for m in matched:
                time_part = f"<span color='#ff9e64'>[{m['time']}]</span> " if m["time"] else ""
                lines.append(f"• {time_part}<b>{m['summary']}</b>")
            self.lbl_event_item.set_markup("\n".join(lines))
        else:
            today = datetime.date.today()
            upcoming = []
            for ev in self.all_events:
                ev_d = ev["date"]
                if ev.get("yearly"):
                    ev_d = datetime.date(today.year if today.month <= ev_d.month else today.year + 1, ev_d.month, ev_d.day)
                if ev_d >= today:
                    upcoming.append({"summary": ev["summary"], "time": ev["time"], "date": ev_d})

            upcoming.sort(key=lambda x: x["date"])
            if upcoming:
                lines = ["<i>Sin eventos este día. Próximas citas:</i>"]
                for u in upcoming[:4]:
                    time_p = f" ({u['time']})" if u['time'] else ""
                    lines.append(f"• <span color='#ff9e64'>{u['date'].day}/{u['date'].month}</span>: {u['summary']}{time_p}")
                self.lbl_event_item.set_markup("\n".join(lines))
            else:
                self.lbl_event_item.set_markup("<i>Sin eventos programados</i>")

    def switch_tab(self, tab_name):
        self.stack.set_visible_child_name(tab_name)
        if tab_name == "cal":
            self.btn_tab_cal.get_style_context().add_class("btn-tab-active")
            self.btn_tab_noti.get_style_context().remove_class("btn-tab-active")
        else:
            self.btn_tab_noti.get_style_context().add_class("btn-tab-active")
            self.btn_tab_cal.get_style_context().remove_class("btn-tab-active")

    def refresh_notifications(self):
        notifs = backend.load_notifications()

        current_ids = [n.get("id") for n in notifs]
        if hasattr(self, "last_notif_ids") and self.last_notif_ids == current_ids:
            return
        self.last_notif_ids = current_ids

        for child in self.noti_list_box.get_children():
            self.noti_list_box.remove(child)

        if not notifs:
            lbl_empty = Gtk.Label(label="󰂛 No hay notificaciones pendientes", xalign=0.5)
            lbl_empty.get_style_context().add_class("slider-label")
            self.noti_list_box.pack_start(lbl_empty, True, True, 40)
        else:
            for item in notifs:
                card = Gtk.Box(orientation=Gtk.Orientation.VERTICAL, spacing=2)
                card.get_style_context().add_class("noti-card")

                head_row = Gtk.Box(orientation=Gtk.Orientation.HORIZONTAL, spacing=6)
                card.pack_start(head_row, False, False, 0)

                app_name = item.get("app", "Sistema")
                lbl_app = Gtk.Label(label=f"󰂚 {app_name}", xalign=0)
                lbl_app.get_style_context().add_class("noti-card-header")
                head_row.pack_start(lbl_app, True, True, 0)

                time_str = item.get("time", "")
                if time_str:
                    lbl_time = Gtk.Label(label=time_str, xalign=1)
                    lbl_time.get_style_context().add_class("noti-card-time")
                    head_row.pack_start(lbl_time, False, False, 0)

                btn_del = Gtk.Button(label="✕")
                btn_del.get_style_context().add_class("flat")
                btn_del.get_style_context().add_class("noti-btn-del")
                btn_del.connect("clicked", lambda w, n_id=item.get("id"): self.on_delete_single_notif(n_id))
                head_row.pack_start(btn_del, False, False, 0)

                title_str = item.get("title", "")
                if title_str:
                    lbl_title = Gtk.Label(label=title_str, xalign=0)
                    lbl_title.set_line_wrap(True)
                    lbl_title.get_style_context().add_class("noti-card-title")
                    card.pack_start(lbl_title, False, False, 0)

                body_str = item.get("body", "")
                if body_str:
                    lbl_body = Gtk.Label(label=body_str, xalign=0)
                    lbl_body.set_line_wrap(True)
                    lbl_body.get_style_context().add_class("noti-card-body")
                    card.pack_start(lbl_body, False, False, 0)

                self.noti_list_box.pack_start(card, False, False, 0)

        self.noti_list_box.show_all()

    def on_delete_single_notif(self, notif_id):
        self.last_notif_ids = None
        backend.delete_notification(notif_id)
        self.update_data()

    def on_clear_notis(self, widget=None):
        self.last_notif_ids = None
        backend.clear_notifications()
        self.update_data()

    def on_vol_changed(self, scale):
        val = scale.get_value()
        backend.set_volume(val)
        self.lbl_vol_pct.set_text(f"{int(val * 100)}%")

    def on_bri_changed(self, scale):
        val = scale.get_value()
        backend.set_brightness(val)
        self.lbl_bri_pct.set_text(f"{int(val * 100)}%")

    def run_action(self, cmd, close_panel=False):
        subprocess.Popen(cmd, shell=True)
        if close_panel:
            self.close()

    def on_toggle_lanmouse(self):
        self.run_action("/home/tara/.local/bin/toggle-lanmouse.sh")
        GLib.timeout_add(300, self.update_toggles_state)
        GLib.timeout_add(800, self.update_toggles_state)

    def on_toggle_bloqueo(self):
        self.run_action("/home/tara/.local/bin/nobloqueo")
        GLib.timeout_add(350, self.update_toggles_state)

    def on_click_modos(self):
        self.run_action("/home/tara/.local/bin/set-system-mode.sh", close_panel=True)

    def set_btn_state(self, btn, label, is_active, color_type="orange"):
        if btn.get_label() != label:
            btn.set_label(label)

        ctx = btn.get_style_context()
        target_class = None
        if is_active:
            if color_type == "green":
                target_class = "btn-toggle-active-green"
            elif color_type == "red":
                target_class = "btn-toggle-active-red"
            else:
                target_class = "btn-toggle-active"

        for c in ["btn-toggle-active", "btn-toggle-active-green", "btn-toggle-active-red"]:
            if c != target_class and ctx.has_class(c):
                ctx.remove_class(c)
        if target_class and not ctx.has_class(target_class):
            ctx.add_class(target_class)

    def update_toggles_state(self):
        # 1. Red (WiFi / Ethernet)
        try:
            is_wifi = backend.is_wifi_enabled()
            self.set_btn_state(self.btn_wifi, "󰤨", is_wifi, "orange")
        except Exception:
            pass

        # 2. Bluetooth
        try:
            is_bt = backend.is_bluetooth_powered()
            self.set_btn_state(self.btn_bt, "󰂯", is_bt, "orange")
        except Exception:
            pass

        # 3. SSH
        try:
            self.set_btn_state(self.btn_ssh, "󰒋", False)
        except Exception:
            pass

        # 4. LanMouse (󰍾 Activo / 󰍽 Inactivo)
        try:
            is_lm = backend.is_lanmouse_running()
            icon = "󰍾" if is_lm else "󰍽"
            self.set_btn_state(self.btn_lanmouse, icon, is_lm, "orange")
            self.btn_lanmouse.set_tooltip_text(f"LanMouse: {'Activo (Mouse On)' if is_lm else 'Inactivo'}")
        except Exception:
            pass

        # 5. TaraTrack
        try:
            self.set_btn_state(self.btn_taratrack, "󰿎", False)
        except Exception:
            pass

        # 6. Modos de Sistema (Uni = Lápiz 󰏫 Verde / Gamer = Gamepad 󰊴 Rojo / Normal = Gauge 󰓅)
        try:
            mode = backend.get_system_mode()
            if mode == "uni":
                self.set_btn_state(self.btn_modos, "󰏫", True, "green")
            elif mode == "gamer":
                self.set_btn_state(self.btn_modos, "󰊴", True, "red")
            else:
                self.set_btn_state(self.btn_modos, "󰓅", False)
        except Exception:
            pass

        # 7. Bloqueo / Cafeína (Inactivo = 󰈈 / Activo = 󰅶 Café Naranja)
        try:
            is_nb = backend.is_nobloqueo_active()
            icon = "󰅶" if is_nb else "󰈈"
            self.set_btn_state(self.btn_bloqueo, icon, is_nb, "orange")
        except Exception:
            pass

        # 8. Limpiar
        try:
            self.set_btn_state(self.btn_limpiar, "󰆴", False)
        except Exception:
            pass

        return False

    def update_data(self):
        now = datetime.datetime.now()
        self.lbl_clock.set_text(now.strftime("%H:%M:%S"))

        notifs = backend.load_notifications()
        count = len(notifs)

        lbl_noti = f"󱅫 {count}" if count > 0 else "󰂚"
        self.btn_tab_noti.set_label(lbl_noti)
        self.btn_tab_noti.set_tooltip_text(f"Notificaciones ({count})")

        self.refresh_notifications()
        self.update_toggles_state()
        return True

    def on_key_press(self, widget, event):
        if event.keyval == Gdk.KEY_Escape:
            self.close()
            return True
        return False

    def on_destroy(self, widget):
        if os.path.exists(backend.PID_FILE):
            try:
                os.remove(backend.PID_FILE)
            except Exception:
                pass


def main():
    if backend.is_running():
        sys.exit(0)

    win = ControlCenterWindow()
    win.show_all()
    Gtk.main()


if __name__ == "__main__":
    main()
