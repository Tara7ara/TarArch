#!/bin/bash
playerctl metadata --format "{{title}}" 2>/dev/null | head -1
