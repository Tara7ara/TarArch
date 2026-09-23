#!/bin/bash
REPO="/home/tara/.mounts/TaraNAS/TarArch_OS/restic-repo"
PASS_FILE="/etc/restic-password"
LOG="/var/log/restic-backup.log"
PROGRESS_FILE="/tmp/restic-backup-progress"
LOCKFILE="/tmp/restic-backup.flock"

# Evita que el timer diario y el botón de backup manual corran a la vez
# (causa más probable de los locks huérfanos vistos desde el 2026-08-11)
exec 9>"$LOCKFILE"
if ! flock -n 9; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Otra copia ya está en marcha, saliendo." >> "$LOG"
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Comprobando si ya hay copia hoy..." >> "$LOG"

FORCE=false
[ "$1" = "--force" ] && FORCE=true

# Limpia locks huérfanos (restic solo borra los que ya no tienen proceso dueño vivo)
restic --no-cache -r "$REPO" --password-file "$PASS_FILE" unlock >> "$LOG" 2>&1

if [ "$FORCE" = false ] && restic --no-cache -r "$REPO" --password-file "$PASS_FILE" snapshots 2>/dev/null | grep -q "$(date +%Y-%m-%d)"; then
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Ya existe copia de hoy. Nada que hacer." >> "$LOG"
    echo "skipped:$(date +%s)" > "$PROGRESS_FILE"
    chmod 644 "$PROGRESS_FILE"
    exit 0
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Iniciando copia de seguridad..." >> "$LOG"
echo "running:0" > "$PROGRESS_FILE"
chmod 644 "$PROGRESS_FILE"

restic --no-cache -r "$REPO" --password-file "$PASS_FILE" backup / /home \
    --exclude=/proc \
    --exclude=/sys \
    --exclude=/dev \
    --exclude=/run \
    --exclude=/tmp \
    --exclude=/mnt \
    --exclude=/home/tara/.mounts/TaraNAS \
    --exclude=/home/tara/.cache \
    --exclude=/home/tara/.local/share/Steam \
    --one-file-system \
    --json 2>>"$LOG" | while IFS= read -r line; do
        echo "$line" >> "$LOG"
        pct=$(printf '%s' "$line" | python3 -c "
import sys, json
try:
    d = json.loads(sys.stdin.read())
    if d.get('message_type') == 'status':
        print(round(d.get('percent_done', 0) * 100))
except Exception:
    pass
" 2>/dev/null)
        if [ -n "$pct" ]; then
            echo "running:$pct" > "$PROGRESS_FILE"
        fi
    done
BACKUP_STATUS=${PIPESTATUS[0]}

# NOTA (2026-09-14): el forget/prune ya NO se hace aquí, se movió al servidor
# (siempre en la LAN junto al NAS, sin el salto de latencia+VPN de cuando
# el portátil está fuera de casa, que era lo que dejaba el prune colgado).

if [ "$BACKUP_STATUS" -eq 0 ]; then
    echo "done:$(date +%s)" > "$PROGRESS_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] Copia finalizada correctamente (backup OK; forget/prune lo hace el servidor)." >> "$LOG"
else
    echo "error:$(date +%s)" > "$PROGRESS_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ERROR: el backup falló (código $BACKUP_STATUS). Revisar log arriba." >> "$LOG"
fi
chmod 644 "$PROGRESS_FILE"
