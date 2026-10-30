-- PadUI independent item shortcuts. Display/assignment never uses an item.
PadUIQuickbar = PadUIQuickbar or {}
local Q = PadUIQuickbar
local ROOT = "ui:interface:padui_items"
local SAVE = "UI:SAVE:PADUI:ITEMS:"
local TEMP = "UI:TEMP:PADUI:ITEMS:"
local BAG = "LOCAL:INVENTORY:BAG:"
local FIELDS = {"SHEET", "QUALITY", "USER_COLOR", "CHARAC_BUFFS", "NAMEID", "ENCHANT"}
local EQUIP = {ARMOR=true, MELEE_WEAPON=true, RANGE_WEAPON=true, AMMO=true,
 SHIELD=true, CRAFTING_TOOL=true, HARVEST_TOOL=true, TAMING_TOOL=true,
 TRAINING_TOOL=true, JEWELRY=true, HANDLED_ITEM=true}
local USE = {TELEPORT=true, CONSUMABLE=true, XP_CATALYSER=true}
Q.count = 8
Q.started = false
-- Revalidate cached positions; never trust them without reading bag fields.
Q.exactPositions = Q.exactPositions or {}
Q.sheetBindings = Q.sheetBindings or {}
Q.sheetBindingTime = Q.sheetBindingTime or {}
Q.namePending = Q.namePending or {}
local function db(path,cache)
 -- Cache only bag reads, only within one synchronous display refresh.
 -- No cache survives inventory changes, clicks or the next refresh.
 if cache and path:sub(1,#BAG)==BAG then
  if cache[path]==nil then cache[path]=tonumber(getDbProp(path)) or 0 end
  return cache[path]
 end
 return tonumber(getDbProp(path)) or 0
end
local function slotNumber(slot)
 slot = tonumber(slot)
 if slot and slot == math.floor(slot) and slot >= 1 and slot <= Q.count then return slot end
end
function Q:bagSize()
 return math.max(1, math.min(1000, tonumber(getDefine("max_bag_invslot")) or 500))
end
function Q:sourceIndex(source)
 if not source then return nil end
 local path = tostring(source.sheet or "")
 local index = tonumber(path:match("^LOCAL:INVENTORY:BAG:(%d+)$") or path:match("^SERVER:INVENTORY:BAG:(%d+)$"))
 if not index or index >= Q:bagSize() or db(BAG..index..":SHEET") == 0 then return nil end
 return index
end
function Q:reference(slot)
 local ref = {}
 for _, field in ipairs(FIELDS) do ref[field] = db(SAVE..slot..":"..field) end
 ref.index = db(SAVE..slot..":INDEX") - 1
 return ref
end
function Q:matches(ref, index, ignoreNameId, cache)
 if index < 0 or index >= Q:bagSize() or ref.SHEET == 0 then return false end
 local path = BAG..index..":"
 for _, field in ipairs(FIELDS) do
  if not (ignoreNameId and field=="NAMEID") and db(path..field,cache) ~= ref[field] then return false end
 end
 return db(path.."QUANTITY",cache) > 0
end
function Q:find(ref,cache,slot)
 if ref.SHEET == 0 then return nil end
 if Q:matches(ref,ref.index,nil,cache) then
  if slot then Q.exactPositions[slot]=nil end
  return ref.index
 end
 local previous=slot and Q.exactPositions[slot]
 if previous and Q:matches(ref,previous,nil,cache) then return previous end
 if slot then Q.exactPositions[slot]=nil end
 for index=0,Q:bagSize()-1 do
  if Q:matches(ref,index,nil,cache) then
   if slot then Q.exactPositions[slot]=index end
   return index
  end
 end
 -- NAMEID references the session's dynamic string table, not a persistent item.
 -- Prefer the exact match above. Recover only an unambiguous stable match;
 -- never select arbitrarily between differently named, otherwise equal items.
 local candidate=nil
 for index=0,Q:bagSize()-1 do
  if Q:matches(ref,index,true,cache) then
   if candidate~=nil then return nil end
   candidate=index
  end
 end
 return candidate
end
function Q:assign(slot, source, deferRefresh)
 slot = slotNumber(slot)
 local index = Q:sourceIndex(source)
 if not slot or not index then return false end
 for _, field in ipairs(FIELDS) do setDbProp(SAVE..slot..":"..field,db(BAG..index..":"..field)) end
 setDbProp(SAVE..slot..":INDEX", index+1)
 Q.exactPositions[slot]=nil;Q.sheetBindings[slot]=nil;Q.namePending[slot]=nil
 Q.lastRefresh = nil
 if not deferRefresh then Q:update() end
 return true
end
function Q:canDrop(slot, sourceId)
 local caller = getUICaller()
 local fromBag = tostring(sourceId):match("^ui:interface:inventory:content:bag:")
  or tostring(sourceId):match("^ui:interface:inv_bag:content:")
 if caller then caller.can_drop = fromBag ~= nil and slotNumber(slot) ~= nil and Q:sourceIndex(getUI(sourceId)) ~= nil end
end
function Q:drop(slot, sourceId)
 local fromBag = tostring(sourceId):match("^ui:interface:inventory:content:bag:")
  or tostring(sourceId):match("^ui:interface:inv_bag:content:")
 if not fromBag then return end
 local source = getUI(sourceId)
 if Q:assign(slot,source) then
  -- Finish the native inventory drag as a drop back into its own list.
  -- That native branch is a no-op: no item move, equip or use.
  runAH(source,"inv_drop","src="..sourceId)
 end
end
function Q:choose(slot)
 slot = slotNumber(slot)
 if not slot then return end
 Q.chooseSlot = slot
 local control = getUI(ROOT..":content:item"..slot)
 runAH(control,"enter_modal","group=ui:interface:padui_item_choose")
end
function Q:chooseItem()
 -- Keep sheet rebinding outside the chooser's mouse-release event.
 -- The saved reference is written now; the next draw refreshes the bar.
 if Q:assign(Q.chooseSlot,getUICaller(),true) then
  Q.chooseSlot = nil
  runAH(getUICaller(),"leave_modal","")
  local chooser=getUI("ui:interface:padui_item_choose")
  if chooser then chooser.active=false end
  local window=getUI(ROOT)
  if window then window:invalidateCoords() end
 end
end
function Q:clear(slot)
 slot = slotNumber(slot)
 if not slot then return end
 for _, field in ipairs(FIELDS) do setDbProp(SAVE..slot..":"..field,0) end
 setDbProp(SAVE..slot..":INDEX",0)
 Q.exactPositions[slot]=nil;Q.sheetBindings[slot]=nil;Q.namePending[slot]=nil
 Q.lastRefresh=nil; Q:update()
end
function Q:layoutMode()
 local mode=db("UI:SAVE:PADUI:ITEM_LAYOUT")
 return (mode==1 or mode==2) and mode or 0
end
function Q:layout()
 local width,height=getWindowSize()
 width=tonumber(width) or 1280; height=tonumber(height) or 720
 local mode=Q:layoutMode()
 local columns=width>=1200 and 8 or (width>=560 and 4 or 2)
 local rows
 if mode==1 then
  columns=math.max(1,math.min(Q.count,math.floor((width-10)/46)))
  rows=math.ceil(Q.count/columns)
 elseif mode==2 then
  rows=math.max(1,math.min(Q.count,math.floor((height-16)/60)))
  columns=math.ceil(Q.count/rows)
 else rows=math.ceil(Q.count/columns) end
 local window=getUI(ROOT)
 local content=getUI(ROOT..":content")
 if not window or not content then return end
 Q.layoutColumns=columns
 local barWidth=10+46*columns
 local contentHeight=2+60*rows
 if Q.appliedLayout==mode and Q.appliedColumns==columns and Q.appliedRows==rows and window.w==barWidth and window.h==4+contentHeight
  and content.w==barWidth-2 and content.h==contentHeight then return end
 Q.appliedLayout=mode;Q.appliedColumns=columns;Q.appliedRows=rows
 -- Reflow native sheets instead of changing their texture-defined icon size.
 window.w=barWidth;window.h=4+contentHeight
 content.w=barWidth-2;content.h=contentHeight
 local header=getUI(ROOT..":header_opened");if header then header.w=barWidth-2 end
 for _,path in ipairs({":header_opened:back",":content:back"}) do
  local back=getUI(ROOT..path)
  if back then back.w=barWidth-2 end
 end
 local back=getUI(ROOT..":content:back")
 if back then back.h=contentHeight end
 for slot=1,Q.count do
  local column=mode==2 and math.floor((slot-1)/rows) or ((slot-1)%columns)
  local row=mode==2 and ((slot-1)%rows) or math.floor((slot-1)/columns)
  local x=5+46*column
  local y=-2-60*row
  local control=getUI(ROOT..":content:item"..slot)
  if control then control.x=x;control.y=y end
  local label=getUI(ROOT..":content:label"..slot)
  if label then label.x=x+1;label.y=y-45 end
  for _,spec in ipairs({{"empty",17},{"missing",16}}) do
   local marker=getUI(ROOT..":content:"..spec[1]..slot)
   if marker then marker.x=x+spec[2];marker.y=y-11 end
  end
 end
 window:invalidateCoords()
end
function Q:update()
 if not game or not game.InGameDbInitialized then return end
 local now=nltime.getLocalTime()
 if Q.lastRefresh and now>=Q.lastRefresh and now-Q.lastRefresh<500 then return end
 Q.lastRefresh=now
 Q:layout()
 PadUI:localize()
 local bagReadCache={}
 for slot=1,Q.count do
  local ref=Q:reference(slot)
  local index=Q:find(ref,bagReadCache,slot)
  local path=index and (BAG..index) or (TEMP..slot)
  if not index then
   for _,field in ipairs(FIELDS) do
    local leaf=TEMP..slot..":"..field
    if db(leaf)~=ref[field] then setDbProp(leaf,ref[field]) end
   end
   local quantity=TEMP..slot..":QUANTITY"
   if db(quantity)~=0 then setDbProp(quantity,0) end
  end
  local label=getUI(ROOT..":content:label"..slot)
  local name=""
  -- The saved reference is independent of native icon/cache initialization.
  -- Establish a readable fallback before touching the sheet control.
  if label then
   local visible=ref.SHEET~=0
   local color=index and "245 235 210 255" or "255 160 120 255"
   if label.active~=visible then label.active=visible end
   if label.color~=color then label.color=color end
  end
  local control=getUI(ROOT..":content:item"..slot)
  if control then
   -- Native sheet initialization is expensive. Rebind on changed source,
   -- unresolved native name (limited retry), or a periodic recovery pass.
   local key=path
   for _,field in ipairs(FIELDS) do key=key..":"..tostring(ref[field]) end
   local boundAt=Q.sheetBindingTime[slot]
   local age=boundAt and now>=boundAt and now-boundAt or nil
   local needBind=Q.sheetBindings[slot]~=key or not age
    or (index and Q.namePending[slot] and age>=1500)
    or (ref.SHEET~=0 and age>=5000)
   -- Keep individual native failures isolated from all remaining slots.
   pcall(function()
    if needBind then
     control.sheet=path
     control:invalidateCoords()
     control:updateCoords()
     Q.sheetBindings[slot]=key
     Q.sheetBindingTime[slot]=now
    end
    local color=index and "255 255 255 255" or "150 150 150 255"
    if control.color~=color then control.color=color end
   end)
   local ok,result=pcall(function() return ref.SHEET~=0 and control:getName() or "" end)
   if ok and result then
    if type(result)~="string" then
     local converted,text=pcall(function() return result:toUtf8() end)
     result=converted and text or ""
    end
    if type(result)=="string" then name=result:gsub("[\r\n]", " ") end
   end
   Q.namePending[slot]=index~=nil and ref.SHEET~=0 and name==""
   local hint=PadUI:tr(ref.SHEET==0 and "empty_tip" or (index and "item_tip" or "missing_tip"))
   if name~="" then hint=name.."\n"..hint end
   pcall(function() if control.tooltip~=hint then control.tooltip=hint end end)
  end
  if label then
   local text=name~="" and name or (ref.SHEET~=0 and PadUI:tr("item_assigned") or "")
   if label.hardtext~=text then label.hardtext=text end
  end
  local empty=getUI(ROOT..":content:empty"..slot)
  if empty and empty.active~=(ref.SHEET==0) then empty.active=ref.SHEET==0 end
  local missing=getUI(ROOT..":content:missing"..slot)
  local unavailable=ref.SHEET~=0 and index==nil
  if missing and missing.active~=unavailable then missing.active=unavailable end
 end
end
function Q:liveControl(slot, ref)
 slot=slotNumber(slot)
 if not slot then return nil end
 ref=ref or Q:reference(slot)
 local index=Q:find(ref)
 if not index then return nil end
 local control=getUI(ROOT..":content:item"..slot)
 if not control then return nil end
 control.sheet=BAG..index
 return control,index
end
function Q:family(sheet)
 local ok,result=pcall(function() return getSheetFamily(getSheetName(sheet)) end)
 return ok and tostring(result):upper() or ""
end
function Q:message(key)
 displaySystemInfo("PadUI: "..PadUI:tr(key),"SYS")
end
function Q:activate(slot, ref)
 slot=slotNumber(slot)
 if not slot then return end
 ref=ref or Q:reference(slot)
 if ref.SHEET==0 then Q:choose(slot); return end
 local control,index=Q:liveControl(slot,ref)
 if not control then Q:message("not_found"); return end
 local family=Q:family(ref.SHEET)
 if EQUIP[family] then
  if db("UI:VARIABLES:ISACTIVE:PHRASE_FABER")~=0 and family~="ARMOR" and family~="JEWELRY" then Q:message("crafting"); return end
  runAH(control,"inv_auto_equip","")
 elseif USE[family] then
  if db(BAG..index..":RESALE_FLAG")==3 then Q:message("locked"); return end
  sendMsgToServerUseItem(index)
 else
  runAH(control,"open_help_auto","")
 end
end
function Q:context(slot)
 slot=slotNumber(slot)
 if not slot then return end
 Q.menuSlot=slot; Q.menuReference=Q:reference(slot)
 local entries={}
 if Q.menuReference.SHEET~=0 then
  entries[#entries+1]={"use","PadUIQuickbar:menuAction('use')"}
  entries[#entries+1]={"details","PadUIQuickbar:menuAction('details')"}
 end
 entries[#entries+1]={"choose","PadUIQuickbar:menuAction('choose')"}
 entries[#entries+1]={"clear","PadUIQuickbar:menuAction('clear')"}
 PadUI:buildMenu("ui:interface:padui_item_menu",entries)
 runAH(getUICaller(),"active_menu","menu=ui:interface:padui_item_menu")
end
function Q:menuAction(action)
 local slot,ref=Q.menuSlot,Q.menuReference
 Q.menuSlot=nil; Q.menuReference=nil
 if not slot or not ref then return end
 -- Do not apply an old menu to a newly assigned shortcut.
 local current=Q:reference(slot)
 for _,field in ipairs(FIELDS) do if current[field]~=ref[field] then return end end
 if action=="use" then Q:activate(slot,ref)
 elseif action=="details" then
  local control=Q:liveControl(slot,ref)
  if control then runAH(control,"open_help_auto","") else Q:message("not_found") end
 elseif action=="choose" then Q:choose(slot)
 elseif action=="clear" then Q:clear(slot) end
end
function Q:start()
 Q.exactPositions={};Q.sheetBindings={};Q.sheetBindingTime={};Q.namePending={}
 local window=getUI(ROOT)
 if not window then return end
 if not Q.started then
  Q.started=true
 end
 setOnDraw(window,"PadUIQuickbar:update()")
 local content=getUI(ROOT..":content")
 if content then setOnDraw(content,"PadUIQuickbar:update()") end
 Q.lastRefresh=nil; Q:update()
end
function Q:onActive()
 setDbProp("UI:VARIABLES:ISACTIVE:PADUI_ITEMS",1)
 Q:start()
end
