#!/bin/bash
# Downloads the upstream files this guide needs into ./downloads and checks their SHA-256.
# Nothing here is redistributed by this repo; every file comes from its official source.
# Usage: scripts/fetch-files.sh
set -euo pipefail
cd "$(dirname "$0")/.."
mkdir -p downloads && cd downloads

get() {  # name url sha256
  local name=$1 url=$2 sum=$3
  if [ ! -f "$name" ]; then echo "Downloading $name"; curl -fL --progress-bar -o "$name" "$url"; fi
  local got; got=$(shasum -a 256 "$name" | cut -d' ' -f1)
  if [ "$got" != "$sum" ]; then
    echo "CHECKSUM MISMATCH for $name"; echo "  expected $sum"; echo "  got      $got"
    echo "  The upstream file may have been updated. Read its release notes before using it, then update the checksum here."
    exit 1
  fi
  echo "OK  $name"
}

get LanguageBreak-16.11.23.tar.gz  https://github.com/notmarek/LanguageBreak/releases/download/1.0.2.1/LanguageBreak-16.11.23.tar.gz  b995cd6c687d007a166f0459dbb39d75de32a24e85be09fe3d911a0eb3736b5f
get Update_hotfix_universal.bin    https://github.com/KindleModding/Hotfix/releases/download/2.5.0/Update_hotfix_universal.bin          94d5c05254b70c4905392515411f620168ac238db62c7dcbc48a1e31d5de6c59
get PEKI.zip                       https://github.com/KindleTweaks/PEKI/releases/latest/download/PEKI.zip                               f653045909ed230496c3d8176c9901d3a6a1f693c52b488569be6a60e0852499
get kual-mrinstaller-khf.zip       https://kindlemodding.org/jailbreaking/Legacy/post-jailbreak/installing-kual-mrpi/kual-mrinstaller-khf.zip  9974dfc2d1e7687b3fc74d68f6b5aeab2428f22d83ab82e6d600a0384c607d09
get koreader-kindlepw2-v2026.07.1.zip https://github.com/koreader/koreader/releases/download/v2026.07.1/koreader-kindlepw2-v2026.07.1.zip ea1f575c54492a2c679d128b7f3210fd7d6a87e5f5a1ff1f7a7fe2080ff68f86

echo "All files verified."
