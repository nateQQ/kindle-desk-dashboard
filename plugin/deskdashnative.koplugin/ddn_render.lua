-- Vẽ giao diện dashboard trực tiếp lên Blitbuffer (không cần server, không cần ảnh).
-- Mọi tọa độ là "px thiết kế" (dọc 536x724, ngang 724x536) rồi nhân hệ số tới độ phân giải thật
-- (PW4: x2 => 1072x1448).
local Blitbuffer = require("ffi/blitbuffer")
local Font = require("ui/font")
local TextWidget = require("ui/widget/textwidget")
local Weather = require("ddn_weather")
local Usage = require("ddn_usage")
local I18n = require("ddn_i18n")
local T = I18n.t

local floor = math.floor
local BLACK = Blitbuffer.COLOR_BLACK
local WHITE = Blitbuffer.COLOR_WHITE
local LIGHT = WHITE
do
    local ok, c = pcall(function() return Blitbuffer.Color8(0xF0) end)
    if ok and c then LIGHT = c end
end

local R = {}

-- KOReader nhân cỡ chữ của Font:getFace() với Screen:scaleBySize() (PW4 ~1.9x).
-- Ta tính sẵn cỡ chữ theo pixel thật nên phải chia ngược lại hệ số này.
local function detect_font_scale()
    local ok, f = pcall(function()
        local Device = require("device")
        return Device.screen:scaleBySize(1000) / 1000
    end)
    if ok and type(f) == "number" and f > 0.2 and f < 10 then return f end
    return 1
end

-- ================================================================ Canvas
local Canvas = {}
Canvas.__index = Canvas

function Canvas.new(bb, W, H, dw, dh, x0, y0, fscale)
    local self = setmetatable({}, Canvas)
    local s = math.min(W / dw, H / dh)
    self.bb, self.s = bb, s
    self.ox = (x0 or 0) + floor((W - dw * s) / 2)
    self.oy = (y0 or 0) + floor((H - dh * s) / 2)
    self.faces = {}
    self.fscale = fscale or 1
    return self
end

function Canvas:X(v) return self.ox + floor(v * self.s + 0.5) end
function Canvas:Y(v) return self.oy + floor(v * self.s + 0.5) end
function Canvas:len(v) return floor(v * self.s + 0.5) end

function Canvas:rect(x, y, w, h, color)
    local X, Y = self:X(x), self:Y(y)
    local X2, Y2 = self:X(x + w), self:Y(y + h)
    if X2 <= X then X2 = X + 1 end
    if Y2 <= Y then Y2 = Y + 1 end
    self.bb:paintRect(X, Y, X2 - X, Y2 - Y, color or BLACK)
end

-- viền nằm bên trong hình chữ nhật
function Canvas:frame(x, y, w, h, bw, color)
    self:rect(x, y, w, bw, color)
    self:rect(x, y + h - bw, w, bw, color)
    self:rect(x, y, bw, h, color)
    self:rect(x + w - bw, y, bw, h, color)
end

-- rounded border (stroke inside the rectangle), corner radius r, all in design px
function Canvas:rrect(x, y, w, h, r, th, color)
    th = th or 2
    local c = th / 2
    self:rect(x + r, y, w - 2 * r, th, color)
    self:rect(x + r, y + h - th, w - 2 * r, th, color)
    self:rect(x, y + r, th, h - 2 * r, color)
    self:rect(x + w - th, y + r, th, h - 2 * r, color)
    self:arc(x + r, y + r, r - c, 90, 180, th, color)
    self:arc(x + w - r, y + r, r - c, 0, 90, th, color)
    self:arc(x + w - r, y + h - r, r - c, -90, 0, th, color)
    self:arc(x + r, y + h - r, r - c, 180, 270, th, color)
end

function Canvas:dot(X, Y, t, color)
    self.bb:paintRect(X - floor(t / 2), Y - floor(t / 2), t, t, color or BLACK)
end

function Canvas:line(x1, y1, x2, y2, th, color)
    local X1, Y1, X2, Y2 = self:X(x1), self:Y(y1), self:X(x2), self:Y(y2)
    local t = math.max(1, self:len(th or 1))
    local n = math.max(math.abs(X2 - X1), math.abs(Y2 - Y1), 1)
    for i = 0, n do
        self:dot(X1 + floor((X2 - X1) * i / n + 0.5), Y1 + floor((Y2 - Y1) * i / n + 0.5), t, color)
    end
