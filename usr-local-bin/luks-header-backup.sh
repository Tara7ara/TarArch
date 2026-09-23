#!/bin/bash
# Backup de la cabecera LUKS de nvme0n1p2 a la NAS. No debe romper la transacción de pacman nunca.
set -u

DEVICE="/dev/nvme0n1p2"
DEST_DIR="/home/tara/.mounts/TaraNAS/TarArch_OS"
LOG="/var/log/luks-header-backup.log"
DATE="$(date +%Y-%m-%d)"
OUT="$DEST_DIR/luks-header-tararch-$DATE.img"
KEEP=3

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG"; }

# La NAS puede no estar disponible (portátil fuera de casa): timeout corto y salida limpia.
if ! timeout 8 stat "$DEST_DIR" >/dev/null 2>&1; then
    log "NAS no disponible ($DEST_DIR inaccesible). Backup de cabecera LUKS omitido."
    exit 0
fi

if timeout 20 cryptsetup luksHeaderBackup "$DEVICE" --header-backup-file "$OUT" >> "$LOG" 2>&1; then
    chown tara:tara "$OUT"
    log "Backup de cabecera LUKS guardado en $OUT"
else
    log "ERROR al hacer backup de cabecera LUKS"
    exit 0
fi

# Rotación: quedarnos solo con los KEEP más recientes.
cd "$DEST_DIR" || exit 0
ls -1t luks-header-tararch-*.img 2>/dev/null | tail -n +$((KEEP + 1)) | while read -r old; do
    rm -f "$old"
    log "Eliminado backup antiguo: $old"
done
