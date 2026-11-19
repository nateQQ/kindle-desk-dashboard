# Troubleshooting

Everything here happened on a real Paperwhite 3, firmware 5.16.2.1.1, unless noted.

## Stuck on the Configure Device screen

"This demonstration device is either missing content or is disconnected from the network / CONFIGURE DEVICE" is a normal step of the demo setup, not an error. The way past it is the secret gesture. Try all three variants, quickly (see [step 2](02-jailbreak.md)). The Kindle does not mount as a USB drive while you are on this screen, so the computer will not see it until you reach the Sideload Content menu.

Reports of people staying stuck exist ([MobileRead thread](https://www.mobileread.com/forums/showthread.php?t=287717)). One worked around it with a factory reset; the Bookfere guide describes a reset by placing an empty file named `DO_FACTORY_RESTORE` in the Kindle root from the Demo Menu's Import Content, then reinstalling the same firmware. We did not need either.

## The computer does not see the Kindle

- Use a data cable, plug straight into the computer (no hub).
- After typing `;uzb` the Kindle mounts after a few seconds. Unplug and replug if needed.
- In demo mode the Kindle only mounts from the Sideload Content screen.

## KUAL does not appear in the library

`KUAL.sh` and `KUAL.jar` are in `documents` but there is no KUAL item. Install the newer hotfix `Update_hotfix_universal.bin` through Update Your Kindle ([step 3B](03-hotfix-and-kual.md)). This was the fix on our device and matches [LanguageBreak issue 78](https://github.com/notmarek/LanguageBreak/issues/78). Other causes people reported (not our case): too little free space (up to 220 MB is recommended for KUAL and MRPI), and a file name with spaces or brackets.

## "no MR packages found"

Shown if you run `;log mrpi`. Expected when `mrpackages` is empty. It does not mean KUAL failed to install.

## A `KPPMainApp...crash...` file in the library

A crash log written during the jailbreak. Harmless. You can delete it.

## Dashboard shows an old or wrong Claude number

The server returns `{}` when the data is older than two hours, and the Kindle then shows "no data". If you see a plausible but wrong number, check which source the server is reading and its timestamp (`luc` in `usage.json`). We hit this once with a stale source file.

## Dashboard shows "no data" or "not connected"

- Is the Kindle on the same 2.4 GHz network as the computer?
- Does `curl http://<ip>:8466/<code>/usage.json` work from another device?
- Did the computer's IP change? Reserve a fixed IP in the router.

## Settings for sleep and Wi-Fi not found in KOReader

They are in the gear (Settings) menu, further down the list, on later pages. See [step 4](04-koreader-and-plugin.md).

## Whatever else

Search the [LanguageBreak thread on MobileRead](https://www.mobileread.com/forums/showthread.php?t=356872) and the [LanguageBreak issues](https://github.com/notmarek/LanguageBreak/issues) first. Many problems are already answered there.
