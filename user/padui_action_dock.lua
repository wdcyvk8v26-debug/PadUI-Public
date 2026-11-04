-- PadUI Action Dock 0.4 - opt-in native 40-slot dock for Ryzom Lua 5.1.
-- Two original native actionbar windows; no changes to any shortcut handlers,
-- window transparency outside these bars, global mouseover, or server/client.
PadUIActionDock = PadUIActionDock or {}
local D = PadUIActionDock

local ROOT = "ui:interface:"
local MAIN = ROOT .. "gestionsets"
local ALT = ROOT .. "gestionsets2"
local SAVE = "UI:SAVE:PADUI:ACTION_DOCK:"
local ALT_MODE = "UI:SAVE:GESTIONSETS2_MODE"
local HORIZONTAL = 1
local BELOW = 0
local ABOVE = 1
local GAP = 0   -- two matching shells read as one continuous dock

local function find(path) return getUI(path) end
local function num(v, fallback) return tonumber(v) or fallback end
local function getSetting(name, fallback)
    return num(getDbProp(SAVE .. name), fallback)
end
local function saveSetting(name, v)
    setDbProp(SAVE .. name, v)
end
local function set(path, field, v)
    local element = find(path)
    if element and v ~= nil then element[field] = v end
end
local function update(e)
    if e then e:updateCoords() end
end
local function rgba(rgb, a)
    return rgb .. " " .. tostring(a)
end
local function clamp(v, lower, upper)
    if upper < lower then return v end
    return math.max(lower, math.min(upper, v))
end

local styles = {
    {name="GOLD",   glass="13 17 24", accent="192 153 94", shade="102 120 127"},
    {name="AETHER", glass="10 22 27", accent="87 174 172", shade="93 141 158"},
    {name="EMBER",  glass="26 15 22", accent="203 132 111", shade="144 93 121"}
}
local function style()
    return styles[getSetting("THEME", 0) + 1] or styles[1]
end

function D:log(msg)
    if debugInfo then debugInfo("PadUI Action Dock: " .. tostring(msg)) end
end

function D:dimensions()
    local pitch = getSetting("SPACING",0)==1 and 36 or 28
    -- Main retains the left/right hand icons and native page controls.
    local w = 410 + (pitch-28)*10
    local h1 = 74 + (pitch-28)*2
    local h2 = 70 + (pitch-28)*2
    return pitch,w,h1,h2
end

function D:placeSlots(group,pitch)
    for i=0,19 do
        local x = (i%10)*pitch
        local y = -math.floor(i/10)*pitch
        set(group .. ":s" .. i, "x", x)
        set(group .. ":s" .. i, "y", y)
    end
end

function D:drawSlotEdges(group,pitch,accent)
    local cell = pitch-2
    local offset = math.floor((cell-24)/2)
    local prefix = group .. ":padui_slot_chrome:"
    local color = getSetting("GLASS",1)==2 and 108 or 170
    for i=0,19 do
        local x = (i%10)*pitch-offset
        local y = -math.floor(i/10)*pitch+offset
        local p = prefix .. "frame" .. i
        set(p,"x",x); set(p,"y",y); set(p,"w",cell); set(p,"h",cell)
        set(p,"color",rgba("12 19 27",color))
        local top=prefix .. "edge_top" .. i
        set(top,"x",x); set(top,"y",y); set(top,"w",cell)
        set(top,"color",rgba(accent,185))
        local left=prefix .. "edge_left" .. i
        set(left,"x",x); set(left,"y",y); set(left,"h",cell)
        set(left,"color",rgba(accent,110))
        local right=prefix .. "edge_right" .. i
        set(right,"x",x+cell-1); set(right,"y",y); set(right,"h",cell)
        set(right,"color",rgba(accent,62))
        local bottom=prefix .. "edge_bottom" .. i
        set(bottom,"x",x); set(bottom,"y",y-cell+1); set(bottom,"w",cell)
        set(bottom,"color",rgba(accent,68))
    end
end

