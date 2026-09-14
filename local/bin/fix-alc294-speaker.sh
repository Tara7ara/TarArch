#!/bin/bash
# Habilita el ampli del altavoz interno del ALC294 (ASUS ROG Strix G512LU, subsystem 0x10431f21).
# El autoconfig genérico del kernel no manda estos coeficientes de fábrica en este modelo concreto;
# sin esto el altavoz interno se queda mudo aunque PipeWire/ALSA reporten volumen y ruta correctos.
# Ver: https://github.com/supg/linux-asus-g512-speaker-fix
DEVICE="/dev/snd/hwC0D0"

hda-verb "$DEVICE" 0x20 0x500 0x0f
hda-verb "$DEVICE" 0x20 0x400 0x7778
hda-verb "$DEVICE" 0x20 0x500 0x40
hda-verb "$DEVICE" 0x20 0x400 0x0800
