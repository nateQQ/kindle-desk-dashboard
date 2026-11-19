# 4. KOReader and the plugin

## A. Edit the plugin config first

Open `plugin/deskdashnative.koplugin/config.lua` (or the copy under `staging/4-koreader/koreader/plugins/` after `prepare.sh`; edit it before copying):

| Key | What it does |
|---|---|
| `lang` | `"en"` (default) or `"vi"` |
| `show_lunar` | `false` hides the Vietnamese lunar block |
| `lat`, `lon`, `tz_offset` | location for weather and time zone (default Ho Chi Minh City) |
| `usage_url` | URL of the usage server, `http://<computer IP>:8466/<code>/usage.json`. Leave empty to hide the Claude bars |
| `interval_sec` | redraw period, default 300 s (5 min), aligned to :00, :05, ... |
| `weather_ttl` | reload weather at most every 600 s |
| `full_refresh_every` | every 6th redraw is a full flashing refresh to clear ghosting (about 30 min) |
| `retry_sec` | after a failed fetch, retry in 60 s |

Do step 5 (usage server) before filling `usage_url`, or fill it now and start the server after.

## B. Copy KOReader

```bash
scripts/copy-to-kindle.sh staging/4-koreader    # about 85 MB: extensions/koreader + koreader/ + the plugin
```

Open **KUAL > KOReader**. The first start can take a while.

## C. Settings inside KOReader

These settings live in the **gear (Settings) menu**, not under a "Device" entry. On the v2026.07.1 build we used, the menu order has `Auto standby`, `Auto suspend timeout` and `Auto shutdown timeout` together near the middle of the list, so you may have to go to the second or third page of the menu.

1. Set **Auto suspend** and **Auto shutdown** to never.
2. **Network**: Wi-Fi on automatically, do not auto-disconnect. Connect the Kindle to a **2.4 GHz** Wi-Fi (the airplane mode you used so far has to go off now).
3. **Frontlight**: turn it down or off for a desk display. The control is the sun icon in KOReader's top menu bar (or in the gear menu on some builds). Close the dashboard first (tap the bottom-left label), then change it. The setting is remembered. The exact menu labels may differ slightly between KOReader versions.

## D. Open the dashboard

Menu > Tools > **Desk dashboard (runs on device)**. The plugin keeps the Kindle awake while the dashboard is open and redraws on its own.

Taps: circular arrow (top right) reloads now, rotate icon switches portrait and landscape, the bottom-left label exits.

## Check

- The clock and weather appear.
- With the server running, the two Claude bars show numbers (otherwise "no data").
- Leave it plugged in. Battery use while unplugged was not measured on this build.

Next: [5. The usage server](05-usage-server.md).
