-- Config for "Desk dashboard (runs on device)". Restart KOReader after editing.
return {
    lang = "en",                    -- "en" (default) or "vi"
    show_lunar = true,              -- Vietnamese lunar calendar block + 1st/15th countdown. Set false outside Vietnam

    -- Location for weather / air quality (default: Ho Chi Minh City)
    lat = 10.78,
    lon = 106.70,
    tz_offset = 7,                  -- hours from UTC

    title = "HO CHI MINH",          -- top-left label (write it in capitals)
    footer = "NateCue",             -- bottom-left label (tap it to exit)

    -- Claude usage bars: URL of the JSON served by your Mac on the home network (see src/usage-server).
    -- Leave empty to show "not connected".
    usage_url = "",                 -- e.g. "http://192.168.1.10:8466/<code>/usage.json"

    interval_sec = 300,             -- redraw every 5 minutes (aligned to :00, :05, :10 ...)
    weather_ttl = 600,              -- reload weather at most every 10 minutes (older data in between saves battery)
    retry_sec = 60,                 -- if a fetch fails: still redraw the clock, retry after this many seconds
    full_refresh_every = 6,         -- every N redraws do one full flashing refresh to clear ghosting (6 x 5' = 30')

    portrait_rotation = 0,          -- KOReader rotation mode for portrait
    landscape_rotation = 1,         -- landscape: 1 = rotate right, use 3 to rotate left

    -- Text too big/small for your screen? Set a fixed value: Paperwhite 3/4 is usually 1.875 (remove = auto-detect).
    -- font_scale = 1.875,

    autostart = false,              -- true: open the dashboard automatically when KOReader starts
    connect_timeout = 10,
    total_timeout = 40,
}
