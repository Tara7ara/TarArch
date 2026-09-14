#!/bin/bash
STATUS=$(playerctl status 2>/dev/null)
[ -z "$STATUS" ] && exit 0
ARTIST=$(playerctl metadata --format "{{artist}}" 2>/dev/null | head -1)
[ -z "$ARTIST" ] && exit 0

PLAYER=$(playerctl metadata --format "{{playerName}}" 2>/dev/null)
if [ "$PLAYER" = "spotify" ]; then
    ICON=$([ "$STATUS" = "Playing" ] && echo "▶" || echo "⏸")
    echo "$ARTIST  $ICON"
else
    echo "$ARTIST"
fi
