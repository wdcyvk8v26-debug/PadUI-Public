-- PadUI settings: local presentation preferences only. Lua 5.1 compatible.
PadUISettings=PadUISettings or {}
local S=PadUISettings
local ROOT='ui:interface:padui_settings'
local SAVE='UI:SAVE:PADUI:'
local COLORS={'110 235 225','120 185 255','190 145 255','255 185 100','255 145 180','170 225 120'}
local words={
 de={title='PadUI Einstellungen',appearance='Darstellung',layout='Anordnung',timer_scale='Timergröße (Miniansicht)',team_scale='Teamgröße',team_layout='Teamfenster',item_layout='Itemleiste',vertical='Vertikal',horizontal='Horizontal',automatic='Automatisch',layout_note='Team horizontal: 5 Spalten, in kleinen Fenstern 3×3. Itemleiste bricht bei Platzmangel um.',windows='Fenster',auras='PadAuras',accent='Akzentfarbe',name='Charakter im Kopf anzeigen',transparency='Transparenz',font='Schrift der kompakten Anzeigen',language='Sprache',saved='Wird pro Charakter sofort gespeichert.',normal='Standard',small='Kleiner',large='Größer',on='An',off='Aus',defaults='Darstellung zurücksetzen',close='Schließen',timers='Timer',team='Team',inventory='Tascheninfo',items='Itemleiste',player='Spieler',target='Ziel',warning='Warnung vor Ablauf',mode='Überwachte Effekte',both='Buffs + Debuffs',buffs='Nur Buffs',debuffs='Nur Debuffs',filters='Einzelne Effekte auswählen',test='Test / Platzieren',stop_test='Test beenden',position='Position zurücksetzen',aura_defaults='Zurücksetzen',placement='Test starten; Kachel am Hintergrund ziehen.',effects='Erkannte Effekte — Klick zum Überwachen',visibility='Anzeigen / Ausblenden',self='Eigenen Charakter im Team',sort='Teamsortierung',sort_name='Name',sort_hp='HP',sort_missing='Fehlende HP',semantic='Balken- und Warnfarben bleiben unverändert.',colors={'Türkis','Blau','Violett','Orange','Rosa','Grün'}},
 en={title='PadUI Settings',appearance='Appearance',layout='Layout',timer_scale='Timer size (compact)',team_scale='Team size',team_layout='Team window',item_layout='Item bar',vertical='Vertical',horizontal='Horizontal',automatic='Automatic',layout_note='Horizontal team: 5 columns, 3×3 in small windows. Item bar wraps if space is limited.',windows='Windows',auras='PadAuras',accent='Accent colour',name='Show character in header',transparency='Transparency',font='Compact display text',language='Language',saved='Changes are saved immediately per character.',normal='Default',small='Smaller',large='Larger',on='On',off='Off',defaults='Reset appearance',close='Close',timers='Timer',team='Team',inventory='Bag info',items='Item bar',player='Player',target='Target',warning='Warning before expiry',mode='Monitored effects',both='Buffs + debuffs',buffs='Buffs only',debuffs='Debuffs only',filters='Choose individual effects',test='Test / Position',stop_test='Stop preview',position='Reset position',aura_defaults='Reset',placement='Start preview; drag the tile background.',effects='Observed effects — click to monitor',visibility='Show / Hide',self='Own character in team',sort='Team sorting',sort_name='Name',sort_hp='HP',sort_missing='Missing HP',semantic='Resource bars and warning colours stay unchanged.',colors={'Turquoise','Blue','Purple','Orange','Pink','Green'}},
 fr={title='Réglages PadUI',appearance='Apparence',layout='Disposition',timer_scale='Taille des minuteurs (réduits)',team_scale='Taille de l’équipe',team_layout='Fenêtre d’équipe',item_layout='Barre d’objets',vertical='Verticale',horizontal='Horizontale',automatic='Automatique',layout_note='Équipe horizontale : 5 colonnes, 3×3 en petite fenêtre. Objets : retour si nécessaire.',windows='Fenêtres',auras='PadAuras',accent='Couleur d’accent',name='Personnage dans l’en-tête',transparency='Transparence',font='Texte des affichages compacts',language='Langue',saved='Modifications enregistrées par personnage.',normal='Défaut',small='Plus petit',large='Plus grand',on='Oui',off='Non',defaults='Réinitialiser l’apparence',close='Fermer',timers='Minuteurs',team='Équipe',inventory='Infos du sac',items='Barre d’objets',player='Personnage',target='Cible',warning='Alerte avant expiration',mode='Effets surveillés',both='Bonus + malus',buffs='Bonus seuls',debuffs='Malus seuls',filters='Choisir les effets individuels',test='Test / Placer',stop_test='Arrêter le test',position='Replacer',aura_defaults='Réinitialiser',placement='Lancer le test ; déplacer par le fond.',effects='Effets observés — cliquer pour surveiller',visibility='Afficher / Masquer',self='Son personnage dans l’équipe',sort='Tri de l’équipe',sort_name='Nom',sort_hp='PV',sort_missing='PV manquants',semantic='Couleurs des jauges et alertes conservées.',colors={'Turquoise','Bleu','Violet','Orange','Rose','Vert'}}
}
local function db(key) return tonumber(getDbProp(SAVE..key)) or 0 end
local function node(path) return getUI(ROOT..path) end
local function text(path,value) local n=node(path);if n then n.hardtext=value end end
function S:texts() return words[PadUI:language()] or words.en end
function S:accent(alpha)
 local index=db('ACCENT');if index<0 or index>5 or index~=math.floor(index) then index=0 end
 return COLORS[index+1]..' '..tostring(alpha or 255)
