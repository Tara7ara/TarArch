#!/usr/bin/env bash
# =============================================================================
# Instalador del tema GRUB de TarArch. CON SUDO:
#     sudo bash grub/tararch/install-grub-theme.sh
#
# Copia el tema a /boot/grub/themes/tararch, pone GRUB_THEME en
# /etc/default/grub (con backup) y SE PARA antes de regenerar grub.cfg.
# Solo cambia el aspecto del menú: las entradas (Arch, Windows, snapshots...)
# siguen siendo las mismas.
# =============================================================================
set -euo pipefail

SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DST="/boot/grub/themes/tararch"
GRUBDEF="/etc/default/grub"
TS=$(date +%Y%m%d-%H%M)

[ "$EUID" -eq 0 ] || { echo "Lánzalo con sudo."; exit 1; }
[ -f "$SRC/theme.txt" ] || { echo "No encuentro theme.txt en $SRC"; exit 1; }
[ -f "$GRUBDEF" ] || { echo "No encuentro $GRUBDEF"; exit 1; }

echo "== 1. Copiar el tema a $DST"
install -d "$DST"
install -m644 "$SRC"/theme.txt "$SRC"/*.png "$SRC"/*.pf2 "$DST/"

echo "== 2. GRUB_THEME en $GRUBDEF (backup: $GRUBDEF.bak-$TS)"
cp -p "$GRUBDEF" "$GRUBDEF.bak-$TS"
if grep -qE '^#?GRUB_THEME=' "$GRUBDEF"; then
    sed -i -E "s|^#?GRUB_THEME=.*|GRUB_THEME=\"$DST/theme.txt\"|" "$GRUBDEF"
else
    echo "GRUB_THEME=\"$DST/theme.txt\"" >> "$GRUBDEF"
fi
# El tema necesita modo gráfico: si el terminal de salida está forzado a consola, avisar.
grep -E '^GRUB_TERMINAL_OUTPUT=' "$GRUBDEF" | grep -q console && \
    echo "   OJO: GRUB_TERMINAL_OUTPUT=console desactiva los temas; coméntalo si quieres verlo."
echo "   $(grep -E '^GRUB_THEME=' "$GRUBDEF")"

echo
echo "================  REVISA LO DE ARRIBA  ================"
echo "Solo debe haber cambiado la línea GRUB_THEME. Backup: $GRUBDEF.bak-$TS"
read -r -p "Pulsa ENTER para regenerar grub.cfg (Ctrl+C para abortar)..."

echo "== 3. Regenerar grub.cfg"
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "Listo. Reinicia para verlo. Si el menú saliera raro o en texto, se vuelve atrás con:"
echo "   cp $GRUBDEF.bak-$TS $GRUBDEF  &&  grub-mkconfig -o /boot/grub/grub.cfg"
