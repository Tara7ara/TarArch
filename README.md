# TarArch

Configuración de escritorio personal para **Arch Linux + Hyprland** en un portátil ASUS ROG (NVIDIA). Estética "Apple dark" con islas flotantes, escrita y mantenida a mano — sin ningún framework de dotfiles ni generador de plantillas, cada fichero se edita directamente.

![Hyprland](https://img.shields.io/badge/Hyprland-Wayland-58e1ff?style=flat-square)
![Arch Linux](https://img.shields.io/badge/Arch-Linux-1793d1?style=flat-square)
![Shell](https://img.shields.io/badge/Shell-Bash%2FZsh-89e051?style=flat-square)
![Python](https://img.shields.io/badge/Python-GTK3-3776ab?style=flat-square)

## Capturas

_(pendiente — añadir capturas reales aquí)_

## Qué incluye

- **Waybar** en islas flotantes (`config/waybar`) — workspaces, reproductor con centrado dinámico en tiempo real, estado de red/VPN, batería con salud real y ritmo de consumo calculado con media móvil, actualizaciones del sistema, temperatura, backup...
- **Centro de Control** propio (`local/bin/control-center.py`) — panel estilo Windows 11 en GTK3 + GtkLayerShell: toggles rápidos, sliders de volumen/brillo, calendario y notificaciones.
- **Tarjeta de música** (`local/bin/media-card.py`) — popup con ecualizador CAVA en tiempo real, portada, letras.
- **Hyprlock** con reloj, arte del álbum en reproducción y accesos rápidos de energía sin desbloquear.
- **Gestión de energía por modos** (`local/bin/modos`, `set-system-mode.sh`) — perfiles uni/gamer/silencioso que ajustan refresco de pantalla, ventiladores y render.
- **Bloqueo por proximidad Bluetooth** — la sesión se bloquea sola si el móvil se aleja.
- **Rofi** con 10+ temas propios (power menu, wifi, bluetooth, launcher, SSH...) e iconos pre-centrados a mano por bounding box real (no glifos de fuente, para evitar el descentrado típico de los iconos de Nerd Font).
- Scripts sueltos para lo de siempre: VPN (WireGuard), Wake-on-LAN + RDP, backups con `restic`, LEDs RGB del teclado, cursor que cambia de tema según el brillo del wallpaper, gestor de cuentas de Codex CLI...

## Stack

Hyprland · Waybar · Rofi · Kitty · GTK3/GtkLayerShell (Python) · Bash · hyprlock/hypridle · systemd (user + system units)

## Requisitos

No es un instalador de un clic — son mis configs reales, pensadas para copiarse y adaptarse, no para ejecutarse tal cual. Necesitarás como mínimo:

`hyprland` `waybar` `rofi` `kitty` `hyprlock` `hypridle` `python-gobject` `gtk-layer-shell` `playerctl` `upower` `networkmanager` `cava` (para la tarjeta de música)

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

## Antes de usar nada de esto

Estas configs son **mías**, para mi red y mi hardware — antes de copiar un script, revisa que no tenga IPs/rutas que solo tienen sentido en mi casa:

- IPs de ejemplo (`192.168.1.10/20/30`) → sustitúyelas por las tuyas.
- MACs de ejemplo (`AA:BB:CC:DD:EE:01/02`) → las tuyas, para Wake-on-LAN / proximidad Bluetooth.
- `local/bin/codex-acc`/`codex-auth`/`codex-switch` llevan cuentas de ejemplo — son 3 copias del mismo gestor de cuentas de Codex CLI bajo nombres distintos, edítalas con las tuyas.
- Nombres de interfaz de red (`eno2`), alias SSH (`servidor`, `nas`) y nombre de conexión VPN (`Portatil`) son los míos, ajústalos a los tuyos.

## Licencia

MIT — usa lo que te sirva, adapta el resto.
