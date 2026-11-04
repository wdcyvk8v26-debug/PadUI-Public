-- PadUI Action Dock - native Ryzom UI prototype (Lua 5.1).
-- All 40 controls remain original MEMORY/MEMORY_ALT slots. No synthetic phrases.
-- No change to global mouseover/alpha, other windows, C++ or server.
PadUIActionDock = PadUIActionDock or {}
local D = PadUIActionDock

local ROOT = "ui:interface:"
local SAVE = "UI:SAVE:PADUI:ACTION_DOCK:"
local MODE = "UI:SAVE:GESTIONSETS2_MODE"
local SECOND_H = 1
local SEP = 2
local PRIMARY = ROOT .. "gestionsets"
local SECONDARY = ROOT .. "gestionsets2"

local function get(path) return getUI(path) end
local function number(v, fallback) return tonumber(v) or fallback end
local function db(key, fallback) return number(getDbProp(SAVE .. key), fallback) end
local function set(key, value) setDbProp(SAVE .. key, value) end

local function prop(path, field, value)
    local element = get(path)
    if element and value ~= nil then element[field] = value end
end

function D:log(message)
    if debugInfo then debugInfo("PadUI Action Dock: " .. tostring(message)) end
end

function D:design()
    -- Both presets retain the native 24 px sheet textures and native controls.
    local wide = db("SPACING", 0) == 1
    local pitch = wide and 31 or 28
    local extra = (pitch - 28) * 10
    return pitch, 410 + extra, 74 + (pitch - 28) * 2, 64 + (pitch - 28) * 2, extra
end

function D:skin(enabled)
    -- Hide only these two original PadUI bar backdrops while the independent
    -- glass layers are drawn, so the three opacity presets stay meaningful.
    prop(PRIMARY .. ":padui_back", "active", not enabled)
    prop(SECONDARY .. ":padui_back", "active", not enabled)
    prop(PRIMARY .. ":padui_dock_chrome", "active", enabled)
    prop(SECONDARY .. ":header_closed:padui_dock_chrome", "active", enabled)
    prop(PRIMARY .. ":shortcuts:padui_slot_chrome", "active", enabled)
    prop(SECONDARY .. ":header_closed:shortcuts:padui_slot_chrome", "active", enabled)
    for _,id in ipairs({"padui_weapon_frame_l", "padui_weapon_frame_r", "padui_weapon_label_l", "padui_weapon_label_r"}) do
        prop(PRIMARY .. ":hands:" .. id, "active", enabled)
    end
    if not enabled then return end

    local alpha = ({[0]=236, [1]=211, [2]=176})[db("GLASS", 1)] or 211
    prop(PRIMARY .. ":padui_dock_chrome:glass", "color", "10 17 26 " .. alpha)
    prop(SECONDARY .. ":header_closed:padui_dock_chrome:glass", "color", "10 17 26 " .. alpha)
end

function D:slotGeometry(path, pitch, rowPitch)
    -- Native Ryzom default is 28 px horizontally but 26 px vertically.
    rowPitch = rowPitch or pitch
    for i = 0, 19 do
        local col, row = i % 10, math.floor(i / 10)
        prop(path .. ":s" .. i, "x", col * pitch)
        prop(path .. ":s" .. i, "y", -row * rowPitch)
        local frame = path .. ":padui_slot_chrome:frame" .. i
        prop(frame, "x", col * pitch - 1)
        prop(frame, "y", -row * rowPitch + 1)
    end
end

