-- PadUI Action Dock 0.3: experimental native Ryzom dock, Lua 5.1 compatible.
-- The 40 original native action controls and both hand slots are never replaced.
-- Only the two existing action-bar windows are repositioned/styled.
-- No global mouseover, tooltip, alpha or other window handlers are changed.
PadUIActionDock = PadUIActionDock or {}
local D = PadUIActionDock

local BASE = "ui:interface:"
local MAIN = BASE .. "gestionsets"
local ALT = BASE .. "gestionsets2"
local SAVE = "UI:SAVE:PADUI:ACTION_DOCK:"
local ALT_MODE = "UI:SAVE:GESTIONSETS2_MODE"
local HORIZONTAL = 1

local function ui(path) return getUI(path) end
local function value(v, fallback) return tonumber(v) or fallback end
local function setting(name, fallback) return value(getDbProp(SAVE .. name), fallback) end
local function save(name, v) setDbProp(SAVE .. name, v) end
local function put(path, field, v)
    local e = ui(path)
    if not e then return false end
    e[field] = v
    return true
end
local function redraw(e)
    if e then e:updateCoords() end
end
local function shade(rgb, alpha)
    return rgb .. " " .. tostring(alpha or 255)
end

local palettes = {
    -- Clearly distinct: metallic brass with cold blue secondary slots.
    {name="GOLD", glass="10 17 27", main="236 186 103", alt="110 202 205", glow="90 109 127"},
    -- Turquoise / electric-blue arcane theme.
    {name="AETHER", glass="5 23 32", main="68 225 219", alt="110 157 247", glow="50 153 179"},
    -- Warm copper/rose fantasy theme.
    {name="EMBER", glass="29 13 26", main="238 129 105", alt="187 137 241", glow="153 76 90"}
}
local function palette()
    return palettes[setting("THEME", 0) + 1] or palettes[1]
end

function D:log(text)
    if debugInfo then debugInfo("PadUI Action Dock: " .. tostring(text)) end
end

function D:design()
    -- The sheet pictures themselves have a fixed native Ryzom texture size.
    -- We change the slot GRID and the frame size, not the cast/drag handlers.
    local wide = setting("SPACING", 0) == 1
    local pitch = wide and 36 or 28
    local width = 410 + (pitch - 28) * 10
    local mainH = pitch + 52
    local altH = pitch + 48
    return pitch, width, mainH, altH
end

function D:frameColors(path, pitch, firstColor, secondColor)
    local cell = pitch == 36 and 32 or 26
    local inset = math.floor((cell - 24) / 2)
    for i = 0, 19 do
        local col, row = i % 10, math.floor(i / 10)
        local x = col * pitch - inset
        local y = -row * pitch + inset
        local base = path .. ":padui_slot_chrome:"
        local accent = row == 0 and firstColor or secondColor
        put(base .. "frame" .. i, "x", x)
        put(base .. "frame" .. i, "y", y)
        put(base .. "frame" .. i, "w", cell)
        put(base .. "frame" .. i, "h", cell)
        put(base .. "frame" .. i, "color", shade("17 26 35", 210))
        put(base .. "edge_top" .. i, "x", x)
        put(base .. "edge_top" .. i, "y", y)
        put(base .. "edge_top" .. i, "w", cell)
        put(base .. "edge_top" .. i, "color", shade(accent, 228))
        put(base .. "edge_left" .. i, "x", x)
        put(base .. "edge_left" .. i, "y", y)
        put(base .. "edge_left" .. i, "h", cell)
        put(base .. "edge_left" .. i, "color", shade(accent, 180))
        put(base .. "edge_right" .. i, "x", x + cell - 1)
        put(base .. "edge_right" .. i, "y", y)
        put(base .. "edge_right" .. i, "h", cell)
        put(base .. "edge_right" .. i, "color", shade(accent, 106))
        put(base .. "edge_bottom" .. i, "x", x)
        put(base .. "edge_bottom" .. i, "y", y - cell + 1)
        put(base .. "edge_bottom" .. i, "w", cell)
        put(base .. "edge_bottom" .. i, "color", shade(accent, 108))
    end
end

function D:placeSlots(path, pitch)
    for i = 0, 19 do
        local col, row = i % 10, math.floor(i / 10)
        put(path .. ":s" .. i, "x", col * pitch)
        put(path .. ":s" .. i, "y", -row * pitch)
    end
end

