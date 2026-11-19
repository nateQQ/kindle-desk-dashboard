--[[
    Màn hình để bàn cho Kindle PW4 - CHẠY TRỰC TIẾP TRÊN KINDLE (KOReader plugin), không cần máy chủ.

    - Tự tính giờ, âm lịch, tiết khí. Bản NateCue: bỏ câu trích dẫn, thêm 2 thanh mức dùng Claude (5 giờ, tuần)
      lấy từ máy Mac qua `usage_url` (xem config.lua).
    - Tải thời tiết/UV/AQI từ Open-Meteo mỗi `weather_ttl` giây (mặc định 10 phút).
    - Vẽ lại toàn màn hình mỗi `interval_sec` giây (mặc định 5 phút).
    - Chạm icon làm mới (góc trên phải)  = tải lại thời tiết + vẽ lại ngay.
    - Chạm icon xoay (góc trên phải, ngoài cùng) = đổi dọc <-> ngang.
    - Chạm góc dưới bên trái (chỗ chữ "Cauhuyy") = thoát về KOReader.
]]

local Blitbuffer = require("ffi/blitbuffer")
local DataStorage = require("datastorage")
local Device = require("device")
local Dispatcher = require("dispatcher")
local Event = require("ui/event")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local InputContainer = require("ui/widget/container/inputcontainer")
local LuaSettings = require("luasettings")
local NetworkMgr = require("ui/network/manager")
local UIManager = require("ui/uimanager")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local logger = require("logger")
local _ = require("gettext")

local Render = require("ddn_render")
local State = require("ddn_state")
local Weather = require("ddn_weather")
local Usage = require("ddn_usage")
local I18n = require("ddn_i18n")

local Screen = Device.screen

-- ---------------------------------------------------------------- cấu hình
local PLUGIN_DIR = debug.getinfo(1, "S").source:match("^@(.*)/[^/]+$") or "."
local CFG = {
    lat = 10.78, lon = 106.70, tz_offset = 7,
    title = "HO CHI MINH", footer = "NateCue", usage_url = "", lang = "en", show_lunar = true,
    interval_sec = 300, weather_ttl = 600, retry_sec = 60, full_refresh_every = 6,
    portrait_rotation = 0, landscape_rotation = 1,
    autostart = false, connect_timeout = 10, total_timeout = 40,
}
do
    local ok, user = pcall(dofile, PLUGIN_DIR .. "/config.lua")
    if ok and type(user) == "table" then
        for k, v in pairs(user) do CFG[k] = v end
    else
        logger.warn("deskdashnative: không đọc được config.lua:", user)
    end
end

I18n.set(CFG.lang)

-- ---------------------------------------------------------------- widget toàn màn hình
local Dashboard = InputContainer:extend{
    name = "deskdashnative_screen",
    covers_fullscreen = true,
}

function Dashboard:init()
    self.dimen = Geom:new{ x = 0, y = 0, w = Screen:getWidth(), h = Screen:getHeight() }
    self.ges_events = {
        Tap = { GestureRange:new{ ges = "tap", range = self.dimen } },
    }
end

-- Vẽ giao diện vào bộ đệm ngoài màn hình 1 lần; các lần repaint sau chỉ chép lại.
function Dashboard:rebuild(st)
    self.state = st
    if self.cache then
        self.cache:free()
        self.cache = nil
    end
    local W, H = self.dimen.w, self.dimen.h
    local ok, bb = pcall(function() return Blitbuffer.new(W, H, Screen.bb:getType()) end)
    if ok and bb then
        bb:fill(Blitbuffer.COLOR_WHITE)
        local ok2, layout = pcall(Render.draw, bb, W, H, st, 0, 0)
        if ok2 then
            self.layout = layout
            self.cache = bb
        else
            logger.warn("deskdashnative: lỗi vẽ:", layout)
            bb:free()
        end
    end
end

function Dashboard:paintTo(bb, x, y)
    local W, H = self.dimen.w, self.dimen.h
    if self.cache then
        bb:blitFrom(self.cache, x, y, 0, 0, W, H)
        return
    end
    bb:paintRect(x, y, W, H, Blitbuffer.COLOR_WHITE)
    if self.state then
        local ok, layout = pcall(Render.draw, bb, W, H, self.state, x, y)
        if ok then self.layout = layout end
    end
end

function Dashboard:onCloseWidget()
    if self.cache then
        self.cache:free()
        self.cache = nil
    end
end

local function inside(r, x, y)
    return x >= r[1] and x <= r[1] + r[3] and y >= r[2] and y <= r[2] + r[4]
end

function Dashboard:onTap(arg, ges)
    local L = self.layout
    if not L then return true end
    local dx = (ges.pos.x - L.ox) / L.s
    local dy = (ges.pos.y - L.oy) / L.s
    local ref, rot, ex = L.hit.refresh, L.hit.rotate, L.hit.exit
    if dy < 56 then
        if dx >= ref[1] - 30 then
            local mid = (ref[1] + ref[3] + rot[1]) / 2
            if dx >= mid then
                self.plugin:rotate()
            else
                self.plugin:tick(true, true)
            end
        end
    elseif inside(ex, dx, dy) then
        self.plugin:close()
    end
    return true
end

-- ---------------------------------------------------------------- plugin
local DeskDash = WidgetContainer:extend{
    name = "deskdashnative",
    is_doc_only = false,
}

