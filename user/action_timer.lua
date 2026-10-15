-- Countdown for both existing copies of the native action bar.
RyzomActionTimer = RyzomActionTimer or {}
-- 100 smooth units per 100 ms server tick = 1000 smooth units per second.
local T = RyzomActionTimer
local paths = {
    "ui:interface:player:content:current_action:remaining_time",
    "ui:interface:current_action:header_opened:current_action:remaining_time"
}
function T:update()
    if not game or not game.InGameDbInitialized then return end
    local ending = tonumber(getDbProp("UI:VARIABLES:SMOOTH_USER_ACT_END")) or 0
    local start = tonumber(getDbProp("UI:VARIABLES:SMOOTH_USER_ACT_START")) or 0
    local tick = tonumber(getDbProp("UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK")) or 0
    local running = getDbProp("SERVER:USER:ACT_TEND") ~= 0 and ending > start
    local seconds = math.max(0, (ending - tick) / 1000)
    local formatted = string.format("%.1f", seconds)
    if PadUI and PadUI:language() ~= "en" then formatted = formatted:gsub("%.", ",") end
    local text = running and (formatted .. " s") or ""
    for _, path in ipairs(paths) do
        local label = getUI(path)
        if label then
            label.active = running
            label.hardtext = text
        end
    end
end