function D:skin(enabled)
    if not enabled then
        local original = self.original or {}
        for _,p in ipairs({MAIN,ALT}) do
            local back = ui(p .. ":padui_back")
            local accent = ui(p .. ":padui_accent")
            if back then back.active = original[p .. ":back"] ~= false end
            if accent then accent.active = original[p .. ":accent"] ~= false end
        end
    else
        put(MAIN .. ":padui_back", "active", false)
        put(ALT .. ":padui_back", "active", false)
        put(MAIN .. ":padui_accent", "active", false)
        put(ALT .. ":padui_accent", "active", false)
    end

    for _,p in ipairs({MAIN .. ":padui_dock_chrome",ALT .. ":header_closed:padui_dock_chrome",
        MAIN .. ":shortcuts:padui_slot_chrome",
        ALT .. ":header_closed:shortcuts:padui_slot_chrome"}) do
        put(p, "active", enabled)
    end
    for _,id in ipairs({"padui_weapon_frame_l","padui_weapon_frame_r",
         "padui_weapon_label_l","padui_weapon_label_r"}) do
        put(MAIN .. ":hands:" .. id, "active", enabled)
    end
    if not enabled then return end

    local p = palette()
    local transparency = ({[0]=245,[1]=195,[2]=106})[setting("GLASS",1)] or 195
    local pitch = self:design()
    for index,cp in ipairs({MAIN .. ":padui_dock_chrome",
        ALT .. ":header_closed:padui_dock_chrome"}) do
        local accent = index == 1 and p.main or p.alt
        put(cp .. ":glass", "color", shade(p.glass, transparency))
        put(cp .. ":sheen", "color", shade(p.glow, 120))
        put(cp .. ":line_top", "color", shade(accent, 255))
        put(cp .. ":line_bottom", "color", shade(accent, 220))
        put(cp .. ":line_left", "color", shade(accent, 225))
        put(cp .. ":line_right", "color", shade(accent, 225))
        put(cp .. ":line_inner", "color", shade(accent, 110))
        put(cp .. ":branding", "color", shade(accent, 255))
        put(cp .. ":padui_mode", "color", shade(accent, 255))
        put(cp .. ":riv_l", "color", shade(accent, 255))
        put(cp .. ":riv_r", "color", shade(accent, 255))
        put(cp .. ":padui_mode", "hardtext", p.name .. " / " .. tostring(pitch))
    end
    self:frameColors(MAIN .. ":shortcuts", pitch, p.main, p.alt)
    self:frameColors(ALT .. ":header_closed:shortcuts", pitch, p.alt, p.main)
    for _,id in ipairs({"padui_weapon_frame_l","padui_weapon_frame_r"}) do
        put(MAIN .. ":hands:" .. id, "color", shade(p.main, 220))
    end
    for _,id in ipairs({"padui_weapon_label_l","padui_weapon_label_r"}) do
        put(MAIN .. ":hands:" .. id, "color", shade(p.main, 255))
    end
end

function D:geometry()
    if not self.joined then return end
    local pitch, width, mainH, altH = self:design()
    local mainShort = MAIN .. ":shortcuts"
    local altHead = ALT .. ":header_closed"
    local altShort = altHead .. ":shortcuts"

    -- On Core4 a container recalculates its height from header_closed.
    put(MAIN .. ":header_closed", "h", mainH)
    put(MAIN .. ":header_closed", "w", width - 16)
    put(MAIN, "w", width)
    put(MAIN, "h", mainH)
    put(MAIN .. ":hands", "w", width - 18)
    put(MAIN .. ":hands", "h", pitch + 40)
    put(mainShort, "w", 10 * pitch - 2)
    put(mainShort, "h", pitch + 24)
    put(MAIN .. ":select_memory", "w", 10 * pitch + 17)
    self:placeSlots(mainShort, pitch)

    put(altHead, "w", width)
    put(altHead, "h", altH)
    put(ALT, "w", width)
    put(ALT, "h", altH)
    put(altShort, "x", 58)
    put(altShort, "y", -12)
    put(altShort, "w", 10 * pitch - 2)
    put(altShort, "h", pitch + 24)
    put(ALT .. ":select_memory_h", "w", 10 * pitch + 20)
    self:placeSlots(altShort, pitch)

    for _,item in ipairs({
       {path=MAIN .. ":padui_dock_chrome",height=mainH},
       {path=altHead .. ":padui_dock_chrome",height=altH}
    }) do
        local path, height = item.path,item.height
        put(path,"w",width)
        put(path,"h",height)
        put(path .. ":glass","w",width)
        put(path .. ":glass","h",height)
        put(path .. ":sheen","w",width-4)
        put(path .. ":line_top","w",width-4)
        put(path .. ":line_bottom","w",width-4)
        put(path .. ":line_bottom","y",-height+2)
        put(path .. ":line_left","h",height-4)
        put(path .. ":line_right","x",width-2)
        put(path .. ":line_right","h",height-4)
        put(path .. ":line_inner","h",height-10)
        put(path .. ":riv_r","x",width-9)
        put(path .. ":padui_mode","x",width-106)
    end

    self:skin(true)
    redraw(ui(MAIN))
    redraw(ui(ALT))
    self:align(true)
