-- Compact team display for Ryzom. Only reads local UI data;
-- targeting is performed exclusively after the user clicks a row.
RyzomTeamUI = RyzomTeamUI or {}
local T = RyzomTeamUI
T.rows = {}
T.lastTick = nil
T.started = false
local ROOT = "ui:interface:team_compact"
local SORT_DB = "UI:SAVE:TEAM_COMPACT:SORT"
local SORT_MODES = {name=0, hp=1, missing=2}
local SORT_LABELS = {[0]="sort_name", [1]="sort_hp", [2]="sort_missing"}
debugInfo("PadUI Team: Lua loaded")

local function db(path)
    return tonumber(getDbProp(path)) or 0
end

local function cleanName(name)
    name = tostring(name or "")
    name = name:gsub("@%b{}", "")
    -- Server text_id can append shard and title: Paduana(Atys)Senior...
    name = name:gsub("%s*%(.*$", "")
    return name:match("^%s*(.-)%s*$")
end

local function normalize(name)
    return cleanName(name):lower()
end

local function percent(raw, maximum)
    return math.floor(math.max(0, math.min(1, raw / maximum)) * 100 + 0.5)
end

function T:horizontal()
    return db("UI:SAVE:PADUI:TEAM_LAYOUT") == 1
end

function T:showSelf()
    return db("UI:SAVE:PADUI:HIDE_SELF") == 0
end

function T:toggleSelf()
    setDbProp("UI:SAVE:PADUI:HIDE_SELF", T:showSelf() and 1 or 0)
    T.lastTick = nil
    T:update()
end

function T:sortMode()
    local mode = db(SORT_DB)
    if mode ~= 1 and mode ~= 2 then return 0 end
    return mode
end

local function memberLess(a, b)
    -- Only percentages are available for other characters, not absolute HP.
    if a.present ~= b.present then return a.present end
    local mode = T:sortMode()
    if a.present and a.hp ~= b.hp then
        if mode == 1 then return a.hp > b.hp end
        if mode == 2 then return a.hp < b.hp end
    end
    local an, bn = normalize(a.name), normalize(b.name)
    if mode == 0 and an ~= bn then return an < bn end
    if an ~= bn then return an < bn end
    return (a.uid or -1) < (b.uid or -1)
end

function T:openSortMenu()
    PadUI:sortMenu()
    runAH(getUICaller(), "active_menu", "menu=ui:interface:team_compact_sort_menu")
end

function T:setSort(mode)
    local value = SORT_MODES[mode]
    if value == nil then return end
    setDbProp(SORT_DB, value)
    T.lastTick = nil
    T:update()
end

function T:start()
    local window = getUI(ROOT)
    if window then
        if not T.started then
            T.started = true
            debugInfo("PadUI Team: window found and activated")
        end
        T.lastTick = nil
        setOnDraw(window, "RyzomTeamUI:update()")
    else
        debugInfo("PadUI Team: window NOT found")
    end
end

local SCALE_GEOMETRY={
 {id="background",h=34},
 {id="selected",x=3,h=34,w=3},
 {id="name",x=5,y=0,fontsize=11},
 {id="status",x=-5,y=0,fontsize=10},
 {id="hp_back",x=5,y=-13,h=10},
 {id="hp_fill",x=5,y=-13,h=10},
 {id="hp_text",x=0,y=0,fontsize=10},
 {id="sap_back",x=5,y=-23,h=10},
 {id="sap_fill",x=5,y=-23,h=10},
 {id="sap_text",x=0,y=0,fontsize=9},
 {id="sta_back",y=-23,h=10},
 {id="sta_fill",y=-23,h=10},
 {id="sta_text",x=0,y=0,fontsize=9},
 {id="target_button",h=34},
 {id="self_marker",h=34,w=3}
}
function T:node(row,id)
 local base=({name=11,status=10,hp_text=10,sap_text=9,sta_text=9})[id]
 if not base then return row:find(id) end
 local size=math.max(7,math.min(22,math.floor(base*(T.scale or 1)+0.5)))
 local selected=row:find(id..'_s'..size)
 if not selected then return row:find(id) end
 T.fontChoices=T.fontChoices or {}
 -- Stable native ID, not the temporary Lua userdata wrapper returned by getUI.
 local key=row.id..':'..id
 local previous=T.fontChoices[key]
 if previous~=size then
  if previous then local old=row:find(id..'_s'..previous);if old then old.active=false end end
  row:find(id).active=false;selected.active=true
  T.fontChoices[key]=size
 end
 return selected
