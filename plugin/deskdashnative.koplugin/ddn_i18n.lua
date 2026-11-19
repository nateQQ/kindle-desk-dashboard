-- Chuỗi giao diện theo ngôn ngữ: lang = "en" (mặc định, dùng toàn cầu) hoặc "vi". Đổi trong config.lua.
local M = { lang = "en" }

local S = {
    en = {
        updated = "Updated: %s", wifi_on = "Wi-Fi: Connected", wifi_off = "Wi-Fi: Off",
        auto_refresh = "Auto-refresh every %d min",
        term_tag = "Solar term: %s", lunar_title = "Lunar date", leap = " (leap)",
        lunar_year = "Year", lunar_month = "Month", lunar_day = "Day",
        c_today1 = "Lunar 1st is today", c_before1 = "%s days to Lunar 1st", c_today15 = "Full moon (Lunar 15th) is today", c_before15 = "%s days to Lunar 15th",
        feels = "Feels like", humidity = "Humidity", wind = "Wind",
        forecast3 = "3-DAY FORECAST", forecast3_s = "3-DAY FORECAST",
        aqi_title = "AIR QUALITY", aqi_title_s = "AQI", hum_title = "HUMIDITY", hum_title_warn = "HUMIDITY WARNING", hum_title_warn_s = "HUMIDITY",
        high = "High", low = "Low",
        weather = "WEATHER", claude = "CLAUDE CODE", five = "5-hour session", week = "Week", resets = "Resets %s", no_reset = "No reset time yet",
        elapsed = "▼ = time elapsed", no_data = "Claude data not connected", fetch_fail = "! can't reach Mac, showing old numbers",
        just_now = "just updated", age_min = "data %d min old", age_hour = "data %d h old",
        left_d = "%dd %dh left", left_h = "%dh %dm left", left_m = "%dm left",
        uv1 = "Low", uv2 = "Moderate", uv3 = "High", uv4 = "Very high", uv5 = "Extreme",
        aqi_na = "N/A", aqi1 = "GOOD", aqi2 = "MODERATE", aqi3 = "SENSITIVE", aqi4 = "UNHEALTHY", aqi5 = "VERY BAD", aqi6 = "HAZARDOUS",
        aqi_n0 = "No data.", aqi_s0 = "No data",
        aqi_n1 = "Air quality is good.", aqi_s1 = "Air is good",
        aqi_n2 = "Sensitive groups take care.", aqi_s2 = "Sensitive groups: take care",
        aqi_n3 = "Sensitive groups limit time outside.", aqi_s3 = "Sensitive groups stay in",
        aqi_n4 = "Wear a mask outdoors.", aqi_s4 = "Wear a mask",
        aqi_n5 = "Avoid going out, wear a mask.", aqi_s5 = "Avoid going out",
        aqi_n6 = "Stay indoors, close windows.", aqi_s6 = "Stay indoors",
        hum_na = "No data.", hum_na_s = "No data",
        hum_wet = "HUMID WARNING", hum_wet_s = "HUMID", hum_wet_n = "Close windows, run a dehumidifier / Dry mode.", hum_wet_ns = "Close windows, dehumidify / Dry.",
        hum_dry = "DRY WARNING", hum_dry_s = "DRY", hum_dry_n = "Use a humidifier, drink water.", hum_dry_ns = "Humidify, drink water",
        hum_ok = "COMFORTABLE", hum_ok_s = "OK", hum_ok_n = "Humidity is in the comfortable range.", hum_ok_ns = "Humidity is comfortable.",
        unknown = "Unknown",
        menu = "Desk dashboard (runs on device)",
        desc = "Full-screen clock, weather, UV, air quality and Claude usage bars for e-ink. Refreshes by itself.",
    },
    vi = {
        updated = "Cập nhật: %s", wifi_on = "Wi-Fi: Đã kết nối", wifi_off = "Wi-Fi: Tắt",
        auto_refresh = "Tự động cập nhật mỗi %d phút",
        term_tag = "Tiết khí: %s", lunar_title = "Âm lịch", leap = " (nhuận)",
        lunar_year = "Năm", lunar_month = "Tháng", lunar_day = "Ngày",
        c_today1 = "Hôm nay Mùng 1", c_before1 = "%s ngày tới Mùng 1", c_today15 = "Hôm nay Rằm", c_before15 = "%s ngày tới Rằm",
        feels = "Cảm nhận", humidity = "Độ ẩm", wind = "Gió",
        forecast3 = "DỰ BÁO 3 NGÀY TỚI", forecast3_s = "DỰ BÁO 3 NGÀY",
        aqi_title = "CHẤT LƯỢNG KHÔNG KHÍ", aqi_title_s = "AQI", hum_title = "ĐỘ ẨM", hum_title_warn = "CẢNH BÁO ĐỘ ẨM / NỒM", hum_title_warn_s = "ĐỘ ẨM / NỒM",
        high = "Cao", low = "Thấp",
        weather = "THỜI TIẾT", claude = "CLAUDE CODE", five = "Phiên 5 giờ", week = "Tuần", resets = "Đặt lại %s", no_reset = "Chưa có giờ đặt lại",
        elapsed = "▼ = thời gian đã trôi", no_data = "Chưa nối dữ liệu Claude", fetch_fail = "! không tải được, đang hiện số cũ",
        just_now = "vừa cập nhật", age_min = "dữ liệu cách %d phút", age_hour = "dữ liệu cách %d giờ",
        left_d = "còn %d ngày %d giờ", left_h = "còn %d giờ %d phút", left_m = "còn %d phút",
        uv1 = "Thấp", uv2 = "Trung bình", uv3 = "Cao", uv4 = "Rất cao", uv5 = "Cực cao",
        aqi_na = "N/A", aqi1 = "TỐT", aqi2 = "TRUNG BÌNH", aqi3 = "KÉM", aqi4 = "XẤU", aqi5 = "RẤT XẤU", aqi6 = "NGUY HẠI",
        aqi_n0 = "Chưa có dữ liệu.", aqi_s0 = "Chưa có dữ liệu",
        aqi_n1 = "Không khí tốt.", aqi_s1 = "Không khí tốt",
        aqi_n2 = "Nhóm nhạy cảm nên lưu ý.", aqi_s2 = "Nhóm nhạy cảm lưu ý",
        aqi_n3 = "Nhóm nhạy cảm hạn chế ra ngoài.", aqi_s3 = "Nhóm nhạy cảm ở trong nhà",
        aqi_n4 = "Nên đeo khẩu trang khi ra ngoài.", aqi_s4 = "Nên đeo khẩu trang",
        aqi_n5 = "Hạn chế ra ngoài, đeo khẩu trang.", aqi_s5 = "Hạn chế ra ngoài",
        aqi_n6 = "Ở trong nhà, đóng kín cửa.", aqi_s6 = "Ở trong nhà",
        hum_na = "Chưa có dữ liệu.", hum_na_s = "Chưa có dữ liệu",
        hum_wet = "CẢNH BÁO NỒM", hum_wet_s = "NỒM", hum_wet_n = "Đóng cửa, bật máy hút ẩm / chế độ Dry.", hum_wet_ns = "Đóng cửa, bật hút ẩm / Dry.",
        hum_dry = "CẢNH BÁO KHÔ", hum_dry_s = "KHÔ", hum_dry_n = "Nên dùng máy tạo ẩm, uống đủ nước.", hum_dry_ns = "Dùng máy tạo ẩm, uống đủ nước",
        hum_ok = "DỄ CHỊU", hum_ok_s = "ỔN", hum_ok_n = "Độ ẩm trong ngưỡng dễ chịu.", hum_ok_ns = "Độ ẩm dễ chịu.",
        unknown = "Không rõ",
        menu = "Màn hình để bàn (chạy trực tiếp)",
        desc = "Đồng hồ, lịch âm, thời tiết, UV, AQI và mức dùng Claude hiển thị toàn màn hình, tự cập nhật.",
    },
}

