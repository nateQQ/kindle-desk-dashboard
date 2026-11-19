-- Âm lịch Việt Nam (thuật toán Hồ Ngọc Đức, UTC+7), can chi, tiết khí.
local M = {}

local PI = math.pi
local floor = math.floor
local sin = math.sin
local TZ = 7.0

local CAN = { "Giáp", "Ất", "Bính", "Đinh", "Mậu", "Kỷ", "Canh", "Tân", "Nhâm", "Quý" }
local CHI = { "Tý", "Sửu", "Dần", "Mão", "Thìn", "Tỵ", "Ngọ", "Mùi", "Thân", "Dậu", "Tuất", "Hợi" }
local TERMS = {
    "Xuân phân", "Thanh minh", "Cốc vũ", "Lập hạ", "Tiểu mãn", "Mang chủng",
    "Hạ chí", "Tiểu thử", "Đại thử", "Lập thu", "Xử thử", "Bạch lộ",
    "Thu phân", "Hàn lộ", "Sương giáng", "Lập đông", "Tiểu tuyết", "Đại tuyết",
    "Đông chí", "Tiểu hàn", "Đại hàn", "Lập xuân", "Vũ thủy", "Kinh trập",
}

local TERMS_UP = {
    "XUÂN PHÂN", "THANH MINH", "CỐC VŨ", "LẬP HẠ", "TIỂU MÃN", "MANG CHỦNG",
    "HẠ CHÍ", "TIỂU THỬ", "ĐẠI THỬ", "LẬP THU", "XỬ THỬ", "BẠCH LỘ",
    "THU PHÂN", "HÀN LỘ", "SƯƠNG GIÁNG", "LẬP ĐÔNG", "TIỂU TUYẾT", "ĐẠI TUYẾT",
    "ĐÔNG CHÍ", "TIỂU HÀN", "ĐẠI HÀN", "LẬP XUÂN", "VŨ THỦY", "KINH TRẬP",
}

local function jd_from_date(dd, mm, yy)
    local a = floor((14 - mm) / 12)
    local y = yy + 4800 - a
    local m = mm + 12 * a - 3
    local jd = dd + floor((153 * m + 2) / 5) + 365 * y + floor(y / 4) - floor(y / 100) + floor(y / 400) - 32045
    if jd < 2299161 then
        jd = dd + floor((153 * m + 2) / 5) + 365 * y + floor(y / 4) - 32083
    end
    return jd
end

local function jd_to_date(jd)
    local a, b, c
    if jd > 2299160 then
        a = jd + 32044
        b = floor((4 * a + 3) / 146097)
        c = a - floor((b * 146097) / 4)
    else
        b = 0
        c = jd + 32082
    end
    local d = floor((4 * c + 3) / 1461)
    local e = c - floor((1461 * d) / 4)
    local m = floor((5 * e + 2) / 153)
    local day = e - floor((153 * m + 2) / 5) + 1
    local month = m + 3 - 12 * floor(m / 10)
    local year = b * 100 + d - 4800 + floor(m / 10)
    return day, month, year
end

local function new_moon(k)
    local T = k / 1236.85
    local T2 = T * T
    local T3 = T2 * T
    local dr = PI / 180
    local jd1 = 2415020.75933 + 29.53058868 * k + 0.0001178 * T2 - 0.000000155 * T3
    jd1 = jd1 + 0.00033 * sin((166.56 + 132.87 * T - 0.009173 * T2) * dr)
    local M = 359.2242 + 29.10535608 * k - 0.0000333 * T2 - 0.00000347 * T3
    local Mpr = 306.0253 + 385.81691806 * k + 0.0107306 * T2 + 0.00001236 * T3
    local F = 21.2964 + 390.67050646 * k - 0.0016528 * T2 - 0.00000239 * T3
    local c1 = (0.1734 - 0.000393 * T) * sin(M * dr) + 0.0021 * sin(2 * dr * M)
    c1 = c1 - 0.4068 * sin(Mpr * dr) + 0.0161 * sin(dr * 2 * Mpr)
    c1 = c1 - 0.0004 * sin(dr * 3 * Mpr)
    c1 = c1 + 0.0104 * sin(dr * 2 * F) - 0.0051 * sin(dr * (M + Mpr))
    c1 = c1 - 0.0074 * sin(dr * (M - Mpr)) + 0.0004 * sin(dr * (2 * F + M))
    c1 = c1 - 0.0004 * sin(dr * (2 * F - M)) - 0.0006 * sin(dr * (2 * F + Mpr))
    c1 = c1 + 0.0010 * sin(dr * (2 * F - Mpr)) + 0.0005 * sin(dr * (2 * Mpr + M))
    local dt
    if T < -11 then
        dt = 0.001 + 0.000839 * T + 0.0002261 * T2 - 0.00000845 * T3 - 0.000000081 * T * T3
    else
        dt = -0.000278 + 0.000265 * T + 0.000262 * T2
    end
    return jd1 + c1 - dt
