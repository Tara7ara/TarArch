#!/bin/bash

LOG="/var/log/restic-backup.log"
PROGRESS_FILE="/tmp/restic-backup-progress"
TODAY=$(date +%Y-%m-%d)

STATE=""
[ -f "$PROGRESS_FILE" ] && STATE=$(cat "$PROGRESS_FILE")
STATE_TYPE="${STATE%%:*}"
STATE_VAL="${STATE#*:}"

# running no lleva timestamp (lleva %); done/error/skipped sí, hay que comprobar que sean de hoy
STATE_IS_TODAY=false
if [ "$STATE_TYPE" != "running" ] && [ -n "$STATE_VAL" ]; then
    [ "$(date -d "@$STATE_VAL" +%Y-%m-%d 2>/dev/null)" = "$TODAY" ] && STATE_IS_TODAY=true
fi

if pgrep -x restic > /dev/null 2>&1; then
    if [ "$STATE_TYPE" = "running" ] && [ -n "$STATE_VAL" ]; then
        echo "{\"text\":\"󰁯\",\"class\":\"running\",\"tooltip\":\"Copia en curso... ${STATE_VAL}%\"}"
    else
        echo '{"text":"󰁯","class":"running","tooltip":"Copia en curso..."}'
    fi
    exit 0
fi

if [ "$STATE_IS_TODAY" = true ]; then
    HORA=$(date -d "@$STATE_VAL" +%H:%M)
    case "$STATE_TYPE" in
        done)
            echo "{\"text\":\"󰄷\",\"class\":\"done\",\"tooltip\":\"Copia completada hoy a las ${HORA}\"}"
            exit 0
            ;;
        skipped)
            echo "{\"text\":\"󰄷\",\"class\":\"done\",\"tooltip\":\"Ya había copia de hoy (comprobado a las ${HORA})\"}"
            exit 0
            ;;
        error)
            echo "{\"text\":\"󰀪\",\"class\":\"error\",\"tooltip\":\"La copia de hoy falló a las ${HORA} — revisa /var/log/restic-backup.log\"}"
            exit 0
            ;;
    esac
fi

# Sin estado fiable en /tmp (p.ej. tras un reboot que lo limpió) -> caer al log de siempre
if grep -q "\[$TODAY.*\] Copia finalizada\." "$LOG" 2>/dev/null; then
    echo '{"text":"󰄷","class":"done","tooltip":"Copia realizada hoy"}'
    exit 0
fi

echo '{"text":"󰄷","class":"missing","tooltip":"Sin copia de seguridad hoy"}'