end

function D:saveOriginal(main, alt)
    -- This backup survives a relog while the dock stays selected.
    if setting("BACKUP_VALID",0) == 0 then
        save("FIRST_ACTIVE",main.active and 1 or 0)
        save("SECOND_ACTIVE",alt.active and 1 or 0)
        save("SECOND_X",value(alt.x,0))
        save("SECOND_Y",value(alt.y,0))
        save("SECOND_MODE",value(getDbProp(ALT_MODE),0))
        save("BACKUP_VALID",1)
    end

    -- Exact original runtime reference/position; no other window is changed.
    local anchor = {}
    anchor.x = alt.x
    anchor.y = alt.y
    anchor.posref = alt.posref
    anchor.parentposref = alt.parentposref
    anchor.parentId = alt.posparent
    self.original = self.original or {}
    self.original.anchor = anchor
    for _,p in ipairs({MAIN,ALT}) do
        local back=ui(p .. ":padui_back")
        local accent=ui(p .. ":padui_accent")
        self.original[p .. ":back"] = back and back.active or false
        self.original[p .. ":accent"] = accent and accent.active or false
    end
end

function D:align(force)
    if not self.joined then return end
    local main,alt=ui(MAIN),ui(ALT)
    if not main or not alt or not main.active or not alt.active then return end

    redraw(main)
    -- Use the actual on-screen bounds ONLY to select above/below.
    -- The alt window itself is anchored by Ryzom, not by mixing x_real with x.
    local root=ui("ui:interface")
    local screenH=root and value(root.h_real,value(root.h,0)) or 0
    local mainY=value(main.y_real,0)
    local mainH=value(main.h_real,value(main.h,80))
    local altH=value(alt.h_real,value(alt.h,76))
    local above=screenH-(mainY+mainH)
    local below=mainY
    local side=(above>=altH+3 or above>=below) and "above" or "below"

    if force or self.side~=side then
        -- Cross-window parent anchoring is implemented by CInterfaceElement.
        -- "TL BL": alt bottom to main top; "BL TL": alt top to main bottom.
        alt:setParentPos(main)
        if side=="above" then
            alt:setPosRef("TL BL")
        else
            alt:setPosRef("BL TL")
        end
        self.side=side
    end
    alt.x=0
    alt.y=(side=="above" and 2 or -2)
    redraw(alt)
end

function D:enable()
    if self.joined then self:geometry() return true end
    local main,alt=ui(MAIN),ui(ALT)
    if not main or not alt then
        self:log("missing native main/secondary action bar; not enabled")
        return false
    end
    self:saveOriginal(main,alt)
    main.active=true
    alt.active=true
    setDbProp(ALT_MODE,HORIZONTAL)
    local ok,err=pcall(runAH,nil,"proc","gestionsets2_proc_horiz")
    if not ok then
        self:log("native alt bar horizontal mode failed: "..tostring(err))
        self.joined=true
        self:disable()
        return false
    end

    self.joined=true
    self.side=nil
    self:geometry()
    -- Reuse the existing native cast-window positioning callback.
    if game and game.updateCurrentActionPosition then
        pcall(function() game:updateCurrentActionPosition() end)
    end
    local chrome=ui(MAIN .. ":padui_dock_chrome")
    if chrome then setOnDraw(chrome,"PadUIActionDock:tick()") end
    self.lastTick=nil
    save("ENABLED",1)
    self:log("joined 20 MEMORY + 20 MEMORY_ALT controls")
    return true
end

function D:detachAlt()
    local alt=ui(ALT)
    if not alt then return end
    local root=ui("ui:interface")
    if root then alt:setParentPos(root) end
    local anchor=self.original and self.original.anchor or nil
    if anchor and anchor.parentId and anchor.parentId~="parent" and anchor.parentId~="" then
        pcall(function() alt.posparent=anchor.parentId end)
    end
    if anchor and anchor.parentposref and anchor.posref then
        alt:setPosRef(anchor.parentposref .. " " .. anchor.posref)
    else
        alt:setPosRef("BL BL")
    end
    alt.x=anchor and anchor.x or setting("SECOND_X",0)
    alt.y=anchor and anchor.y or setting("SECOND_Y",0)
    redraw(alt)
    self.side=nil
end

