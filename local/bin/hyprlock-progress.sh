#!/bin/bash
STATUS=$(playerctl status 2>/dev/null)
[ -z "$STATUS" ] && exit 0

DUR_US=$(playerctl metadata mpris:length 2>/dev/null)
POS_S=$(playerctl position 2>/dev/null)
[ -z "$DUR_US" ] || [ -z "$POS_S" ] && exit 0

POS="${POS_S%%.*}"
DUR=$(( DUR_US / 1000000 ))
[ "$DUR" -eq 0 ] && exit 0

POS_FMT=$(printf "%d:%02d" $((POS/60)) $((POS%60)))
DUR_FMT=$(printf "%d:%02d" $((DUR/60)) $((DUR%60)))

TOTAL=26
FILLED=$(( POS * TOTAL / DUR ))
[ $FILLED -gt $TOTAL ] && FILLED=$TOTAL
EMPTY=$(( TOTAL - FILLED ))

BAR=""
for i in $(seq 1 $FILLED); do BAR="${BAR}█"; done
for i in $(seq 1 $EMPTY); do BAR="${BAR}░"; done

echo "$POS_FMT  $BAR  $DUR_FMT"