end
function S:brand(compact)
 if db('SHOW_NAME')==1 and (not isPlayerReady or isPlayerReady()) then
  local ok,name=pcall(getPlayerName)
  if ok and type(name)=='string' and name~='' then return 'PadUI · '..name end
 end
 return compact and 'PadUI' or ('PadUI '..PadUI.version)
end
function S:transparency()
 local value=tonumber(getDbProp(SAVE..'TRANSPARENCY'))
 if value and value>=0 and value<=100 then return math.floor(value) end
 local alpha=db('BACKGROUND_ALPHA')
 if alpha>=1 and alpha<=255 then return math.floor((1-alpha/255)*100+0.5) end
 return 8 -- slider starting point; unchanged legacy backgrounds keep their defaults.
end
function S:setTimerScale()
 local value=tonumber(getDbProp('UI:VARIABLES:PADUI:TIMER_SCALE'))
 if value then S:set('TIMER_SCALE',math.max(50,math.min(150,math.floor(value/25+0.5)*25))) end
end
function S:setTeamScale()
 local value=tonumber(getDbProp('UI:VARIABLES:PADUI:TEAM_SCALE'))
 if value then S:set('TEAM_SCALE',math.max(75,math.min(150,math.floor(value/25+0.5)*25))) end
end
function S:setTransparency()
 local value=tonumber(getDbProp('UI:VARIABLES:PADUI:TRANSPARENCY'))
 if not value then return end
 S:set('TRANSPARENCY',math.max(0,math.min(100,math.floor(value))))
end
function S:set(key,value)
 value=tonumber(value)
 if not value or value~=math.floor(value) then return end
 local valid=(key=='ACCENT' and value>=0 and value<=5)
  or (key=='SHOW_NAME' and (value==0 or value==1))
  or (key=='BACKGROUND_ALPHA' and (value==0 or value==204 or value==230 or value==255))
  or (key=='TRANSPARENCY' and value>=0 and value<=100)
  or (key=='TIMER_SCALE' and value>=50 and value<=150)
  or (key=='TEAM_SCALE' and value>=75 and value<=150)
  or (key=='TEAM_LAYOUT' and value>=0 and value<=1)
  or (key=='ITEM_LAYOUT' and value>=0 and value<=2)
  or (key=='FONT_DELTA' and value>=-1 and value<=1)
  or (key=='LANGUAGE' and value>=0 and value<=3)
 if not valid then return end
 setDbProp(SAVE..key,value)
 if key=='TRANSPARENCY' then S.nativeWindowAlpha={} end
 if key=='ACCENT' then S:applyNativeAccent() end
 S:apply(true)
 if key=='ITEM_LAYOUT' and PadUIQuickbar then PadUIQuickbar.lastRefresh=nil;PadUIQuickbar:update() end
 if key=='LANGUAGE' then
  PadUI:localize(true)
  if RyzomInventoryCompact then RyzomInventoryCompact.lastRefresh=nil;RyzomInventoryCompact:update() end
  if PadUIQuickbar then PadUIQuickbar.lastRefresh=nil;PadUIQuickbar:update() end
 end
 S:refresh()
