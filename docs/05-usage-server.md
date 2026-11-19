# 5. The usage server

The Kindle cannot read your Claude usage, so a script on a computer in your home network serves two numbers.

## Setup

```bash
cd server
cp config.example.json config.json
# edit config.json: set "code" to a long random string (the code is the only protection)
node usage-server.mjs
```

Check from another device on the network:

```bash
curl http://<computer IP>:8466/<code>/usage.json
# {"luc":1795075622,"nam_gio":{"pt":14,"reset":1795087779},"tuan":{"pt":38,"reset":1795474779}}
```

`nam_gio` = 5-hour session, `tuan` = week, `pt` = percent used, `reset` = epoch seconds when the window resets. When no fresh data exists the server returns `{}` and the Kindle shows "no data". Data older than `max_age_sec` (default 2 hours) is ignored on purpose, so the Kindle never shows an old number as if it were current.

Put `http://<computer IP>:8466/<code>/usage.json` into `usage_url` in `config.lua`.

## Data source

The server tries these in order and uses the first fresh one:

1. **Claude Code status line helper** (`statusline-usage.py`). Claude Code pipes `rate_limits` into your status line command. Call the helper from that command:
   ```bash
   input=$(cat)
   echo "$input" | python3 /path/to/server/statusline-usage.py >/dev/null
   ```
   It writes `~/.kindle-desk/usage.json` with only the two percentages and their reset times. This updates whenever Claude Code runs.
2. **ClawTicker daemon** (optional). Set `clawticker_url` (for example `http://127.0.0.1:8787/payload`) and `clawticker_token_file` in `config.json`. The server reads the bearer token from that file locally and never prints or serves it. The daemon's `t` field holds the local time stuffed into an epoch, so the server converts it back to a real UTC epoch. Pick the account with `clawticker_account` (default `Personal`).

We started with a third source, the Claude desktop app's usage history file, and removed it: it only updates when the app writes it and was 8 days old when we first noticed. Do not use a source that can silently go stale.

## Run it permanently with pm2

```bash
cd server
cp ecosystem.config.example.cjs ecosystem.config.cjs
pm2 start ecosystem.config.cjs && pm2 save
```

Use the ecosystem file. `pm2 start /path with spaces/usage-server.mjs` ends up trying to run the file with `/bin/bash`.

If you start pm2 from inside a Claude Code session, start it with a clean environment (`env -i HOME=$HOME PATH=... pm2 start ...`) so session tokens do not get saved in pm2's dump.

## Give the computer a fixed IP

The Kindle stores the server's IP in `usage_url`. If your router hands out a new address, the Kindle loses the server. Reserve a fixed IP for the computer in your router's DHCP settings.

## Security

HTTP only, no TLS, protected by the random code in the path. Keep it inside your home network. Do not forward the port, do not put it on a public address.