function D:skin(enabled)
    local parts={MAIN .. ":padui_dock_chrome",
        ALT .. ":header_closed:padui_dock_chrome",
        MAIN .. ":shortcuts:padui_slot_chrome",
        ALT .. ":header_closed:shortcuts:padui_slot_chrome"}
    for _,path in ipairs(parts) do set(path,"active",enabled) end
    for _,id in ipairs({"padui_weapon_frame_l","padui_weapon_frame_r",
        "padui_weapon_label_l","padui_weapon_label_r"}) do
        set(MAIN .. ":hands:" .. id,"active",enabled)
    end
    if not enabled then
        local original=self.original
        for _,p in ipairs({MAIN,ALT}) do
            local b=find(p .. ":padui_back")
            local a=find(p .. ":padui_accent")
            if b then b.active=not (original and original[p .. ":back"]==false) end
            if a then a.active=not (original and original[p .. ":accent"]==false) end
        end
        return
    end

    for _,p in ipairs({MAIN,ALT}) do
        set(p .. ":padui_back","active",false)
        set(p .. ":padui_accent","active",false)
    end
    local theme=style()
    local alpha=({[0]=244,[1]=207,[2]=155})[getSetting("GLASS",1)] or 207
    local pitch=self:dimensions()
    local side=getSetting("SIDE",BELOW)
    for i,chrome in ipairs({parts[1],parts[2]}) do
        set(chrome .. ":glass","color",rgba(theme.glass,alpha))
        set(chrome .. ":sheen","color",rgba(theme.shade,44))
        for _,part in ipairs({"line_top","line_bottom","line_left","line_right","line_inner"}) do
            set(chrome .. ":" .. part,"color",rgba(theme.accent,
                (part=="line_top" or part=="line_bottom") and 174 or 126))
        end
        set(chrome .. ":branding","color",rgba(theme.accent,225))
        set(chrome .. ":padui_mode","color",rgba(theme.accent,190))
        set(chrome .. ":riv_l","color",rgba(theme.accent,210))
        set(chrome .. ":riv_r","color",rgba(theme.accent,210))
        -- No second titlebar: only the primary bar shows a compact identity.
        set(chrome .. ":branding","active",i==1)
        set(chrome .. ":padui_mode","active",i==1)
        set(chrome .. ":riv_l","active",i==1)
        set(chrome .. ":riv_r","active",i==1)
        set(chrome .. ":aux_label","active",false)
        set(chrome .. ":aux_caption","active",false)
        set(chrome .. ":padui_mode","hardtext",theme.name .. " / " .. pitch)
        -- Joined seams have no double gold line.
        local isTop=(side==BELOW and i==1) or (side==ABOVE and i==2)
        set(chrome .. ":line_top","active",isTop)
        set(chrome .. ":line_bottom","active",not isTop)
    end
    local mainGrid=MAIN .. ":shortcuts"
    local altGrid=ALT .. ":header_closed:shortcuts"
    self:drawSlotEdges(mainGrid,pitch,theme.accent)
    self:drawSlotEdges(altGrid,pitch,theme.accent)
    for _,id in ipairs({"padui_weapon_frame_l","padui_weapon_frame_r"}) do
        set(MAIN .. ":hands:" .. id,"color",rgba(theme.accent,190))
    end
    for _,id in ipairs({"padui_weapon_label_l","padui_weapon_label_r"}) do
        set(MAIN .. ":hands:" .. id,"color",rgba(theme.accent,220))
    end
end

function D:geometry()
    if not self.joined then return end
    local pitch,w,mainH,altH=self:dimensions()
    local mainGrid=MAIN .. ":shortcuts"
    local altHeader=ALT .. ":header_closed"
    local altGrid=altHeader .. ":shortcuts"

    set(MAIN,"w",w); set(MAIN,"h",mainH)
    set(MAIN .. ":header_closed","w",w-16)
    set(MAIN .. ":header_closed","h",mainH)
    set(MAIN .. ":hands","w",w-18)
    set(MAIN .. ":hands","h",68+(pitch-28)*2)
    set(mainGrid,"w",10*pitch-2)
    set(mainGrid,"h",pitch+24)
    set(MAIN .. ":select_memory","w",10*pitch+17)
    self:placeSlots(mainGrid,pitch)

    set(ALT,"w",w); set(ALT,"h",altH)
    set(altHeader,"w",w); set(altHeader,"h",altH)
    set(altGrid,"x",58); set(altGrid,"y",-12)
    set(altGrid,"w",10*pitch-2); set(altGrid,"h",pitch+24)
    set(ALT .. ":select_memory_h","w",10*pitch+20)
    self:placeSlots(altGrid,pitch)

    for _,spec in ipairs({{path=MAIN .. ":padui_dock_chrome",h=mainH},
        {path=altHeader .. ":padui_dock_chrome",h=altH}}) do
        local cp,h=spec.path,spec.h
        set(cp,"w",w); set(cp,"h",h)
        set(cp .. ":glass","w",w); set(cp .. ":glass","h",h)
        set(cp .. ":sheen","w",w-4)
        set(cp .. ":line_top","w",w-4)
        set(cp .. ":line_bottom","w",w-4)
        set(cp .. ":line_bottom","y",-h+2)
        set(cp .. ":line_left","h",h-4)
        set(cp .. ":line_right","x",w-2)
        set(cp .. ":line_right","h",h-4)
        set(cp .. ":line_inner","h",h-10)
        set(cp .. ":riv_r","x",w-9)
        set(cp .. ":padui_mode","x",w-106)
    end
    self:skin(true)
    update(find(MAIN))
    update(find(ALT))
    self:sync("main")
