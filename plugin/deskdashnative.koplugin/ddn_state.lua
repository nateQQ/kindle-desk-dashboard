-- Gom dữ liệu (giờ, âm lịch, thời tiết, trích dẫn, pin...) thành bảng `st` cho render.lua.
local Lunar = require("ddn_lunar")
local Usage = require("ddn_usage")
local I18n = require("ddn_i18n")
local Weather = require("ddn_weather")

local S = {}


-- cfg: cấu hình; now: os.time() (UTC); raw: dữ liệu Open-Meteo thô (hoặc nil);
-- dev: {batt=, chg=, wifi=, stale=}; usage_raw: JSON thô từ Mac (hoặc nil)
function S.build(cfg, now, raw, dev, usage_raw)
    I18n.set(cfg.lang or "en")
    local d = os.date("!*t", now + (cfg.tz_offset or 7) * 3600)
    local li = Lunar.info(d.day, d.month, d.year)
    local dm = string.format("%02d/%02d", li.day, li.month) .. (li.leap == 1 and I18n.t("leap") or "")
    local lunar = {
        dm = dm, year_cc = li.year_cc, month_cc = li.month_cc, day_cc = li.day_cc,
        term = li.term, term_up = (I18n.lang == "vi") and li.term_up or I18n.arr("terms_up")[li.term_idx],
    }
        local usage
    if usage_raw then
        local okU, resU = pcall(Usage.normalize, usage_raw, now)
        if okU then usage = resU end
    end

    local wx
    if raw then
        local ok, res = pcall(Weather.normalize, raw, d)
        if ok then wx = res end
    end

    return {
        title = cfg.title, footer = cfg.footer, font_scale = cfg.font_scale,
        interval_min = math.max(1, math.floor((cfg.interval_sec or 300) / 60 + 0.5)),
        time = string.format("%02d:%02d", d.hour, d.min),
        date_str = I18n.date_str(d),
        show_lunar = cfg.show_lunar ~= false,
        lunar = lunar,
        count = {
            n1 = Lunar.days_until(d.day, d.month, d.year, 1),
            n15 = Lunar.days_until(d.day, d.month, d.year, 15),
        },
        wx = wx,
        usage = usage, tz = cfg.tz_offset or 7,
        batt = dev and dev.batt, chg = dev and dev.chg, wifi = not dev or dev.wifi ~= false,
        stale = dev and dev.stale or false,
        usage_stale = dev and dev.usage_stale or false,
    }
end

return S