local ARR = {
    en = {
        weekday_up = { "SUNDAY", "MONDAY", "TUESDAY", "WEDNESDAY", "THURSDAY", "FRIDAY", "SATURDAY" },
        weekday = { "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", "Sunday" },   -- 1 = Thứ Hai
        weekday_short = { "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat" },                           -- 1 = Chủ Nhật (wday của os.date)
        month = { "Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec" },
        terms_up = {
            "SPRING EQUINOX", "CLEAR AND BRIGHT", "GRAIN RAIN", "START OF SUMMER", "GRAIN BUDS", "GRAIN IN EAR",
            "SUMMER SOLSTICE", "MINOR HEAT", "MAJOR HEAT", "START OF AUTUMN", "END OF HEAT", "WHITE DEW",
            "AUTUMN EQUINOX", "COLD DEW", "FROST DESCENDS", "START OF WINTER", "MINOR SNOW", "MAJOR SNOW",
            "WINTER SOLSTICE", "MINOR COLD", "MAJOR COLD", "START OF SPRING", "RAIN WATER", "AWAKENING OF INSECTS",
        },
        wcode = {
            [0] = "Clear sky", [1] = "Mostly clear", [2] = "Partly cloudy", [3] = "Overcast", [45] = "Fog", [48] = "Fog",
            [51] = "Light drizzle", [53] = "Drizzle", [55] = "Heavy drizzle", [56] = "Freezing drizzle", [57] = "Freezing drizzle",
            [61] = "Light rain", [63] = "Rain", [65] = "Heavy rain", [66] = "Freezing rain", [67] = "Freezing rain",
            [71] = "Light snow", [73] = "Snow", [75] = "Heavy snow", [77] = "Snow grains",
            [80] = "Scattered showers", [81] = "Showers", [82] = "Heavy showers", [85] = "Snow showers", [86] = "Snow showers",
            [95] = "Thunderstorm", [96] = "Thunderstorm, hail", [99] = "Thunderstorm, hail",
        },
        strip = "Scattered ",
    },
    vi = {
        weekday_up = { "CHỦ NHẬT", "THỨ HAI", "THỨ BA", "THỨ TƯ", "THỨ NĂM", "THỨ SÁU", "THỨ BẢY" },
        weekday = { "Thứ Hai", "Thứ Ba", "Thứ Tư", "Thứ Năm", "Thứ Sáu", "Thứ Bảy", "Chủ Nhật" },
        weekday_short = { "CN", "T2", "T3", "T4", "T5", "T6", "T7" },
        month = { "01", "02", "03", "04", "05", "06", "07", "08", "09", "10", "11", "12" },
        terms_up = nil,   -- tiếng Việt dùng tên trong ddn_lunar.lua
        wcode = {
            [0] = "Trời quang", [1] = "Ít mây", [2] = "Mây rải rác", [3] = "Nhiều mây", [45] = "Sương mù", [48] = "Sương mù",
            [51] = "Mưa phùn nhẹ", [53] = "Mưa phùn", [55] = "Mưa phùn dày", [56] = "Mưa phùn lạnh", [57] = "Mưa phùn lạnh",
            [61] = "Mưa nhẹ", [63] = "Mưa vừa", [65] = "Mưa to", [66] = "Mưa lạnh", [67] = "Mưa lạnh",
            [71] = "Tuyết nhẹ", [73] = "Tuyết", [75] = "Tuyết dày", [77] = "Tuyết hạt",
            [80] = "Mưa rào rải rác", [81] = "Mưa rào", [82] = "Mưa rào lớn", [85] = "Tuyết rào", [86] = "Tuyết rào",
            [95] = "Dông", [96] = "Dông, mưa đá", [99] = "Dông, mưa đá",
        },
        strip = " rải rác",
    },
}