end
function S:toggleName() S:set('SHOW_NAME',db('SHOW_NAME')==1 and 0 or 1) end
function S:defaults()
 for _,key in ipairs({'ACCENT','SHOW_NAME','BACKGROUND_ALPHA','FONT_DELTA'}) do setDbProp(SAVE..key,0) end
 setDbProp(SAVE..'TRANSPARENCY',-1)
 setDbProp(SAVE..'TEAM_SCALE',100)
 setDbProp(SAVE..'TIMER_SCALE',100)
 S:applyNativeAccent()
 S:apply(true);S:refresh()
end
function S:page(value)
 if value~=0 and value~=1 and value~=2 and value~=3 then return end
 S.currentPage=value;S:refresh()
end
-- Shared alpha for static styles and colours refreshed by live resource updates.
function S:withTransparency(color)
 local transparency=tonumber(getDbProp(SAVE..'TRANSPARENCY'))
 local alpha
 if transparency and transparency>=0 and transparency<=100 then
  alpha=math.floor(255*(100-transparency)/100+0.5)
 else
  local saved=db('BACKGROUND_ALPHA')
  if saved==204 or saved==230 or saved==255 then alpha=saved end
 end
 return alpha and (color:gsub('%d+%s*$',tostring(alpha))) or color
end
-- Use Ryzom's native global background alpha. No window enumeration or dynamic UI.
function S:applyNativeWindows(custom,alpha)
 -- Undo the global 0.8.9 rollover change once, without continually replacing user settings.
 if tonumber(getDbProp('UI:SAVE:PADUI:ROLLOVER_RESTORED_0810'))~=1 then
  if tonumber(getDbProp('UI:SAVE:CONTAINER_ROLLOVER_FACTOR'))==0 then
   setDbProp('UI:SAVE:CONTAINER_ROLLOVER_FACTOR',255)
  end
  setDbProp('UI:SAVE:PADUI:ROLLOVER_RESTORED_0810',1)
 end
 if not custom then return end
 if tonumber(getDbProp('UI:SAVE:CONTAINER_ALPHA'))~=alpha then
  setDbProp('UI:SAVE:CONTAINER_ALPHA',alpha)
 end
 S.nativeWindowAlpha=S.nativeWindowAlpha or {}
 for _,path in ipairs(PadUINativeWindows or {}) do
  if S.nativeWindowAlpha[path]~=alpha then
   local window=getUI(path)
   if window then
    -- Native action also disables local rollover fading and keeps content legible.
    runAH(nil,'set_alpha','target='..path..'|alpha='..alpha)
    S.nativeWindowAlpha[path]=alpha
   end
  end
 end
end
-- Native palette changes only after an explicit accent choice, never at login.
function S:applyNativeAccent()
 if not game or not game.InGameDbInitialized then return end
 local r,g,b=S:accent():match('^(%d+) (%d+) (%d+)')
 if not r then return end
 local ok,value=pcall(runExpr,'makeRGB('..r..','..g..','..b..',255)')
 value=ok and tonumber(value) or nil
 if not value then return end
 for _,category in ipairs({'PLA','ANI','COM','INV','OPT','LAB','MEM','MAP','HELP','INFOS','TRADE','BOT'}) do
  local path='UI:SAVE:WIN:COLORS:'..category
  if tonumber(getDbProp(path))~=value then setDbProp(path,value) end
 end
end
function S:apply(force)
 if not game or not game.InGameDbInitialized then return end
 local signature=tostring(db('TIMER_SCALE'))..':'..tostring(db('TEAM_SCALE'))..':'..S:accent()..':'..db('SHOW_NAME')..':'..db('BACKGROUND_ALPHA')..':'..db('FONT_DELTA')..':'..tostring(getDbProp(SAVE..'TRANSPARENCY'))
 if not force and S.signature==signature then return end
 S.signature=signature
 local alpha=db('BACKGROUND_ALPHA')
 if alpha~=204 and alpha~=230 and alpha~=255 then alpha=0 end
 local transparency=tonumber(getDbProp(SAVE..'TRANSPARENCY'))
 local custom=transparency and transparency>=0 and transparency<=100
 if custom then alpha=math.floor(255*(100-transparency)/100+0.5) end
 S:applyNativeWindows(custom,alpha)
 local delta=db('FONT_DELTA');if delta<-1 or delta>1 then delta=0 end
 for _,spec in ipairs(PadUIStyle or {}) do
  local n=getUI(spec[1])
  if n then
   if spec[2]=='accent' then n.color=S:accent(spec[3])
   elseif spec[2]=='background' then n.color=spec[3]..' '..((not custom and alpha==0) and spec[4] or alpha)
   elseif spec[2]=='font' then
    -- fontsize is a native property, but is not exported as a Lua field.
    runAH(nil,'set','target_property='..spec[1]..':fontsize|value='..(spec[3]+delta))
   end
  end
 end
 if RyzomTeamUI then RyzomTeamUI.lastTick=nil;RyzomTeamUI:update() end
 if PadUIAuras then PadUIAuras.settingsDirty=true;PadUIAuras:update() end
 if PadUITimers then PadUITimers.layoutSignature=nil;PadUITimers:refresh() end
