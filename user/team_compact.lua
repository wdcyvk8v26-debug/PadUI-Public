-- PadUI modular team: one controller, nine independent native windows.
-- Lua 5.1 syntax. Native team data is read locally; targeting requires a click.
-- The old team_compact container is retained ONLY as an inactive compatibility
-- switch for the native window manager. It never surrounds the member windows.
RyzomTeamUI = RyzomTeamUI or {}
local T = RyzomTeamUI
local LEGACY = 'ui:interface:team_compact'
local DRIVER = 'ui:interface:padui_team_driver'
local CARD = 'ui:interface:padui_team_member'
local SAVE = 'UI:SAVE:PADUI:TEAM_MODULAR:'
local SORT_DB = 'UI:SAVE:TEAM_COMPACT:SORT'
local MODE_DB = 'UI:SAVE:PADUI:TEAM_LAYOUT'
local ACTIVE_DB = 'UI:VARIABLES:ISACTIVE:TEAM_COMPACT'
local PAGE = 'ui:interface:padui_settings:content:page3'
local SORT_MODES = {name=0, hp=1, missing=2}
local BASE_FONT = {name=11, status=10, hp_text=10, sap_text=9, sta_text=9}
local SCORES = {'hp', 'sap', 'sta'}
local TEXT_IDS = {'name', 'status', 'hp_text', 'sap_text', 'sta_text'}
local words = {
 de={title='Teamfenster', modes={'Vertikal','Horizontal','Frei'}, columns='Spalten (vertikal)', rows='Zeilen (horizontal)', free='Positionen einzeln gespeichert', locked='Positionen gesperrt', unlocked='Verschieben erlaubt', reset='Positionen zur\195\188cksetzen', note='Zum Verschieben entsperren; am linken Rand ziehen. Frei: keine laufende Umsortierung.', overflow='Raster gr\195\182\195\159er als Bildschirm: Gr\195\182\195\159e oder Zeilen/Spalten anpassen.'},
 en={title='Team windows', modes={'Vertical','Horizontal','Free'}, columns='Columns (vertical)', rows='Rows (horizontal)', free='Individual positions saved', locked='Positions locked', unlocked='Movement unlocked', reset='Reset positions', note='Unlock, then drag the left edge. Free: members keep their positions when HP changes.', overflow='Grid exceeds screen: adjust scale or row/column count.'},
 fr={title='Fen\195\170tres d\226\128\153\195\169quipe', modes={'Vertical','Horizontal','Libre'}, columns='Colonnes (vertical)', rows='Lignes (horizontal)', free='Positions individuelles sauv\195\169es', locked='Positions verrouill\195\169es', unlocked='D\195\169placement permis', reset='Replacer les fen\195\170tres', note='D\195\169verrouiller puis tirer le bord gauche. Libre : les PV ne changent pas les positions.', overflow='Grille trop grande : ajuster la taille ou les lignes/colonnes.'}
}
local function db(p) return tonumber(getDbProp(p)) or 0 end
local function ready() return game and game.InGameDbInitialized and (not isPlayerReady or isPlayerReady()) end
local function clean(s) return tostring(s or ''):gsub('@%b{}',''):gsub('%s*%(.*$',''):match('^%s*(.-)%s*$') end
local function round(x) return x < 0 and -math.floor(-x+0.5) or math.floor(x+0.5) end
local function clamp(x, a, b) return math.max(a, math.min(b, x)) end
local function percent(v, maximum) return round(clamp(v / maximum, 0, 1) * 100) end
local function ui(p) return getUI(p, false) end
local function changed(n, k, value)
 if n and n[k] ~= value then n[k] = value; return true end
 return false
end
local function store(p, value)
 if db(p) ~= value then setDbProp(p, value) end
end
local function xml(s)
 return tostring(s):gsub('&','&amp;'):gsub('"','&quot;'):gsub('<','&lt;'):gsub('>','&gt;')
end
local function labels() return words[PadUI:language()] or words.en end

-- Native streamToDataBase only restores leaves that already exist. Declare our
-- UI:SAVE leaves while this Lua file is parsed, BEFORE character .icfg loading.
-- This touches neither UI objects nor the native player entity. In-game Lua
-- reloads preserve values; normal UI initialization starts with default leaves.
local function declareSaved(reset)
 if not addDbProp or not getDbProp then return end
 local function leaf(p) addDbProp(p,reset and 0 or db(p)) end
 for _,k in ipairs({'INIT','ENABLED','COLUMNS','ROWS','LOCKED','ANCHOR_X','ANCHOR_Y'}) do leaf(SAVE..k) end
 for i=1,9 do for _,k in ipairs({'SET','X','Y'}) do leaf(SAVE..'FREE:'..i..':'..k) end end
end
declareSaved(not (game and game.InGameDbInitialized))

