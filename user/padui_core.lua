-- PadUI: shared translations and native UI integration. Lua 5.1 compatible.

-- Safe wrappers for getPlayerName and getPlayerPos to prevent SIGSEGV
-- on Linux/POSIX when invoked before the character entity is spawned.
if not _G.__padui_safe_player_wrapped then
	_G.__padui_safe_player_wrapped = true
	local _orig_getPlayerName = getPlayerName
	local _orig_getPlayerPos = getPlayerPos

	function isPlayerReady()
		return game ~= nil and game.InGameDbInitialized == true
	end

	function getPlayerName()
		if not (game and game.InGameDbInitialized) then
			return ""
		end
		if _orig_getPlayerName then
			local name = _orig_getPlayerName()
			if name and name ~= "" then
				return name
			end
		end
		return ""
	end

	function getPlayerPos()
		if game and game.InGameDbInitialized and _orig_getPlayerPos then
			return _orig_getPlayerPos()
		end
		return 0, 0, 0
	end
end

PadUI = PadUI or {}
local P = PadUI
 P.version = "0.8.10"
P.texts = {
 de = {
  item_assigned="Belegt",
  skill_tree="Skillbaum auswählen", skill_fight="Kampf", skill_magic="Magie", skill_craft="Handwerk", skill_harvest="Ernte", skill_back="Zurück zu den vier Skillbäumen",
  skill_choose="Skill auswählen", skill_level="Level", skill_progress="zum nächsten Level", skill_tip="Linksklick: Skill wählen / Rechtsklick: Auswahl entfernen", skill_max="Maximum dieses Zweigs erreicht", skill_empty="Noch keine erlernten Skills verfügbar", skill_previous="Vorherige Seite", skill_next="Nächste Seite", skill_clear="Auswahl entfernen",
  hide_self="Eigenen Charakter ausblenden", show_self="Eigenen Charakter anzeigen", humidity="Feucht.", humidity_tip="Aktuelle Feuchtigkeit wie in der Wetteranzeige auf der Karte.",
  team="PadUI Team", inventory="PadUI Tasche", items="PadUI Itemleiste",
  waiting="Warte auf Spieldaten", self="Du", absent="Abwesend", ko="KO", target="Ziel", leader="Leitung",
  sort_name="Sort.: Name", sort_hp="Sort.: HP", sort_missing="Sort.: fehlt",
  name_order="Name: A–Z", hp_order="HP: meiste zuerst (%)", missing_order="Fehlende HP: meiste zuerst (%)",
  sort_tip="Sortierung nach Name, HP oder fehlendem HP-Anteil", sap="S ", stamina="A ",
  dodge="Ausw.", parry="Parade", base="Basis", modifier="Erfolgsmod.", active="aktiv", activate="Klick zum Aktivieren",
  volume_tip="Volumen / maximales Volumen. Klick öffnet das Inventar.",
  item_tip="Linksklick: benutzen / anlegen / Details. Rechtsklick: Optionen. Item hierher ziehen: belegen.",
  empty_tip="Item aus der Tasche hierher ziehen oder klicken, um eines auszuwählen.",
  missing_tip="Dieses Item ist nicht in der Tasche. Die Verknüpfung bleibt gespeichert.",
  choose="Item auswählen", clear="Verknüpfung entfernen", details="Details", use="Benutzen / Anlegen", close="Schließen",
  language_tip="PadUI-Sprache wechseln: Auto, Deutsch, English, Français", auto="Auto",
  not_found="Item nicht in der Tasche gefunden.", locked="Dieses Item ist gesperrt.", crafting="Handitems können während des Craftens nicht gewechselt werden."
 },
 en = {
  item_assigned="Assigned",
  skill_tree="Choose skill tree", skill_fight="Fight", skill_magic="Magic", skill_craft="Craft", skill_harvest="Harvest", skill_back="Back to the four skill trees",
  skill_choose="Choose skill", skill_level="Level", skill_progress="towards next level", skill_tip="Left click: choose skill / Right click: clear selection", skill_max="Maximum of this branch reached", skill_empty="No learned skills available yet", skill_previous="Previous page", skill_next="Next page", skill_clear="Clear selection",
  hide_self="Hide own character", show_self="Show own character", humidity="Humidity", humidity_tip="Current humidity, as shown by the map weather display.",
  team="PadUI Team", inventory="PadUI Bag", items="PadUI Item bar",
  waiting="Waiting for game data", self="You", absent="Away", ko="KO", target="Target", leader="Leader",
  sort_name="Sort: Name", sort_hp="Sort: HP", sort_missing="Sort: missing",
  name_order="Name: A–Z", hp_order="HP: highest first (%)", missing_order="Missing HP: highest first (%)",
  sort_tip="Sort by name, HP or missing HP percentage", sap="S ", stamina="St ",
  dodge="Dodge", parry="Parry", base="Base", modifier="Success mod.", active="active", activate="Click to activate",
  volume_tip="Bulk / maximum bulk. Click to open the inventory.",
  item_tip="Left click: use / equip / details. Right click: options. Drop a bag item here to assign it.",
  empty_tip="Drop an item from your bag here, or click to choose one.",
  missing_tip="This item is not in your bag. Its shortcut stays saved.",
  choose="Choose item", clear="Remove shortcut", details="Details", use="Use / Equip", close="Close",
  language_tip="Change PadUI language: Auto, Deutsch, English, Français", auto="Auto",
  not_found="Item not found in your bag.", locked="This item is locked.", crafting="Hand items cannot be changed while crafting."
 },
 fr = {
  item_assigned="Affecté",
  skill_tree="Choisir un arbre", skill_fight="Combat", skill_magic="Magie", skill_craft="Artisanat", skill_harvest="Récolte", skill_back="Retour aux quatre arbres",
  skill_choose="Choisir une compétence", skill_level="Niveau", skill_progress="vers le niveau suivant", skill_tip="Clic gauche : choisir / Clic droit : retirer", skill_max="Maximum de cette branche atteint", skill_empty="Aucune compétence apprise disponible", skill_previous="Page précédente", skill_next="Page suivante", skill_clear="Retirer la sélection",
  hide_self="Masquer son personnage", show_self="Afficher son personnage", humidity="Humidité", humidity_tip="Humidité actuelle, comme dans la météo de la carte.",
  team="PadUI Équipe", inventory="PadUI Sac", items="PadUI Barre d’objets",
  waiting="En attente des données", self="Vous", absent="Absent", ko="KO", target="Cible", leader="Chef",
  sort_name="Tri : nom", sort_hp="Tri : PV", sort_missing="Tri : manque",
  name_order="Nom : A–Z", hp_order="PV : plus élevés d’abord (%)", missing_order="PV manquants : plus élevés d’abord (%)",
  sort_tip="Trier par nom, PV ou pourcentage de PV manquants", sap="S ", stamina="E ",
  dodge="Esquive", parry="Parade", base="Base", modifier="Mod. réussite", active="actif", activate="Cliquer pour activer",
  volume_tip="Encombrement / encombrement maximal. Cliquer pour ouvrir l’inventaire.",
  item_tip="Clic gauche : utiliser / équiper / détails. Clic droit : options. Glisser un objet du sac ici pour l’affecter.",
  empty_tip="Glisser un objet du sac ici ou cliquer pour en choisir un.",
  missing_tip="Cet objet n’est pas dans votre sac. Son raccourci reste enregistré.",
  choose="Choisir un objet", clear="Retirer le raccourci", details="Détails", use="Utiliser / Équiper", close="Fermer",
  language_tip="Changer la langue de PadUI : Auto, Deutsch, English, Français", auto="Auto",
  not_found="Objet introuvable dans votre sac.", locked="Cet objet est verrouillé.", crafting="Les objets en main ne peuvent pas être changés pendant la fabrication."
 }
}