function D:geometry()
    local pitch, width, mainH, upperH, extra = self:design()
    local mainHeader = PRIMARY .. ":header_closed"
    local mainHands = PRIMARY .. ":hands"
    local mainShort = PRIMARY .. ":shortcuts"
    local upperHeader = SECONDARY .. ":header_closed"
    local upperShort = upperHeader .. ":shortcuts"

    prop(PRIMARY, "w", width)
    prop(PRIMARY, "h", mainH)
    prop(mainHeader, "w", width - 16)
    prop(mainHeader, "h", mainH)
    prop(mainHands, "w", 392 + extra)
    prop(mainShort, "w", 278 + extra)
    prop(mainShort, "h", 52 + (pitch - 28))
    prop(PRIMARY .. ":select_memory", "w", 297 + extra)
    self:slotGeometry(mainShort, pitch)

    prop(SECONDARY, "w", width)
    prop(SECONDARY, "h", upperH)
    prop(upperHeader, "w", width)
    prop(upperHeader, "h", upperH)
    prop(upperShort, "x", 58)
    prop(upperShort, "y", -4)
    prop(upperShort, "w", 278 + extra)
    prop(upperShort, "h", 52 + (pitch - 28))
    prop(SECONDARY .. ":select_memory_h", "w", 300 + extra)
    self:slotGeometry(upperShort, pitch)

    for _,path in ipairs({PRIMARY .. ":padui_dock_chrome", upperHeader .. ":padui_dock_chrome"}) do
        prop(path, "w", width)
        prop(path, "h", path == PRIMARY .. ":padui_dock_chrome" and mainH or upperH)
        prop(path .. ":glass", "w", width)
        prop(path .. ":glass", "h", path == PRIMARY .. ":padui_dock_chrome" and mainH or upperH)
        prop(path .. ":sheen", "w", width - 4)
        prop(path .. ":line_top", "w", width - 4)
        prop(path .. ":line_bottom", "w", width - 4)
        prop(path .. ":line_bottom", "y", -(path == PRIMARY .. ":padui_dock_chrome" and mainH or upperH) + 2)
        prop(path .. ":line_right", "x", width - 2)
        prop(path .. ":line_right", "h", (path == PRIMARY .. ":padui_dock_chrome" and mainH or upperH) - 4)
    end

    if self.joined then self:align() end
end

function D:resetGeometry()
    local mainShort = PRIMARY .. ":shortcuts"
    local upperHeader = SECONDARY .. ":header_closed"
    local upperShort = upperHeader .. ":shortcuts"

    prop(PRIMARY, "w", 410)
    prop(PRIMARY, "h", 48)
    prop(PRIMARY .. ":header_closed", "w", 394)
    prop(PRIMARY .. ":header_closed", "h", 48)
    prop(PRIMARY .. ":hands", "w", 392)
    prop(mainShort, "w", 278)
    prop(mainShort, "h", 52)
    prop(PRIMARY .. ":select_memory", "w", 297)
    -- The native orientation proc is invoked before these resets.
    prop(upperShort, "x", 0)
    prop(upperShort, "y", -1)
    prop(SECONDARY .. ":select_memory_h", "w", 300)
    self:slotGeometry(mainShort, 28, 26)
    -- A vertical secondary bar is positioned by Ryzom's native proc. Only
    -- restore horizontal slot positions when the original mode was horizontal.
    if number(getDbProp(MODE), 0) == SECOND_H then
        self:slotGeometry(upperShort, 28, 26)
    end
end

function D:align()
    if not self.joined then return end
    local main, upper = get(PRIMARY), get(SECONDARY)
    if not main or not upper or not main.active or not upper.active then return end

    -- x_real/y_real reflect the screen position of the original action bar.
    local x = number(main.x_real, number(main.x, 0))
    local y = number(main.y_real, number(main.y, 0)) + number(main.h_real, number(main.h, 74)) + 2
    local root = get("ui:interface")
    local screenW = root and number(root.w_real, number(root.w, 0)) or 0
    local screenH = root and number(root.h_real, number(root.h, 0)) or 0
    local w = number(upper.w_real, number(upper.w, 410))
    local h = number(upper.h_real, number(upper.h, 64))

    if screenW > w then x = math.max(0, math.min(x, screenW - w)) end
    if screenH > h and y + h > screenH then
        -- Still keep both bars visible near the top of the screen.
        y = number(main.y_real, number(main.y, 0)) - h - 2
    end
    if screenH > h then y = math.max(0, math.min(y, screenH - h)) end
    upper.x = math.floor(x + 0.5)
    upper.y = math.floor(y + 0.5)
end

function D:saveOriginal(main, upper)
    -- A separate saved snapshot survives relog even if the dock is enabled.
    if db("BACKUP_VALID", 0) == 1 then return end
    set("FIRST_ACTIVE", main.active and 1 or 0)
    set("SECOND_ACTIVE", upper.active and 1 or 0)
    set("SECOND_X", number(upper.x, 0))
    set("SECOND_Y", number(upper.y, 0))
    set("SECOND_MODE", number(getDbProp(MODE), 0))
    set("BACKUP_VALID", 1)
end