-- Pure layout helper: distribute members evenly across the requested tracks.
-- Vertical fills each column downwards; horizontal fills each row to the right.
function T:grid(count, mode, tracks)
 local out = {}
 if count == 0 then return out, 0, 0 end
 tracks = clamp(math.floor(tracks or 1), 1, count)
 local base, extra, rank = math.floor(count / tracks), count % tracks, 1
 local longest = base + (extra > 0 and 1 or 0)
 for track = 0, tracks-1 do
  for cell = 0, base + (track < extra and 1 or 0)-1 do
   out[rank] = mode == 0 and {x=track,y=cell} or {x=cell,y=track}
   rank = rank + 1
  end
 end
 return out, mode == 0 and tracks or longest, mode == 0 and longest or tracks
end
function T:mode()
 local m = db(MODE_DB); return (m == 1 or m == 2) and m or 0
end
function T:horizontal() return T:mode() == 1 end
function T:showSelf() return db('UI:SAVE:PADUI:HIDE_SELF') == 0 end
function T:isEnabled()
 if db(SAVE..'INIT') == 1 then return db(SAVE..'ENABLED') == 1 end
 local w = ui(LEGACY); return w and w.active or false
end
function T:sortMode()
 local m = db(SORT_DB); return (m == 1 or m == 2) and m or 0
end
function T:trackCount(mode)
 local value = db(SAVE..(mode == 0 and 'COLUMNS' or 'ROWS'))
 return clamp(math.floor(value), 1, 9)
end

