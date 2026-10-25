-- PadAuras preview: display-only warnings for timed effects on this character.
-- Server timers use game cycles (10 per second), not milliseconds.
PadUIAuras = PadUIAuras or {}
local A=PadUIAuras
local ROOT='ui:interface:padui_auras'
local TEMP='UI:VARIABLES:PADUI:AURAS:'
local words={
 de={test='Test',tip='Testanzeige für 5 Sekunden. Testkachel am Hintergrund ziehen.',bonus='Buff läuft aus',malus='Debuff läuft aus',demo='Testanzeige',position='Position in den sichtbaren Bereich zurücksetzen'},
 en={test='Test',tip='Show a 5-second preview. Drag the preview tile background.',bonus='Buff expires',malus='Debuff expires',demo='Preview',position='Reset position to the visible area'},
 fr={test='Test',tip='Aperçu de 5 secondes. Déplacer par le fond de la tuile.',bonus='Bonus expire',malus='Malus expire',demo='Aperçu',position='Replacer dans la zone visible'}
}
local function db(p) return tonumber(getDbProp(p)) or 0 end
function A:remaining(ending,tick,disabled)
 if disabled~=0 or ending<=tick then return nil end
 local seconds=(ending-tick)/10
 if seconds>A:warningSeconds() then return nil end
 return seconds
