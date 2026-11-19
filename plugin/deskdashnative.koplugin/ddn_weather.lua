-- Lấy thời tiết + AQI từ Open-Meteo (miễn phí, không cần API key) và chuẩn hóa dữ liệu.
local Lunar = require("ddn_lunar")
local I18n = require("ddn_i18n")

local M = {}
local floor = math.floor


-- ---------------------------------------------------------------- tải dữ liệu
local function http_get(url, cfg)
    local ltn12 = require("ltn12")
    local socket = require("socket")
    local socketutil = require("socketutil")
    local json = require("json")
    local http = url:match("^https") and require("ssl.https") or require("socket.http")
    local chunks = {}
    socketutil:set_timeout(cfg.connect_timeout or 10, cfg.total_timeout or 40)
    local ok, code = pcall(function()
        return socket.skip(1, http.request{ url = url, method = "GET", sink = ltn12.sink.table(chunks) })
    end)
    socketutil:reset_timeout()
    if not ok then return nil, tostring(code) end
    if code ~= 200 then return nil, "HTTP " .. tostring(code) end
    local ok2, data = pcall(json.decode, table.concat(chunks))
    if not ok2 or type(data) ~= "table" then return nil, "JSON lỗi" end
    return data
end

-- Trả về bảng {forecast=..., aq=...} hoặc nil, lỗi.
function M.fetch(cfg)
    local q = string.format(
        "latitude=%s&longitude=%s&timezone=auto&forecast_days=4" ..
        "&current=temperature_2m,relative_humidity_2m,apparent_temperature,wind_speed_10m,weather_code" ..
        "&hourly=temperature_2m,precipitation_probability,uv_index" ..
        "&daily=weather_code,temperature_2m_max,temperature_2m_min",
        tostring(cfg.lat), tostring(cfg.lon))
    local forecast, err = http_get("https://api.open-meteo.com/v1/forecast?" .. q, cfg)
    if not forecast then return nil, err end
    local aq = http_get(string.format(
        "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=%s&longitude=%s&timezone=auto&current=us_aqi,pm2_5",
        tostring(cfg.lat), tostring(cfg.lon)), cfg)
    return { forecast = forecast, aq = aq }
end

-- ---------------------------------------------------------------- chuẩn hóa
local function num(v, default)
    if type(v) == "number" then return v end
    return default
end

local function round(v)
    return floor(v + 0.5)
end

-- now: bảng {year, month, day, hour, min} giờ địa phương
function M.normalize(raw, now)
    local fc = raw.forecast
    local cur = fc.current
    local hourly = fc.hourly
    local times = hourly.time
    local now_key = string.format("%04d-%02d-%02dT%02d:%02d", now.year, now.month, now.day, now.hour, now.min)
    local today_key = string.format("%04d-%02d-%02d", now.year, now.month, now.day)

    local start = #times - 5
    for i = 1, #times do
        if times[i] > now_key then start = i; break end
    end
    if start < 1 then start = 1 end

    local hours = {}
    for i = start, math.min(start + 5, #times) do
        hours[#hours + 1] = {
            h = times[i]:sub(12, 13),
            temp = round(num(hourly.temperature_2m[i], 0)),
            rain = round(num(hourly.precipitation_probability[i], 0)),
            uv = round(num(hourly.uv_index[i], 0)),
        }
    end

    local uv_peak, uv_hour = 0, now.hour
    for i = 1, #times do
        if times[i]:sub(1, 10) == today_key then
            local u = num(hourly.uv_index[i], 0)
            if u > uv_peak then uv_peak, uv_hour = u, tonumber(times[i]:sub(12, 13)) end
        end
    end

    local d = fc.daily
    local days = {}
    for i = 2, math.min(4, #d.time) do
        local y, m, dd = d.time[i]:match("^(%d+)-(%d+)-(%d+)")
        y, m, dd = tonumber(y), tonumber(m), tonumber(dd)
        days[#days + 1] = {
            label = I18n.day_label(Lunar.weekday(dd, m, y), dd, m),
            code = num(d.weather_code[i], 3),
            tmin = round(num(d.temperature_2m_min[i], 0)),
            tmax = round(num(d.temperature_2m_max[i], 0)),
        }
    end

    local aqi, pm25
    if raw.aq and type(raw.aq.current) == "table" then
        aqi = num(raw.aq.current.us_aqi)
        pm25 = num(raw.aq.current.pm2_5)
        if aqi then aqi = round(aqi) end
    end

    return {
        temp = num(cur.temperature_2m), feels = num(cur.apparent_temperature),
        humidity = cur.relative_humidity_2m and round(num(cur.relative_humidity_2m, 0)) or nil,
        wind = num(cur.wind_speed_10m), code = num(cur.weather_code, 3),
        tmax = round(num(d.temperature_2m_max[1], 0)), tmin = round(num(d.temperature_2m_min[1], 0)),
        hours = hours, uv_peak = round(uv_peak), uv_peak_hour = string.format("%02d", uv_hour),
        days = days, aqi = aqi, pm25 = pm25,
    }
end

-- ---------------------------------------------------------------- text + icons (language in ddn_i18n.lua)
local KIND = {
    [0] = "sun", [1] = "partly", [2] = "partly", [3] = "cloud", [45] = "fog", [48] = "fog",
    [51] = "rain", [53] = "rain", [55] = "rain", [56] = "rain", [57] = "rain",
    [61] = "rain", [63] = "rain", [65] = "rain", [66] = "rain", [67] = "rain",
    [71] = "snow", [73] = "snow", [75] = "snow", [77] = "snow",
    [80] = "rain", [81] = "rain", [82] = "rain", [85] = "snow", [86] = "snow",
    [95] = "storm", [96] = "storm", [99] = "storm",
}

function M.describe(code, short)
    local text = I18n.wcode(code) or I18n.t("unknown")
    if short then text = text:gsub(I18n.strip(), "") end
    return text, KIND[code] or "cloud"
end

function M.uv_label(uv)
    if uv < 3 then return I18n.t("uv1") elseif uv < 6 then return I18n.t("uv2") elseif uv < 8 then return I18n.t("uv3")
    elseif uv < 11 then return I18n.t("uv4") end
    return I18n.t("uv5")
end

-- returns label, bar %, long note, short note
function M.aqi_info(aqi)
    local t = I18n.t
    if not aqi then return t("aqi_na"), 0, t("aqi_n0"), t("aqi_s0") end
    local pct = math.min(100, round(aqi / 200 * 100))
    local i = (aqi <= 50 and 1) or (aqi <= 100 and 2) or (aqi <= 150 and 3) or (aqi <= 200 and 4) or (aqi <= 300 and 5) or 6
    return t("aqi" .. i), pct, t("aqi_n" .. i), t("aqi_s" .. i)
end

-- returns state, long pill, short pill, warning?, long note, short note
function M.hum_info(h)
    local t = I18n.t
    if not h then return "na", "--", "--", false, t("hum_na"), t("hum_na_s") end
    if h > 85 then return "nom", t("hum_wet"), t("hum_wet_s"), true, t("hum_wet_n"), t("hum_wet_ns")
    elseif h < 45 then return "kho", t("hum_dry"), t("hum_dry_s"), true, t("hum_dry_n"), t("hum_dry_ns") end
    return "ok", t("hum_ok"), t("hum_ok_s"), false, t("hum_ok_n"), t("hum_ok_ns")
end

return M