function P:accent(alpha)
 if PadUISettings then return PadUISettings:accent(alpha) end
 return "110 235 225 "..tostring(alpha or 255)
end
function P:language()
 local mode = tonumber(getDbProp("UI:SAVE:PADUI:LANGUAGE")) or 0
 if mode == 1 then return "de" elseif mode == 2 then return "en" elseif mode == 3 then return "fr" end
 local ok, lang = pcall(function() return getClientCfgVar("LanguageCode") end)
 lang = ok and tostring(lang):lower():sub(1,2) or "en"
 return P.texts[lang] and lang or "en"
end
function P:tr(key)
 return P.texts[P:language()][key] or P.texts.en[key] or key
end
function P:setText(path, text, property)
 local node = getUI(path)
 if node then node[property or "hardtext"] = text end
end
function P:buildMenu(path, entries)
 local menu = getUI(path)
 if not menu then return end
 local root = menu:getRootMenu()
 root:reset()
 for _, e in ipairs(entries) do
  local text = P:tr(e[1])
  local ok = pcall(function() root:addLine(text, "lua", e[2], e[1]) end)
  -- Older clients require ucstring for menu labels; newer clients use UTF-8 strings.
  if not ok then root:addLine(ucstring(text), "lua", e[2], e[1]) end
 end
