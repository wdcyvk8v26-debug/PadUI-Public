-- Experimental read-only summary of entity database slots. No targeting/actions.
PadUIMobs=PadUIMobs or {}
local M=PadUIMobs
local ROOT='ui:interface:padui_mobs'
local TEMP='UI:VARIABLES:PADUI:MOBS:'
local SIZE=14
local CACHE='UI:SAVE:PADUI:MOBS:CACHE:'
local CAPACITY=512
local NAME_BYTES=128
local words={
 de={title='PadUI Umgebung',name='Name',count='Anz.',level='Stufe',force='Sterne',empty='Keine benannten Clientdaten gefunden.',note='Eigene Liste: Named und Bosse.',filters={'Named + Bosse','Named + Bosse','Nur Bosse'},kinds={normal='Normal',named='Named',boss='Boss'},sort='Sortierung: ',orders={'Stufe','Name','Sterne'},summary='%d Figuren / %d Varianten',page='Seite',unknown='Unbekannt',ambiguous='Werte widersprüchlich'},
 en={title='PadUI Nearby',name='Name',count='Count',level='Level',force='Stars',empty='No named client records found.',note='Locally learned named creatures and bosses.',filters={'Named + bosses','Named + bosses','Bosses only'},kinds={normal='Normal',named='Named',boss='Boss'},sort='Sort: ',orders={'Level','Name','Stars'},summary='%d entities / %d variants',page='Page',unknown='Unknown',ambiguous='Conflicting values'},
 fr={title='PadUI Environs',name='Nom',count='Nb.',level='Niveau',force='Étoiles',empty='Aucune donnée nommée trouvée.',note='Nommés et boss appris localement.',filters={'Nommés + boss','Nommés + boss','Boss uniquement'},kinds={normal='Normal',named='Nommé',boss='Boss'},sort='Tri : ',orders={'Niveau','Nom','Étoiles'},summary='%d entités / %d variantes',page='Page',unknown='Inconnu',ambiguous='Valeurs contradictoires'}
}
local function db(path)return tonumber(getDbProp(path)) or 0 end
local function clean(value)return tostring(value or ''):gsub('@%b{}',''):gsub('%s*%(.*$',''):gsub('%$.*$',''):match('^%s*(.-)%s*$') end
local function text(id,value)
 local n=getUI(ROOT..':content:'..id)
 if n and n.hardtext~=value then n.hardtext=value end
end
local function call(fn,arg)
 if fn==nil then return nil end
 local ok,result
 if arg==nil then ok,result=pcall(fn) else ok,result=pcall(fn,arg) end
 if ok then return result end
 M.lastApiError=tostring(result)
 return nil
end
function M:words()return words[PadUI:language()] or words.en end
-- Independent, manually curated reference list (initially empty).
function M:catalogReference(name)
 local data=PadUIMobCatalog or {}
 local language=tostring(getClientCfgVar('LanguageCode') or 'en')
 return (data[language] and data[language][name])
  or (data.en and data.en[name]) or (data.de and data.de[name]) or (data.fr and data.fr[name])
end
function M:shouldPersist(name,metadata)
 return type(name)=='string' and #name>0 and #name<=NAME_BYTES
  and name:sub(1,1)~='#' and not name:find('_',1,true) and not name:find('%z')
  and metadata and type(metadata.level)=='number' and metadata.level>0
  and type(metadata.force)=='number' and metadata.force>=6
  and not M:catalogReference(name)
end
-- UI:SAVE is serialized in the character's native interface configuration.
-- Store full UTF-8 names as signed 32-bit packs, without truncating keys.
function M:loadCache()
 if M.cacheLoaded or not game or not game.InGameDbInitialized then return end
 M.byName=M.byName or {};M.cacheIndex={};M.savedMetadata={};M.usedSlots={}
 for slot=0,CAPACITY-1 do
  local base=CACHE..slot..':'
  local length=db(base..'LENGTH')
  if length>=1 and length<=NAME_BYTES and length==math.floor(length) then
   local bytes={}
   for block=0,math.ceil(length/4)-1 do
    local packed=db(base..'NAME:'..block)
    if packed<0 then packed=packed+4294967296 end
    for offset=0,3 do
     if #bytes<length then bytes[#bytes+1]=string.char(math.floor(packed/(256^offset))%256) end
    end
   end
   local name=table.concat(bytes)
   local level,stars=db(base..'LEVEL'),db(base..'STARS')
   local metadata={level=level,force=stars}
   if M:shouldPersist(name,metadata) then
    M.usedSlots[slot]=true
    M.byName[name]=metadata;M.savedMetadata[name]=metadata;M.cacheIndex[name]=slot
   else
    -- Drop invalid and ordinary-creature cache entries.
    setDbProp(base..'LENGTH',0);setDbProp(base..'LEVEL',-1);setDbProp(base..'STARS',0)
    for block=0,math.ceil(length/4)-1 do setDbProp(base..'NAME:'..block,0) end
   end
  end
 end
 M.cacheLoaded=true
