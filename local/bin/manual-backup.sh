#!/bin/bash
if pgrep -x restic > /dev/null 2>&1; then
    notify-send "Backup" "Ya hay una copia en curso"
    exit 0
fi

notify-send "Backup" "Copia manual iniciada..."
if sudo -n /usr/local/bin/restic-backup.sh --force; then
    notify-send "Backup" "Copia manual completada"
else
    notify-send "Backup" "Copia manual falló — revisa /var/log/restic-backup.log" -u critical
fi
