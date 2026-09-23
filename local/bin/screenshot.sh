#!/bin/bash
# Captura de región, guarda el archivo y copia la ruta al portapapeles

SAVE_DIR="$HOME/img/screenshots"
mkdir -p "$SAVE_DIR"

TIMESTAMP=$(date +%Y%m%d_%H%M%S)
FILE="$SAVE_DIR/screenshot_${TIMESTAMP}.png"
TEMP_FILE="/tmp/screenshot_latest.png"

# 1. Seleccionar región
GEOM=$(slurp -b 00000088 -c ff9e64ff -d -w 2 2>/dev/null)
[ -z "$GEOM" ] && exit 0

# 2. Capturar directamente a archivo
if ! grim -g "$GEOM" "$FILE"; then
    exit 1
fi

# 3. Guardar copia en temporal fijo
cp -f "$FILE" "$TEMP_FILE"

# 4. Copiar la ruta de texto directamente al portapapeles
echo -n "$FILE" | wl-copy

# 5. Notificación rápida con icono
notify-send \
    --app-name="Captura de Pantalla" \
    --icon="$FILE" \
    "Ruta copiada al portapapeles" \
    "$FILE" \
    -u low &
