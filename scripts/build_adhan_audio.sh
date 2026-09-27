#!/bin/sh
# Builds the bundled adhan sounds from freely licensed recordings on Wikimedia Commons:
# - "The Adhan - Muslim Call to Prayer - Aaqib Azeez.mp3" by Atcovi (CC BY-SA 4.0)
#   https://commons.wikimedia.org/wiki/File:The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3
# - "Adhan, Great Mosque of Mecca - Jan 21, 2013.webm" by Seyfula Islam (CC BY 3.0)
#   https://commons.wikimedia.org/wiki/File:Adhan,_Great_Mosque_of_Mecca_-_Jan_21,_2013.webm
# - "Call to prayer by Sabah Fakhry.mp3" (public domain)
#   https://commons.wikimedia.org/wiki/File:Call_to_prayer_by_Sabah_Fakhry.mp3
# Requires ffmpeg for the Makkah recording (WebM/Vorbis) and loudness matching.
set -eu

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CACHE="$ROOT/scripts/.cache"
OUT="$ROOT/Abrar/Resources/Sounds"
COMMONS="https://upload.wikimedia.org/wikipedia/commons"

mkdir -p "$CACHE" "$OUT"

fetch() {
    [ -f "$CACHE/$1" ] || curl -fsSL -A "Abrar build script" -o "$CACHE/$1" "$2"
}

# Notification sounds must be under 30 s and use a format UserNotifications accepts (IMA4 in CAF).
# <source> <name> <start seconds>
build() {
    ffmpeg -v error -y -ss "$3" -i "$CACHE/$1" -vn -af loudnorm=I=-16:TP=-1.5 -ar 44100 -ac 2 "$CACHE/$2-full.wav"
    swift "$ROOT/scripts/trim_audio.swift" "$CACHE/$2-full.wav" "$CACHE/$2-short.wav" 28 3
    afconvert -f caff -d ima4 -c 1 "$CACHE/$2-short.wav" "$OUT/$2.caf"
    afconvert -f m4af -d aac -b 96000 "$CACHE/$2-full.wav" "$OUT/$2_full.m4a"
}

fetch adhan-source.mp3 "$COMMONS/7/7d/The_Adhan_-_Muslim_Call_to_Prayer_-_Aaqib_Azeez.mp3"
swift "$ROOT/scripts/trim_audio.swift" "$CACHE/adhan-source.mp3" "$CACHE/adhan-short.wav" 28 3
afconvert -f caff -d ima4 -c 1 "$CACHE/adhan-short.wav" "$OUT/adhan.caf"
afconvert -f m4af -d aac -b 96000 "$CACHE/adhan-source.mp3" "$OUT/adhan_full.m4a"

fetch makkah.webm "$COMMONS/a/a7/Adhan%2C_Great_Mosque_of_Mecca_-_Jan_21%2C_2013.webm"
build makkah.webm adhan_makkah 4

fetch fakhri.mp3 "$COMMONS/2/27/Call_to_prayer_by_Sabah_Fakhry.mp3"
build fakhri.mp3 adhan_fakhri 2.3

for file in "$OUT"/adhan*; do
    echo "$(basename "$file"): $(afinfo "$file" | grep -E "estimated duration" | sed 's/.*: //')"
done
