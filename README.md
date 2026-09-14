# TarArch

Mi Arch Linux con Hyprland, día a día, en un ASUS ROG con NVIDIA. Sin framework de dotfiles ni generador de plantillas.

## Algunas cosas que costó sacar adelante

- **Los tooltips/popups se pintaban invisibles** en cualquier superficie layer-shell (Waybar, Centro de Control) en cuanto llevaban `rgba()` con alpha < 1 — bug real de la mezcla de capas NVIDIA+Wayland, no de mi CSS. Con opacidad completa (`rgb()`, alpha=1) pinta bien; por debajo de 1, nada. Sigue documentado por si reaparece en otro sitio.
- **Los iconos de rofi nunca quedaban centrados de verdad** por mucho que ajustara el tamaño de fuente — pango centra la *caja lógica* del glifo, no la tinta, y los iconos de Nerd Font tienen side-bearings asimétricos. Solución real: `make-rofi-icon.py` renderiza cada icono como PNG, mide el bounding box de tinta de verdad con PIL y lo centra a mano en un canvas cuadrado — cero dependencia de que pango decida centrar bien.
- **`asusd` competía con `rogauracore`** por el LED RGB del teclado (el color hacía pop-up y se revertía en un segundo) — `asusd` reaplicaba su propio estado guardado en cada evento USB del teclado. Y `systemctl disable` no bastaba: una regla udev del propio paquete lo reactivaba en cada boot vía `SYSTEMD_WANTS`, ignorando el disable. Hace falta `mask`, no `disable`.
- **El cursor cambia de tema solo** según el brillo medio del wallpaper activo (blanco sobre fondos oscuros, negro sobre claros) — y sincronizado en 5 capas a la vez (compositor, gsettings, `~/.icons/default`, GTK3/GTK4, kitty) porque cualquiera de ellas por separado se queda desincronizada tarde o temprano.
- **Centro de Control** propio en vez de usar algo ya hecho — GTK3 + GtkLayerShell, estilo Windows 11, porque quería toggles/sliders/calendario en un panel que se sintiera parte del mismo sistema, no otra app suelta con su propio estilo.
- La tarjeta de música (`media-card.py`) mete un ecualizador CAVA en tiempo real en el popup, con portada y letras.

## Stack

Hyprland · Waybar · Rofi · Kitty · GTK3/GtkLayerShell (Python) · Bash · hyprlock/hypridle · systemd

## Estructura

```
config/       → ~/.config/*  (hypr, waybar, rofi, kitty, gtk, fastfetch...)
local/bin/    → ~/.local/bin/*  (scripts propios)
usr-local-bin/→ /usr/local/bin/*  (scripts que necesitan vivir fuera del home)
systemd/      → unidades de systemd (system, user, sleep hooks)
udev-rules/   → reglas udev
pacman-hooks/ → hooks de pacman
.zshrc, .zprofile
```

## Requisitos

No es un instalador de un clic, son mis configs reales para copiar y adaptar. Como mínimo:

`hyprland` `waybar` `rofi` `kitty` `hyprlock` `hypridle` `python-gobject` `gtk-layer-shell` `playerctl` `upower` `networkmanager` `cava`

## Antes de copiar nada de esto

Son mis configs, para mi red y mi hardware — revisa esto antes de usarlas tal cual:

- IPs de ejemplo (`192.168.1.10/20/30`) → las tuyas.
- MACs de ejemplo (`AA:BB:CC:DD:EE:01/02`) → las tuyas, para Wake-on-LAN / proximidad Bluetooth.
- `local/bin/codex-acc` lleva cuentas de ejemplo — edítalas con las tuyas.
- Nombres de interfaz de red (`eno2`), alias SSH (`servidor`, `nas`) y nombre de conexión VPN (`Portatil`) son los míos.
