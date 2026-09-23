#!/bin/bash
# Copia el backup diario de TaraTrack del servidor al NAS y deja los 7 últimos.
set -euo pipefail

DEST="/home/tara/.mounts/TaraNAS/Taratara/TaraTrack/Backup"
KEEP=7
STAMP=$(date +%F)

# Espera a network-online.target antes de tocar el NAS: si el automount se
# dispara antes se queda colgado y bloquea a polkit, upower...
for _ in $(seq 100); do
    systemctl is-active -q network-online.target && break
    sleep 3
done
systemctl is-active -q network-online.target || { echo "sin red tras 5 min, se omite" >&2; exit 0; }
# El automount puede tardar unos segundos la primera vez
for _ in 1 2 3 4 5; do
    mkdir -p "$DEST" 2>/dev/null && break
    sleep 3
done
mkdir -p "$DEST"

if ! scp -q "servidor:/home/tara/taratrack/backups/taratrack-${STAMP}.db" "$DEST/" 2>/dev/null; then
    echo "[$(date -Iseconds)] aviso: no hay backup de hoy (${STAMP}) en el servidor todavia, se omite" >&2
    exit 0
fi

# Mantener solo los KEEP mas recientes.
ls -1t "$DEST"/taratrack-*.db 2>/dev/null | tail -n "+$((KEEP + 1))" | xargs -r rm -f

echo "[$(date -Iseconds)] copiado taratrack-${STAMP}.db al NAS ($(ls "$DEST"/taratrack-*.db | wc -l) guardados)"