function D:resetGeometry()
    -- Reset native main layout to its exact original dimensions and 28x26.
    put(MAIN,"w",410)
    put(MAIN,"h",48)
    put(MAIN .. ":header_closed","h",48)
    put(MAIN .. ":header_closed","w",394)
    put(MAIN .. ":hands","w",392)
    put(MAIN .. ":hands","h",68)
    put(MAIN .. ":shortcuts","w",278)
    put(MAIN .. ":shortcuts","h",52)
    put(MAIN .. ":select_memory","w",297)
    for i=0,19 do
        put(MAIN .. ":shortcuts:s" .. i,"x",(i%10)*28)
        put(MAIN .. ":shortcuts:s" .. i,"y",-math.floor(i/10)*26)
    end
    put(ALT .. ":header_closed:shortcuts","x",0)
    put(ALT .. ":header_closed:shortcuts","y",-1)
    put(ALT .. ":select_memory_h","w",300)
    if value(getDbProp(ALT_MODE),0)==HORIZONTAL then
        for i=0,19 do
            put(ALT .. ":header_closed:shortcuts:s" .. i,"x",(i%10)*28)
            put(ALT .. ":header_closed:shortcuts:s" .. i,"y",-math.floor(i/10)*26)
        end
    end
    redraw(ui(MAIN))
    redraw(ui(ALT))
end

function D:disable()
    if not self.joined and setting("ENABLED",0)~=1 then return true end
    self.joined=false
    local chrome=ui(MAIN .. ":padui_dock_chrome")
    if chrome then setOnDraw(chrome,"") end
    self:skin(false)
    self:detachAlt()
    if setting("BACKUP_VALID",0)==1 then
        setDbProp(ALT_MODE,setting("SECOND_MODE",2))
        pcall(runAH,nil,"proc","gestionsets2_proc_mode")
    end
    self:resetGeometry()
    local main,alt=ui(MAIN),ui(ALT)
    if alt and setting("BACKUP_VALID",0)==1 then
        alt.active=setting("SECOND_ACTIVE",1)==1
    end
    if main and setting("BACKUP_VALID",0)==1 then
        main.active=setting("FIRST_ACTIVE",0)==1
    end
    self.original=nil
    save("BACKUP_VALID",0)
    save("ENABLED",0)
    self:log("detached; native positions, slots and orientation restored")
    return true
end

function D:toggle()
    if self.joined then return self:disable() else return self:enable() end
end

function D:setSpacing(v)
    v=value(v,-1)
    if v~=0 and v~=1 then return end
    save("SPACING",v)
    if self.joined then self:geometry() end
end
function D:setTheme(v)
    v=value(v,-1)
    if v<0 or v>2 then return end
    save("THEME",v)
    if self.joined then self:skin(true) end
end
function D:setGlass(v)
    v=value(v,-1)
    if v<0 or v>2 then return end
    save("GLASS",v)
    if self.joined then self:skin(true) end
end

function D:tick()
    if not self.joined or not game or not game.InGameDbInitialized then return end
    local now=nltime and nltime.getLocalTime and nltime.getLocalTime() or 0
    if self.lastTick and now>=self.lastTick and now-self.lastTick<500 then return end
    self.lastTick=now

    local main,alt=ui(MAIN),ui(ALT)
    if not main or not alt then return end
    if value(getDbProp(ALT_MODE),0)~=HORIZONTAL then
        setDbProp(ALT_MODE,HORIZONTAL)
        pcall(runAH,nil,"proc","gestionsets2_proc_horiz")
        self:geometry()
    end
    local _,w,mh,ah=self:design()
    if value(main.w,0)~=w or value(main.h,0)~=mh or
        value(alt.w,0)~=w or value(alt.h,0)~=ah then
        self:geometry()
    end
    self:align(false)
end

function D:prepareManualSecondBarChange()
    if self.joined then self:disable() end
end

function D:onMainMoved()
    if game and game.updateCurrentActionPosition then
        local ok,err=pcall(function() game:updateCurrentActionPosition() end)
        if not ok then self:log("original current action callback: "..tostring(err)) end
    end
    if self.joined then self:align(false) end
end

function D:diagnostics()
    local main,alt=ui(MAIN),ui(ALT)
    if not main or not alt then return end
    self:log("main ("..tostring(main.x_real)..","..tostring(main.y_real)..") "
        ..tostring(main.w_real).."x"..tostring(main.h_real)
        .."; alt ("..tostring(alt.x_real)..","..tostring(alt.y_real)..") "
        ..tostring(alt.w_real).."x"..tostring(alt.h_real)
        .."; anchor "..tostring(alt.posparent).."; side "..tostring(self.side))
end

function D:start()
    -- Restart per-character runtime, but keep saved preferences only.
    self.joined=false
    self.side=nil
    self.original=nil
    if setting("ENABLED",0)==1 then self:enable() end
end
