#!/bin/bash
# Statusline de Claude Code: muestra el % de uso (sesion 5h / semanal 7d)
# en la propia UI de Claude Code, debajo de donde escribes.
python3 -c "
import json, sys

data = json.load(sys.stdin)
rl = data.get('rate_limits', {}) or {}
five = rl.get('five_hour', {}) or {}
seven = rl.get('seven_day', {}) or {}

five_pct = five.get('used_percentage')
seven_pct = seven.get('used_percentage')
parts = []
if five_pct is not None:
    parts.append(f'5h {five_pct:.0f}%')
if seven_pct is not None:
    parts.append(f'7d {seven_pct:.0f}%')
print(' · '.join(parts) if parts else 'Claude Code')
" 2>/dev/null || echo "Claude Code"
