#!/bin/sh
# Builds the bundled adhan sounds from a CC BY-SA 4.0 recording on Wikimedia Commons:
# "The Adhan - Muslim Call to Prayer - Aaqib Azeez.mp3" by Atcovi
# https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CACHE="$ROOT/scripts/.cache"
OUT="$ROOT/Abrar/Resources/Sounds"
SOURCE_URL="https://upload.wikimedia.org/wikipedia/commons/7/7d/The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3"

mkdir -p "$CACHE" "$OUT"
[ -f "$CACHE/adhan-source.mp3" ] || curl -fsSL -A "Abrar build script" -o "$CACHE/adhan-source.mp3" "$SOURCE_URL"

# Notification sounds must be under 30 s and use a format UserNotifications accepts (IMA4 in CAF).
swift "$ROOT/scripts/trim_audio.swift" "$CACHE/adhan-source.mp3" "$CACHE/adhan-short.wav" 28 3
afconvert -f caff -d ima4 -c 1 "$CACHE/adhan-short.wav" "$OUT/adhan.caf"
afconvert -f m4af -d aac -b 96000 "$CACHE/adhan-source.mp3" "$OUT/adhan_full.m4a"

afinfo "$OUT/adhan.caf" | grep -E "duration|format"
afinfo "$OUT/adhan_full.m4a" | grep -E "duration|format"
