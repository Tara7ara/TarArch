#!/bin/bash
# Copia el backup diario de TaraTrack (creado por scripts/backup.sh en el servidor,
# cron a las 4:00) al NAS, y mantiene solo los 7 mas recientes (una semana). El
# servidor no tiene el NAS montado, asi que se tira de aqui (este PC) via scp -
# ya hay ssh de sobra al servidor y el NAS ya esta montado en /home/tara/TaraNAS.
set -euo pipefail

DEST="/home/tara/TaraNAS/Taratara/TaraTrack/Backup"
KEEP=7
STAMP=$(date +%F)

# El NAS es un automount (systemd autofs) - la primera vez que se toca la ruta tras
# un arranque/inicio de sesion puede tardar unos segundos en montarse de verdad. Sin
# este reintento, el temporizador (que puede lanzarse via Persistent=true justo
# despues de iniciar sesion, antes de que el automount responda) fallaba con "mkdir:
# No existe el fichero o el directorio" - confirmado en los dos unicos fallos reales
# del servicio hasta ahora (13 y 14 de agosto de 2026), los dos justo tras un arranque.
#
# Antes de nada, esperar a network-online.target: si se toca la ruta antes, el automount
# se queda colgado esperandolo (x-systemd.requires en fstab) y bloquea a cualquier
# servicio con ProtectHome=yes (polkit, upower...) hasta que monta - el 23/09 eso
# retraso polkit 60s en el arranque, el agente xfce-polkit dio timeout y Waybar tardo
# en salir. Ojo: nm-online no vale, vuelve en cuanto hay cable aunque el target siga
# esperando al WiFi.
for _ in $(seq 100); do
    systemctl is-active -q network-online.target && break
    sleep 3
done
systemctl is-active -q network-online.target || { echo "sin red tras 5 min, se omite" >&2; exit 0; }
for _ in 1 2 3 4 5; do
    mkdir -p "$DEST" 2>/dev/null && break
    sleep 3
done
mkdir -p "$DEST"  # si sigue fallando tras los reintentos, que falle de verdad y quede en el log

if ! scp -q "servidor:/home/tara/taratrack/backups/taratrack-${STAMP}.db" "$DEST/" 2>/dev/null; then
    echo "[$(date -Iseconds)] aviso: no hay backup de hoy (${STAMP}) en el servidor todavia, se omite" >&2
    exit 0
fi

# Mantener solo los KEEP mas recientes.
ls -1t "$DEST"/taratrack-*.db 2>/dev/null | tail -n "+$((KEEP + 1))" | xargs -r rm -f

echo "[$(date -Iseconds)] copiado taratrack-${STAMP}.db al NAS ($(ls "$DEST"/taratrack-*.db | wc -l) guardados)"
