-- Fetch Claude usage (5-hour + weekly) from a Mac on the home LAN: GET <usage_url> -> JSON
-- {"luc": epoch, "nam_gio": {"pt": 29, "reset": epoch}, "tuan": {"pt": 16, "reset": epoch}}
-- (same shape as ~/.kindle-desk/usage.json written by server/statusline-usage.py). Plain HTTP, LAN only.
local I18n = require("ddn_i18n")
local M = {}

local function http_get(url, cfg)
    local ltn12 = require("ltn12")
    local socket = require("socket")
    local socketutil = require("socketutil")
    local json = require("json")
    local http = require("socket.http")
    local chunks = {}
    socketutil:set_timeout(cfg.usage_connect_timeout or 6, cfg.usage_total_timeout or 15)
    local ok, code = pcall(function()
        return socket.skip(1, http.request{ url = url, method = "GET", sink = ltn12.sink.table(chunks) })
    end)
    socketutil:reset_timeout()
    if not ok then return nil, tostring(code) end
    if code ~= 200 then return nil, "HTTP " .. tostring(code) end
    local ok2, data = pcall(json.decode, table.concat(chunks))
    if not ok2 or type(data) ~= "table" then return nil, "bad JSON" end
    return data
end

-- trả về bảng thô hoặc nil, lỗi
function M.fetch(cfg)
    if type(cfg.usage_url) ~= "string" or cfg.usage_url == "" then return nil, "usage_url not set" end
    return http_get(cfg.usage_url, cfg)
end

local function pick(x)
    if type(x) ~= "table" then return nil end
    local pt = tonumber(x.pt)
    if not pt then return nil end
    return { pct = math.max(0, math.min(100, pt)), reset = tonumber(x.reset) }
end

-- now: os.time() (UTC epoch). Cửa sổ đã qua giờ reset -> coi như 0%.
function M.normalize(raw, now)
    local out = { five = pick(raw.nam_gio), week = pick(raw.tuan) }
    local luc = tonumber(raw.luc)
    if luc then out.age = math.max(0, now - luc) end
    for _, k in ipairs({ "five", "week" }) do
        local w = out[k]
        if w and w.reset and w.reset < now then w.pct, w.reset = 0, nil end
    end
    out.now = now
    return out
end

-- "18:38" nếu trong hôm nay, còn lại "T3 24/11 18:00"
function M.reset_text(reset, now, tz)
    if not reset then return "--" end
    local r = os.date("!*t", reset + tz * 3600)
    local n = os.date("!*t", now + tz * 3600)
    local hm = string.format("%02d:%02d", r.hour, r.min)
    if r.year == n.year and r.month == n.month and r.day == n.day then return hm end
    return string.format("%s %02d/%02d %s", I18n.arr("weekday_short")[r.wday], r.day, r.month, hm)
end

function M.remain_text(reset, now)
    if not reset then return "" end
    local s = reset - now
    if s <= 0 then return "" end
    local d, h, m = math.floor(s / 86400), math.floor(s % 86400 / 3600), math.floor(s % 3600 / 60)
    if d > 0 then return I18n.t("left_d", d, h) end
    if h > 0 then return I18n.t("left_h", h, m) end
    return I18n.t("left_m", math.max(m, 1))
end

-- vị trí vạch nhịp (0..1): đã trôi qua bao nhiêu phần của cửa sổ thời gian
function M.pace(reset, now, window)
    if not reset then return nil end
    local f = 1 - (reset - now) / window
    return math.max(0, math.min(1, f))
end

function M.age_text(age)
    if not age then return "" end
    if age < 120 then return I18n.t("just_now") end
    if age < 3600 then return I18n.t("age_min", math.floor(age / 60)) end
    return I18n.t("age_hour", math.floor(age / 3600))
end

return M
