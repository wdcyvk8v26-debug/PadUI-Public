-- PadUI low-health screen tint. XML/Lua only; no input controls or native window changes.
-- Lua 5.1 compatible. The overlay contains a single non-interactive bitmap.
PadUILowHealth = PadUILowHealth or {}
local H = PadUILowHealth
local ROOT = 'ui:interface:padui_low_hp_overlay'
local ENABLED = 'UI:SAVE:PADUI:LOW_HP:ENABLED'
local THRESHOLD = 'UI:SAVE:PADUI:LOW_HP:THRESHOLD'
local HP = 'UI:VARIABLES:USER:HP_RATIO'

local function read(path)
 local ok,value=pcall(getDbProp,path)
 return ok and tonumber(value) or nil
end
local function put(node,key,value)
 if node and node[key]~=value then node[key]=value end
end

function H:limit()
 local v=read(THRESHOLD)
 return (v==15 or v==25 or v==35) and v or 25
end
function H:hide(reset)
 local group=getUI(ROOT,false)
 put(group,'active',false)
 H.warning=false
 if reset then H.seenHP=false;H.lastTime=nil end
end
function H:update(force)
 if not game or not game.InGameDbInitialized or (isPlayerReady and not isPlayerReady()) then
  H:hide(true)
  return
 end
 local now=nltime.getLocalTime()
 if not force and H.lastTime and now>=H.lastTime and now-H.lastTime<200 then return end
 H.lastTime=now
 if read(ENABLED)~=1 then H:hide();return end
 local ratio=read(HP)
 if not ratio or ratio<0 or ratio>1024 then H:hide();return end
 -- DB initialization may expose zero HP before the character is actually ready.
 if ratio>0 then H.seenHP=true end
 if not H.seenHP then H:hide();return end
 local threshold=H:limit()
 if H.warning then
  if ratio*100 >= (threshold+5)*1024 then H.warning=false end
 elseif ratio*100 <= threshold*1024 then
  H.warning=true
 end
 if not H.warning then H:hide();return end
 local group=getUI(ROOT,false)
 if not group then return end
 local tint=getUI(ROOT..':tint',false)
 if not tint then return end
 local width,height=getWindowSize()
 width=tonumber(width);height=tonumber(height)
 if not width or not height or width<1 or height<1 then H:hide();return end
 width=math.floor(width);height=math.floor(height)
 put(group,'w',width);put(group,'h',height)
 put(tint,'w',width);put(tint,'h',height)
 -- Gentle 1.6 s triangular pulse instead of a hard blink.
 local wave=(now%1600)/800
 if wave>1 then wave=2-wave end
 local critical=ratio*100 <= 15*1024
 local base=critical and 22 or 12
 local range=critical and 30 or 24
 local alpha=math.floor(base+range*wave+0.5)
 put(tint,'color','185 15 15 '..alpha)
 put(group,'active',true)
end
function H:start()
 H.warning=false;H.seenHP=false;H.lastTime=nil
 H:update(true)
end