end
S.windows={
 {'team_compact','TEAM_COMPACT','team'},
 {'inventory_compact','INVENTORY_COMPACT','inventory'},
 {'padui_items','PADUI_ITEMS','items'},
 {'padui_auras','PADUI_AURAS','auras'},
 {'player','PLAYER','player'},
 {'target','TARGET','target'},
 {'padui_timers','PADUI_TIMERS','timers'}
}
function S:toggleWindow(index)
 local spec=S.windows[tonumber(index) or 0];if not spec then return end
 if spec[1]=='padui_auras' and PadUIAuras then
  PadUIAuras:toggleEnabled()
  S:refresh()
  return
 end
 local w=getUI('ui:interface:'..spec[1]);if not w then return end
 w.active=not w.active
 setDbProp('UI:VARIABLES:ISACTIVE:'..spec[2],w.active and 1 or 0)
 if w.active then runAH(nil,'set','target_property=ui:interface:'..spec[1]..':opened|value=1') end
 S:refresh()
end
function S:toggleSelf()
 if RyzomTeamUI then RyzomTeamUI:toggleSelf() end
 S:refresh()
end
function S:sort(mode)
 if mode~='name' and mode~='hp' and mode~='missing' then return end
 if RyzomTeamUI then RyzomTeamUI:setSort(mode) end
 S:refresh()