end
function P:sortMenu()
 P:buildMenu("ui:interface:team_compact_sort_menu", {
  {"name_order", "RyzomTeamUI:setSort('name')"},
  {"hp_order", "RyzomTeamUI:setSort('hp')"},
  {"missing_order", "RyzomTeamUI:setSort('missing')"},
  {RyzomTeamUI:showSelf() and "hide_self" or "show_self", "RyzomTeamUI:toggleSelf()"}
 })
end
function P:localize(force)
 local lang = P:language()
 if not force and P.lastLanguage == lang then return end
 P.lastLanguage = lang
 P:setText("ui:interface:team_compact:content:waiting", P:tr("waiting"))
 P:setText("ui:interface:team_compact:content:sort_controls:sort_button", P:tr("sort_tip"), "tooltip")
 P:setText("ui:interface:inventory_compact:content:open_inventory", P:tr("volume_tip"), "tooltip")
 P:setText("ui:interface:gestion_windows:inventory:inventory_compact:text", P:tr("inventory"))
 P:setText("ui:interface:gestion_windows:inventory:padui_items:text", P:tr("items"))
 P:setText("ui:interface:gestion_windows:memory:team_compact:text", P:tr("team"))
 P:setText("ui:interface:padui_item_choose:choose_title", P:tr("choose"))
 P:setText("ui:interface:padui_item_choose:close", P:tr("close"), "tooltip")
end
function P:cycleLanguage()
 local value = tonumber(getDbProp("UI:SAVE:PADUI:LANGUAGE")) or 0
 setDbProp("UI:SAVE:PADUI:LANGUAGE", (value + 1) % 4)
 P:localize(true)
 if PadUISettings then PadUISettings:refresh() end
 if RyzomTeamUI then RyzomTeamUI.lastTick=nil; RyzomTeamUI:update() end
 if RyzomInventoryCompact then RyzomInventoryCompact.lastRefresh=nil; RyzomInventoryCompact:update() end
 if PadUIQuickbar then PadUIQuickbar.lastRefresh=nil; PadUIQuickbar:update() end
end
function P:start()
 P.Team, P.Inventory, P.Target, P.ActionTimer = RyzomTeamUI, RyzomInventoryCompact, RyzomTargetDistance, RyzomActionTimer
 P.Skill = PadUISkill
 P.Items = PadUIQuickbar
 P.Auras = PadUIAuras
 P.Settings = PadUISettings
 P.Timers = PadUITimers
 P.Mobs = PadUIMobs
 P.TeamRoles = PadUITeamRoles
 -- One failed window initializer must not prevent the others from starting.
 for _,name in ipairs({"Skill","Items","Auras","Settings","Timers","Mobs","TeamRoles"}) do
  local module=P[name]
  if module then
   local ok,err=pcall(function() module:start() end)
   if not ok then debugInfo("PadUI initialization: "..tostring(err)) end
  end
 end
 P:localize(true)
end

