#!/bin/bash
# =============================================================================
# MANTENIMIENTO Y LIMPIEZA INTELIGENTE DEL SISTEMA — TARARCH
# Limpieza de capturas, cache de paquetes, logs y temporales
# =============================================================================

echo -e "\033[1;33m[TarArch] Iniciando rutina de limpieza y mantenimiento...\033[0m\n"

INITIAL_AVAIL=$(df -k / | awk 'NR==2 {print $4}')

# -----------------------------------------------------------------------------
# 1. GESTIÓN Y LIMPIEZA DE CAPTURAS DE PANTALLA
# -----------------------------------------------------------------------------
SCREENSHOT_DIR="$HOME/img/screenshots"
mkdir -p "$SCREENSHOT_DIR"

SHOT_COUNT=$(find "$SCREENSHOT_DIR" -type f -name "*.png" | wc -l)
SHOT_SIZE=$(du -sh "$SCREENSHOT_DIR" 2>/dev/null | awk '{print $1}')

echo -e "\033[1;36m:: Capturas de Pantalla (~/img/screenshots):\033[0m"
echo -e "   Total guardadas: \033[1m$SHOT_COUNT\033[0m ($SHOT_SIZE)"

if [ "$SHOT_COUNT" -gt 0 ]; then
    echo -e "   1) Eliminar capturas con más de 14 días (recomendado)"
    echo -e "   2) Eliminar todas las capturas"
    echo -e "   3) Mantener todas las capturas intactas"
    read -p "   Selecciona una opción [1/2/3] (Enter = 1): " shot_opt
    shot_opt=${shot_opt:-1}

    case "$shot_opt" in
        1)
            DELETED=$(find "$SCREENSHOT_DIR" -type f -name "*.png" -mtime +14 -delete -print | wc -l)
            echo -e "   \033[32m✔ Eliminadas $DELETED capturas antiguas (>14 días).\033[0m"
            ;;
        2)
            rm -f "$SCREENSHOT_DIR"/*.png
            echo -e "   \033[32m✔ Se han eliminado todas las capturas.\033[0m"
            ;;
        *)
            echo -e "   \033[33m✔ Capturas conservadas.\033[0m"
            ;;
    esac
fi

# Limpiar temporales de captura
rm -f /tmp/screenshot_*.png /tmp/tararch_media_card_* 2>/dev/null
echo ""

# -----------------------------------------------------------------------------
# 2. LIMPIEZA DE CACHÉ DE PACMAN Y YAY
# -----------------------------------------------------------------------------
echo -e "\033[1;36m:: Limpiando paquetes descargados en caché (Pacman / Yay)...\033[0m"
if command -v paccache &>/dev/null; then
    sudo paccache -rk1 -q 2>/dev/null || true
fi
yay -Sc --noconfirm 2>/dev/null || true
echo -e "   \033[32m✔ Caché de paquetes optimizada.\033[0m\n"

# -----------------------------------------------------------------------------
# 3. PAQUETES HUÉRFANOS
# -----------------------------------------------------------------------------
echo -e "\033[1;36m:: Comprobando paquetes huérfanos sin dependencias...\033[0m"
ORPHANS=$(pacman -Qtdq 2>/dev/null)
if [ -n "$ORPHANS" ]; then
    echo "$ORPHANS" | sudo pacman -Rns --noconfirm - 2>/dev/null || true
    echo -e "   \033[32m✔ Paquetes huérfanos eliminados.\033[0m\n"
else
    echo -e "   \033[32m✔ No hay paquetes huérfanos residuales.\033[0m\n"
fi

# -----------------------------------------------------------------------------
# 4. REGISTROS DE SYSTEMD (JOURNALCTL)
# -----------------------------------------------------------------------------
echo -e "\033[1;36m:: Reduciendo logs de Systemd a un máximo de 50MB...\033[0m"
sudo journalctl --vacuum-size=50M >/dev/null 2>&1 || true
echo -e "   \033[32m✔ Logs del sistema purgados.\033[0m\n"

# -----------------------------------------------------------------------------
# 5. CACHÉ DE MINIATURAS ROTAS DE USUARIO
# -----------------------------------------------------------------------------
echo -e "\033[1;36m:: Limpiando miniaturas obsoletas (~/.cache/thumbnails)...\033[0m"
rm -rf "$HOME/.cache/thumbnails/"* 2>/dev/null || true
echo -e "   \033[32m✔ Miniaturas residuales eliminadas.\033[0m\n"

# -----------------------------------------------------------------------------
# REPORTE FINAL
# -----------------------------------------------------------------------------
FINAL_AVAIL=$(df -k / | awk 'NR==2 {print $4}')
FREED_KB=$((FINAL_AVAIL - INITIAL_AVAIL))

if [ "$FREED_KB" -gt 0 ]; then
    if [ "$FREED_KB" -gt 1048576 ]; then
        FREED_TXT="$(awk "BEGIN {printf \"%.2f GB\", $FREED_KB/1048576}")"
    else
        FREED_TXT="$(awk "BEGIN {printf \"%.2f MB\", $FREED_KB/1024}")"
    fi
    echo -e "\033[1;32m====================================================\033[0m"
    echo -e "\033[1;32m  ✔ Limpieza completada con éxito: $FREED_TXT liberados\033[0m"
    echo -e "\033[1;32m====================================================\033[0m"
    notify-send "Limpieza TarArch" "Sistema optimizado: $FREED_TXT de espacio liberado" -i drive-harddisk -u low &
else
    echo -e "\033[1;32m====================================================\033[0m"
    echo -e "\033[1;32m  ✔ El sistema ya se encontraba limpio y optimizado.\033[0m"
    echo -e "\033[1;32m====================================================\033[0m"
    notify-send "Limpieza TarArch" "El sistema ya se encontraba limpio y al 100%" -i drive-harddisk -u low &
fi