end
function M:saveKnown(name,metadata)
 M:loadCache()
 if not M.cacheLoaded or not M:shouldPersist(name,metadata) then return end
 local previous=M.savedMetadata[name]
 if previous and previous.level==metadata.level and previous.force==metadata.force then return end
 local slot=M.cacheIndex[name]
 if slot==nil then
  slot=0;while slot<CAPACITY and M.usedSlots[slot] do slot=slot+1 end
  if slot>=CAPACITY then M.lastApiError='PadUI cache full (512 names)';return end
  local base=CACHE..slot..':'
  for block=0,math.ceil(#name/4)-1 do
   local packed=0
   for offset=0,3 do packed=packed+(name:byte(block*4+offset+1) or 0)*256^offset end
   if packed>=2147483648 then packed=packed-4294967296 end
   setDbProp(base..'NAME:'..block,packed)
  end
 end
 local base=CACHE..slot..':'
 setDbProp(base..'LEVEL',metadata.level);setDbProp(base..'STARS',metadata.force)
 setDbProp(base..'LENGTH',#name)
 M.cacheIndex[name]=slot;M.usedSlots[slot]=true
 M.savedMetadata[name]={level=metadata.level,force=metadata.force}
end
function M:reference(name)
 local reference=M:catalogReference(name)
 if reference then return reference end
 local learned=M.byName and M.byName[name]
 if learned and learned.force and learned.force>=6 then
   return {level=learned.level,force=learned.force,kind=learned.force>=7 and 'boss' or 'named',native=true}
 end
end
function M:allowsReference(reference)
 if not reference then return false end
 local filter=db('UI:SAVE:PADUI:MOBS:FILTER')
 if filter==2 then return reference.kind=='boss' end
  return reference.kind=='named' or reference.kind=='boss'
end
function M:scan()
 M:loadCache()
 local groups,total={},0
 M.sheetCache=M.sheetCache or {};M.learned={}
 M.lastApiError=nil
 local selected=db('UI:VARIABLES:TARGET:SLOT')
 local targetSheet=clean(call(getTargetSheet) or '')
 local targetLevel=tonumber(call(getTargetLevel))
 local targetStars=tonumber(call(getTargetLevelForce))
 local targetName=clean(call(getTargetName) or '')
 if selected>=1 and selected<255 and selected==math.floor(selected)
  and targetName~='' and targetSheet~='' and targetLevel and targetLevel>0
  and targetStars and targetStars>=6 and call(isTargetPlayer)==false
  and call(isTargetNPC)==false and targetSheet:match('%.creature$')
  and not M:catalogReference(targetName)
  and targetName:sub(1,1)~='#' and not targetName:find('_',1,true) then
  local metadata={sheet=targetSheet,level=targetLevel,force=targetStars}
  M.byName=M.byName or {};M.byName[targetName]=metadata
  M:saveKnown(targetName,metadata)
 end
 for slot=1,254 do
  local base='SERVER:Entities:E'..slot..':'
  local nameId=db(base..'P6')
  local plate=getUI('ui:interface:in_scene_entity_info_'..slot..':right:info0')
  local plateName=plate and clean(plate.hardtext) or ''
  -- Scene names are authoritative; P6 may describe a different server string after re-entry.
  local name=plateName
  if slot==selected and targetName~='' then name=targetName end
  -- Filter the displayed name before grouping/counting; unresolved #ID placeholders are omitted.
  local reference=M:reference(name)
  if name~='' and name:sub(1,1)~='#' and not name:find('_',1,true) and M:allowsReference(reference) then
   local rawSheet=db(base..'P4')
   local key='name:'..name..':'..tostring(rawSheet)
   local entry=groups[key]
   if not entry then
    entry={key=key,nameId=nameId,rawSheet=rawSheet,count=0,slots={},name=name,reference=reference}
    groups[key]=entry
   end
   entry.count=entry.count+1;total=total+1
   entry.slots[#entry.slots+1]=slot
   if slot==selected and targetSheet~='' then
    M.learned[key]={sheet=targetSheet,level=targetLevel and targetLevel>=0 and targetLevel or nil,force=targetStars and targetStars>0 and targetStars or nil}

   end
  end
 end
 local rows={}
 for key,entry in pairs(groups) do
  local known=M.learned[key]
  local sheet=known and known.sheet
  if not sheet and entry.rawSheet~=0 and entry.rawSheet~=-1 then
   local unsigned=entry.rawSheet<0 and entry.rawSheet+4294967296 or entry.rawSheet
   if M.sheetCache[entry.rawSheet]==nil then
    M.sheetCache[entry.rawSheet]=clean(call(getSheetName,unsigned) or '')
   end
   sheet=M.sheetCache[entry.rawSheet]
  end
  entry.sheet=sheet or ''
  local metadata=known or (entry.name and M.byName and M.byName[entry.name])
  entry.level=(metadata and metadata.level) or entry.reference.level
  entry.force=(metadata and metadata.force) or entry.reference.force
  entry.kind=entry.reference.kind
  if metadata and metadata.sheet then entry.sheet=metadata.sheet end
  -- ForceLevel is the native star rating. RegionForce is not a substitute.
  rows[#rows+1]=entry
 end
 M.rows=rows;M.total=total
end
function M:render()
 local w=M:words();local rows=M.rows or {};local order=db('UI:SAVE:PADUI:MOBS:SORT')
 if order<0 or order>2 then order=0 end
 table.sort(rows,function(a,b)
  if order==0 and (a.level or -1)~=(b.level or -1) then return (a.level or -1)>(b.level or -1) end
  if order~=1 and (a.force or -1)~=(b.force or -1) then return (a.force or -1)>(b.force or -1) end
  local an,bn=a.name or '',b.name or ''
  if an~=bn then return an:lower()<bn:lower() end
  return a.key<b.key
 end)
 local pages=math.max(1,math.ceil(#rows/SIZE))
 M.page=math.max(0,math.min(pages-1,M.page or 0))
 local title=getUI(ROOT..':header_opened:title');if title then title.hardtext=w.title;title.color=PadUI:accent() end
 PadUI:setText('ui:interface:gestion_windows:inventory:padui_mobs:text',w.title)
 text('name_heading',w.name);text('count_heading',w.count);text('level_heading',w.level);text('force_heading',w.force)
 text('summary',string.format(w.summary,M.total or 0,#rows))
 text('note',w.note);text('sort_text',w.sort..w.orders[order+1])
 local filter=db('UI:SAVE:PADUI:MOBS:FILTER');text('filter_text',w.filters[filter+1] or w.filters[1])
 text('page',w.page..' '..(M.page+1)..' / '..pages)
 local empty=getUI(ROOT..':content:empty');if empty then empty.active=#rows==0 and db('UI:SAVE:PADUI:MOBS:COMPACT')~=1;empty.hardtext=w.empty end
 for index=0,SIZE-1 do
  local entry=rows[M.page*SIZE+index+1]
  local row=getUI(ROOT..':content:row'..index)
  local visible=entry~=nil and db('UI:SAVE:PADUI:MOBS:COMPACT')~=1
  if row and row.active~=visible then row.active=visible end
  local id=entry and entry.nameId or 0
  if entry then
   text('row'..index..':name',entry.name or (id~=0 and ('#'..id) or w.unknown))
   text('row'..index..':count',tostring(entry.count))
   text('row'..index..':level',entry.level and tostring(entry.level) or '--')
   text('row'..index..':force',entry.force and tostring(entry.force) or '--')
   local tip=getUI(ROOT..':content:row'..index..':tip')
   if tip then
    local samples={};for i=1,math.min(6,#entry.slots) do samples[i]=tostring(entry.slots[i]) end
    local value=(entry.name or (id~=0 and ('#'..id) or w.unknown))..' / Sheet: '..(entry.sheet~='' and entry.sheet or w.unknown)..' / P4: '..entry.rawSheet..' / P6: '..id..' / Slots: '..table.concat(samples,', ')
    value=value..' / '..(entry.reference.native and 'Client: ' or 'Ballistic Mystix: ')..(w.kinds[entry.kind] or '')
    if entry.reference.ambiguous then value=value..' / '..w.ambiguous end
    if M.lastApiError then value=value..' / API: '..M.lastApiError end
    if tip.tooltip~=value then tip.tooltip=value end
   end
  end
 end
 M:layout()
end
function M:layout()
 local compact=db('UI:SAVE:PADUI:MOBS:COMPACT')==1
 if M.layoutCompact==compact then return end
 local root=getUI(ROOT);local content=getUI(ROOT..':content')
 if not root or not content then return end
 root.h=compact and 54 or 392;content.h=compact and 34 or 372
 local back=getUI(ROOT..':content:back');if back then back.h=content.h end
 for _,id in ipairs({'sort','sort_back','sort_text','filter','filter_back','filter_text','name_heading','count_heading','level_heading','force_heading','previous','previous_back','previous_text','page','next','next_back','next_text','note'}) do
  local n=getUI(ROOT..':content:'..id);if n and n.active~=not compact then n.active=not compact end
 end
 for i=0,SIZE-1 do
  local row=getUI(ROOT..':content:row'..i)
  if row then row.active=not compact and (M.rows or {})[(M.page or 0)*SIZE+i+1]~=nil end
 end
 local label=getUI(ROOT..':header_opened:compact_text');if label then label.hardtext=compact and '+' or '−' end
 root:invalidateCoords();content:invalidateCoords();M.layoutCompact=compact
end
function M:toggleCompact()
 setDbProp('UI:SAVE:PADUI:MOBS:COMPACT',db('UI:SAVE:PADUI:MOBS:COMPACT')==1 and 0 or 1)
 M.layoutCompact=nil;M:render()
end
-- Wiki boss suffixes are hints only; never identify a player from a name.
local function bossSuffix(name)
 local lower=tostring(name or ''):lower()
 return lower:match('kan$') or lower:match('kin$') or lower:match('keth$')
  or lower:match('kya$') or lower:match('kyo$') or lower:match('koo$')
end
function M:notifyBosses()
 M.seenBosses=M.seenBosses or {}
 local now=nltime.getLocalTime()
 -- Clear all reported boss names together every five minutes.
 if not M.bossAlertResetAt or now<M.bossAlertResetAt or now-M.bossAlertResetAt>=300000 then
  M.seenBosses={}
  M.bossAlertResetAt=now
 end
 local slot=db('UI:VARIABLES:TARGET:SLOT')
 local name=clean(call(getTargetName) or '')
 local sheet=clean(call(getTargetSheet) or '')
 local stars=tonumber(call(getTargetLevelForce))
 local creature=slot>=1 and slot<255 and slot==math.floor(slot)
  and sheet:match('%.creature$') and call(isTargetPlayer)==false
  and call(isTargetNPC)==false
 local confirmed=creature and stars and stars>=7 and bossSuffix(name)
 if not confirmed then return end
 if M.seenBosses[name] then return end
 M.seenBosses[name]=true
 local lang=PadUI:language()
 local prefix=lang=='de' and 'Boss gefunden: ' or (lang=='fr' and 'Boss détecté : ' or 'Boss found: ')
 local message='PadUI: '..prefix..name
 local ok=pcall(displaySystemInfo,message,'SYS')
 if not ok and ucstring then pcall(function()displaySystemInfo(ucstring(message),'SYS')end) end
 local popup=getUI('ui:interface:padui_boss_alert:content:message')
 local window=getUI('ui:interface:padui_boss_alert')
 if popup and window then popup.hardtext=message;window.active=true;M.alertUntil=now+10000 end
end
function M:tick(force)
 if not game or not game.InGameDbInitialized then return end
 local now=nltime.getLocalTime()
 if M.alertUntil and now>=M.alertUntil then
  local alert=getUI('ui:interface:padui_boss_alert');if alert then alert.active=false end
  M.alertUntil=nil
 end
 local root=getUI(ROOT)
 if not root or not root.active then return end
 if not force and M.lastTick and now>=M.lastTick and now-M.lastTick<1000 then return end
 M.lastTick=now
 local ok,err=pcall(function()M:scan();M:render();M:notifyBosses()end)
 if not ok then text('summary','PadUI: '..tostring(err)) end
end
function M:turn(delta)M.page=(M.page or 0)+delta;M:render()end
function M:sort()
 setDbProp('UI:SAVE:PADUI:MOBS:SORT',(db('UI:SAVE:PADUI:MOBS:SORT')+1)%3)
 M.page=0;M:render()
end
function M:filter()
 setDbProp('UI:SAVE:PADUI:MOBS:FILTER',(db('UI:SAVE:PADUI:MOBS:FILTER')+1)%3)
 M.page=0;M:tick(true)
end
function M:onActive()
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_MOBS',1)
 M:tick(true)
end
function M:start()
 M:loadCache()
 PadUI:setText('ui:interface:gestion_windows:inventory:padui_mobs:text',M:words().title)
 M:tick(true)
end
