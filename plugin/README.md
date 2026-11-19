# Desk dashboard for Kindle (KOReader plugin) - NateCue edition

A full-screen e-ink desk dashboard that runs directly on a jailbroken Kindle through KOReader: clock, date, optional Vietnamese lunar calendar, weather, UV, air quality, a 3-day forecast, and two Claude usage bars (5-hour session and weekly) with a time-elapsed marker.

Based on the `deskdashnative` plugin by Cauhuyy (see Credits). Changes in this edition: English UI by default (`lang = "vi"` for Vietnamese), quote band removed, Claude usage section added, lunar block optional, default location Ho Chi Minh City.

Tested on a real Paperwhite 3 (7th gen), firmware 5.16.2.1.1, KOReader v2026.07.1 `kindlepw2`. Other models are untested.

## What you need
- A jailbroken Kindle running KOReader (Paperwhite 3 on firmware 5.16.2.1.1 or lower: KOReader `kindlepw2` package).
- Wi-Fi on the same network as the Mac that serves Claude usage (optional, only for the Claude bars).
- Keep the Kindle plugged in: it stays awake and keeps Wi-Fi on to refresh every 5 minutes.

## Install
1. Copy the `deskdashnative.koplugin` folder to `koreader/plugins/` on the Kindle.
2. Edit `config.lua` (location, `lang`, `show_lunar`, `usage_url`).
3. Restart KOReader. Open it from Menu > Tools > "Desk dashboard (runs on device)".
4. In KOReader's gear (Settings) menu: auto suspend and auto shutdown = never (they are further down the list); Network: turn Wi-Fi on automatically, do not auto-disconnect; turn the frontlight off. Details in `../docs/04-koreader-and-plugin.md`.

Taps: top-right circular arrow = reload now, rotate icon = portrait/landscape, bottom-left label = exit.

## Claude usage bars
The Kindle cannot read your Claude usage by itself. A small script on a computer in your network serves it. See `../server/` and `../docs/05-usage-server.md`. Put the resulting URL in `usage_url`. HTTP only, LAN only, the random code in the path is the only protection. Do not expose it to the internet.

## Config reference
See comments in `config.lua`. `lang`: `en` or `vi`. `show_lunar = false` hides the lunar block and the 1st/15th countdown.

## Credits
Original plugin and layout: Cauhuyy (no license file in the original package, see ../NOTICE.md), "Man hinh de ban cho Kindle (KOReader)" guide and `kindle-dashboard-native.zip` (https://docs.google.com/document/d/1X5L4N2Q_aZTKDp8HUqOZ8CY1b7IUzaSehEL6qthafK0/edit). Lunar calendar algorithm: Ho Ngoc Duc. Weather: Open-Meteo.
