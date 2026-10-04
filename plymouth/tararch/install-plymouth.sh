#!/usr/bin/env bash
# =============================================================================
# Instalador del splash Plymouth de TarArch (GRUB + mkinitcpio). CON SUDO:
#     sudo bash plymouth/tararch/install-plymouth.sh
#
# Toca el arranque. Hace backup de todo lo que cambia y SE PARA antes de
# regenerar el initramfs para que revises. Si el disco va cifrado, ten un
# USB live a mano por si acaso.
# =============================================================================
set -euo pipefail

THEME_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
THEME_DST="/usr/share/plymouth/themes/tararch"
MKINIT="/etc/mkinitcpio.conf"
GRUBDEF="/etc/default/grub"
TS=$(date +%Y%m%d-%H%M)

[ "$EUID" -eq 0 ] || { echo "Lánzalo con sudo."; exit 1; }
[ -f "$THEME_SRC/tararch.script" ] || { echo "No encuentro el tema en $THEME_SRC"; exit 1; }
[ -f "$GRUBDEF" ] || { echo "No encuentro $GRUBDEF. Este instalador es para GRUB; con otro gestor añade 'splash' al cmdline a mano."; exit 1; }

echo "== 1. Instalar plymouth (si falta)"
if ! pacman -Q plymouth >/dev/null 2>&1; then
    pacman -S --needed --noconfirm plymouth
else
    echo "   ya instalado."
fi

echo "== 2. Copiar el tema a $THEME_DST"
install -d "$THEME_DST"
install -m644 "$THEME_SRC/tararch.plymouth" "$THEME_SRC/tararch.script" "$THEME_SRC/logo.png" "$THEME_SRC/prompt.png" "$THEME_DST/"

echo "== 3. Ajustar mkinitcpio (backup: $MKINIT.bak-$TS)"
cp -p "$MKINIT" "$MKINIT.bak-$TS"
echo "   HOOKS antes: $(grep -E '^HOOKS=' "$MKINIT")"
# OJO: plymouth 26.x ya no trae el hook 'plymouth-encrypt' (muchas guías viejas
# lo piden). Si lo pones, mkinitcpio falla y el initramfs se queda SIN hook de
# descifrado. Lo correcto es 'plymouth' + 'encrypt' (o 'sd-encrypt'), sin más.
# Va antes de añadir 'plymouth' porque grep -w ve "plymouth" en "plymouth-encrypt".
if grep -E '^HOOKS=' "$MKINIT" | grep -q 'plymouth-encrypt'; then
    sed -i -E '/^HOOKS=/ s/\bplymouth-encrypt\b/encrypt/' "$MKINIT"
    echo "   'plymouth-encrypt' cambiado por 'encrypt' (ese hook ya no existe)."
fi
# 'plymouth' justo después de 'systemd' (initramfs con systemd) o de 'udev'.
hooks=$(grep -E '^HOOKS=' "$MKINIT")
if ! echo "$hooks" | grep -qE '[( ]plymouth[ )]'; then
    if echo "$hooks" | grep -qw systemd; then
        sed -i -E 's/^(HOOKS=\([^)]*\bsystemd\b)/\1 plymouth/' "$MKINIT"
    else
        sed -i -E 's/^(HOOKS=\([^)]*\budev\b)/\1 plymouth/' "$MKINIT"
    fi
fi
echo "   HOOKS ahora: $(grep -E '^HOOKS=' "$MKINIT")"

# Portátiles híbridos Intel + NVIDIA: la pantalla interna suele ir por la Intel.
# Si i915 no está en el initramfs, plymouth arranca sobre otra GPU y el logo
# desaparece en cuanto carga i915 (se ve negro o el log de systemd).
if lspci 2>/dev/null | grep -iE 'vga|display' | grep -qi intel; then
    if ! grep -E '^MODULES=' "$MKINIT" | grep -qw i915; then
        sed -i -E 's/^MODULES=\(\s*/MODULES=(i915 /; s/^MODULES=\(i915 \)/MODULES=(i915)/' "$MKINIT"
        echo "   GPU Intel detectada: añadido i915 a MODULES."
    fi
fi
echo "   MODULES ahora: $(grep -E '^MODULES=' "$MKINIT")"

echo "== 4. Añadir 'splash' al cmdline de GRUB (backup: $GRUBDEF.bak-$TS)"
cp -p "$GRUBDEF" "$GRUBDEF.bak-$TS"
if ! grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUBDEF" | grep -qw splash; then
    sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 splash"/' "$GRUBDEF"
fi
echo "   $(grep -E '^GRUB_CMDLINE_LINUX_DEFAULT=' "$GRUBDEF")"

echo "== 5. Fijar el tema por defecto"
plymouth-set-default-theme tararch

echo
echo "================  REVISA LO DE ARRIBA  ================"
echo "HOOKS: 'plymouth' tras udev/systemd, y si cifras, 'encrypt' o 'sd-encrypt' (NO plymouth-encrypt)."
echo "MODULES: con gráfica Intel (también en híbridos), 'i915' el primero."
echo "Cmdline de GRUB: debe llevar 'splash'."
echo "Backups: $MKINIT.bak-$TS  y  $GRUBDEF.bak-$TS"
echo
read -r -p "Si todo está bien, pulsa ENTER para regenerar initramfs y GRUB (Ctrl+C para abortar)..."

echo "== 6. Regenerar initramfs"
mkinitcpio -P
echo "== 7. Regenerar la config de GRUB"
grub-mkconfig -o /boot/grub/grub.cfg

echo
echo "Listo. Reinicia para ver el splash (la vista previa desde Wayland sale en negro, la prueba buena es reiniciar)."
echo "Si no arranca o no pide la contraseña del disco, desde un USB live:"
echo "   cp $MKINIT.bak-$TS $MKINIT   &&   mkinitcpio -P"
echo "   cp $GRUBDEF.bak-$TS $GRUBDEF  &&   grub-mkconfig -o /boot/grub/grub.cfg"