-- Inline XML is registered once per UI lifetime. No extra runtime file/symlink
-- is needed and no GUI object is created in the steady-state update loop.
function T:interfaceXML()
 local a = {'<interface_config><root id="interface" x="0" y="0" w="800" h="600" active="true" />'}
 a[#a+1] = '<group id="padui_team_driver" w="1" h="1" active="true" use_cursor="false" child_resize_w="false" child_resize_h="false" posref="TL TL">'
 for i=0,7 do
  a[#a+1] = '<view type="text_id" id="name_source'..i..'" textid="0" dynamic_string="false" posref="TL TL" fontsize="10" color="0 0 0 0" shadow="false" global_color="false" />'
 end
 -- Root groups need an explicit tree entry for native draw/checkCoords.
 a[#a+1] = '</group><tree node="padui_team_driver" />'
 for i=1,9 do
  local id = 'padui_team_member'..i
  a[#a+1] = '<group type="container" id="'..id..'" w="200" h="34" x="20" y="-100" posref="TL TL" title="" options="no_bordure" active="false" opened="true" openable="false" resizer="false" movable="true" lockable="true" locked="true" savable="false" active_savable="false" popable="false" force_open_out="true" open_button="false" title_bar_open="false" right_button="false" header_active="false" global_color="false" global_color_over="false" min_w="1" min_h="1" max_w="4096" max_h="4096" pop_min_w="1" pop_min_h="1" pop_max_w="4096" pop_max_h="4096" escapable="false">'
  a[#a+1] = '<group id="header_closed" h="0" /><group id="header_opened" w="200" h="34" posref="TL TL">'
  local function bitmap(name, x, y, w, h, color)
   a[#a+1] = '<view type="bitmap" id="'..name..'" posref="TL TL" x="'..x..'" y="'..y..'" w="'..w..'" h="'..h..'" texture="blank.tga" scale="true" color="'..color..'" global_color="false" />'
  end
  bitmap('background',0,0,200,34,'12 18 24 255')
  bitmap('grip',0,0,4,34,'110 235 225 120')
  bitmap('selected',4,0,3,34,'255 215 110 255')
  bitmap('self_marker',0,0,3,34,'110 235 225 255')
  bitmap('hp_back',8,-13,188,10,'35 42 48 255')
  bitmap('hp_fill',8,-13,188,10,'150 38 16 255')
  bitmap('sap_back',8,-23,92,10,'35 42 48 255')
  bitmap('sap_fill',8,-23,92,10,'55 95 25 255')
  bitmap('sta_back',104,-23,92,10,'35 42 48 255')
  bitmap('sta_fill',104,-23,92,10,'100 45 105 255')
  for _, name in ipairs(TEXT_IDS) do
   local parent = name:gsub('_text','_back')
   local posref, x = 'MM MM', 0
   if name == 'name' then parent=''; posref='TL TL'; x=8
   elseif name == 'status' then parent=''; posref='TR TR'; x=-4 end
   for size=7,18 do
    a[#a+1] = '<view type="text" id="'..name..'_s'..size..'" posref="'..posref..'"'..(parent ~= '' and (' posparent="'..parent..'"') or '')..' x="'..x..'" y="0" fontsize="'..size..'" hardtext="" color="245 235 210 255" shadow="true" global_color="false" active="false" />'
   end
  end
  a[#a+1] = '<ctrl type="button" id="target_button" posref="TL TL" x="7" y="0" w="193" h="34" button_type="push_button" scale="true" tx_normal="blank.tga" tx_pushed="blank.tga" tx_over="blank.tga" color="0 0 0 0" col_pushed="0 0 0 0" col_over="255 255 255 16" global_color_normal="false" global_color_pushed="false" global_color_over="false" onclick_l="lua" params_l="RyzomTeamUI:click('..i..', &apos;left&apos;)" onclick_r="lua" params_r="RyzomTeamUI:click('..i..', &apos;right&apos;)" />'
  a[#a+1] = '</group><group id="content" w="0" h="0" /></group><tree node="'..id..'" />'
 end
 -- A small child panel in the existing Layout tab. Original scale sliders stay.
 a[#a+1] = '<template name="padui_modular_team_settings" keep="true"><group id="modular_team" posref="TL TL" w="342" h="172">'
 local function label(id,x,y,size,maxw)
  a[#a+1] = '<view type="text" id="'..id..'" posref="TL TL" x="'..x..'" y="'..y..'" fontsize="'..size..'" line_maxw="'..maxw..'" hardtext="" shadow="true" global_color="false" color="245 235 210 255" />'
 end
 local function button(id,x,y,w,action)
  a[#a+1] = '<group id="'..id..'" posref="TL TL" x="'..x..'" y="'..y..'" w="'..w..'" h="26"><view type="bitmap" id="back" posref="TL TL" sizeref="wh" w="0" h="0" texture="blank.tga" scale="true" color="35 45 53 220" global_color="false" />'
  label('text',5,-5,9,w-10)
  a[#a+1] = '<ctrl type="button" id="button" posref="TL TL" sizeref="wh" w="0" h="0" button_type="push_button" scale="true" tx_normal="blank.tga" tx_pushed="blank.tga" tx_over="blank.tga" color="0 0 0 0" col_pushed="0 0 0 0" col_over="110 235 225 40" global_color_normal="false" global_color_pushed="false" global_color_over="false" onclick_l="lua" params_l="'..xml(action)..'" /></group>'
 end
 label('title',0,0,11,336)
 for i=0,2 do button('mode'..i,114*i,-24,108,'RyzomTeamUI:setLayout('..i..')') end
 label('count_label',0,-117,10,210)
 button('less',214,-111,28,'RyzomTeamUI:changeTracks(-1)')
 label('count',254,-117,10,32)
 button('more',300,-111,28,'RyzomTeamUI:changeTracks(1)')
 button('lock',0,-143,164,'RyzomTeamUI:toggleLock()')
 button('reset',171,-143,165,'RyzomTeamUI:resetPositions()')
 a[#a+1] = '</group></template></interface_config>'
 return table.concat(a)
end

-- Statistics are counters, not per-frame logging. Useful for regression tests.
T.stats = {polls=0, sorts=0, layouts=0, writes=0, builds=0}
T.rows, T.cards, T.members = {}, {}, {}
T.lastTick, T.character, T.failed, T.initializing = nil, nil, nil, false
T.uiReady, T.panel, T.busy, T.menuMember = false, nil, false, nil
local function put(v, id, key, value)
 local n = v.nodes[id]
 if not n then return end
 local ck = id..':'..key
 if v.cache[ck] ~= value then
  if changed(n,key,value) then T.stats.writes=T.stats.writes+1 end
  v.cache[ck] = value
 end
end
function T:hideCards()
 for _,v in ipairs(T.cards) do
  if v.window then changed(v.window,'active',false) end
 end
end
function T:initUI()
 if T.uiReady then return true end
 if not parseInterfaceFromString or not createGroupInstance or not addDbProp or not getMouseDown or not setOnDraw then
  error('Client lacks native XML/template/DB/mouse/draw API')
 end
 local legacy = ui(LEGACY)
 if not legacy then return false end
 if not ui(DRIVER) then
  if parseInterfaceFromString(T:interfaceXML()) == false then error('Cannot parse modular team XML') end
  T.stats.builds = T.stats.builds+1
 end
 T.driver, T.legacy = ui(DRIVER), legacy
 if not T.driver then error('Team controller not created') end
 T.sources, T.oldSources, T.nameRequests = {}, {}, {}
 for i=0,7 do
  T.sources[i] = ui(DRIVER..':name_source'..i)
  T.oldSources[i] = ui(LEGACY..':content:name_source'..i)
  if not T.sources[i] then error('Missing native team name source '..i) end
  -- A previous test version bound this view to SERVER:GROUP. Never write its
  -- textid: the native setter would write through that DB link. Restart first.
  if T.sources[i].textid_dblink~='' then error('Team name widgets changed; fully restart Ryzom') end
 end
 for i=1,9 do
  local w = ui(CARD..i)
  if not w then error('Team member window not created: '..i) end
  local v = {window=w, nodes={}, cache={}, slot=i}
  v.nodes.window = w
  v.nodes.header = ui(CARD..i..':header_opened')
  for _,id in ipairs({'background','grip','selected','self_marker','hp_back','hp_fill','sap_back','sap_fill','sta_back','sta_fill','target_button'}) do
   v.nodes[id] = ui(CARD..i..':header_opened:'..id)
   if not v.nodes[id] then error('Missing member element '..id) end
  end
  for _,id in ipairs(TEXT_IDS) do
   for size=7,18 do v.nodes[id..'_s'..size] = ui(CARD..i..':header_opened:'..id..'_s'..size) end
  end
  -- Only these new containers: no native frame/fading, custom bars stay visible.
  runAH(nil,'set_alpha','target='..CARD..i..'|alpha=0')
  T.cards[i] = v
 end
 setOnDraw(T.driver,'RyzomTeamUI:update()') -- ONE frame hook for all nine windows
 setOnDraw(legacy,'')
 T.uiReady = true
 return true
end
function T:initCharacter(name)
 T:hideCards()
 T.menuMember=nil
 T.rows, T.members, T.ordered, T.nameRequests = {}, {}, {}, {}
 T.rosterKey, T.sortKey, T.layoutKey, T.geometryKey = nil,nil,nil,nil
 T.dragging, T.lastMode, T.pendingPositionSave = nil,nil,false
 for _,v in ipairs(T.cards) do v.key=nil;v.member=nil;v.cache={};v.x=nil;v.y=nil end
 declareSaved(false)
 if db(SAVE..'INIT') ~= 1 then
  local sw,sh=getWindowSize();sw=tonumber(sw) or 1280;sh=tonumber(sh) or 720
  store(SAVE..'ENABLED', T.legacy.active and 1 or 0)
  store(SAVE..'COLUMNS',1);store(SAVE..'ROWS',2);store(SAVE..'LOCKED',1)
  store(SAVE..'ANCHOR_X',clamp(round(T.legacy.x_real or 20),0,math.max(0,sw-200)))
  local top=(T.legacy.y_real or sh-100)+(T.legacy.h_real or 0)
  store(SAVE..'ANCHOR_Y',-clamp(round(sh-top),0,math.max(0,sh-34)))
  store(SAVE..'INIT',1)
 end
 T.anchorX,T.anchorY=db(SAVE..'ANCHOR_X'),db(SAVE..'ANCHOR_Y')
 for _,v in ipairs(T.cards) do
  local p=SAVE..'FREE:'..v.slot..':'
  v.freeSet=db(p..'SET')==1;v.freeX=db(p..'X');v.freeY=db(p..'Y')
 end
 -- Keep the native show_hide entry working, but never display its old rectangle.
 T.legacy.on_active='lua';T.legacy.on_active_params='RyzomTeamUI:toggleFromLegacy()'
 T.legacy.on_deactive='';T.legacy.on_deactive_params=''
 T.legacy.active=false
 store(ACTIVE_DB,T:isEnabled() and 1 or 0)
 T.character=name
end
function T:installSettings()
 local s=PadUISettings
 if not s then return end
 -- Extensions call the original settings implementation. Reinstall safely after
 -- Lua reload; closures deliberately resolve the current global team controller.
 if s.refresh ~= s._modularTeamRefresh then
  local original=s.refresh
  s._modularTeamRefresh=function(self,...)
   original(self,...)
   if RyzomTeamUI then RyzomTeamUI:refreshSettings() end
  end
  s.refresh=s._modularTeamRefresh
 end
 if s.toggleWindow ~= s._modularTeamToggle then
  local original=s.toggleWindow
  s._modularTeamToggle=function(self,index)
   local spec=self.windows[tonumber(index) or 0]
   if spec and spec[1]=='team_compact' and RyzomTeamUI then
    RyzomTeamUI:toggle();self:refresh()
   else original(self,index) end
  end
  s.toggleWindow=s._modularTeamToggle
 end
 if not T.panel then
  local page=ui(PAGE);if not page then return end
  local p=ui(PAGE..':modular_team')
  if not p then
   p=createGroupInstance('padui_modular_team_settings',page.id,{})
   if not p then error('Cannot create modular team settings') end
   page:addGroup(p)
  end
  T.panel=p
  for _,id in ipairs({'team_layout_text','team_layout0','team_layout0_back','team_layout0_text','team_layout1','team_layout1_back','team_layout1_text'}) do changed(ui(PAGE..':'..id),'active',false) end
  -- Make room without changing either existing scale slider or item-bar logic.
  local ys={item_layout_text=-180,timer_scale_text=-241,timer_scale_slider=-263,timer_scale_value=-266,layout_note=-296}
  for i=0,2 do ys['item_layout'..i]=-202;ys['item_layout'..i..'_back']=-202;ys['item_layout'..i..'_text']=-207 end
  for id,y in pairs(ys) do changed(ui(PAGE..':'..id),'y',y) end
  page:invalidateCoords()
 end
end
function T:refreshSettings()
 if not T.uiReady or not T.panel then return end
 local w=labels();local mode=T:mode()
 local function label(id,value) changed(ui(PAGE..':modular_team:'..id),'hardtext',value) end
 label('title',w.title)
 for i=0,2 do
  label('mode'..i..':text',(mode==i and '[x] ' or '')..w.modes[i+1])
 end
 label('count_label',mode==2 and w.free or (mode==0 and w.columns or w.rows))
 label('count',tostring(T:trackCount(mode)))
 label('less:text','-');label('more:text','+')
 for _,id in ipairs({'less','more','count'}) do changed(ui(PAGE..':modular_team:'..id),'active',mode~=2) end
 label('lock:text',db(SAVE..'LOCKED')==1 and w.locked or w.unlocked)
 label('reset:text',w.reset)
 changed(ui(PAGE..':layout_note'),'hardtext',T.overflow and w.overflow or w.note)
 -- The legacy container is an inactive switch, not the visibility authority.
 local st=PadUISettings:texts()
 changed(ui('ui:interface:padui_settings:content:page1:window1_text'),'hardtext',(T:isEnabled() and '[x] ' or '[ ] ')..st.team)
end
function T:requestUpdate()
 T.lastTick=nil;T:update(true)
 if PadUISettings then PadUISettings:refresh() end
end
function T:toggle()
 if not ready() or not T.character then return end
 T:savePositions();T.dragging=nil
 store(SAVE..'ENABLED',T:isEnabled() and 0 or 1)
 T.legacy.active=false
 store(ACTIVE_DB,T:isEnabled() and 1 or 0)
 T:requestUpdate()
end
function T:toggleFromLegacy()
 if T.initializing then return end
 T:toggle()
end
function T:setLayout(mode)
 if not ready() or not T.character or (mode~=0 and mode~=1 and mode~=2) then return end
 T:savePositions();T.dragging=nil
 store(MODE_DB,mode);T:requestUpdate()
end
function T:changeTracks(delta)
 local mode=T:mode()
 if not ready() or not T.character or mode==2 or (delta~=-1 and delta~=1) then return end
 store(SAVE..(mode==0 and 'COLUMNS' or 'ROWS'),clamp(T:trackCount(mode)+delta,1,9))
 T:requestUpdate()
end
function T:toggleLock()
 if not ready() or not T.character then return end
 T:savePositions();T.dragging=nil
 store(SAVE..'LOCKED',db(SAVE..'LOCKED')==1 and 0 or 1);T:requestUpdate()
end
function T:toggleSelf()
 if not ready() then return end
 store('UI:SAVE:PADUI:HIDE_SELF',T:showSelf() and 1 or 0);T:requestUpdate()
end
function T:setSort(mode)
 if not ready() or SORT_MODES[mode]==nil then return end
 store(SORT_DB,SORT_MODES[mode]);T:requestUpdate()
end
function T:openSortMenu() end -- compatibility only; no on-window sort bar

-- CViewTextID.textid is UInt32: the a8fb199cf6 Lua getter hits nlstop,
-- even inside pcall. Its setter IS supported. These private text_id views have
-- a numeric XML id (no DB binding), so assigning them cannot write SERVER data.
-- Own request state replaces the unsafe getter; clear stale text on a change
-- and let native checkCoords resolve it asynchronously. Never use changed()
-- for textid because that helper reads a property before writing it.
function T:memberName(index,nameId,uid)
 local source=T.sources[index]
 local request=T.nameRequests[index]
 if not request or request.nameId~=nameId or request.uid~=uid then
  source.textid=0
  source.hardtext=''
  if nameId~=0 then source.textid=nameId<0 and nameId+4294967296 or nameId end
  T.nameRequests[index]={nameId=nameId,uid=uid}
 end
 if nameId==0 then return '' end
 local name=clean(source.hardtext)
 if name~='' then return name end
 -- A member moved to another server group slot: keep its window/name while
 -- this slot's resolver catches up, but only for the same UID AND name ID.
 local previous=T.members['uid:'..uid]
 return previous and previous.nameId==nameId and previous.name or ''
end

function T:collect(ownName)
 local out, live, roster, sort = {}, {}, {}, {}
 local ownLower=ownName:lower()
 local byHP=T:mode()~=2 and T:sortMode()~=0
 local function member(key,fields)
  local m=T.members[key] or {key=key}
  for k,v in pairs(fields) do m[k]=v end
  m.normal=clean(m.name):lower()
  out[#out+1]=m;live[key]=m;roster[#roster+1]=key
  sort[#sort+1]=key..':'..m.normal..':'..(m.present and '1' or '0')..':'..(byHP and tostring(m.hp) or '')
 end
 if T:showSelf() then
  local h=db('UI:VARIABLES:USER:HP_RATIO')
  member('self',{name=ownName,self=true,present=true,hpRaw=h,hp=percent(h,1024),sap=percent(db('UI:VARIABLES:USER:SAP_RATIO'),1024),sta=percent(db('UI:VARIABLES:USER:STA_RATIO'),1024)})
 end
 for index=0,7 do
  local p='SERVER:GROUP:'..index..':'
  local nameId=db(p..'NAME')
  local uid=db(p..'UID')
  local name=T:memberName(index,nameId,uid)
  local old=T.oldSources[index]
  if old then changed(old,'hardtext',name) end -- target-of-target compatibility
  if name~='' and name:sub(1,1)~='#' and name:lower()~=ownLower then
   local key='uid:'..uid
   if not live[key] then
    local bars='UI:VARIABLES:BARS:TEAM:'..index..':'
    local h=db(bars..'HP')
    member(key,{name=name,self=false,index=index,uid=uid,nameId=nameId,present=db(p..'PRESENT')~=0,hpRaw=h,hp=percent(h,127),sap=percent(db(bars..'SAP'),127),sta=percent(db(bars..'STA'),127)})
   end
  end
 end
 T.members=live
 return out,table.concat(roster,'|'),table.concat(sort,'|')
end
local function less(a,b)
 if a.present~=b.present then return a.present end
 local mode=T:mode()==2 and 0 or T:sortMode()
 if mode~=0 and a.present and a.hp~=b.hp then return mode==1 and a.hp>b.hp or mode==2 and a.hp<b.hp end
 if a.normal~=b.normal then return a.normal<b.normal end
 return a.key<b.key
end
function T:bind(members,rosterKey)
 if rosterKey~=T.rosterKey then
  local occupied={}
  for _,v in ipairs(T.cards) do
   v.member=T.members[v.key]
   if v.member then occupied[v.key]=true else v.key=nil end
  end
  for _,m in ipairs(members) do
   if not occupied[m.key] then
    for _,v in ipairs(T.cards) do
     if not v.key then v.key=m.key;v.member=m;v.cache={};occupied[m.key]=true;break end
    end
   end
  end
  T.rosterKey=rosterKey;T.layoutKey=nil
 end
 for i,v in ipairs(T.cards) do
  v.member=T.members[v.key];T.rows[i]=v.member
  if v.member then v.member.viewSlot=i end
 end
end
function T:geometry(scale,delta)
 local key=scale..':'..delta
 if T.geometryKey==key then return end
 T.geometryKey=key;T.layoutKey=nil
 T.scale=scale/100
 local function px(x) return round(x*T.scale) end
 T.cellW,T.cellH,T.gap=px(200),px(34),px(2)
 T.hpW=T.cellW-px(12);T.halfW=math.floor((T.hpW-px(4))/2)
 for _,v in ipairs(T.cards) do
  put(v,'window','w',T.cellW);put(v,'window','h',T.cellH)
  put(v,'header','w',T.cellW);put(v,'header','h',T.cellH)
  put(v,'background','w',T.cellW);put(v,'background','h',T.cellH)
  for _,id in ipairs({'grip','selected','self_marker'}) do put(v,id,'h',T.cellH) end
  put(v,'grip','w',px(4));put(v,'self_marker','w',px(3));put(v,'selected','x',px(4));put(v,'selected','w',px(3))
  for _,score in ipairs(SCORES) do
   local width=score=='hp' and T.hpW or T.halfW
   local x=score=='sta' and px(12)+T.halfW or px(8)
   for _,suffix in ipairs({'_back','_fill'}) do
    put(v,score..suffix,'x',x);put(v,score..suffix,'y',score=='hp' and -px(13) or -px(23));put(v,score..suffix,'h',px(10))
   end
   put(v,score..'_back','w',width)
  end
  for _,id in ipairs(TEXT_IDS) do
   local size=clamp(round(BASE_FONT[id]*T.scale)+delta,7,18)
   for s=7,18 do put(v,id..'_s'..s,'active',s==size) end
   v.nodes[id]=v.nodes[id..'_s'..size]
   -- Alias changed: invalidate the alias's property cache.
   for k in pairs(v.cache) do if k:sub(1,#id+1)==id..':' then v.cache[k]=nil end end
  end
  put(v,'name','x',px(8));put(v,'status','x',-px(4))
  v.nodes.name:setLineMaxW(T.cellW-px(80))
  v.nodes.status:setLineMaxW(px(70))
  put(v,'target_button','x',px(7));put(v,'target_button','w',T.cellW-px(7));put(v,'target_button','h',T.cellH)
 end
end
function T:savePositions()
 if not T.character or not ready() then return end
 store(SAVE..'ANCHOR_X',round(T.anchorX));store(SAVE..'ANCHOR_Y',round(T.anchorY))
 for _,v in ipairs(T.cards) do
  if v.freeSet then
   local p=SAVE..'FREE:'..v.slot..':'
   store(p..'X',round(v.freeX));store(p..'Y',round(v.freeY));store(p..'SET',1)
  end
 end
 T.pendingPositionSave=false
end
function T:resetPositions()
 if not ready() or not T.character then return end
 T.anchorX,T.anchorY=20,-100
 for _,v in ipairs(T.cards) do
  v.freeSet=false;v.x=nil;v.y=nil
  store(SAVE..'FREE:'..v.slot..':SET',0)
 end
 T.dragging=nil;T.layoutKey=nil;T.lastMode=nil;T:savePositions();T:requestUpdate()
end
function T:trackMovement(mode)
 local down=getMouseDown and getMouseDown() or false
 if db(SAVE..'LOCKED')==1 then down=false end
 if down or T.dragging then
  for _,v in ipairs(T.cards) do
   if v.member and v.window.active and v.x~=nil and (not T.dragging or T.dragging==v.slot) then
    local x,y=v.window.x,v.window.y
    if x~=v.x or y~=v.y then
     T.dragging=v.slot
     if mode==2 then v.freeX=x;v.freeY=y;v.freeSet=true
     else T.anchorX=T.anchorX+x-v.x;T.anchorY=T.anchorY+y-v.y end
     T.pendingPositionSave=true;T.layoutKey=nil
     break
    end
   end
  end
 end
 if not down and T.dragging then
  -- Include the final native mouse-up position; persist after layout clamping.
  T.dragging=nil;T.pendingPositionSave=true;T.layoutKey=nil;T.sortKey=nil
 end
end
function T:arrange(mode,sw,sh)
 local order={}
 for _,m in ipairs(T.ordered) do order[#order+1]=m.key end
 local prefix=mode..':'..T:trackCount(mode)..':'..sw..':'..sh..':'..T.geometryKey..':'
 local suffix=':'..table.concat(order,',')
 local sig=prefix..T.anchorX..':'..T.anchorY..suffix
 if T.layoutKey==sig then return end
 T.stats.layouts=T.stats.layouts+1
 local positions,cols,rows=T:grid(#T.ordered,mode==0 and 0 or 1,T:trackCount(mode))
 local stepX,stepY=T.cellW+T.gap,T.cellH+T.gap
 T.overflow=mode~=2 and (cols*stepX-T.gap>sw or rows*stepY-T.gap>sh)
 if mode~=2 then
  T.anchorX=clamp(T.anchorX,0,math.max(0,sw-(cols*stepX-T.gap)))
  T.anchorY=-clamp(-T.anchorY,0,math.max(0,sh-(rows*stepY-T.gap)))
 end
 for rank,m in ipairs(T.ordered) do
  local v=T.cards[m.viewSlot];local x,y
  if mode==2 then
   if not v.freeSet then
    -- First free placement starts from the previous automatic position.
    v.freeX=v.x or (T.anchorX+((v.slot-1)%3)*stepX)
    v.freeY=v.y or (T.anchorY-math.floor((v.slot-1)/3)*stepY)
    v.freeSet=true;T.pendingPositionSave=true
   end
   x=clamp(v.freeX,0,math.max(0,sw-T.cellW))
   y=-clamp(-v.freeY,0,math.max(0,sh-T.cellH))
  else x=T.anchorX+positions[rank].x*stepX;y=T.anchorY-positions[rank].y*stepY end
  changed(v.window,'x',round(x));changed(v.window,'y',round(y))
  v.x,v.y=v.window.x,v.window.y
 end
 T.layoutKey=prefix..T.anchorX..':'..T.anchorY..suffix
 T.lastMode=mode
 if T.pendingPositionSave and not T.dragging then T:savePositions() end
end
function T:render(ownName)
 local targetUid=db('UI:VARIABLES:TARGET:UID')
 local targetName=clean(getTargetName()):lower()
 local leader=db('SERVER:GROUP:LEADER_INDEX')
 local locked=db(SAVE..'LOCKED')==1
 local colors={}
 local function color(c)
  if not colors[c] then colors[c]=PadUISettings and PadUISettings:withTransparency(c) or c end
  return colors[c]
 end
 local accent,gripColor=PadUI:accent(),PadUI:accent(160)
 local tr={}
 for _,key in ipairs({'self','absent','ko','target','leader','sap','stamina'}) do tr[key]=PadUI:tr(key) end
 for _,v in ipairs(T.cards) do
  local m=v.member
  changed(v.window,'active',m~=nil)
  if m then
   put(v,'window','locked',locked)
   put(v,'grip','active',not locked);put(v,'grip','color',gripColor)
   local selected=(m.self and targetName==ownName:lower()) or (not m.self and m.uid==targetUid)
   put(v,'selected','active',selected);put(v,'self_marker','active',m.self)
   put(v,'self_marker','color',accent)
   put(v,'name','hardtext',m.name)
   put(v,'name','color',m.self and accent or (selected and '255 215 110 255' or '245 235 210 255'))
   local status=m.self and tr['self'] or ''
   if not m.present then status=tr['absent']
   elseif m.hpRaw<0 then status=tr['ko']
   elseif selected then status=m.self and (tr['self']..' / '..tr['target']) or tr['target']
   elseif not m.self and m.index==leader then status=tr['leader'] end
   put(v,'status','hardtext',status)
   put(v,'status','color',m.self and accent or (m.present and '220 220 205 255' or '180 180 170 255'))
   put(v,'background','color',color(m.self and '16 43 55 255' or (m.present and '12 18 24 255' or '18 18 18 255')))
   put(v,'target_button','tooltip',m.name)
   for _,score in ipairs(SCORES) do
    local value=m.present and m[score] or 0
    local width=score=='hp' and T.hpW or T.halfW
    local prefix=score=='hp' and '' or tr[score=='sap' and 'sap' or 'stamina']
    local fill=score=='hp' and (m.hp<15 and '180 25 25 255' or (m.hp<30 and '150 65 12 255' or '150 38 16 255')) or (score=='sap' and '55 95 25 255' or '100 45 105 255')
    put(v,score..'_back','color',color('35 42 48 255'))
    put(v,score..'_fill','color',color(fill))
    put(v,score..'_fill','w',round(width*value/100))
    put(v,score..'_text','hardtext',prefix..(m.present and (value..'%') or '--'))
   end
  end
 end
end
function T:step(force)
 local ownName=clean(getPlayerName());if ownName=='' then return end
 if not T:initUI() then return end
 if T.character~=ownName then T:initCharacter(ownName) end
 T:installSettings()
 if not T:isEnabled() then T:hideCards();return end
 local mode=T:mode()
 if T.lastMode==mode then T:trackMovement(mode) end
 local tick=db('UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK')
 local sw,sh=getWindowSize();sw=tonumber(sw) or 1280;sh=tonumber(sh) or 720
 if force or T.lastTick~=tick then
  T.lastTick=tick;T.stats.polls=T.stats.polls+1
  local members,rosterKey,sortKey=T:collect(ownName)
  sortKey=mode..':'..T:sortMode()..':'..sortKey
  if sortKey~=T.sortKey and (not T.dragging or rosterKey~=T.rosterKey) then
   table.sort(members,less);T.ordered=members;T.sortKey=sortKey;T.stats.sorts=T.stats.sorts+1
  end
  T:bind(T.ordered,rosterKey)
  local scale=db('UI:SAVE:PADUI:TEAM_SCALE')
  if scale<75 or scale>150 then scale=100 end
  scale=clamp(round(scale/25)*25,75,150)
  T:geometry(scale,clamp(db('UI:SAVE:PADUI:FONT_DELTA'),-1,1))
  T:arrange(mode,sw,sh);T:render(ownName)
 elseif T.geometryKey then T:arrange(mode,sw,sh) end
end
function T:update(force)
 if T.busy or T.failed then return end
 if not ready() then
  if T.uiReady then
   pcall(T.hideCards,T)
   T.uiReady=false;T.panel=nil;T.cards={};T.sources=nil;T.oldSources=nil
   T.driver=nil;T.legacy=nil
  end
  T.character=nil;T.lastTick=nil
  return
 end
 T.busy=true;T.initializing=not T.character
 local ok,err=pcall(T.step,T,force)
 T.initializing=false;T.busy=false
 if not ok then
  T.failed=tostring(err);pcall(T.hideCards,T)
  debugInfo('PadUI modular team: '..T.failed)
  pcall(function()
   for i=1,9 do local w=ui(CARD..i);if w then w.active=false end end
   local old=ui(LEGACY);if old then old.active=false end
   local native=ui('ui:interface:team_list');if native then native.active=true end
  end)
  pcall(displaySystemInfo,'PadUI Team: '..T.failed..' (native team window enabled)','SYS')
 end
end
function T:start()
 T.lastTick=nil;T:update(true)
end
function T:validMember(m)
 if not m or not ready() then return false end
 if m.self then return clean(m.name):lower()==clean(getPlayerName()):lower() end
 local p='SERVER:GROUP:'..m.index..':'
 return db(p..'UID')==m.uid and db(p..'NAME')==m.nameId and db(p..'PRESENT')~=0
end
function T:selectMember(m)
 if not T:validMember(m) then return false end
 if m.self then runAH(nil,'self_target','') else runAH(nil,'team_target',tostring(m.index)) end
 T.lastTick=nil
 return true
end
function T:target(slot) return T:selectMember(T.rows[tonumber(slot)]) end
function T:assistMember(m)
 if T:validMember(m) and not m.self then runAH(nil,'assist','entity='..m.name) end
end
function T:click(slot,side)
 local m=T.rows[tonumber(slot)]
 if not T:validMember(m) then return end
 if side=='left' then T:selectMember(m)
 else
  -- Snapshot: later roster mutation must never retarget an open context menu.
  T.menuMember={name=m.name,self=m.self,index=m.index,uid=m.uid,nameId=m.nameId}
  runAH(getUICaller(),'active_menu','menu=ui:interface:team_compact_menu')
 end
end
function T:menuAction(action)
 local m=T.menuMember;T.menuMember=nil
 if not T:validMember(m) then return end
 if action=='assist' then T:assistMember(m)
 elseif action=='select' then T:selectMember(m)
 elseif action=='trade' and not m.self and T:selectMember(m) then runAH(nil,'context_exchange','') end
end
