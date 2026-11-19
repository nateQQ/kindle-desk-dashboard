// Serves your Claude usage to the Kindle over the local network.
//   GET http://<this machine>:<port>/<code>/usage.json
//   -> {"luc": <epoch>, "nam_gio": {"pt": 14, "reset": <epoch>}, "tuan": {"pt": 38, "reset": <epoch>}}
//      (nam_gio = 5-hour session, tuan = weekly; pt = percent used; the keys are what the plugin reads)
//
// HTTP only, home network only: the random <code> in the path is the only protection. Never expose it to the internet.
// Read-only: it never writes anything and returns {} when the data is older than MAX_AGE (the Kindle then shows "no data").
//
// Data sources, first fresh one wins:
//   1. Claude Code status line helper (statusline-usage.py) -> ~/.kindle-desk/usage.json   (percent + reset time)
//   2. Optional ClawTicker daemon (https://github.com/nateQQ/clawticker): set CLAWTICKER_URL and
//      CLAWTICKER_TOKEN_FILE (see docs/05-usage-server.md). The daemon's `t` field is local time stuffed into an epoch,
//      so the server converts it back to a real UTC epoch.
//
// Config: config.json next to this file (copy config.example.json) or env CODE / PORT.
import http from 'node:http';
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const readJson = (f) => { try { return JSON.parse(fs.readFileSync(f, 'utf8')); } catch { return null; } };
const cfg = readJson(path.join(HERE, 'config.json')) || {};
const CODE = process.env.CODE || cfg.code;
const PORT = Number(process.env.PORT || cfg.port || 8466);
const MAX_AGE = Number(cfg.max_age_sec || 2 * 3600);
const ACCOUNT = cfg.clawticker_account || 'Personal';
const CLAW_URL = process.env.CLAWTICKER_URL || cfg.clawticker_url || '';
const CLAW_TOKEN_FILE = process.env.CLAWTICKER_TOKEN_FILE || cfg.clawticker_token_file || '';
if (!CODE) { console.error('Missing "code": copy config.example.json to config.json and set a random code'); process.exit(1); }

const fromStatusline = () => {
  const a = readJson(path.join(os.homedir(), '.kindle-desk/usage.json'));
  return a?.luc ? { luc: a.luc, nam_gio: a.nam_gio, tuan: a.tuan } : null;
};

async function fromClawTicker() {
  if (!CLAW_URL || !CLAW_TOKEN_FILE) return null;
  let token;
  try { token = fs.readFileSync(CLAW_TOKEN_FILE.replace(/^~/, os.homedir()), 'utf8').trim(); } catch { return null; }
  try {
    const r = await fetch(CLAW_URL, { headers: { Authorization: `Bearer ${token}` }, signal: AbortSignal.timeout(3000) });
    if (!r.ok) return null;
    const p = await r.json();
    const list = Array.isArray(p.a) ? p.a : [];
    const acc = list.find((x) => x.n === ACCOUNT) || list[0];
    if (!acc || !p.t || typeof acc.s !== 'number' || typeof acc.w !== 'number') return null;
    // s/w = percent (5h/week), sr/wr = minutes until reset, counted from p.t
    const t = p.t - Math.round((p.t - Date.now() / 1000) / 3600) * 3600;
    return { luc: t, nam_gio: { pt: acc.s, reset: t + acc.sr * 60 }, tuan: { pt: acc.w, reset: t + acc.wr * 60 } };
  } catch { return null; }
}

async function usage() {
  const now = Date.now() / 1000;
  for (const src of [fromStatusline, fromClawTicker]) {
    const u = await src();
    if (u && now - u.luc < MAX_AGE) return u;
  }
  return {};
}

http.createServer(async (req, res) => {
  if (req.url.split('?')[0] === `/${CODE}/usage.json`) {
    res.writeHead(200, { 'content-type': 'application/json', 'cache-control': 'no-store' });
    return res.end(JSON.stringify(await usage()));
  }
  res.writeHead(404); res.end();
}).listen(PORT, '0.0.0.0', () => console.log(`Serving Claude usage on port ${PORT}`));
