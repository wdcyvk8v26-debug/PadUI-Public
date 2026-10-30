-- Read-only horizontal target distance; no target changes or gameplay actions.
RyzomTargetDistance = RyzomTargetDistance or {}
local D = RyzomTargetDistance
local ROOT = "ui:interface:target"
local NAME_DB = 'UI:VARIABLES:PADUI:TARGET_OF_TARGET:NAME'
local words = {
    de = {prefix='Ziel: ', empty='—', loading='…', unknown='HP nicht verfügbar'},
    en = {prefix='Target: ', empty='—', loading='…', unknown='HP unavailable'},
    fr = {prefix='Cible : ', empty='—', loading='…', unknown='PV indisponibles'}
}
local function db(path)
    local ok,value=pcall(getDbProp,path)
    return ok and tonumber(value) or nil
end
-- Native UI property writes may trigger layout even when the value is unchanged.
local function writeChanged(node,key,value)
    if node and node[key]~=value then node[key]=value end
end

local function validSlot(value)
    return value and value==math.floor(value) and value>=0 and value<255
end
local function cleanName(value)
    return tostring(value or ''):gsub('@%b{}',''):gsub('%s*%(.*$',''):gsub('%$.*$',''):match('^%s*(.-)%s*$')
end

function D:targetHealth(target,name)
    if target==nil then return nil end
    if target==0 then
        return math.max(0,math.min(1,(db('UI:VARIABLES:USER:HP_RATIO') or 0)/1024))
    end
    -- Prefer native team bars, including a legitimate zero-HP value.
    if name~='' then
        for index=0,7 do
            local source=getUI('ui:interface:team_compact:content:name_source'..index)
            if (db('SERVER:GROUP:'..index..':NAME') or 0)~=0 and source
                and cleanName(source.hardtext):lower()==name:lower() then
                return math.max(0,math.min(1,(db('UI:VARIABLES:BARS:TEAM:'..index..':HP') or 0)/127))
            end
        end
    end
    local packed=db('SERVER:Entities:E'..target..':P15')
    -- A completely empty property may mean that no bars have been received.
    if not packed or packed==0 then return nil end
    local hp=packed%2048
    return math.max(0,math.min(1,hp/1023))
end

function D:updateTargetOfTarget()
    local now=nltime.getLocalTime()
    if D.lastTargetTick and now>=D.lastTargetTick and now-D.lastTargetTick<200 then return end
    D.lastTargetTick=now
    local label=getUI(ROOT..':header_opened:target_of_target')
    local source=getUI(ROOT..':header_opened:target_of_target_source')
    if not label or not source then return end
    local selected=db('UI:VARIABLES:TARGET:SLOT')
    local target
    if validSlot(selected) then
        target=db('SERVER:Entities:E'..selected..':P7')
    end
    if not validSlot(target) then target=nil end
    local nameId=target and (db('SERVER:Entities:E'..target..':P6') or 0) or 0
    -- P4 is a visual property, not a reliable presence check for a loaded slot.
    -- Use the received target reference and name instead of rejecting P4 == 0.
    -- Clear old text before asking the native text_id view to resolve a new name.
    if D.boundNameId~=nameId then
        setDbProp(NAME_DB,nameId)
        source.hardtext=''
        D.boundNameId=nameId
    end
    local text=words[PadUI:language()] or words.en
    local name=''
    if target==0 then
        if not isPlayerReady or isPlayerReady() then
            name=cleanName(getPlayerName())
        end
    elseif target and nameId~=0 then name=cleanName(source.hardtext) end
    local value=text.prefix..(name~='' and name or (target and nameId~=0 and text.loading or text.empty))
    if label.hardtext~=value then label.hardtext=value end
    local health=D:targetHealth(target,name)
    local bar=getUI(ROOT..':header_opened:target_of_target_hp')
    local percent=getUI(ROOT..':header_opened:target_of_target_percent')
    local width=health and math.floor(188*health+0.5) or 0
    if bar and bar.w~=width then bar.w=width;bar:invalidateCoords() end
    local hpText=health and (tostring(math.floor(health*100+0.5))..'%') or '--'
    if percent and percent.hardtext~=hpText then percent.hardtext=hpText end
    local tip=getUI(ROOT..':header_opened:target_of_target_tip')
    local tooltip=value..' / '..(health and hpText or text.unknown)
    if tip and tip.tooltip~=tooltip then tip.tooltip=tooltip end
end

function D:update()
    if not game or not game.InGameDbInitialized then return end
    -- Native consider updates also resize this header; restore the compact layout.
    local window = getUI(ROOT)
    local header = getUI(ROOT .. ":header_opened")
    local tags = getUI(ROOT .. ":pvp_tags")
    writeChanged(header,'h',40)
    local back=getUI(ROOT..':header_opened:compact_back')
    writeChanged(back,'h',40)
    writeChanged(tags,'y',-56)
    writeChanged(window,'h',56 + ((tags and tags.active) and 24 or 0))
    -- Optional target-of-target must not stop the native target/distance update.
    if not D.targetOfTargetFailed then
        local ok,err=pcall(D.updateTargetOfTarget,D)
        if not ok then
            D.targetOfTargetFailed=true
            local extra=getUI(ROOT..':header_opened:target_of_target')
            if extra then
                local text=words[PadUI:language()] or words.en
                extra.hardtext=text.prefix..text.empty
            end
            local tip=getUI(ROOT..':header_opened:target_of_target_tip')
            if tip then tip.tooltip='PadUI: '..tostring(err) end
        end
    end
    local name = getUI(ROOT .. ":header_opened:target_name")
    if name then
        local text = tostring(getTargetName() or "")
        text = text:gsub("@%b{}", ""):gsub("%s*%(.*$", "")
        writeChanged(name,'hardtext',text)
    end
    local title = getUI(ROOT .. ":header_opened:target_title")
    writeChanged(title,'active',false)
    local label = getUI(ROOT .. ":header_opened:target_distance")
    if not label then return end
    if isPlayerReady and not isPlayerReady() then
        writeChanged(label,'hardtext',"-- m")
        return
    end
    local px, py = getPlayerPos()
    local tx, ty = getTargetPos()
    if type(px) ~= "number" or type(py) ~= "number"
        or type(tx) ~= "number" or type(ty) ~= "number" then
        writeChanged(label,'hardtext',"-- m")
        return
    end
    local dx, dy = px - tx, py - ty
    local distance = math.sqrt(dx * dx + dy * dy)
    if distance ~= distance or distance == math.huge then
        writeChanged(label,'hardtext',"-- m")
        return
    end
    writeChanged(label,'hardtext',tostring(math.floor(distance + 0.5)) .. " m")
end

function D:start()
    local window = getUI(ROOT)
    if window then
        setOnDraw(window, "RyzomTargetDistance:update()")
        D:update()
    end
end