end

function Canvas:disc(cx, cy, r, color)
    local CX, CY = self:X(cx), self:Y(cy)
    local Rr = math.max(1, self:len(r))
    for dy = -Rr, Rr do
        local half = floor(math.sqrt(Rr * Rr - dy * dy) + 0.5)
        self.bb:paintRect(CX - half, CY + dy, half * 2 + 1, 1, color or BLACK)
    end
end

-- góc tính bằng độ, 0 = hướng phải, tăng ngược chiều kim đồng hồ (hệ tọa độ màn hình đã đảo y)
function Canvas:arc(cx, cy, r, a1, a2, th, color)
    local CX, CY, Rr = self:X(cx), self:Y(cy), self:len(r)
    local t = math.max(1, self:len(th or 1))
    local da = a2 - a1
    local n = math.max(12, floor(Rr * math.abs(da) * math.pi / 180))
    for i = 0, n do
        local a = math.rad(a1 + da * i / n)
        self:dot(CX + floor(Rr * math.cos(a) + 0.5), CY - floor(Rr * math.sin(a) + 0.5), t, color)
    end
end

-- đầu mũi tên tại (px,py), hướng (dx,dy) là vector đơn vị trong hệ màn hình
function Canvas:arrowhead(px, py, dx, dy, len, wid, th)
    local bx, by = px - dx * len, py - dy * len
    local nx, ny = -dy, dx
    self:line(px, py, bx + nx * wid, by + ny * wid, th)
    self:line(px, py, bx - nx * wid, by - ny * wid, th)
end

-- ---------------------------------------------------------------- chữ
function Canvas:face(size, kind)
    local px = math.max(6, self:len(size))
    local req = math.max(4, floor(px / self.fscale + 0.5))
    local key = kind .. ":" .. px
    if self.faces[key] == nil then
        local names = {
            bold = { "tfont", "cfont" },
            reg = { "cfont" },
            serif = { "NotoSerif-BoldItalic.ttf", "NotoSerif-Italic.ttf", "cfont" },
        }
        local face = false
        for _, n in ipairs(names[kind] or names.reg) do
            local ok, f = pcall(Font.getFace, Font, n, req)
            if ok and f then face = f; break end
        end
        self.faces[key] = face
    end
    return self.faces[key] or nil
end

function Canvas:tw(str, size, o)
    return TextWidget:new{
        text = str, face = self:face(size, o.kind or "reg"), padding = 0,
        bold = o.faux and true or false, fgcolor = o.color or BLACK,
    }
end

function Canvas:measure(str, size, o)
    local tw = self:tw(str, size, o or {})
    local w = tw:getSize().w
    tw:free()
    return w / self.s
end

-- x: mốc căn; base: đường cơ sở (baseline); trả về độ rộng (px thiết kế)
function Canvas:text(x, base, str, size, o)
    o = o or {}
    local tw = self:tw(str, size, o)
    local sz = tw:getSize()
    local X = self:X(x)
    if o.align == "c" then X = X - floor(sz.w / 2) elseif o.align == "r" then X = X - sz.w end
    local b = tw.getBaseline and tw:getBaseline() or floor(sz.h * 0.78)
    tw:paintTo(self.bb, X, self:Y(base) - b)
    tw:free()
    return sz.w / self.s
end

-- pieces = { {chuỗi, đậm?}, ... }
function Canvas:rich(x, base, pieces, size, align, color)
    local ws, total = {}, 0
    for i, p in ipairs(pieces) do
        ws[i] = self:measure(p[1], size, { kind = p[2] and "bold" or "reg" })
        total = total + ws[i]
    end
    local cx = x
    if align == "c" then cx = x - total / 2 elseif align == "r" then cx = x - total end
    for i, p in ipairs(pieces) do
        self:text(cx, base, p[1], size, { kind = p[2] and "bold" or "reg", color = color })
        cx = cx + ws[i]
    end
    return total
end