-- Team roles, stage 2 test: local symbols plus explicit team-chat proclamation.
-- No extra channel, background sender or saved roles; the tested team mover is not replaced.
PadUITeamRoles = {}
do
 local R = PadUITeamRoles
 local MENU = 'ui:interface:team_compact_menu'
 local TEMPLATE = 'padui_local_role_icon_v1'
 local ORDER = {'tank','heal','melee','ele','affliction','none'}
 local words = {
  de={menu='Rolle zuweisen (lokal)',tank='Tank',heal='Heal',melee='Melee',ele='Ele',affliction='Affliction',none='Keine Rolle',announce='Rollen im Teamchat bekanntgeben',
   tips={tank='Tank',heal='Heiler',melee='Nahkampf',ele='Elementarmagie',affliction='Affliction',none='Keine Rolle'}},
  en={menu='Assign role (local)',tank='Tank',heal='Heal',melee='Melee',ele='Ele',affliction='Affliction',none='No role',announce='Announce roles in team chat',
   tips={tank='Tank',heal='Healer',melee='Melee',ele='Elemental magic',affliction='Affliction',none='No role'}},
  fr={menu='Attribuer un r\195\180le (local)',tank='Tank',heal='Heal',melee='Melee',ele='Ele',affliction='Affliction',none='Aucun r\195\180le',announce='Annoncer les r\195\180les dans le chat d\226\128\153\195\169quipe',
   tips={tank='Tank',heal='Soins',melee='Corps \195\160 corps',ele='Magie \195\169l\195\169mentaire',affliction='Affliction',none='Aucun r\195\180le'}}
 }
 -- Original pixel-art masks. o = dark contour, x = role colour, h = light.
 -- The 9px masters retain eyes, sword guards and arrow points at 75% scale.
 -- Each mask is compiled to merged bitmap rectangles using only blank.tga.
 local art = {
  tank={color='80 162 237 255',light='191 226 255 255',
   large={'.oooooooooo.','ohhhhhhhhhho','ohxxxxxxxxho','ohxxxxxxxxho','ohxxxxxxxxho','ohxxxxxxxxho','.ohxxxxxxho.','.ohxxxxxxho.','..ohxxxxho..','...ohxxho...','....ohho....','.....oo.....'},
   small={'ooooooooo','ohhhhhhho','ohxxxxxho','ohxxxxxho','.hxxxxxh.','.ohxxxho.','..ohxho..','...oho...','....o....'}},
  heal={color='65 218 118 255',light='192 255 217 255',
   large={'....oooo....','...ohhhho...','...oxxxxo...','...oxxxxo...','oooxxxxxxooo','ohhxxxxxxhho','oxxxxxxxxxxo','oooxxxxxxooo','...oxxxxo...','...oxxxxo...','...ohhhho...','....oooo....'},
   small={'...ooo...','...oxo...','...oxo...','oooxxxooo','oxxxxxxxo','oooxxxooo','...oxo...','...oxo...','...ooo...'}},
  melee={color='235 91 91 255',light='255 210 198 255',
   large={'ho........oh','hho......ohh','.hho....ohh.','..hho..ohh..','...hhoohh...','....hhhh....','...oxhhxo...','..oxxooxxo..','.oxxo..oxxo.','..ox....xo..','.oxo....oxo.','oxo......oxo'},
   small={'ho.....oh','hho...ohh','.hho.ohh.','..hhhhh..','...hhh...','..oxxxo..','.xxo.oxx.','..x...x..','.xo...ox.'}},
  ele={color='255 151 32 255',light='255 239 174 255',
   large={'.....x......','..x..hx..x..','...xohxox...','...ohhhxo...','.xohhhhhhxx.','xxhhhoohhhxx','..xhhxxhhx..','..xohhhho...','..xohhxhox..','.x..xhx..x..','....ox......','.....x......'},
   small={'....x....','.x..h..x.','..xxhxx..','..xhhhx..','xhhhxhhhx','..xhhhx..','..xxhxx..','.x..h..x.','....x....'}},
  affliction={color='187 113 236 255',light='239 209 255 255',
   large={'...oooooo...','..ohhhhhho..','.ohxxxxxxho.','ohxxxxxxxxho','ohxooxxooxho','oxxooxxooxxo','oxxxxxxxxxxo','.oxxxooxxxo.','..oxxxxxxo..','...oxxxxo...','...ohxhxo...','....oooo....'},
   small={'..ooooo..','.ohhhhho.','ohxxxxxho','oxooxooxo','oxooxooxo','.xxxxxxx.','..xxoxx..','..hxhhx..','...ooo...'}},
  check={color='125 238 154 255',light='125 238 154 255',
   small={'.......xx','......xx.','.....xx..','x...xx...','xx.xx....','.xxx.....','..x......','.........','.........'}}
 }
 local function round(n) return math.floor(n+0.5) end
 local function ready() return game and game.InGameDbInitialized == true end
 local function db(p) return tonumber(getDbProp(p)) or 0 end
 local function labels() return words[PadUI:language()] or words.en end
 local function set(n,k,value) if n and n[k]~=value then n[k]=value end end
 local function normalizeName(value)
  local s=tostring(value or ''):gsub('@%b{}','')
  s=s:gsub('%s*%(.*$',''):match('^%s*(.-)%s*$') or ''
  return s:lower()
 end
 local function stripChat(value)
  local s=tostring(value or ''):gsub('@%b{}',''):gsub('{break}','')
  s=s:gsub('^%s*%[%d%d?:%d%d?:%d%d[^%]]*%]%s*','')
  return s
 end
 local function key(m)
  if not m then return nil end
  return m.self and 'self' or ('uid:'..m.uid..':'..m.nameId)
 end
 R.order,R.art=ORDER,art
 R.roles,R.icons,R.epoch={}, {}, 0
 R.chatList,R.chatSeen,R.chatTail=nil,nil,nil
 R.stats={builds=0,paints=0,chatRead=0,chatApplied=0,chatSent=0}
 R.compiled={}
 function R:rectangles(role,size)
  if role=='none' then return {} end
  local id=role..':'..size
  if self.compiled[id] then return self.compiled[id] end
  local spec=assert(art[role],'Unknown role artwork')
  local mask=(size==9 or not spec.large) and spec.small or spec.large
  local n=#mask;local out,previous={},{}
  for y=0,size-1 do
   local source=mask[math.min(n,math.floor((y+0.5)*n/size)+1)]
   assert(#source==n,'Role mask must be square: '..role)
   local row={}
   for x=0,size-1 do row[x]=source:sub(math.min(n,math.floor((x+0.5)*n/size)+1),math.min(n,math.floor((x+0.5)*n/size)+1)) end
   local x,nextRow=0,{}
   while x<size do
    local c,start=row[x],x;x=x+1
    while x<size and row[x]==c do x=x+1 end
    if c~='.' then
     assert(c=='o' or c=='x' or c=='h','Unknown role pixel')
     local code=start..':'..(x-start)..':'..c
     local r=previous[code]
     if r then r.h=r.h+1 else
      r={x=start,y=-y,w=x-start,h=1,color=c=='o' and '4 9 15 255' or (c=='h' and spec.light or spec.color)}
      out[#out+1]=r
     end
     nextRow[code]=r
    end
   end
   previous=nextRow
  end
  self.compiled[id]=out
  return out
 end
 local parts=0
 for role in pairs(art) do for _,size in ipairs({9,12,15,18}) do parts=math.max(parts,#R:rectangles(role,size)) end end
 R.parts=parts
 function R:interfaceXML()
  local out={'<interface_config><template name="'..TEMPLATE..'" keep="true"><group id="#id" posref="TL TL" w="12" h="12" use_cursor="false" child_resize_w="false" child_resize_h="false">'}
  for i=1,parts do
   out[#out+1]='<view type="bitmap" id="p'..i..'" posref="TL TL" w="1" h="1" active="false" texture="blank.tga" scale="true" color="255 255 255 255" global_color="false" />'
  end
  out[#out+1]='</group></template></interface_config>'
  return table.concat(out)
 end
 function R:ensureTemplate()
  local root=getUI('ui:interface',false)
  if not root then error('Root interface is unavailable') end
  if self.templateRoot==root then return end
  if parseInterfaceFromString(self:interfaceXML())==false then error('Cannot register role-icon template') end
  self.templateRoot=root
 end
 function R:icon(parent,id,existing)
  self:ensureTemplate()
  local group=existing
  if not group then
   group=createGroupInstance(TEMPLATE,parent,{id=id})
   if not group then error('Cannot create role icon '..id) end
   self.stats.builds=self.stats.builds+1
  end
  local result={group=group,nodes={}}
  for i=1,parts do
   result.nodes[i]=group:find('p'..i)
   if not result.nodes[i] then error('Role icon structure changed; fully restart Ryzom') end
  end
  return result
 end
 function R:paint(icon,role,size)
  local id=role..':'..size
  if icon.paintKey==id then return end
  local rects=self:rectangles(role,size)
  set(icon.group,'w',size);set(icon.group,'h',size)
  for i,n in ipairs(icon.nodes) do
   local r=rects[i];set(n,'active',r~=nil)
   if r then
    for _,p in ipairs({'x','y','w','h','color'}) do set(n,p,r[p]) end
   end
  end
  icon.paintKey=id;self.stats.paints=self.stats.paints+1
 end
 function R:reset()
  self.roles={};self.menuMember=nil;self.epoch=self.epoch+1
  self.chatList=nil;self.chatSeen=nil;self.chatTail=nil
  for _,icon in pairs(self.icons) do icon.layoutKey=nil end
 end
 -- This observes the existing shared team update; no additional frame hook.
 -- It still sees leave/join while the team window or self card is hidden.
 function R:observeSession()
  local t=RyzomTeamUI
  if not ready() then
   if self.wasReady then self:reset() end
   self.wasReady=false;self.character=nil;self.inTeam=nil
   self.templateRoot=nil;self.icons={};return
  end
  local inTeam=db('SERVER:USER:TEAM_MEMBER')==1
  local character=t and t.character
  if not self.wasReady or character~=self.character or inTeam~=self.inTeam then self:reset() end
  self.wasReady=true;self.character=character;self.inTeam=inTeam
 end
 function R:prune()
  local live={self=true}
  if self.inTeam then
   for i=0,7 do
    local p='SERVER:GROUP:'..i..':'
    local nameId=db(p..'NAME')
    if nameId~=0 then live['uid:'..db(p..'UID')..':'..nameId]=true end
   end
  end
  for k in pairs(self.roles) do if not live[k] then self.roles[k]=nil end end
 end
 function R:render(t)
  if not ready() then return end
  self:observeSession();self:prune()
  if not t.uiReady or not t.geometryKey then return end
  local scale=t.scale
  local size=round(12*scale);local reserve=size+round(4*scale)
  local locked=db('UI:SAVE:PADUI:TEAM_MODULAR:LOCKED')==1
  local right=locked and round(4*scale) or math.max(8,round(8*scale))+8
  local width=math.max(1,t.cellW-right-round(82*scale)-reserve)
  local w=labels()
  for _,v in ipairs(t.cards) do
   if v.member then
    local header=v.nodes.header
    local icon=self.icons[v.slot]
    if not icon or icon.header~=header then
     local old=header:find('padui_role_icon')
     icon=self:icon(header.id,'padui_role_icon',old)
     if not old then header:addGroup(icon.group) end
     icon.header=header;self.icons[v.slot]=icon
    end
    local role=self.roles[key(v.member)] or 'none'
    self:paint(icon,role,size)
    set(icon.group,'x',round(8*scale));set(icon.group,'y',0)
    set(v.nodes.name,'x',round(8*scale)+reserve)
    local layout=t.geometryKey..':'..tostring(v.inputKey)..':'..v.nodes.name.id
    if icon.layoutKey~=layout then
     v.nodes.name:setLineMaxW(width);icon.layoutKey=layout
    end
    local tip=v.member.name..' - '..w.tips[role]
    for _,id in ipairs({'target_button','target_top','target_bottom','target_rim'}) do set(v.nodes[id],'tooltip',tip) end
   end
  end
 end
 local function addLine(menu,text,action,id)
  local ok,err=pcall(function() menu:addLine(text,'lua',action,id) end)
  if not ok then
   if not ucstring then error(err) end
   menu:addLine(ucstring(text),'lua',action,id)
  end
 end
 function R:prepareMenu(m)
  self.menuMember=nil
  if not ready() then return end
  self:observeSession();self:prune()
  if not m then return end
  local menu=getUI(MENU,false);if not menu then return end
  local root=menu:getRootMenu();local w=labels()
  local index=root:getLineFromId('padui_roles')
  if index<0 then
   root:addSeparator();addLine(root,w.menu,'','padui_roles')
   index=root:getLineFromId('padui_roles')
  end
  assert(index>=0 and index<root:getNumLine(),'Invalid roles menu index')
  local sub=root:getSubMenu(index)
  if not sub then sub=root:addSubMenu(index);sub.active=false end
  set(getUI(MENU..':padui_roles',false),'hardtext',w.menu)
  self.menuMember={key=key(m),epoch=self.epoch,character=self.character}
  local current=self.roles[key(m)] or 'none'
  for _,role in ipairs(ORDER) do
   local id='padui_role_'..role
   local line=sub:getLineFromId(id)
   if line<0 then
    if role=='none' then sub:addSeparator() end
    addLine(sub,w[role],"PadUITeamRoles:assign('"..role.."')",id)
    line=sub:getLineFromId(id)
   end
   assert(line>=0 and line<sub:getNumLine(),'Invalid role entry index')
   set(getUI(MENU..':'..id,false),'hardtext',w[role])
   -- Native user-group ownership supplies real graphics beside menu labels.
   local left=sub:getUserGroupLeft(line)
   local icon=self:icon(MENU,id..'_icon',left)
   if not left then sub:setUserGroupLeft(line,icon.group) end
   self:paint(icon,role,12)
   local rightGroup=sub:getUserGroupRight(line)
   local mark=self:icon(MENU,id..'_mark',rightGroup)
   if not rightGroup then sub:setUserGroupRight(line,mark.group) end
   self:paint(mark,current==role and 'check' or 'none',9)
  end
  local announceId='padui_role_announce'
  local announce=sub:getLineFromId(announceId)
  local mayAnnounce=self.inTeam and db('SERVER:GROUP:LEADER_INDEX')%16==15
  if mayAnnounce then
   if announce<0 then
    sub:addSeparator()
    addLine(sub,w.announce,'PadUITeamRoles:announce()',announceId)
    announce=sub:getLineFromId(announceId)
   end
   if announce>=0 then set(getUI(MENU..':'..announceId,false),'hardtext',w.announce) end
  elseif announce>=0 then
   sub:removeLine(announce)
  end
 end
 function R:assign(role)
  -- A menu callback carries only a whitelisted role, never executable data.
  local allowed=false
  for _,r in ipairs(ORDER) do if role==r then allowed=true end end
  if not allowed or self.failed or not ready() then return false end
  local snapshot=self.menuMember;self.menuMember=nil
  self:observeSession()
  local t=RyzomTeamUI
  if not snapshot or snapshot.epoch~=self.epoch or snapshot.character~=self.character
   or not t or not t.uiReady or t.failed then return false end
  for _,v in ipairs(t.cards) do
   if v.member and key(v.member)==snapshot.key and t:validMember(v.member) then
    self.roles[snapshot.key]=role~='none' and role or nil
    self:guard('render',t)
    return not self.failed
   end
  end
  return false
 end
 function R:currentLeaderName()
  if not ready() or not self.inTeam then return '' end
  if db('SERVER:GROUP:LEADER_INDEX')%16==15 then return tostring(getPlayerName() or '') end
  local leader=db('SERVER:GROUP:LEADER_INDEX')
  local t=RyzomTeamUI
  if t then
   for _,v in ipairs(t.cards or {}) do
    local m=v.member
    if m and not m.self and m.index==leader then return tostring(m.name or '') end
   end
  end
  return ''
 end
 function R:roleRoster()
  local t=RyzomTeamUI
  local out={{name=tostring(getPlayerName() or ''),role=self.roles.self or 'none'}}
  if t then
   for _,m in pairs(t.members or {}) do
    if m and not m.self and m.name and m.name~='' then
     out[#out+1]={name=m.name,role=self.roles[key(m)] or 'none'}
    end
   end
  end
  table.sort(out,function(a,b) return normalizeName(a.name)<normalizeName(b.name) end)
  return out
 end
 local roleToken={tank='Tank',heal='Heal',melee='Melee',ele='Ele',affliction='Affliction',none='None'}
 local tokenRole={tank='tank',heal='heal',melee='melee',ele='ele',affliction='affliction',none='none'}
 function R:sendTeamMessage(message)
  local eb=getUI('ui:interface:team_chat:content:ebw:eb',false)
  if not eb then error('Native team-chat input is unavailable') end
  local previous=eb.input_string or ''
  eb.input_string=message
  runAH(eb,'chat_box_entry','')
  if previous~='' then eb.input_string=previous end
  self.stats.chatSent=self.stats.chatSent+1
 end
 function R:announce()
  if self.failed or not ready() then return false end
  self:observeSession()
  if not self.inTeam or db('SERVER:GROUP:LEADER_INDEX')%16~=15 then return false end
  local prefix='[PadUI] '
  local current=prefix
  for _,entry in ipairs(self:roleRoster()) do
   local token=entry.name..': '..roleToken[entry.role]
   local piece=(current==prefix and '' or '; ')..token
   if #current+#piece>240 and current~=prefix then
    self:sendTeamMessage(current)
    current=prefix..token
   else
    current=current..piece
   end
  end
  if current~=prefix then self:sendTeamMessage(current) end
  return true
 end
 function R:memberRoleMap()
  local map={}
  local own=tostring(getPlayerName() or '')
  if own~='' then map[normalizeName(own)]='self' end
  local t=RyzomTeamUI
  if t then
   for _,m in pairs(t.members or {}) do
    if m and m.name and m.name~='' then map[normalizeName(m.name)]=key(m) end
   end
  end
  return map
 end
 function R:applyChatLine(raw)
  local line=stripChat(raw)
  local tagStart=line:find('[PadUI]',1,true)
  if not tagStart then return false end
  local leader=self:currentLeaderName()
  if leader=='' then return false end
  local before=line:sub(1,tagStart-1):gsub('%s+$','')
  local explicit=before:match('^%s*(.-)%s*:%s*$')
  if explicit and normalizeName(explicit)~=normalizeName(leader) then return false end
  if not explicit and not normalizeName(before):find(normalizeName(leader),1,true) then return false end
  local roster=self:memberRoleMap()
  local changedAny=false
  local payload=line:sub(tagStart+7)
  for part in payload:gmatch('[^;]+') do
   local name,token=part:match('^%s*(.-)%s*:%s*([%a]+)%s*$')
   local role=token and tokenRole[token:lower()] or nil
   local memberKey=name and roster[normalizeName(name)] or nil
   if memberKey and role then
    self.roles[memberKey]=role~='none' and role or nil
    changedAny=true
   end
  end
  if changedAny then
   self.stats.chatApplied=self.stats.chatApplied+1
   local t=RyzomTeamUI
   if t and t.uiReady and t.geometryKey then self:render(t) end
  end
  return changedAny
 end
 function R:pollChat()
  if not ready() then return end
  self:observeSession()
  if not self.inTeam then return end
  local list=getUI('ui:interface:team_chat:content:cb:text_list',false)
  if not list then return end
  local count=tonumber(list.childrenNb) or 0
  local function textAt(i)
   local child=list:getChild(i)
   return child and child.right_click_params or ''
  end
  if self.chatList~=list or self.chatSeen==nil or count<self.chatSeen then
   self.chatList=list;self.chatSeen=count
   self.chatTail=count>0 and textAt(count-1) or nil
   return
  end
  local start=self.chatSeen
  if self.chatTail and count>0 then
   local found=nil
   for i=count-1,0,-1 do
    if textAt(i)==self.chatTail then found=i;break end
   end
   if found then
    start=found+1
   elseif count==self.chatSeen then
    -- History was cleared/replaced while keeping the same size: establish a
    -- fresh baseline instead of replaying old visible chat.
    self.chatSeen=count;self.chatTail=textAt(count-1)
    return
   end
  end
  for i=start,count-1 do
   local raw=textAt(i)
   self.stats.chatRead=self.stats.chatRead+1
   if raw and raw~='' then self:applyChatLine(raw) end
  end
  self.chatSeen=count
  self.chatTail=count>0 and textAt(count-1) or nil
 end
 function R:guard(method,...)
  if self.failed then return false end
  local ok,err=pcall(self[method],self,...)
  if not ok then
   self.failed=tostring(err)
   -- A role error must not disable the working team display or its controls.
   for _,icon in pairs(self.icons) do pcall(function() icon.group.active=false end) end
   local t=RyzomTeamUI
   if t and t.scale then
    for _,v in ipairs(t.cards) do pcall(function()
     set(v.nodes.name,'x',round(8*t.scale));v.inputKey=nil
    end) end
   end
   pcall(function() set(getUI(MENU..':padui_roles',false),'grayed',true) end)
   pcall(debugInfo,'PadUI local roles: '..self.failed)
   pcall(displaySystemInfo,'PadUI roles: '..self.failed,'SYS')
  end
  return ok
 end
 function R:start()
  local t=RyzomTeamUI
  if not t or not t.render or not t.update or not t.click then error('Modular team controller is unavailable') end
  -- Wrappers resolve the current global module, so reloads do not stack them.
  if t.update~=t._paduiRolesUpdate then
   local original=t.update
   t._paduiRolesUpdate=function(self,...)
    PadUITeamRoles:guard('observeSession')
    local result=original(self,...)
    PadUITeamRoles:guard('pollChat')
    return result
   end
   t.update=t._paduiRolesUpdate
  end
  if t.render~=t._paduiRolesRender then
   local original=t.render
   t._paduiRolesRender=function(self,...)
    original(self,...)
    PadUITeamRoles:guard('render',self)
   end
   t.render=t._paduiRolesRender
  end
  if t.click~=t._paduiRolesClick then
   local original=t.click
   t._paduiRolesClick=function(self,slot,side)
    local m=self.rows[tonumber(slot)]
    if side=='right' and ready() and not self.failed and self:validMember(m) then
     PadUITeamRoles:guard('prepareMenu',m)
    end
    return original(self,slot,side)
   end
   t.click=t._paduiRolesClick
  end
  self:guard('observeSession')
  -- Also applies when the team was created before PadUI:start() ran.
  if ready() and t.uiReady and t.geometryKey then self:guard('render',t) end
 end
end