function M.set(lang) if S[lang] then M.lang = lang end end
function M.t(key, ...)
    local s = S[M.lang][key] or S.en[key] or key
    if select("#", ...) > 0 then return string.format(s, ...) end
    return s
end
function M.raw(key) return S[M.lang][key] or S.en[key] or key end
function M.arr(key) return ARR[M.lang][key] end
function M.strip() return ARR[M.lang].strip end
function M.wcode(code) return ARR[M.lang].wcode[code] end

-- "WEDNESDAY, 18 Nov 2026" (en) | "THỨ TƯ, 18/11/2026" (vi)
function M.date_str(d)
    local wd = ARR[M.lang].weekday_up[d.wday]
    if M.lang == "vi" then return string.format("%s, %02d/%02d/%d", wd, d.day, d.month, d.year) end
    return string.format("%s, %d %s %d", wd, d.day, ARR.en.month[d.month], d.year)
end

-- nhãn ngày dự báo: widx 0 = Thứ Hai ... 6 = Chủ Nhật
function M.day_label(widx, dd, mm)
    local name = ARR[M.lang].weekday[widx + 1]
    if M.lang == "vi" then return string.format("%s (%02d/%02d)", name, dd, mm) end
    return string.format("%s (%d %s)", name:sub(1, 3), dd, ARR.en.month[mm])
end

return M