end

-- Native screen-space movement using DELTAS. Never assign x_real/y_real to x/y.
-- This works with existing Ryzom window position references and drag handlers.
function D:moveReal(e,targetX,targetY)
    if not e then return end
    update(e)
    local x0=num(e.x_real,num(e.x,0))
    local y0=num(e.y_real,num(e.y,0))
    local dx=math.floor(targetX-x0+0.5)
    local dy=math.floor(targetY-y0+0.5)
    if dx==0 and dy==0 then return end
    e.x=num(e.x,0)+dx
    e.y=num(e.y,0)+dy
    update(e)
end

function D:sync(source)
    if not self.joined or self.moving then return end
    local main,alt=find(MAIN),find(ALT)
    if not main or not alt or not main.active or not alt.active then return end
    self.moving=true
    local ok,err=pcall(function()
        update(main); update(alt)
        local side=getSetting("SIDE",BELOW)
        local mainH=num(main.h_real,num(main.h,74))
        local altH=num(alt.h_real,num(alt.h,70))
        if source=="alt" then
            local x=num(alt.x_real,0)
            local y=num(alt.y_real,0)
            local mainY=side==BELOW and y+altH+GAP or y-mainH-GAP
            self:moveReal(main,x,mainY)
        end

        -- Entire joined dock stays within the same screen rectangle.
        update(main)
        local root=find("ui:interface")
        local sw=root and num(root.w_real,num(root.w,0)) or 0
        local sh=root and num(root.h_real,num(root.h,0)) or 0
        local x=num(main.x_real,0)
        local y=num(main.y_real,0)
        local w=num(main.w_real,num(main.w,410))
        if sw>=w then x=clamp(x,0,sw-w) end
        if sh>=mainH+altH+GAP then
            if side==BELOW then
                y=clamp(y,altH+GAP,sh-mainH)
            else
                y=clamp(y,0,sh-mainH-altH-GAP)
            end
        end
        self:moveReal(main,x,y)
        update(main)
        local ax=num(main.x_real,0)
        local my=num(main.y_real,0)
        local ay=side==BELOW and my-altH-GAP or my+mainH+GAP
        self:moveReal(alt,ax,ay)
    end)
    self.moving=false
    if not ok then self:log("move sync failed: " .. tostring(err)) end
end

function D:saveOriginal(main,alt)
    if getSetting("BACKUP_VALID",0)==0 then
        saveSetting("FIRST_ACTIVE",main.active and 1 or 0)
        saveSetting("SECOND_ACTIVE",alt.active and 1 or 0)
        saveSetting("SECOND_X",num(alt.x,0))
        saveSetting("SECOND_Y",num(alt.y,0))
        saveSetting("SECOND_MODE",num(getDbProp(ALT_MODE),0))
        saveSetting("BACKUP_VALID",1)
    end
    -- Before docking, remember original presentation of exactly these two bars.
    self.original={}
    for _,p in ipairs({MAIN,ALT}) do
        local b=find(p .. ":padui_back")
        local a=find(p .. ":padui_accent")
        self.original[p .. ":back"]=b and b.active or false
        self.original[p .. ":accent"]=a and a.active or false
    end
end

function D:enable()
    if self.joined then self:sync("main") return true end
    local main,alt=find(MAIN),find(ALT)
    if not main or not alt then
        self:log("native action bars missing; no changes")
        return false
    end
    self:saveOriginal(main,alt)
    main.active=true
    alt.active=true

    -- Upgrade from 0.3: ALT may still be parent-positioned against MAIN.
    -- Return it to its native root before establishing screen-space drag syncing.
    local root=find("ui:interface")
    if root then
        alt:setParentPos(root)
        alt:setPosRef("BL BL")
    end
    setDbProp(ALT_MODE,HORIZONTAL)
    local ok,err=pcall(runAH,nil,"proc","gestionsets2_proc_horiz")
    if not ok then
        self:log("native horizontal orientation failed: "..tostring(err))
        self.joined=true
        self:disable()
        return false
    end
    self.joined=true
    self:geometry()
    if game and game.updateCurrentActionPosition then
        pcall(function() game:updateCurrentActionPosition() end)
    end
    saveSetting("ENABLED",1)
    self:log("joined at "..(getSetting("SIDE",BELOW)==BELOW and "BOTTOM" or "TOP"))
    return true
