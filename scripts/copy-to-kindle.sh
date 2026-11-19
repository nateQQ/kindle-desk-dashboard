#!/bin/bash
# Waits for the Kindle to appear as a USB drive, removes stray update files, copies a folder to its root,
# cleans macOS junk files and ejects it.
# Usage: scripts/copy-to-kindle.sh staging/1-languagebreak
# macOS only (uses /Volumes and diskutil). On Linux copy the folder by hand with `cp -R <folder>/. /media/.../Kindle/`.
# macOS may ask once to let Terminal access removable volumes.
set -u
SRC=${1:-}; [ -d "$SRC" ] || { echo "Usage: $0 <folder to copy>"; exit 1; }
echo "Waiting for the Kindle (up to 15 minutes)..."
VOL=""
for _ in $(seq 1 1800); do
  for v in /Volumes/Kindle /Volumes/KINDLE; do [ -d "$v" ] && VOL=$v; done
  [ -n "$VOL" ] && break; sleep 0.5
done
[ -n "$VOL" ] || { echo "No Kindle found"; exit 1; }
sleep 1
# LanguageBreak asks for no stray update files before every copy
find "$VOL" -maxdepth 1 \( -name '*.bin' -o -name 'update.bin.tmp.partial' \) -print -delete
COPYFILE_DISABLE=1 cp -R -X "$SRC"/. "$VOL"/ && sync
dot_clean -m "$VOL" 2>/dev/null; find "$VOL" -name '._*' -delete 2>/dev/null; sync
echo "Copied. Root of the Kindle now:"; ls -la "$VOL" | head -30
diskutil eject "$VOL" && echo "Ejected, you can unplug the cable."