function DeskDash:init()
    self.settings = LuaSettings:open(DataStorage:getSettingsDir() .. "/deskdashnative.lua")
    self.update_count = 0
    self.timer = function() self:tick() end
    self.ui.menu:registerToMainMenu(self)
    Dispatcher:registerAction("deskdashnative_open", {
        category = "none", event = "OpenDeskDashNative",
        title = I18n.t("menu"), general = true,
    })
    if CFG.autostart and not self.ui.document then
        UIManager:scheduleIn(3, function() self:open() end)
    end
end

function DeskDash:addToMainMenu(menu_items)
    menu_items.deskdashnative = {
        text = I18n.t("menu"),
        sorting_hint = "tools",
        callback = function() self:open() end,
    }
end

function DeskDash:onOpenDeskDashNative()
    self:open()
    return true
end

function DeskDash:open()
    if self.widget then return end
    local want = self.settings:readSetting("rotation")
    if want ~= nil and want ~= Screen:getRotationMode() then
        UIManager:broadcastEvent(Event:new("SetRotationMode", want))
        UIManager:scheduleIn(1, function() self:show() end)
    else
        self:show()
    end
end

function DeskDash:show()
    if self.widget then return end
    self.widget = Dashboard:new{ plugin = self }
    UIManager:show(self.widget)
    UIManager:preventStandby()
    self:tick(true, true)
end

function DeskDash:close()
    UIManager:unschedule(self.timer)
    if self.widget then
        UIManager:close(self.widget)
        self.widget = nil
        UIManager:allowStandby()
    end
    UIManager:setDirty("all", "full")
end

function DeskDash:rotate()
    local landscape = Screen:getWidth() > Screen:getHeight()
    local want = landscape and CFG.portrait_rotation or CFG.landscape_rotation
    self.settings:saveSetting("rotation", want)
    self.settings:flush()
    UIManager:unschedule(self.timer)
    if self.widget then
        UIManager:close(self.widget)
        self.widget = nil
        UIManager:allowStandby()
    end
    UIManager:broadcastEvent(Event:new("SetRotationMode", want))
    UIManager:scheduleIn(1, function() self:show() end)
end

-- báo cho tính năng tự ngủ của KOReader biết máy vẫn đang được dùng
function DeskDash:resetAutosuspend()
    pcall(function() UIManager:broadcastEvent(Event:new("InputEvent")) end)
end

function DeskDash:schedule(seconds)
    UIManager:unschedule(self.timer)
    UIManager:scheduleIn(seconds, self.timer)
end

-- số giây còn lại tới mốc kế tiếp (:00, :05, ...) cộng 2 giây
function DeskDash:nextDelay()
    local iv = CFG.interval_sec
    local d = iv - (os.time() % iv) + 2
    if d < 20 then d = d + iv end
    return d
end

-- force_full: nháy toàn màn hình; refetch: bắt buộc tải lại thời tiết
function DeskDash:tick(force_full, refetch)
    UIManager:unschedule(self.timer)
    if not self.widget then return end
    self:resetAutosuspend()

    local need_w = refetch or (not self.raw) or (os.time() - (self.raw_time or 0) >= CFG.weather_ttl)
    local need_u = CFG.usage_url ~= nil and CFG.usage_url ~= ""   -- số Claude lấy lại mỗi lần vẽ (LAN, nhẹ)
    if not (need_w or need_u) or self.busy then
        self:draw(force_full)
        return
    end

    self.busy = true
    -- phòng khi chờ Wi-Fi quá lâu: vẫn cập nhật đồng hồ bằng dữ liệu cũ
    self:schedule(CFG.connect_timeout + CFG.total_timeout + 20)
    local function go()
        self.busy = false
        if not self.widget then return end
        if need_w then
            local raw, err = Weather.fetch(CFG)
            if raw then
                self.raw, self.raw_time, self.fetch_failed = raw, os.time(), false
            else
                self.fetch_failed = true
                logger.warn("deskdashnative: lỗi tải thời tiết:", err)
            end
        end
        if need_u then
            local okU, u, uerr = pcall(Usage.fetch, CFG)
            if not okU then u, uerr = nil, u end
            if u then
                self.usage_raw, self.usage_failed = u, false
            else
                self.usage_failed = true   -- giữ số cũ, vẽ kèm dấu cảnh báo
                logger.warn("deskdashnative: lỗi tải mức dùng Claude:", uerr)
            end
        end
        self:draw(force_full)
    end
    if NetworkMgr.runWhenOnline then
        NetworkMgr:runWhenOnline(go)
    else
        go()
    end
end

function DeskDash:draw(force_full)
    if not self.widget then return end
    local dev = { wifi = false, stale = self.fetch_failed or false, usage_stale = self.usage_failed or false }
    pcall(function()
        local powerd = Device:getPowerDevice()
        dev.batt = math.floor(powerd:getCapacity() or 0)
        dev.chg = powerd:isCharging() and true or false
    end)
    pcall(function() dev.wifi = NetworkMgr:isConnected() and true or false end)

    local ok, st = pcall(State.build, CFG, os.time(), self.raw, dev, self.usage_raw)
    if ok then
        self.widget:rebuild(st)
        self.update_count = self.update_count + 1
        local full = force_full or (self.update_count % CFG.full_refresh_every == 0)
        UIManager:setDirty(self.widget, full and "full" or "partial")
    else
        logger.warn("deskdashnative: lỗi dựng dữ liệu:", st)
    end

    local delay = self:nextDelay()
    if self.fetch_failed then delay = math.min(delay, CFG.retry_sec) end
    self:schedule(delay)
end

return DeskDash
