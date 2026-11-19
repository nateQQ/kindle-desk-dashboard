# Kindle desk dashboard

Turn an old, jailbroken Kindle Paperwhite into a desk dashboard that shows the clock, date, weather, air quality and your Claude usage (5-hour session and weekly limit). The dashboard runs on the Kindle itself as a KOReader plugin. A tiny script on your computer serves the Claude numbers over your home network.

This repo is the complete, tested path, written from a real run on a **Paperwhite 3 (7th gen) on firmware 5.16.2.1.1**: backup, jailbreak, KUAL, KOReader, the plugin, and the usage server. It also lists the problems that actually came up and how they were fixed.

> Be realistic about the result. E-ink refreshes every 5 minutes at best, the Kindle has to stay plugged in (it keeps Wi-Fi on and never sleeps), and jailbreaking wipes the Kindle's content. This is a fun experiment for an old device. If you want live AI usage on a desk, a purpose-built device is a better tool.

## What you get

- Full-screen dashboard in KOReader: clock, date, optional Vietnamese lunar calendar, weather, UV, air quality, 3-day forecast.
- Two Claude usage bars (5-hour session and weekly) with a time-elapsed marker and reset time.
- English UI by default, Vietnamese with `lang = "vi"`. Default location is Ho Chi Minh City, change it in `config.lua`.

## How it works

```
 Mac / PC (always on)                           Kindle (plugged in)
 ┌──────────────────────────┐   Wi-Fi 2.4GHz    ┌───────────────────────────────┐
 │ usage-server.mjs :8466   │ <───────────────  │ KOReader + deskdashnative     │
 │  reads Claude usage      │   GET usage.json  │  redraws every 5 min          │
 └──────────────────────────┘                   │  weather from Open-Meteo      │
                                                └───────────────────────────────┘
```

The Kindle cannot see your Claude usage by itself, so the server hands it two numbers over HTTP. Weather comes straight from Open-Meteo (free, no key).

## Requirements

- Kindle on **firmware 5.16.2.1.1 or lower** (this is the limit of the LanguageBreak jailbreak). Check it in Settings > Device Options > Device Info. **If your firmware is newer, stop here.** Do not update it either, before or after.
- A USB cable that carries data, not a charge-only one.
- A computer that stays on in the same network as the Kindle (macOS for the helper scripts; the steps work on any OS if you copy by hand). Node 18 or newer for the usage server.
- Kindle Wi-Fi on a **2.4 GHz** network.

## Steps

Follow the docs in order. Each one ends with a way to check it worked.

| Step | Doc |
|---|---|
| 0 | [Before you start: risks, firmware check](docs/00-before-you-start.md) |
| 1 | [Back up your books](docs/01-backup.md) |
| 2 | [Jailbreak with LanguageBreak](docs/02-jailbreak.md) |
| 3 | [Hotfixes and KUAL](docs/03-hotfix-and-kual.md) |
| 4 | [KOReader and the plugin](docs/04-koreader-and-plugin.md) |
| 5 | [The usage server](docs/05-usage-server.md) |
| - | [Troubleshooting](docs/06-troubleshooting.md) |
| - | [Going back to stock](docs/07-restore.md) |

Quick preparation of all files:

```bash
scripts/fetch-files.sh      # downloads every upstream file and verifies SHA-256
scripts/prepare.sh          # builds the staging/ folders (1, 2a, 2b, 3, 4) you copy to the Kindle, one per USB session
```

## Repo layout

```
plugin/deskdashnative.koplugin   the KOReader plugin (edit config.lua)
server/usage-server.mjs          serves the Claude numbers over your LAN
server/statusline-usage.py       optional Claude Code status line helper
scripts/                         fetch, prepare, copy-to-Kindle helpers
docs/                            the step-by-step guide
```

No jailbreak binaries are stored in this repo. `fetch-files.sh` downloads them from their official release pages and checks the hashes.

## Safety

Jailbreaking can brick a device and may void the warranty (community guides say so). LanguageBreak replaces parts of the Kindle's system, and it deletes everything in the user storage. Back up first, and read [going back to stock](docs/07-restore.md) before you start, not after. You do all of this at your own risk.

## Credits

- Plugin base: **Cauhuyy**, "Man hinh de ban cho Kindle (KOReader)" guide and `kindle-dashboard-native.zip`. See [NOTICE.md](NOTICE.md).
- Jailbreak: [LanguageBreak](https://github.com/notmarek/LanguageBreak) by Marek, with thanks to Bluebotlabs, GeorgeYellow and bulltricks.
- Hotfix: [KindleModding/Hotfix](https://github.com/KindleModding/Hotfix). KUAL loader: [PEKI](https://github.com/KindleTweaks/PEKI). MRPI: [Marek's khf build](https://fw.notmarek.com/khf/).
- Reading the guides at [kindlemodding.org](https://kindlemodding.org/) is the best way to understand each step.
- Lunar calendar algorithm: Ho Ngoc Duc. Weather: [Open-Meteo](https://open-meteo.com/). Reader: [KOReader](https://github.com/koreader/koreader).
