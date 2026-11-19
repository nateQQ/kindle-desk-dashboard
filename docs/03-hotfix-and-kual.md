# 3. Hotfixes and KUAL

## A. First hotfix (takes the Kindle out of demo mode)

1. On the Kindle, type `;uzb`. Plug the Kindle in.
2. `scripts/copy-to-kindle.sh staging/2a-hotfix-languagebreak` copies `Update_hotfix_languagebreak-en-US.bin` to the Kindle root.
3. Eject. On the Kindle type `;dsts` (or swipe down and open Settings), choose **Update Your Kindle**. It installs the hotfix and reboots. Pick another language file from the LanguageBreak tarball if you want a different language than en-US.
4. When it comes back you should be in the normal library in English. Plug in and check for a folder named `mkk` in the Kindle root. If `mkk` is missing, copy `1-languagebreak` again and redo the hotfix.

A registered Kindle may land in "managed mode". The LanguageBreak README has an "Exiting managed/demo mode" section for that: `;demo`, the right button, and the device resets into normal mode.

## B. Newer hotfix (needed on our Paperwhite 3)

The LanguageBreak tarball's hotfix is older and **lacks the `sh_integration` update**. Without it, `KUAL.sh` and `KUAL.jar` sit in `documents` but never show up in the library. This matches [LanguageBreak issue 78](https://github.com/notmarek/LanguageBreak/issues/78) (same device and firmware); the author's answer was to use the latest hotfix from [KindleModding/Hotfix](https://github.com/KindleModding/Hotfix/releases).

We installed `Update_hotfix_universal.bin` 2.5.0 the same way, as a second round: `scripts/copy-to-kindle.sh staging/2b-hotfix-universal`, then **Update Your Kindle** again. KUAL showed up after that. We ran them in this order (language hotfix first, universal second) and did not test other orders. Doing this before copying KUAL avoids the missing-KUAL problem.

## C. Install KUAL and MRPI

Copy `staging/3-kual` (this holds `documents/KUAL.sh`, `documents/KUAL.jar`, `extensions/MRInstaller`, `mrpackages`). Eject, restart if needed, wait a couple of minutes, refresh the library.

You should see a **KUAL** item in the library. Tap it to open.

Notes from our run:

- You do not need `;log mrpi` to make KUAL appear. If you type it you may see **"no MR packages found"**. That is normal: `mrpackages` is empty because nothing needs installing through MRPI here, and it only means MRPI itself runs.
- KUAL needs some free space (the guide says up to 220 MB for KUAL and MRPI). Keep airplane mode on while freeing space so the Kindle does not download an update into it.
- If a file name has a space or brackets, rename it. Browsers add `(1)` when you download twice.

Next: [4. KOReader and the plugin](04-koreader-and-plugin.md).
