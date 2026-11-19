# 0. Before you start

## Check the model and firmware

On the Kindle: Settings > Device Options > Device Info (or the three-dot menu > Settings). Note the model and the firmware.

- This guide was run on a **Paperwhite 3 (7th gen)**, firmware **5.16.2.1.1**.
- LanguageBreak works on firmware **5.16.2.1.1 or lower**. The author says it works best around 5.16.2, and warns that on anything newer "everything is broken". If your firmware is newer, do not continue.
- Never update the firmware afterwards, not even when the Kindle asks. Keep Wi-Fi off during the jailbreak so it cannot update itself.

Other models need a different KOReader package. This guide uses `kindlepw2`, which is correct for Paperwhite 2 and newer on this firmware range. Check [kindlemodding.org](https://kindlemodding.org/) for your device before copying anything.

## What gets erased

The jailbreak deletes **everything in the Kindle's user storage** (the `documents` folder with your books). Step 1 backs it up. Content bought from Amazon can be downloaded again from your account, but your own files, highlights and annotations only survive if you copy them.

## Do not do this if

- You use the Kindle daily and cannot be without it for an hour.
- Your firmware is above 5.16.2.1.1.
- You are not willing to risk the device.

## Prepare

1. Disable the screen passcode. If you forget and get stuck on the passcode screen, entering `111222777` factory-resets the Kindle.
2. Battery above 50%.
3. Turn on **airplane mode** and keep it on until step 4 tells you to turn Wi-Fi on.
4. Find a USB cable that carries data.
5. Read [going back to stock](07-restore.md).
6. Run `scripts/fetch-files.sh`, then `scripts/prepare.sh`.

Next: [1. Back up your books](01-backup.md).