end

function D:disable()
    if not self.joined and getSetting("ENABLED",0)~=1 then return true end
    self.joined=false
    self:skin(false)

    local main,alt=find(MAIN),find(ALT)
    if alt then
        local root=find("ui:interface")
        if root then alt:setParentPos(root); alt:setPosRef("BL BL") end
    end

    if getSetting("BACKUP_VALID",0)==1 then
        setDbProp(ALT_MODE,getSetting("SECOND_MODE",2))
        pcall(runAH,nil,"proc","gestionsets2_proc_mode")
    end

    self:resetGeometry()
    if alt and getSetting("BACKUP_VALID",0)==1 then
        alt.x=getSetting("SECOND_X",num(alt.x,0))
        alt.y=getSetting("SECOND_Y",num(alt.y,0))
        alt.active=getSetting("SECOND_ACTIVE",1)==1
        update(alt)
    end
    if main and getSetting("BACKUP_VALID",0)==1 then
        main.active=getSetting("FIRST_ACTIVE",1)==1
    end
    self.original=nil
    saveSetting("BACKUP_VALID",0)
    saveSetting("ENABLED",0)
    self:log("restored independently movable native action bars")
    return true
end

function D:resetGeometry()
    set(MAIN,"w",410); set(MAIN,"h",48)
    set(MAIN .. ":header_closed","w",394)
    set(MAIN .. ":header_closed","h",48)
    set(MAIN .. ":hands","w",392)
    set(MAIN .. ":hands","h",68)
    set(MAIN .. ":shortcuts","w",278)
    set(MAIN .. ":shortcuts","h",52)
    set(MAIN .. ":select_memory","w",297)
    for i=0,19 do
        set(MAIN .. ":shortcuts:s" .. i,"x",(i%10)*28)
        set(MAIN .. ":shortcuts:s" .. i,"y",-math.floor(i/10)*26)
    end
    set(ALT .. ":header_closed:shortcuts","x",0)
    set(ALT .. ":header_closed:shortcuts","y",-1)
    set(ALT .. ":select_memory_h","w",300)
    if num(getDbProp(ALT_MODE),0)==HORIZONTAL then
        for i=0,19 do
            set(ALT .. ":header_closed:shortcuts:s" .. i,"x",(i%10)*28)
            set(ALT .. ":header_closed:shortcuts:s" .. i,"y",-math.floor(i/10)*26)
        end
    end
    update(find(MAIN)); update(find(ALT))
end

function D:joinBelow()
    saveSetting("SIDE",BELOW)
    if not self.joined then return self:enable() end
    self:skin(true); self:sync("main")
    return true
end
function D:joinAbove()
    saveSetting("SIDE",ABOVE)
    if not self.joined then return self:enable() end
    self:skin(true); self:sync("main")
    return true
end
function D:setSide(which)
    if num(which,BELOW)==ABOVE then return self:joinAbove() end
    return self:joinBelow()
end
function D:toggle()
    if self.joined then return self:disable() end
    return self:joinBelow()
end
function D:setSpacing(which)
    which=num(which,-1)
    if which~=0 and which~=1 then return end
    saveSetting("SPACING",which)
    if self.joined then self:geometry() end
end
function D:setTheme(which)
    which=num(which,-1)
    if which<0 or which>2 then return end
    saveSetting("THEME",which)
    if self.joined then self:skin(true) end
end
function D:setGlass(which)
    which=num(which,-1)
    if which<0 or which>2 then return end
    saveSetting("GLASS",which)
    if self.joined then self:skin(true) end
end
function D:prepareManualSecondBarChange()
    if self.joined then self:disable() end
end
function D:onMainMoved()
    -- The original castbar positioning callback remains unchanged.
    if game and game.updateCurrentActionPosition then
        pcall(function() game:updateCurrentActionPosition() end)
    end
    if self.joined then self:sync("main") end
end
function D:onAltMoved()
    if not self.joined then return end
    self:sync("alt")
    if game and game.updateCurrentActionPosition then
        pcall(function() game:updateCurrentActionPosition() end)
    end
end
function D:start()
    self.joined=false
    self.moving=false
    self.original=nil
    if getSetting("ENABLED",0)==1 then self:enable() end
end