end
function A:collect(tick)
 A:loadCatalog()
 local entries={}
 for _,kind in ipairs({'BONUS','MALUS'}) do
  for i=0,11 do
   local p='SERVER:MODIFIERS:'..kind..':'..i..':'
   local sheet=db(p..'SHEET')
   local ending=db(p..'DISABLED_TIME')
   if sheet~=0 and ending>0 then A:remember(sheet) end
   local seconds=A:remaining(ending,tick,db(p..'DISABLED'))
   if sheet~=0 and seconds and A:allows(sheet,kind) then
    entries[#entries+1]={sheet=sheet,seconds=seconds,kind=kind:lower(),key=kind..i}
   end
  end
 end
 table.sort(entries,function(a,b)
  if a.seconds~=b.seconds then return a.seconds<b.seconds end
  return a.key<b.key
 end)
 return entries
end
function A:tickNow()
 local current=db('UI:VARIABLES:CURRENT_SERVER_TICK')
 local smooth=db('UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK')
 -- Smooth clock: 100 units per game cycle, 1000 units per second.
 return smooth>0 and math.max(current,smooth/100) or current
end
function A:beginPreview()
 A.placing=true
 A.demoStart=nltime.getLocalTime()
 A.demoSheet=0
 for i=0,11 do
  local sheet=db('SERVER:MODIFIERS:BONUS:'..i..':SHEET')
  if sheet~=0 then A.demoSheet=sheet;break end
 end
 if A.demoSheet==0 then A.demoSheet=getSheetId('mod_dodge_success.sbrick') end
end
function A:test()
 if not game or not game.InGameDbInitialized then return end
 if A.placing then A.placing=false else A:beginPreview() end
 if A.placing then
  local window=getUI(ROOT)
  if window then window.active=true end
  runAH(nil,'set','target_property='..ROOT..':opened|value=1')
 end
 A:update()
end
function A:menuToggle()
 if not game or not game.InGameDbInitialized then return end
 local window=getUI(ROOT)
 if not window then return end
 if window.active then
  A.placing=false
  A.autoHidden=false
  window.active=false
  return
 end
 local entries=A:collect(A:tickNow())
 A.autoHidden=false
 if #entries==0 then A:beginPreview() else A.placing=false end
 window.active=true
 runAH(nil,'set','target_property='..ROOT..':opened|value=1')
 A:update()
end
function A:resetPosition()
 local window=getUI(ROOT)
 if not window then return end
 local width,height=getWindowSize()
 height=tonumber(height) or 400
 setDbProp('UI:SAVE:PADUI:AURAS:PLACED_012',1)
 window.x=20
 window.y=-math.min(140,math.max(24,height-70))
 window.active=true
 runAH(nil,'set','target_property='..ROOT..':opened|value=1')
 window:invalidateCoords()
end
function A:onActive()
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_AURAS',1)
 runAH(nil,'set','target_property='..ROOT..':opened|value=1')
 A:update()
end
function A:start()
 -- Saved window coordinates and visibility are owned by the native client.
 A:update()
end
function A:update()
 if not game or not game.InGameDbInitialized then return end
 local window=getUI(ROOT)
 local header=getUI(ROOT..':header_opened')
 if not window or not header then return end
 if db('UI:SAVE:PADUI:AURAS:PLACED_012')==0 then A:resetPosition() end
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_AURAS',window.active and 1 or 0)
 local tick=A:tickNow()
 local entries=A:collect(tick)
 -- Hide the native container completely while there are no aura tiles.
 -- Remember only automatic hiding so a manually hidden window stays hidden.
 if #entries==0 and not A.placing then
  if window.active then A.autoHidden=true;window.active=false end
 elseif A.autoHidden then
  window.active=true
  A.autoHidden=false
 end
 if A.placing then
  local duration=A:warningSeconds()
  local elapsed=math.max(0,nltime.getLocalTime()-(A.demoStart or nltime.getLocalTime()))/1000
  -- Preview stays in the first slot so real effects cannot move the drag target.
  table.insert(entries,1,{sheet=A.demoSheet,seconds=duration-(elapsed%duration),kind='demo'})
 end
 local text,lang=A:texts()
 local page=getUI('ui:interface:padui_settings:content:page2')
 if page and page.active and (A.settingsDirty or A.settingsLanguage~=lang) then A:refreshSettings() end
 A.tileSignatures=A.tileSignatures or {}
 for i=0,24 do
  local base=ROOT..':header_opened:alert'..i
  local tile=getUI(base)
  local entry=entries[i+1]
  local seconds=entry and math.floor(entry.seconds+0.000001) or 0
  local signature=entry and table.concat({tostring(entry.sheet),tostring(seconds),
   entry.seconds<=2 and 'critical' or 'normal',entry.kind,lang,PadUI:accent(220)},':') or 'empty'
  if tile and A.tileSignatures[i]~=signature then
   if tile.active~=(entry~=nil) then tile.active=entry~=nil end
   if entry then
    if db(TEMP..i..':SHEET')~=entry.sheet then setDbProp(TEMP..i..':SHEET',entry.sheet) end
    local countdown=getUI(base..':countdown')
    if countdown then
     countdown.hardtext=seconds<1 and '<1' or tostring(seconds)
     countdown.color=entry.seconds<=2 and '255 115 95 255' or '245 235 210 255'
    end
    local status=getUI(base..':status')
    if status then status.hardtext=entry.kind=='demo' and text.demo or '' end
    local icon=getUI(base..':icon')
    if icon then icon.tooltip=text[entry.kind] end
    local border=getUI(base..':accent')
    if border then border.color=entry.kind=='malus' and '225 90 80 220' or PadUI:accent(220) end
   end
   A.tileSignatures[i]=signature
  end
 end
 local width=#entries>0 and (8+66*math.min(4,#entries)) or 1
 local height=#entries>0 and (4+math.ceil(#entries/4)*74) or 1
 if header.h~=height or header.w~=width then
  header.h=height;header.w=width;window.w=width;window.h=height
  header:invalidateCoords();window:invalidateCoords()
 end
end

-- Settings/catalog are saved per character, independently of alert slot order.
local SAVE='UI:SAVE:PADUI:AURAS:'
local MODAL='ui:interface:padui_settings:content:page2'
local PICK='UI:VARIABLES:PADUI:AURAS_PICK:'
local TIMES={3,5,10,15,30}
local PAGE_SIZE=3
local MAX_KNOWN=256
local more={
 de={settings='PadAuras einstellen',warning='Warnung vor Ablauf',both='Beide',buffs='Buffs',debuffs='Debuffs',effects='Erkannte Effekte — Klick zum Ein-/Ausschließen',empty='Noch kein zeitgesteuerter Effekt erkannt.',included='Überwachen',excluded='Ausgeschlossen',defaults='Standard',default_tip='5 Sekunden, Buffs und Debuffs, alle Effekte überwachen.',close='Schließen',page='Seite'},
 en={settings='PadAuras settings',warning='Warn before expiry',both='Both',buffs='Buffs',debuffs='Debuffs',effects='Observed effects — click to include/exclude',empty='No timed effect observed yet.',included='Monitor',excluded='Excluded',defaults='Defaults',default_tip='5 seconds, buffs and debuffs, monitor all effects.',close='Close',page='Page'},
 fr={settings='Réglages PadAuras',warning='Alerte avant expiration',both='Les deux',buffs='Bonus',debuffs='Malus',effects='Effets observés — cliquer pour inclure/exclure',empty='Aucun effet temporisé observé.',included='Surveiller',excluded='Exclu',defaults='Défaut',default_tip='5 secondes, bonus et malus, surveiller tous les effets.',close='Fermer',page='Page'}
}
for lang,values in pairs(more) do for k,v in pairs(values) do words[lang][k]=v end end
function A:texts()
 local lang=PadUI and PadUI:language() or 'en'
 return words[lang] or words.en,lang
end
function A:warningSeconds()
 local value=db(SAVE..'SECONDS')
 for _,seconds in ipairs(TIMES) do if value==seconds then return value end end
 return 5
end
function A:mode()
 local value=db(SAVE..'MODE')
 return (value==1 or value==2) and value or 0
end
function A:loadCatalog()
 if A.catalog then return end
 A.catalog={};A.catalogIndex={}
 for i=0,MAX_KNOWN-1 do
  local sheet=db(SAVE..'KNOWN:'..i..':SHEET')
  if sheet~=0 then
   A.catalog[#A.catalog+1]={sheet=sheet,slot=i}
   A.catalogIndex[sheet]=i
  end
 end
end
function A:remember(sheet)
 A:loadCatalog()
 if A.catalogIndex[sheet]~=nil or #A.catalog>=MAX_KNOWN then return end
 local used={};for _,entry in ipairs(A.catalog) do used[entry.slot]=true end
 local slot=0;while used[slot] do slot=slot+1 end
 setDbProp(SAVE..'KNOWN:'..slot..':SHEET',sheet)
 setDbProp(SAVE..'KNOWN:'..slot..':EXCLUDED',0)
 A.catalogIndex[sheet]=slot
 A.catalog[#A.catalog+1]={sheet=sheet,slot=slot}
 A.settingsDirty=true
end
function A:allows(sheet,kind)
 local mode=A:mode()
 if (mode==1 and kind=='MALUS') or (mode==2 and kind=='BONUS') then return false end
 local slot=A.catalogIndex and A.catalogIndex[sheet]
 return slot==nil or db(SAVE..'KNOWN:'..slot..':EXCLUDED')~=1
end
function A:setSeconds(value)
 value=tonumber(value)
 for _,seconds in ipairs(TIMES) do
  if value==seconds then
   setDbProp(SAVE..'SECONDS',value);A:refreshSettings();A:update();return
  end
 end
end
function A:setMode(value)
 value=tonumber(value)
 if value~=0 and value~=1 and value~=2 then return end
 setDbProp(SAVE..'MODE',value);A:refreshSettings();A:update()
end
function A:toggleEffect(row)
 row=tonumber(row)
 if not row or row~=math.floor(row) or row<0 or row>=PAGE_SIZE then return end
 local entry=A.settingsRows and A.settingsRows[row+1]
 if not entry then return end
 local key=SAVE..'KNOWN:'..entry.slot..':EXCLUDED'
 setDbProp(key,db(key)==1 and 0 or 1)
 A:refreshSettings();A:update()
end
function A:defaults()
 A:loadCatalog()
 for _,entry in ipairs(A.catalog) do setDbProp(SAVE..'KNOWN:'..entry.slot..':EXCLUDED',0) end
 setDbProp(SAVE..'SECONDS',5);setDbProp(SAVE..'MODE',0)
 A:refreshSettings();A:update()
end
function A:settings()
 A:loadCatalog();A.page=0
 if PadUISettings then PadUISettings:page(2) end
 local window=getUI('ui:interface:padui_settings');if window then window.active=true end
 A:refreshSettings()
end
function A:turnPage(delta)
 A.page=(A.page or 0)+(tonumber(delta) or 0);A:refreshSettings()
end
function A:refreshSettings()
 A:loadCatalog()
 local text,lang=A:texts()
 A.settingsLanguage=lang;A.settingsDirty=false
 local function label(id,value)
  local node=getUI(MODAL..':'..id);if node then node.hardtext=value end
 end
 label('empty',text.empty)
 local pages=math.max(1,math.ceil(#A.catalog/PAGE_SIZE))
 A.page=math.max(0,math.min(pages-1,math.floor(A.page or 0)))
 A.settingsRows={}
 for row=0,PAGE_SIZE-1 do
  local entry=A.catalog[A.page*PAGE_SIZE+row+1]
  A.settingsRows[row+1]=entry
  local base=MODAL..':row'..row
  local group=getUI(base);if group then group.active=entry~=nil end
  setDbProp(PICK..row..':0:SHEET',entry and entry.sheet or 0)
  if entry then
   local excluded=db(SAVE..'KNOWN:'..entry.slot..':EXCLUDED')==1
   local check=getUI(base..':check');if check then check.hardtext=excluded and '[-]' or '[x]';check.color=excluded and '255 170 130 255' or PadUI:accent() end
   local toggle=getUI(base..':toggle');if toggle then toggle.tooltip=excluded and text.excluded or text.included end
  end
 end
 local empty=getUI(MODAL..':empty');if empty then empty.active=#A.catalog==0 end
 label('page',text.page..' '..(A.page+1)..' / '..pages)
 for _,pair in ipairs({{'previous',A.page>0},{'next',A.page<pages-1}}) do
  local button=getUI(MODAL..':'..pair[1]);if button then button.active=pair[2] end
  local value=getUI(MODAL..':'..pair[1]..'_text');if value then value.active=pair[2] end
 end
 local reset=getUI(MODAL..':aura_defaults');if reset then reset.tooltip=text.default_tip end
end
