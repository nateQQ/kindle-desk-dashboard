# 2. Jailbreak with LanguageBreak

Based on the [LanguageBreak README](https://github.com/notmarek/LanguageBreak) and the [Bookfere walkthrough](https://en.bookfere.com/post/kindle-jailbreak-instruction-5-16-2-1-1.html). Read the whole page before you touch the Kindle. **Airplane mode on, passcode off, backup done.**

Folder `staging/1-languagebreak` (from `scripts/prepare.sh`) holds the files you copy. `scripts/copy-to-kindle.sh <folder>` waits for the Kindle, removes stray `.bin` files, copies, and ejects.

## A. Enter demo mode

1. On the Kindle home screen, tap the search icon, type `;enter_demo`, press Enter. Choose **Restart**.
2. The Kindle boots into demo setup. **Skip Wi-Fi.** On "Register Demo Unit" type random characters, Continue.
3. "Getting optional demo type": **Skip**, then pick **Standard**.
4. "Demo Mode: Add Content": tap **Done**. The screen may stay white for a while.
5. When the screensaver appears, tap the screen. You land on a **Configure Device** screen ("This demonstration device is either missing content or is disconnected from the network"). This is a normal step, not an error.
6. Get past it with the **secret gesture**: tap the bottom-right corner with two fingers, then swipe left right away. If it does not work try these variants: press and hold the bottom-right corner with two fingers, lift one finger, then swipe left; or hold with two fingers and swipe left horizontally. Do it quickly and decisively. You end up in the normal library.

## B. Sideload the jailbreak, twice

1. In the library type `;demo`, Enter, then choose **Sideload Content**. The Kindle now mounts as a USB drive.
2. Plug in and run `scripts/copy-to-kindle.sh staging/1-languagebreak` (copy 1). It ejects at the end. Unplug.
3. On the Kindle tap **Done** to go back to the Demo Menu, choose **Resell Device**, confirm with Yes/Resell.
4. Wait for the **"press power button"** screen (a diagram of the Kindle buttons).
5. **The moment it appears**, plug the Kindle in again and run the same copy command (copy 2, overwriting). Eject, unplug.
6. Hold the power button as the screen says. After a few seconds a **language menu** appears.
7. Choose **Chinese** (the one above the odd "Pseudot" language, below Japanese; Bookfere calls it Simplified Chinese), then Next.
8. The Kindle reboots and prints log text on the screen.

## C. Check it worked

Type `;uzb` in the search box and plug the Kindle in. In the Kindle's root you should see `LanguageBreakRan` and `languagebreak_log`. The log ends with:

```
Enabled developer flag
Enabled mntus exec flag
Finished installing jailbreak!
```

On our run the log also showed a `/etc/uks.sqsh - exists - replacing whole sqshfs` line, which is normal.

## If you get stuck

- Stuck on Configure Device: [troubleshooting](06-troubleshooting.md#stuck-on-the-configure-device-screen).
- A "Collecting Debug Info" dialog means the steps were retried wrongly. Bookfere says reset and start over.
- Do not connect to Wi-Fi to "fix" it.

Next: [3. Hotfixes and KUAL](03-hotfix-and-kual.md).
