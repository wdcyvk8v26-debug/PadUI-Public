-- Compact inventory summary. Update native volume text and bar together.
RyzomInventoryCompact = RyzomInventoryCompact or {}
local T = RyzomInventoryCompact
local ROOT = "ui:interface:inventory_compact"
T.started = false
T.lastRefresh = nil
function T:update()
    if not game or not game.InGameDbInitialized then return end
    local now = nltime.getLocalTime()
    if T.lastRefresh and now >= T.lastRefresh and now - T.lastRefresh < 500 then return end
    T.lastRefresh = now
    T:updateExtra()
    local mode = tonumber(getDbProp("SERVER:DEFENSE:DEFENSE_MODE"))
    for _, spec in ipairs({{"dodge", PadUI:tr("dodge"), "DODGE", 0}, {"parry", PadUI:tr("parry"), "PARRY", 1}}) do
        local prefix = "SERVER:CHARACTER_INFO:" .. spec[3] .. ":"
        local current = tonumber(getDbProp(prefix .. "Current")) or 0
        local base = tonumber(getDbProp(prefix .. "Base")) or 0
        local modifier = tonumber(getDbProp("SERVER:CHARACTER_INFO:SUCCESS_MODIFIER:" .. spec[3])) or 0
        local active = mode == spec[4]
        local label = getUI(ROOT .. ":content:" .. spec[1] .. "_text")
        local back = getUI(ROOT .. ":content:" .. spec[1] .. "_back")
        local button = getUI(ROOT .. ":content:" .. spec[1] .. "_button")
        if label then
            label.hardtext = spec[2] .. " " .. tostring(current)
            label.color = active and "110 235 225 255" or "245 235 210 255"
        end
        if back then back.color = active and "16 60 62 235" or "18 28 35 235" end
        if button then button.tooltip = spec[2] .. ": " .. current .. " / " .. PadUI:tr("base") .. " " .. base
            .. " / " .. PadUI:tr("modifier") .. " " .. modifier .. " / " .. PadUI:tr(active and "active" or "activate") end
    end
    local fill = getUI(ROOT .. ":content:bulk_fill")
    if not fill then return end
    local bag = getDefine("bag")
    local maximumPath = getDefine("bag_bulk_max")
    local volume = getUI(ROOT .. ":content:volume")
    local label = runExpr("getBulkStr('" .. bag .. "', @" .. maximumPath .. ")")
    if volume and label ~= nil then volume.hardtext = tostring(label) end
    local bulk = tonumber(runExpr("getItemsBulk('" .. bag .. "',0,10000)")) or 0
    local maximum = tonumber(getDbProp(maximumPath)) or 0
    local ratio = maximum > 0 and math.max(0, math.min(1, bulk / maximum)) or 0
    fill.w = math.floor(188 * ratio + 0.5)
    fill.color = ratio >= 0.95 and "145 38 25 255"
        or (ratio >= 0.80 and "115 75 20 255" or "55 95 25 255")
end
-- Prefer the native map text: it uses WeatherManager and the game's rounding.
-- The map updates every three seconds even while its window is closed.
function T:humidity()
    local weather=getUI("ui:interface:map:content:map_content:weather")
    local text=weather and weather.hardtext or ""
    local value=tonumber(tostring(text):match("(%d+)%s*%%"))
    if value and value>=0 and value<=100 then return value end
    return nil
end

function T:updateExtra()
    local humidity=T:humidity()
    local label=getUI(ROOT..":content:humidity_text")
    if label then label.hardtext=PadUI:tr("humidity").." "..(humidity and (humidity.."%") or "--") end
    local tooltip=getUI(ROOT..":content:humidity_tip")
    if tooltip then tooltip.tooltip=PadUI:tr("humidity_tip") end
end

function T:start()
    local window = getUI(ROOT)
    if not window then return end
    if not T.started then
        T.started = true
    end
    T.lastRefresh = nil
    setOnDraw(window, "RyzomInventoryCompact:update()")
    T:update()
end
function T:open()
    local inventory = getUI("ui:interface:inventory")
    if inventory then inventory.active = true; setTopWindow(inventory) end
end
