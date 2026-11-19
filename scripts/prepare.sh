#!/bin/bash
# Unpacks the downloads into ./staging/ in the exact folder layout you copy to the Kindle, one folder per USB session:
#   staging/1-languagebreak   copy twice (before and after "Resell Device")
#   staging/2a-hotfix-languagebreak   the hotfix from the LanguageBreak tarball (copy first)
#   staging/2b-hotfix-universal       the newer KindleModding hotfix (copy second)
#   staging/3-kual            KUAL + MRPI
#   staging/4-koreader        KOReader + this repo's plugin
# Usage: scripts/prepare.sh   (run scripts/fetch-files.sh first)
set -euo pipefail
cd "$(dirname "$0")/.."
D=downloads; S=staging
for f in LanguageBreak-16.11.23.tar.gz Update_hotfix_universal.bin PEKI.zip kual-mrinstaller-khf.zip koreader-kindlepw2-v2026.07.1.zip; do
  [ -f "$D/$f" ] || { echo "Missing $D/$f, run scripts/fetch-files.sh first"; exit 1; }
done
rm -rf "$S"; mkdir -p "$S"/{1-languagebreak,2a-hotfix-languagebreak,2b-hotfix-universal,3-kual/documents,4-koreader} "$S/.tmp"/{lb,peki,mrpi,kr}

tar -xzf "$D/LanguageBreak-16.11.23.tar.gz" -C "$S/.tmp/lb"
LB=$(find "$S/.tmp/lb" -type d -name LanguageBreak -maxdepth 3 | head -1)
[ -n "$LB" ] || { echo "LanguageBreak folder not found in the archive"; exit 1; }
cp -R "$LB"/. "$S/1-languagebreak/"
# 'Update_hotfix_languagebreak-en-US.bin' ships inside the tarball; pick your language if you want another
HF=$(find "$S/.tmp/lb" -name 'Update_hotfix_languagebreak-en-US.bin' | head -1)
[ -n "$HF" ] && cp "$HF" "$S/2a-hotfix-languagebreak/" || echo "Warning: en-US hotfix not found in the tarball"
cp "$D/Update_hotfix_universal.bin" "$S/2b-hotfix-universal/"

unzip -q "$D/PEKI.zip" -d "$S/.tmp/peki"
cp "$(find "$S/.tmp/peki" -name KUAL.sh | head -1)" "$(find "$S/.tmp/peki" -name KUAL.jar | head -1)" "$S/3-kual/documents/"
unzip -q "$D/kual-mrinstaller-khf.zip" -d "$S/.tmp/mrpi"
for x in "$S"/.tmp/mrpi/*.tar* ; do [ -f "$x" ] && tar -xf "$x" -C "$S/.tmp/mrpi"; done
cp -R "$(find "$S/.tmp/mrpi" -type d -name extensions | head -1)" "$S/3-kual/extensions"
cp -R "$(find "$S/.tmp/mrpi" -type d -name mrpackages | head -1)" "$S/3-kual/mrpackages"

unzip -q "$D/koreader-kindlepw2-v2026.07.1.zip" -d "$S/4-koreader"
cp -R plugin/deskdashnative.koplugin "$S/4-koreader/koreader/plugins/"

rm -rf "$S/.tmp"; find "$S" -name '.DS_Store' -delete
echo "Done. Review staging/4-koreader/koreader/plugins/deskdashnative.koplugin/config.lua (usage_url, location) before copying."