function D:enable()
    if self.joined then self:align(); return true end
    local main, upper = get(PRIMARY), get(SECONDARY)
    if not main or not upper then
        self:log("native bars not found; original interface unchanged")
        return false
    end
    self:saveOriginal(main, upper)
    main.active = true
    upper.active = true
    setDbProp(MODE, SECOND_H)
    local ok, err = pcall(runAH, nil, "proc", "gestionsets2_proc_horiz")
    if not ok then
        self:log("native horizontal mode failed: " .. tostring(err))
        self.joined = true
        self:disable() -- restore saved activation, second bar orientation and position
        return false
    end

    self.joined = true
    self:geometry()
    self:skin(true)
    self:align()
    if game and game.updateCurrentActionPosition then
        pcall(function() game:updateCurrentActionPosition() end)
    end
    local dockChrome = get(PRIMARY .. ":padui_dock_chrome")
    if dockChrome then setOnDraw(dockChrome, "PadUIActionDock:tick()") end
    self.lastTick = nil
    set("ENABLED", 1)
    self:log("joined 20 native MEMORY + 20 native MEMORY_ALT slots")
    return true
end

function D:disable()
    if not self.joined and db("ENABLED", 0) ~= 1 then return true end
    self.joined = false
    local dockChrome = get(PRIMARY .. ":padui_dock_chrome")
    if dockChrome then setOnDraw(dockChrome, "") end
    self:skin(false)
    if db("BACKUP_VALID", 0) == 1 then
        setDbProp(MODE, db("SECOND_MODE", SEP))
        pcall(runAH, nil, "proc", "gestionsets2_proc_mode")
    end
    self:resetGeometry()
    local main, upper = get(PRIMARY), get(SECONDARY)
    if upper and db("BACKUP_VALID", 0) == 1 then
        upper.x = db("SECOND_X", number(upper.x, 0))
        upper.y = db("SECOND_Y", number(upper.y, 0))
        upper.active = db("SECOND_ACTIVE", 1) == 1
    end
    if main and db("BACKUP_VALID", 0) == 1 then
        main.active = db("FIRST_ACTIVE", 0) == 1
    end
    set("BACKUP_VALID", 0)
    set("ENABLED", 0)
    self:log("restored separate native action bars")
    return true
end

function D:toggle()
    if self.joined then return self:disable() else return self:enable() end
end

function D:setSpacing(which)
    which = number(which, -1)
    if which ~= 0 and which ~= 1 then return end
    set("SPACING", which)
    if self.joined then self:geometry() end
end

function D:setGlass(which)
    which = number(which, -1)
    if which < 0 or which > 2 then return end
    set("GLASS", which)
    if self.joined then self:skin(true) end
end

function D:tick()
    if not self.joined or not game or not game.InGameDbInitialized then return end
    -- Low-frequency guard against native orientation links restoring dimensions
    -- after the dock layout was initialized. Never touch phrase contents.
    local now = nltime and nltime.getLocalTime and nltime.getLocalTime() or 0
    if self.lastTick and now >= self.lastTick and now - self.lastTick < 500 then return end
    self.lastTick = now

    if number(getDbProp(MODE), 0) ~= SECOND_H then
        setDbProp(MODE, SECOND_H)
        pcall(runAH, nil, "proc", "gestionsets2_proc_horiz")
    end

    local main, upper = get(PRIMARY), get(SECONDARY)
    if not main or not upper then return end
    local _, width, mainH, upperH = self:design()
    if number(main.w, 0) ~= width or number(main.h, 0) ~= mainH or
       number(upper.w, 0) ~= width or number(upper.h, 0) ~= upperH then
        self:geometry()
    end
    self:align()
end

function D:prepareManualSecondBarChange()
    -- The original horizontal/vertical menu keeps its old behavior.
    if self.joined then self:disable() end
end

function D:onMainMoved()
    -- Preserve Ryzom's existing current-action/cast-bar position update.
    if game and game.updateCurrentActionPosition then
        local ok, err = pcall(function() game:updateCurrentActionPosition() end)
        if not ok then self:log("native current action position: " .. tostring(err)) end
    end
    if self.joined then self:align() end
end

function D:start()
    -- Explicitly reset runtime state on character/relog initialization.
    self.joined = false
    if db("ENABLED", 0) == 1 then self:enable() end
end