end

local function sun_longitude(jdn)
    local T = (jdn - 2451545.0) / 36525
    local T2 = T * T
    local dr = PI / 180
    local M = 357.52910 + 35999.05030 * T - 0.0001559 * T2 - 0.00000048 * T * T2
    local L0 = 280.46645 + 36000.76983 * T + 0.0003032 * T2
    local DL = (1.914600 - 0.004817 * T - 0.000014 * T2) * sin(dr * M)
    DL = DL + (0.019993 - 0.000101 * T) * sin(dr * 2 * M) + 0.000290 * sin(dr * 3 * M)
    local L = (L0 + DL) * dr
    return L - PI * 2 * floor(L / (PI * 2))
end

local function sun_sector(day_number)
    return floor(sun_longitude(day_number - 0.5 - TZ / 24.0) / PI * 6)
end

local function new_moon_day(k)
    return floor(new_moon(k) + 0.5 + TZ / 24.0)
end

local function lunar_month11(yy)
    local off = jd_from_date(31, 12, yy) - 2415021
    local k = floor(off / 29.530588853)
    local nm = new_moon_day(k)
    if sun_sector(nm) >= 9 then
        nm = new_moon_day(k - 1)
    end
    return nm
end

local function leap_offset(a11)
    local k = floor((a11 - 2415021.076998695) / 29.530588853 + 0.5)
    local i = 1
    local arc = sun_sector(new_moon_day(k + i))
    local last
    repeat
        last = arc
        i = i + 1
        arc = sun_sector(new_moon_day(k + i))
    until not (arc ~= last and i < 14)
    return i - 1
end

-- Trả về ngày, tháng, năm, nhuận (0/1) âm lịch của ngày dương dd/mm/yy.
local function solar_to_lunar(dd, mm, yy)
    local day_number = jd_from_date(dd, mm, yy)
    local k = floor((day_number - 2415021.076998695) / 29.530588853)
    local month_start = new_moon_day(k + 1)
    if month_start > day_number then
        month_start = new_moon_day(k)
    end
    local a11 = lunar_month11(yy)
    local b11 = a11
    local lunar_year
    if a11 >= month_start then
        lunar_year = yy
        a11 = lunar_month11(yy - 1)
    else
        lunar_year = yy + 1
        b11 = lunar_month11(yy + 1)
    end
    local lunar_day = day_number - month_start + 1
    local diff = floor((month_start - a11) / 29)
    local leap = 0
    local lunar_month = diff + 11
    if b11 - a11 > 365 then
        local leap_diff = leap_offset(a11)
        if diff >= leap_diff then
            lunar_month = diff + 10
            if diff == leap_diff then leap = 1 end
        end
    end
    if lunar_month > 12 then lunar_month = lunar_month - 12 end
    if lunar_month >= 11 and diff < 4 then lunar_year = lunar_year - 1 end
    return lunar_day, lunar_month, lunar_year, leap
end

M.solar_to_lunar = solar_to_lunar
M.jd_from_date = jd_from_date

-- Thứ trong tuần: 0 = Thứ Hai ... 6 = Chủ Nhật
function M.weekday(dd, mm, yy)
    return jd_from_date(dd, mm, yy) % 7
end

function M.info(dd, mm, yy)
    local day, month, year, leap = solar_to_lunar(dd, mm, yy)
    local jd = jd_from_date(dd, mm, yy)
    local sector = floor(sun_longitude(jd - 0.5 - TZ / 24.0) / PI * 12) % 24
    return {
        day = day, month = month, year = year, leap = leap,
        year_cc = CAN[(year + 6) % 10 + 1] .. " " .. CHI[(year + 8) % 12 + 1],
        month_cc = CAN[(year * 12 + month + 3) % 10 + 1] .. " " .. CHI[(month + 1) % 12 + 1],
        day_cc = CAN[(jd + 9) % 10 + 1] .. " " .. CHI[(jd + 1) % 12 + 1],
        term_idx = sector + 1,
        term = TERMS[sector + 1],
        term_up = TERMS_UP[sector + 1],
    }
end

-- Số ngày (>=0) tới ngày âm lịch target_day (1 = mùng 1, 15 = rằm).
function M.days_until(dd, mm, yy, target_day)
    local jd0 = jd_from_date(dd, mm, yy)
    for i = 0, 40 do
        local d, m, y = jd_to_date(jd0 + i)
        if (solar_to_lunar(d, m, y)) == target_day then
            return i
        end
    end
    return nil
end

return M