end
function T:update()
    if not game or not game.InGameDbInitialized or (isPlayerReady and not isPlayerReady()) then return end
    local tick = db("UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK")
    if T.lastTick == tick then return end
    T.lastTick = tick
    local window = getUI(ROOT)
    if not window then return end
    local ownName = cleanName(getPlayerName())
    if ownName == "" then return end
    local members = {}
    if T:showSelf() then members[1] = {
        name = ownName, self = true, present = true,
        hpRaw = db("UI:VARIABLES:USER:HP_RATIO"),
        hp = percent(db("UI:VARIABLES:USER:HP_RATIO"), 1024),
        sap = percent(db("UI:VARIABLES:USER:SAP_RATIO"), 1024),
        sta = percent(db("UI:VARIABLES:USER:STA_RATIO"), 1024)
    } end
    for index = 0, 7 do
        local path = "SERVER:GROUP:" .. index .. ":"
        local nameId = db(path .. "NAME")
        if nameId ~= 0 then
            local source = getUI(ROOT .. ":content:name_source" .. index)
            local name = source and cleanName(source.hardtext) or ""
            -- Native text_id resolves the server name asynchronously;
            -- omit empty labels until the name has arrived.
            if name ~= "" and normalize(name) ~= normalize(ownName) then
                local bars = "UI:VARIABLES:BARS:TEAM:" .. index .. ":"
                members[#members + 1] = {
                    name = name, index = index, uid = db(path .. "UID"),
                    nameId = nameId, present = db(path .. "PRESENT") ~= 0,
                    hpRaw = db(bars .. "HP"),
                    hp = percent(db(bars .. "HP"), 127),
                    sap = percent(db(bars .. "SAP"), 127),
                    sta = percent(db(bars .. "STA"), 127)
                }
            end
        end
    end
    table.sort(members, memberLess)
    T.rows = members
    local targetUid = db("UI:VARIABLES:TARGET:UID")
    local targetName = normalize(getTargetName())
    local leaderIndex = db("SERVER:GROUP:LEADER_INDEX")
    local screenWidth = getWindowSize()
    screenWidth = tonumber(screenWidth) or 1280
    local horizontal = T:horizontal()
    local limit = screenWidth >= 1000 and 5 or 3
    local columns = horizontal and math.max(1, math.min(math.max(1,#members), limit)) or 1
    local cellWidth = horizontal and math.max(96, math.min(200, math.floor(screenWidth / limit))) or 200
    local scalePercent=db("UI:SAVE:PADUI:TEAM_SCALE")
    if scalePercent<75 or scalePercent>150 then scalePercent=100 end
    scalePercent=math.max(75,math.min(150,math.floor(scalePercent/25+0.5)*25))
    local scale=scalePercent/100
    T.scale=scale
    local function px(value)
        return value<0 and -math.floor(-value*scale+0.5) or math.floor(value*scale+0.5)
    end
    cellWidth=px(cellWidth)
    local hpWidth = cellWidth - px(12)
    local halfWidth = math.floor((hpWidth - px(4)) / 2)
    for i = 1, 9 do
        local row = getUI(ROOT .. ":content:row" .. i)
        local m = members[i]
        row.active = m ~= nil
        if m then
            row.h=px(34)
            for _,spec in ipairs(SCALE_GEOMETRY) do
                local child=T:node(row,spec.id)
                if child then
                    for key,value in pairs(spec) do
                        if key~="id" and key~="fontsize" then child[key]=px(value) end
                    end
                end
            end
            row.w = cellWidth - px(2)
            row.x = ((i - 1) % columns) * cellWidth
            row:find("background").w = cellWidth - px(2)
            row:find("target_button").w = cellWidth - px(2)
            row:find("target_button").tooltip = m.name
            T:node(row,"name"):setLineMaxW(cellWidth >= px(160) and (cellWidth - px(72)) or (cellWidth - px(12)))
            T:node(row,"status").active = cellWidth >= px(160)
            row:find("hp_back").w = hpWidth
            row:find("sap_back").w = halfWidth
            row:find("sta_back").w = halfWidth
            row:find("sta_back").x = px(9) + halfWidth
            row:find("sta_fill").x = px(9) + halfWidth
            row.y = -math.floor((i - 1) / columns) * px(34)
            local selected = (m.self and targetName == normalize(ownName))
                or (not m.self and m.uid == targetUid)
            T:node(row,"name").hardtext = m.name
            T:node(row,"name").color = m.self and PadUI:accent() or (selected and "255 215 110 255" or "245 235 210 255")
            local status = m.self and PadUI:tr("self") or ""
            if not m.present then status = PadUI:tr("absent")
            elseif m.hpRaw < 0 then status = PadUI:tr("ko")
            elseif selected then status = m.self and (PadUI:tr("self") .. " / " .. PadUI:tr("target")) or PadUI:tr("target")
            elseif not m.self and m.index == leaderIndex then status = PadUI:tr("leader") end
            T:node(row,"status").hardtext = status
            T:node(row,"status").color = m.self and PadUI:accent() or (m.present and "220 220 205 255" or "180 180 170 255")
            row:find("selected").active = selected
            row:find("self_marker").active = m.self == true
            local hpColor = "150 38 16 255"
            if m.hp < 15 then hpColor = "180 25 25 255"
            elseif m.hp < 30 then hpColor = "150 65 12 255" end
            row:find("hp_fill").color = PadUISettings and PadUISettings:withTransparency(hpColor) or hpColor
            for _, score in ipairs({"hp", "sap", "sta"}) do
                local value = m.present and m[score] or 0
                local width = score == "hp" and hpWidth or halfWidth
                row:find(score .. "_fill").w = math.floor(width * value / 100 + 0.5)
                local label = ({hp="", sap=PadUI:tr("sap"), sta=PadUI:tr("stamina")})[score]
                T:node(row,score .. "_text").hardtext = label .. (m.present and (value .. "%") or "--")
            end
            local backgroundColor = m.self and "16 43 55 255" or (m.present and "12 18 24 255" or "18 18 18 255")
            row:find("background").color = PadUISettings and PadUISettings:withTransparency(backgroundColor) or backgroundColor
        end
    end
    local height = math.ceil(#members / columns) * px(34)
    local width = cellWidth * columns
    getUI(ROOT .. ":content:waiting").active = false
    local controls = getUI(ROOT .. ":content:sort_controls")
    if controls then
        controls.y = -height
        controls.h=px(18)
        controls.w = width - px(2)
        for _,id in ipairs({"footer_back","sort_back","sort_button"}) do
            local child=controls:find(id)
            if child then child.h=px(18) end
        end
        controls:find("sort_back").w=px(97)
        controls:find("sort_button").w=px(97)
        controls:find("footer_back").w = width - px(2)
        controls:find("sort_back").x = width - px(99)
        controls:find("sort_button").x = width - px(99)
        controls:find("sort_label").hardtext = PadUI:tr(SORT_LABELS[T:sortMode()])
    end
    local content = getUI(ROOT .. ":content")
    content.w = width - px(2); content.h = height + px(18)
    local header = getUI(ROOT .. ":header_opened")
    if header then header.w = width - px(2) end
    local resized = window.w ~= width or window.h ~= height + px(24)
    window.w = width; window.h = height + px(24)
    T.appliedScale=scalePercent
    if resized then window:invalidateCoords() end
end

-- Validate the displayed member again before every click/menu action.
function T:validMember(m)
    if not m then return false end
    if m.self then
        if isPlayerReady and not isPlayerReady() then return false end
        return normalize(m.name) == normalize(getPlayerName())
    end
    local path = "SERVER:GROUP:" .. m.index .. ":"
    return db(path .. "UID") == m.uid and db(path .. "NAME") == m.nameId
        and db(path .. "PRESENT") ~= 0
end

function T:selectMember(m)
    if not T:validMember(m) then return false end
    if m.self then runAH(nil, "self_target", "")
    else runAH(nil, "team_target", tostring(m.index)) end
    return true
end

function T:target(rowNumber)
    return T:selectMember(T.rows[tonumber(rowNumber)])
end

function T:assistMember(m)
    if not T:validMember(m) or m.self then return end
    runAH(nil, "assist", "entity=" .. m.name)
end

function T:click(rowNumber, side)
    local m = T.rows[tonumber(rowNumber)]
    if not T:validMember(m) then return end
    if side == "left" then
        T:selectMember(m)
    else
        T.menuMember = m
        runAH(getUICaller(), "active_menu", "menu=ui:interface:team_compact_menu")
    end
end

function T:menuAction(action)
    local m = T.menuMember
    T.menuMember = nil
    if not T:validMember(m) then return end
    if action == "assist" then T:assistMember(m)
    elseif action == "select" then T:selectMember(m)
    elseif action == "trade" and not m.self then
        if T:selectMember(m) then runAH(nil, "context_exchange", "") end
    end
end