end
function S:seconds(value) if PadUIAuras then PadUIAuras:setSeconds(value) end S:refresh() end
function S:mode(value) if PadUIAuras then PadUIAuras:setMode(value) end S:refresh() end
function S:filters() S:page(2) end
function S:position() if PadUIAuras then PadUIAuras:resetPosition() end end
function S:auraDefaults() if PadUIAuras then PadUIAuras:defaults() end S:refresh() end
function S:test() if PadUIAuras then PadUIAuras:test() end S:refresh() end
function S:refresh()
 local t=S:texts();local page=S.currentPage or 0
 local function label(id,value) text(':content:'..id,value) end
 text(':header_opened:title',t.title)
 text(':header_opened:close_text','×')
 label('saved',t.saved)
 for i,key in ipairs({'appearance','windows','auras','layout'}) do
  label('tab'..(i-1)..'_text',t[key])
  local back=node(':content:tab'..(i-1)..'_back')
  if back then back.color=page==i-1 and S:accent(60) or '35 45 53 220' end
  local body=node(':content:page'..(i-1));if body then body.active=page==i-1 end
 end
 local function pl(p,id,value) text(':content:page'..p..':'..id,value) end
 for _,key in ipairs({'accent','transparency','font','language','semantic','defaults'}) do pl(0,key..'_text',t[key]) end
 for i=0,5 do
  pl(0,'color'..i..'_text',(db('ACCENT')==i and '[x] ' or '')..t.colors[i+1])
 end
 local ok,character = false, ""
 if not isPlayerReady or isPlayerReady() then
  ok,character=pcall(getPlayerName)
 end
 pl(0,'version_text','PadUI '..PadUI.version..(ok and type(character)=='string' and character~='' and (' · '..character) or ''))
 local percentage=S:transparency()
 if getDbProp('UI:VARIABLES:PADUI:TRANSPARENCY')~=percentage then
  setDbProp('UI:VARIABLES:PADUI:TRANSPARENCY',percentage)
 end
 local custom=tonumber(getDbProp(SAVE..'TRANSPARENCY')) or -1
 pl(0,'alpha_value',custom<0 and db('BACKGROUND_ALPHA')==0 and t.normal or (percentage..'%'))
 local slider=node(':content:page0:alpha_slider');if slider then slider.tooltip=t.transparency..' (0–100%)' end
 for i,key in ipairs({'small','normal','large'}) do pl(0,'font'..(i-2)..'_text',(db('FONT_DELTA')==i-2 and '[x] ' or '')..t[key]) end
 for i,value in ipairs({PadUI:tr('auto'),'Deutsch','English','Français'}) do pl(0,'lang'..(i-1)..'_text',(db('LANGUAGE')==i-1 and '[x] ' or '')..value) end
 pl(1,'visibility_text',t.visibility);pl(1,'self_text',t.self);pl(1,'sort_text',t.sort)
 for i,spec in ipairs(S.windows) do
  local w=getUI('ui:interface:'..spec[1])
  local checked=(spec[1]=='padui_auras' and PadUIAuras and PadUIAuras:isEnabled()) or (w and w.active)
  pl(1,'window'..i..'_text',(checked and '[x] ' or '[ ] ')..t[spec[3]])
 end
 pl(1,'self_button_text',RyzomTeamUI and RyzomTeamUI:showSelf() and t.on or t.off)
 local mode=RyzomTeamUI and RyzomTeamUI:sortMode() or 0
 mode=({[0]='name',[1]='hp',[2]='missing'})[mode] or 'name'
 for _,key in ipairs({'name','hp','missing'}) do pl(1,'sort_'..key..'_text',(mode==key and '[x] ' or '')..t['sort_'..key]) end
 pl(2,'warning_text',t.warning);pl(2,'mode_text',t.mode)
 local seconds=PadUIAuras and PadUIAuras:warningSeconds() or 5
 for _,value in ipairs({3,5,10,15,30}) do pl(2,'time'..value..'_text',(seconds==value and '[x] ' or '')..value..' s') end
 local kind=PadUIAuras and PadUIAuras:mode() or 0
 for i,key in ipairs({'both','buffs','debuffs'}) do pl(2,'mode'..(i-1)..'_text',(kind==i-1 and '[x] ' or '')..t[key]) end
 pl(2,'test_text',PadUIAuras and PadUIAuras.placing and t.stop_test or t.test)
 pl(2,'position_text',t.position);pl(2,'aura_defaults_text',t.aura_defaults)
 pl(2,'placement_text',t.placement);pl(2,'effects_text',t.effects)
 if PadUIAuras then PadUIAuras:refreshSettings() end
 local scale=db('TEAM_SCALE');if scale<75 or scale>150 then scale=100 end
 scale=math.floor(scale/25+0.5)*25
 local ts=db('TIMER_SCALE');if ts<50 or ts>150 then ts=100 end
 ts=math.floor(ts/25+0.5)*25
 pl(3,'timer_scale_text',t.timer_scale);pl(3,'timer_scale_value',ts..'%')
 if getDbProp('UI:VARIABLES:PADUI:TIMER_SCALE')~=ts then setDbProp('UI:VARIABLES:PADUI:TIMER_SCALE',ts) end
 pl(3,'team_scale_text',t.team_scale);pl(3,'team_scale_value',scale..'%')
 if getDbProp('UI:VARIABLES:PADUI:TEAM_SCALE')~=scale then setDbProp('UI:VARIABLES:PADUI:TEAM_SCALE',scale) end
 pl(3,'team_layout_text',t.team_layout);pl(3,'item_layout_text',t.item_layout);pl(3,'layout_note',t.layout_note)
 for i,key in ipairs({'vertical','horizontal'}) do pl(3,'team_layout'..(i-1)..'_text',(db('TEAM_LAYOUT')==i-1 and '[x] ' or '')..t[key]) end
 for i,key in ipairs({'automatic','horizontal','vertical'}) do pl(3,'item_layout'..(i-1)..'_text',(db('ITEM_LAYOUT')==i-1 and '[x] ' or '')..t[key]) end
 PadUI:setText('ui:interface:gestion_windows:inventory:padui_settings:text',t.title)
 S.lastLanguage=PadUI:language()
end
function S:onActive()
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_SETTINGS',1)
 S:apply(true);S:refresh()
end
function S:tick()
 if not game or not game.InGameDbInitialized then return end
 local now=nltime.getLocalTime()
 if S.lastTick and now>=S.lastTick and now-S.lastTick<500 then return end
 S.lastTick=now
 -- Retry a few times during startup to cover windows created after this module.
 local retry=(S.startupRetries or 0)>0
 if retry then S.startupRetries=S.startupRetries-1 end
 S:apply(retry)
 local w=getUI(ROOT)
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_SETTINGS',w and w.active and 1 or 0)
 if (w and w.active) or S.lastLanguage~=PadUI:language() then S:refresh() end
end
function S:start()
 S.nativeWindowAlpha={}
 S.startupRetries=3;S.lastTick=nil;S:apply(true);S:refresh()
end