function Canvas:wrap(str, size, maxw, o)
    local lines, cur = {}, ""
    for word in str:gmatch("%S+") do
        local try = (cur == "") and word or (cur .. " " .. word)
        if cur ~= "" and self:measure(try, size, o) > maxw then
            lines[#lines + 1] = cur
            cur = word
        else
            cur = try
        end
    end
    if cur ~= "" then lines[#lines + 1] = cur end
    return lines
end

-- ---------------------------------------------------------------- icon
local function cloud(C, x, y, s, color, grow)
    local g = grow or 0
    C:disc(x + .28 * s, y + .56 * s, .17 * s + g, color)
    C:disc(x + .47 * s, y + .40 * s, .24 * s + g, color)
    C:disc(x + .72 * s, y + .54 * s, .19 * s + g, color)
    C:rect(x + .28 * s, y + .52 * s - g, .44 * s, .22 * s + 2 * g, color)
end

local function sun(C, cx, cy, r, ray1, ray2, th)
    C:disc(cx, cy, r)
    for i = 0, 7 do
        local a = math.rad(i * 45)
        C:line(cx + ray1 * math.cos(a), cy - ray1 * math.sin(a), cx + ray2 * math.cos(a), cy - ray2 * math.sin(a), th)
    end
end

function Canvas:icon(kind, x, y, s)
    if kind == "sun" then
        sun(self, x + .5 * s, y + .5 * s, .2 * s, .32 * s, .46 * s, 1.3)
    elseif kind == "partly" then
        sun(self, x + .30 * s, y + .30 * s, .13 * s, .21 * s, .30 * s, 1.1)
        cloud(self, x + .20 * s, y + .22 * s, .80 * s, WHITE, 1.4)
        cloud(self, x + .20 * s, y + .22 * s, .80 * s, BLACK, 0)
    elseif kind == "rain" then
        cloud(self, x, y - .06 * s, s, BLACK, 0)
        for i = 0, 2 do
            local dx = x + (.30 + i * .20) * s
            self:line(dx, y + .70 * s, dx - .06 * s, y + .94 * s, 1.5)
        end
    elseif kind == "storm" then
        cloud(self, x, y - .06 * s, s, BLACK, 0)
        self:line(x + .56 * s, y + .62 * s, x + .42 * s, y + .80 * s, 1.6)
        self:line(x + .42 * s, y + .80 * s, x + .60 * s, y + .80 * s, 1.6)
        self:line(x + .60 * s, y + .80 * s, x + .46 * s, y + 1.0 * s, 1.6)
    elseif kind == "snow" then
        cloud(self, x, y - .06 * s, s, BLACK, 0)
        for i = 0, 2 do
            self:disc(x + (.30 + i * .20) * s, y + (i % 2 == 0 and .84 or .94) * s, .06 * s)
        end
    elseif kind == "fog" then
        for i = 0, 3 do
            self:rect(x + (i % 2 == 0 and .08 or .22) * s, y + (.2 + i * .2) * s, (i % 2 == 0 and .84 or .6) * s, math.max(1.2, .09 * s))
        end
    else -- cloud
        cloud(self, x, y + .08 * s, s, BLACK, 0)
    end
end

function Canvas:hourglass(x, y, w, h)
    self:rect(x, y, w, 1.6)
    self:rect(x, y + h - 1.6, w, 1.6)
    local cx, cy = x + w / 2, y + h / 2
    self:line(x + 1.5, y + 1.6, cx, cy, 1.4)
    self:line(x + w - 1.5, y + 1.6, cx, cy, 1.4)
    self:line(cx, cy, x + 1.5, y + h - 1.6, 1.4)
    self:line(cx, cy, x + w - 1.5, y + h - 1.6, 1.4)
end

function Canvas:wifi_icon(x, y)
    local cx, cy = x + 9, y + 13
    for _, r in ipairs({ 4.5, 8, 11.5 }) do
        self:arc(cx, cy, r, 45, 135, 1.7)
    end
    self:disc(cx, cy, 1.4)
end

-- trả về độ rộng đã dùng
function Canvas:battery_icon(x, y, pct, charging)
    self:frame(x, y, 21, 11, 1.6)
    self:rect(x + 21.5, y + 3.5, 2.5, 5)
    if pct then
        local fw = math.max(pct > 0 and 1 or 0, 16 * math.min(pct, 100) / 100)
        if fw > 0 then self:rect(x + 2.5, y + 2.5, fw, 6) end
    end
    if charging then
        self:line(x - 4, y - 1, x - 8, y + 6, 1.8)
        self:line(x - 8, y + 6, x - 5, y + 6, 1.8)
        self:line(x - 5, y + 6, x - 8.5, y + 13, 1.8)
    end
    return 24
end

local function refresh_icon(C, x, y)
    local cx, cy, r = x + 10, y + 10, 6.5
    C:arc(cx, cy, r, 50, -230, 1.9)
    local a = math.rad(-230)
    local px, py = cx + r * math.cos(a), cy - r * math.sin(a)
    C:arrowhead(px, py, math.sin(a), math.cos(a), 5, 3.2, 1.9)
end

local function rotate_icon(C, x, y)
    local cx, cy, h = x + 10, y + 8, 4.5
    local rot = math.rad(-25)
    local pts = {}
    for i, c in ipairs({ { -h, -h }, { h, -h }, { h, h }, { -h, h } }) do
        pts[i] = { cx + c[1] * math.cos(rot) - c[2] * math.sin(rot), cy + c[1] * math.sin(rot) + c[2] * math.cos(rot) }
    end
    for i = 1, 4 do
        local a, b = pts[i], pts[i % 4 + 1]
        C:line(a[1], a[2], b[1], b[2], 1.8)
    end
    C:arc(cx, cy + 1, 9, -155, -25, 1.8)
    local a = math.rad(-25)
    C:arrowhead(cx + 9 * math.cos(a), cy + 1 - 9 * math.sin(a), -math.sin(a), -math.cos(a), 4.5, 3, 1.8)
end

-- ================================================================ khối dùng chung
local function f1(v) return v and string.format("%.1f", v) or "--" end

local function button(C, x, y, kind)
    C:frame(x, y, 38, 28, 2)
    if kind == "refresh" then refresh_icon(C, x + 9, y + 4) else rotate_icon(C, x + 9, y + 4) end
end

-- trả về x ngoài cùng bên trái của cụm trạng thái
local function status(C, st, xr, base)
    local pct_txt = st.batt and (tostring(st.batt) .. "%") or "--%"
    local wpct = C:text(xr, base, pct_txt, 12, { kind = "bold", align = "r" })
    local bx = xr - wpct - 4 - 24
    C:battery_icon(bx, base - 11, st.batt, st.chg)
    local left = bx - (st.chg and 10 or 0) - 12
    local wtxt = st.wifi and T("wifi_on") or T("wifi_off")
    local ww = C:text(left, base, wtxt, 12, { kind = "bold", align = "r" })
    C:wifi_icon(left - ww - 23, base - 13)
    return left - ww - 23
end

local function days(C, x, xr, base0, step, size, list, short)
    for i = 1, 3 do
        local d = list and list[i]
        local b = base0 + (i - 1) * step
        if d then
            local w1 = C:text(x, b, d.label .. " · ", size)
            local text, kind = Weather.describe(d.code, short)
            local isz = size + 2
            C:icon(kind, x + w1, b - size * 0.38 - isz / 2, isz)
            C:text(x + w1 + isz + 4, b, text, size)
            local sep = short and "°" or "°C"
            C:text(xr, b, string.format("%d%s - %d%s", d.tmin, sep, d.tmax, sep), size, { kind = "bold", align = "r" })
        else
            C:text(x, b, "--", size)
        end
        local xx = x
        while xx < xr do
            C:rect(xx, b + 5, 1.2, 1)
            xx = xx + 3
        end
    end
end

-- Khối "Claude Code": 2 thanh ngang (phiên 5 giờ, tuần), số % to bên phải, vạch ▼ = phần thời gian đã trôi qua
-- trong cửa sổ (như ClawTicker), dưới thanh: giờ đặt lại (trái) + còn bao lâu (phải).
local WIN = { five = 18000, week = 604800 }

local function usage_row(C, x, xr, y, kind, label, u, now, tz, z)
    local w = xr - x
    local entry = u and u[kind]
    local pct = entry and entry.pct
    local pbase = y + z.pct * 0.78
    C:text(x, pbase, label, z.label, { kind = "bold" })
    local ptxt = pct and (string.format("%d", pct + 0.5) .. "%") or "--"
    C:text(xr, pbase, ptxt, z.pct, { kind = "bold", faux = true, align = "r" })
    local by = pbase + z.tri + 8
    C:frame(x, by, w, z.bar, 2)
    if pct and pct > 0 then C:rect(x + 2, by + 2, (w - 4) * pct / 100, z.bar - 4) end
    local f = entry and Usage.pace(entry.reset, now, WIN[kind])
    if f then
        local mx = x + w * f
        for i = 0, z.tri - 1 do C:rect(mx - (z.tri - i), by - 2 - z.tri + i, 2 * (z.tri - i), 1) end
        C:rect(mx - 0.75, by + z.bar, 1.5, 4)
    end
    local sb = by + z.bar + 6 + z.small
    if entry and entry.reset then
        C:text(x, sb, T("resets", Usage.reset_text(entry.reset, now, tz)), z.small)
        C:text(xr, sb, Usage.remain_text(entry.reset, now), z.small, { kind = "bold", align = "r" })
    elseif pct then
        C:text(x, sb, T("no_reset"), z.small)
    end
    return sb + 6
end

-- trả về y kết thúc khối
local function claude_block(C, x, xr, y, st, z)
    C:text(x, y, T("claude"), z.title or 13, { kind = "bold" })
    local note
    if not st.usage then
        note = T("no_data")
    elseif st.usage_stale then
        note = T("fetch_fail")
    else
        note = Usage.age_text(st.usage.age)
    end
    local lead = T("elapsed")
    C:text(xr, y, (note ~= "" and (note .. " · ") or "") .. lead, 9.5, { align = "r" })
    local now = st.usage and st.usage.now or 0
    local e1 = usage_row(C, x, xr, y + 8, "five", T("five"), st.usage, now, st.tz, z)
    local e2 = usage_row(C, x, xr, e1 + z.gap, "week", T("week"), st.usage, now, st.tz, z)
    return e2
end

-- ================================================================ section helpers
-- Every block of information is its own rounded box (the only lines on screen). Claude = thick border + biggest numbers.
local function box(C, x, y, w, h, th) C:rrect(x, y, w, h, 9, th or 2) end
local function label(C, x, base, str, xr, meta)
    C:text(x, base, str, 10.5, { kind = "bold" })
    if meta and xr then C:text(xr, base, meta, 9.5, { align = "r" }) end
end

-- "21 days to Lunar 1st" with the number in bold; returns one pieces-list per line
local function count_lines(c)
    local function piece(tpl, n)
        local pre, post = tpl:match("^(.-)%%s(.*)$")
        local out = {}
        if pre and pre ~= "" then out[#out + 1] = { pre, false } end
        out[#out + 1] = { tostring(n), true }
        if post and post ~= "" then out[#out + 1] = { post, false } end
        return out
    end
    local out = {}
    if c and c.n1 then out[#out + 1] = (c.n1 == 0) and { { T("c_today1"), false } } or piece(I18n.raw("c_before1"), c.n1) end
    if c and c.n15 then out[#out + 1] = (c.n15 == 0) and { { T("c_today15"), false } } or piece(I18n.raw("c_before15"), c.n15) end
    return out
end

-- one cell of the "air & humidity" section: label, big value, status word, bar, note (no box)
local function air_cell(C, x, w, y, which, st, k)
    local wx = st.wx or {}
    local title, big, status, pct, note
    if which == "aqi" then
        local lab, p, _, note_s = Weather.aqi_info(wx.aqi)
        title, big, status, pct = T("aqi_title"), tostring(wx.aqi or "--"), lab, p
        local pm = wx.pm25 and string.format("PM2.5: %.1f µg/m³", wx.pm25) or nil
        note = pm and (pm .. " · " .. note_s) or note_s
    else
        local _, long_pill, short_pill, _, _, note_s = Weather.hum_info(wx.humidity)
        title, big, status, note = T("hum_title"), wx.humidity and (wx.humidity .. "%") or "--", k.short and short_pill or long_pill, note_s
        pct = wx.humidity and math.min(wx.humidity, 100) or 0
    end
    C:text(x, y, title, 10.5, { kind = "bold" })
    local wb = C:text(x, y + k.big_dy, big, k.big, { kind = "bold", faux = true })
    C:text(x + wb + 10, y + k.big_dy, status, 12, { kind = "bold" })
    local by = y + k.big_dy + 10
    C:frame(x, by, w, 7, 1.5)
    if pct and pct > 0 then C:rect(x + 1.5, by + 1.5, (w - 3) * pct / 100, 4) end
    for i, l in ipairs(C:wrap(note, 10.5, w)) do
        if i <= 2 then C:text(x, by + 20 + (i - 1) * 13, l, 10.5) end
    end
end

-- 3 forecast days side by side: day, icon + range, condition
local function forecast_cols(C, x, xr, y, list)
    local cw = (xr - x) / 3
    for i = 1, 3 do
        local d, cx = list and list[i], x + (i - 1) * cw
        if d then
            local text, kind = Weather.describe(d.code, true)
            C:text(cx, y, d.label, 10.5, { kind = "bold" })
            C:icon(kind, cx, y + 7, 15)
            C:text(cx + 21, y + 19, string.format("%d° - %d°", d.tmin, d.tmax), 13, { kind = "bold" })
            C:text(cx, y + 33, text, 10.5)
        else
            C:text(cx, y, "--", 10.5)
        end
    end
end

-- ================================================================ portrait 536x724
local function portrait(C, st)
    local wx = st.wx or {}
    local lu = st.lunar

    -- header (quiet, no lines)
    C:text(20, 28, st.title, 13, { kind = "bold" })
    button(C, 432, 8, "refresh")
    button(C, 478, 8, "rotate")
    C:text(422, 27, T("updated", st.time) .. (st.stale and " !" or ""), 12, { align = "r" })

    -- 1. today
    box(C, 16, 46, 504, 118)
    C:text(30, 112, st.time, 62, { kind = "bold", faux = true })
    C:text(30, 142, st.date_str, 13, { kind = "bold" })
    if st.show_lunar then
        C:text(292, 76, T("lunar_title") .. ": " .. (lu.dm:gsub("/", " / ")), 16, { kind = "bold" })
        C:text(292, 96, lu.year_cc .. " · " .. lu.month_cc .. " · " .. lu.day_cc, 11.5)
        C:text(292, 114, T("term_tag", lu.term_up), 11.5)
        for i, pieces in ipairs(count_lines(st.count)) do C:rich(292, 133 + (i - 1) * 16, pieces, 11.5) end
    else
        C:text(292, 96, T("term_tag", lu.term_up), 12)
    end

    -- 2. Claude (primary)
    local ye = claude_block(C, 30, 506, 196, st, { title = 14, label = 13, pct = 44, bar = 24, tri = 7, small = 11, gap = 10 })
    box(C, 16, 170, 504, ye + 10 - 170, 3)

    -- 3. weather
    local wy = ye + 18
    local w0 = wy + 19
    label(C, 30, w0, T("weather"))
    local ctext, cicon = "--", "cloud"
    if wx.code then ctext, cicon = Weather.describe(wx.code) end
    C:text(30, w0 + 40, f1(wx.temp) .. "°C", 38, { kind = "bold", faux = true })
    C:icon(cicon, 30, w0 + 48, 16)
    C:text(52, w0 + 61, ctext, 13, { kind = "bold" })
    C:rich(270, w0 + 22, { { "• " .. T("feels") .. ": ", false }, { f1(wx.feels) .. "°C", true } }, 12)
    C:rich(270, w0 + 41, { { "• " .. T("humidity") .. ": ", false }, { (wx.humidity and (wx.humidity .. "%") or "--"), true } }, 12)
    C:rich(270, w0 + 60, { { "• " .. T("wind") .. ": ", false }, { f1(wx.wind) .. " km/h", true } }, 12)
    forecast_cols(C, 30, 506, w0 + 88, wx.days)
    box(C, 16, wy, 504, 153)

    -- 4. air + humidity
    local ay = wy + 153 + 8
    local k = { big = 28, big_dy = 28 }
    air_cell(C, 30, 224, ay + 19, "aqi", st, k)
    air_cell(C, 282, 224, ay + 19, "hum", st, k)
    box(C, 16, ay, 504, 98)

    -- footer (quiet)
    C:text(20, 712, st.footer, 12, { kind = "bold" })
    status(C, st, 516, 712)

    return { hit = { refresh = { 432, 8, 38, 28 }, rotate = { 478, 8, 38, 28 }, exit = { 0, 680, 150, 44 } } }
end

-- ================================================================ landscape 724x536
local function landscape(C, st)
    local wx = st.wx or {}
    local lu = st.lunar

    -- header (quiet, no lines)
    C:text(18, 28, st.title, 13, { kind = "bold" })
    button(C, 622, 8, "refresh")
    button(C, 668, 8, "rotate")
    local left = status(C, st, 612, 27)
    C:text(left - 14, 27, T("updated", st.time) .. (st.stale and " !" or ""), 12, { align = "r" })

    -- left column: 1. today
    box(C, 14, 46, 316, 170)
    C:text(28, 114, st.time, 70, { kind = "bold", faux = true })
    C:text(28, 138, st.date_str, 13, { kind = "bold" })
    if st.show_lunar then
        C:text(28, 160, T("lunar_title") .. ": " .. lu.dm .. " · " .. lu.year_cc, 12, { kind = "bold" })
        C:text(28, 176, T("term_tag", lu.term_up), 11)
        for i, pieces in ipairs(count_lines(st.count)) do C:rich(28, 192 + (i - 1) * 15, pieces, 11) end
    else
        C:text(28, 162, T("term_tag", lu.term_up), 12)
    end

    -- left column: 3. weather
    local w0 = 224 + 19
    label(C, 28, w0, T("weather"))
    local ctext, cicon = "--", "cloud"
    if wx.code then ctext, cicon = Weather.describe(wx.code) end
    C:text(28, w0 + 40, f1(wx.temp) .. "°C", 36, { kind = "bold", faux = true })
    C:icon(cicon, 28, w0 + 48, 15)
    C:text(48, w0 + 60, ctext, 12, { kind = "bold" })
    C:rich(196, w0 + 22, { { "• " .. T("feels") .. ": ", false }, { f1(wx.feels) .. "°", true } }, 11.5)
    C:rich(196, w0 + 40, { { "• " .. T("humidity") .. ": ", false }, { (wx.humidity and (wx.humidity .. "%") or "--"), true } }, 11.5)
    C:rich(196, w0 + 58, { { "• " .. T("wind") .. ": ", false }, { f1(wx.wind) .. " km/h", true } }, 11.5)
    days(C, 28, 316, w0 + 104, 34, 13, wx.days, true)
    box(C, 14, 224, 316, 244)

    -- right column: 2. Claude (primary)
    local ye = claude_block(C, 356, 694, 72, st, { title = 13, label = 13, pct = 56, bar = 34, tri = 8, small = 12, gap = 22 })
    box(C, 342, 46, 368, ye + 10 - 46, 3)

    -- right column: 4. air + humidity
    local ay = ye + 18
    local k = { big = 26, big_dy = 28, short = true }
    air_cell(C, 356, 156, ay + 19, "aqi", st, k)
    air_cell(C, 540, 156, ay + 19, "hum", st, k)
    box(C, 342, ay, 368, 468 - ay)

    -- footer (quiet)
    C:text(18, 516, st.footer, 12, { kind = "bold" })
    C:text(706, 516, T("auto_refresh", st.interval_min), 10, { align = "r" })

    return { hit = { refresh = { 622, 8, 38, 28 }, rotate = { 668, 8, 38, 28 }, exit = { 0, 480, 160, 56 } } }
end

-- ================================================================ API
-- Vẽ lên bb (kích thước W x H, gốc x0,y0). Trả về {hit=..., s=, ox=, oy=} để xử lý chạm.
function R.draw(bb, W, H, st, x0, y0)
    local land = W > H
    local dw, dh = (land and 724 or 536), (land and 536 or 724)
    local C = Canvas.new(bb, W, H, dw, dh, x0, y0, st.font_scale or detect_font_scale())
    local res = land and landscape(C, st) or portrait(C, st)
    res.s, res.ox, res.oy = C.s, C.ox - (x0 or 0), C.oy - (y0 or 0)
    return res
end

return R
