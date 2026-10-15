-- PadUI manual countdowns. No gameplay actions, no automatic repetition.
PadUITimers=PadUITimers or {}
local T=PadUITimers
local ROOT='ui:interface:padui_timers'
local SAVE='UI:SAVE:PADUI:TIMERS:'
local words={
 de={mode='Modus: ',countdown='Countdown',stopwatch='Stoppuhr',mini='Miniansicht',mini_tip='In Miniansicht anzeigen',title='PadUI Timer',timer='Timer',start='Start',pause='Pause',resume='Weiter',reset='Zurücksetzen',done='Abgelaufen',idle='Bereit',paused='Pausiert',running='Läuft',hint='Minuten / Sekunden; Zeiten werden gespeichert.',invalid='Bitte eine Zeit zwischen 1 Sekunde und 24 Stunden eingeben.',message='%s ist abgelaufen.',idle_note='Kein Timer zur Anzeige ausgewählt',compact='Minimieren / Erweitern',name_tip='Eigener Name für diesen Timer',note='Läuft auch bei geschlossenem Fenster. Neustart stoppt die Timer.'},
 en={mode='Mode: ',countdown='Countdown',stopwatch='Stopwatch',mini='Compact view',mini_tip='Show in compact view',title='PadUI Timers',timer='Timer',start='Start',pause='Pause',resume='Resume',reset='Reset',done='Finished',idle='Ready',paused='Paused',running='Running',hint='Minutes / seconds; durations are saved.',invalid='Enter a duration between 1 second and 24 hours.',message='%s has finished.',idle_note='No timer selected for display',compact='Minimize / Expand',name_tip='Your name for this timer',note='Runs while hidden. Restarting the client stops the timers.'},
 fr={mode='Mode : ',countdown='Compte à rebours',stopwatch='Chronomètre',mini='Vue réduite',mini_tip='Afficher dans la vue réduite',title='Minuteurs PadUI',timer='Minuteur',start='Démarrer',pause='Pause',resume='Reprendre',reset='Réinitialiser',done='Terminé',idle='Prêt',paused='En pause',running='En cours',hint='Minutes / secondes ; durées mémorisées.',invalid='Saisir une durée entre 1 seconde et 24 heures.',message='%s est terminé.',idle_note='Aucun minuteur sélectionné',compact='Réduire / Développer',name_tip='Nom de ce minuteur',note='Continue si masqué. Redémarrer le client arrête les minuteurs.'}
}
T.count=3
local function slot(value)
 value=tonumber(value)
 if value and value==math.floor(value) and value>=1 and value<=T.count then return value end
end
local function ui(index,id)
 local compact=tonumber(getDbProp(SAVE..'COMPACT'))==1
 local base=({name=11,countdown=compact and 14 or 20,mini_start_text=12,mini_reset_text=12})[id]
 if not base then return getUI(ROOT..':content:timer'..index..':'..id) end
 local size=math.max(7,math.min(22,math.floor(base*(compact and (T.scale or 1) or 1)+0.5)))
 local path=ROOT..':content:timer'..index..':'..id
 local selected=getUI(path..'_s'..size)
 if not selected then return getUI(path) end
 T.fontChoices=T.fontChoices or {};local previous=T.fontChoices[path]
 if previous~=size then
  if previous then local old=getUI(path..'_s'..previous);if old then old.active=false end end
  local original=getUI(path);if original then original.active=false end
  T.fontChoices[path]=size
 end
 return selected
end
function T:stopwatch(index)return tonumber(getDbProp(SAVE..index..':MODE'))==1 end
function T:toggleMode(index)
 index=slot(index);if not index then return end
 setDbProp(SAVE..index..':MODE',T:stopwatch(index) and 0 or 1)
 T.states=T.states or {};T.states[index]={remaining=T:stopwatch(index) and 0 or T:duration(index),status='idle'}
 T:refresh()
end
-- Client builds accept either UTF-8 strings or native ucstrings here.
-- A notification must never interrupt the countdown's final display update.
local function notify(message)
 local ok=pcall(displaySystemInfo,message,'SYS')
 if not ok and type(ucstring)=='function' then
  pcall(function() displaySystemInfo(ucstring(message),'SYS') end)
 end
end
-- Persist UTF-8 names as signed 32-bit byte packs: UI:SAVE supports numbers.
function T:loadName(index)
 local length=tonumber(getDbProp(SAVE..index..':NAME_LENGTH')) or 0
 length=math.max(0,math.min(80,math.floor(length)))
 local bytes={}
 for block=0,math.ceil(length/4)-1 do
  local value=tonumber(getDbProp(SAVE..index..':NAME:'..block)) or 0
  if value<0 then value=value+4294967296 end
  for offset=0,3 do
   if #bytes<length then bytes[#bytes+1]=string.char(math.floor(value/(256^offset))%256) end
  end
 end
 return table.concat(bytes)
end
function T:name(index)
 local value=T:loadName(index)
 return value~='' and value or (T:texts().timer..' '..index)
end
function T:saveName(index)
 index=slot(index);if not index then return end
 local edit=ui(index,'name_input');if not edit then return end
 local value=tostring(edit.input_string or ''):gsub('^%s+',''):gsub('%s+$',''):gsub('[\r\n]',' ')
 if #value>80 then
  local cut=80
  while cut>0 and value:byte(cut+1)>=128 and value:byte(cut+1)<=191 do cut=cut-1 end
  value=value:sub(1,cut)
 end
 for block=0,19 do
  local packed=0
  for offset=0,3 do packed=packed+(value:byte(block*4+offset+1) or 0)*256^offset end
  if packed>=2147483648 then packed=packed-4294967296 end
  setDbProp(SAVE..index..':NAME:'..block,packed)
 end
 setDbProp(SAVE..index..':NAME_LENGTH',#value)
 T:refresh()
end
function T:miniVisible(index)
 return tonumber(getDbProp(SAVE..index..':HIDE_MINI'))~=1
end
function T:toggleMiniVisible(index)
 index=slot(index);if not index then return end
 setDbProp(SAVE..index..':HIDE_MINI',T:miniVisible(index) and 1 or 0)
 T:refresh()
end
function T:toggleCompact()
 local compact=tonumber(getDbProp(SAVE..'COMPACT'))==1
 setDbProp(SAVE..'COMPACT',compact and 0 or 1)
 T:refresh()
end
local function active(node,value)
 -- Native edit_box:setActive(false) resets GLOBAL keyboard capture even if
 -- already hidden. Never repeat it on countdown/name/settings refreshes.
 if node and node.active~=value then node.active=value end
end
function T:layout()
 local compact=tonumber(getDbProp(SAVE..'COMPACT'))==1
 local window=getUI(ROOT);local content=getUI(ROOT..':content')
 if not window or not content then return end
 local savedScale=tonumber(getDbProp('UI:SAVE:PADUI:TIMER_SCALE')) or 100
 if savedScale<50 or savedScale>150 then savedScale=100 end
 savedScale=math.max(50,math.min(150,math.floor(savedScale/25+0.5)*25))
 T.scale=compact and savedScale/100 or 1
 local function px(value)return math.floor(value*T.scale+0.5)end
 local signature=(compact and 'compact' or 'full')..':'..savedScale
 for index=1,T.count do signature=signature..':'..tostring(T:stopwatch(index)) end
 if compact then
  for index=1,T.count do signature=signature..(T:miniVisible(index) and ':1' or ':0') end
 end
 if T.layoutSignature==signature then return end
 local count=0;local width=compact and px(300) or 360
 for index=1,T.count do
  local state=T:state(index)
  local visible=not compact or T:miniVisible(index)
  local row=getUI(ROOT..':content:timer'..index)
  if row then
   active(row,visible);row.w=width-(compact and px(18) or 18);row.h=compact and px(28) or 116
   row.y=compact and (-px(6)-count*px(28)) or (-28-(index-1)*120)
  end
  if visible then count=count+1 end
  local back=ui(index,'back');if back then back.w=width-(compact and px(18) or 18);back.h=compact and px(28) or 116 end
  for _,id in ipairs({'mode','mode_back','mode_text','name_input','name_input_back','minutes','minutes_back','minutes_unit','seconds','seconds_back','seconds_unit','status','show_mini','show_mini_back','show_mini_mark','show_mini_label',
   'start','start_back','start_text','reset','reset_back','reset_text','preset60','preset60_back','preset60_text','preset300','preset300_back','preset300_text','preset900','preset900_back','preset900_text'}) do
   local n=ui(index,id)
   local durationField=id:match('^minutes') or id:match('^seconds') or id:match('^preset')
   active(n,not compact and not (durationField and T:stopwatch(index)))
  end
  for _,id in ipairs({'mini_start','mini_start_back','mini_start_text','mini_reset','mini_reset_back','mini_reset_text'}) do
   local n=ui(index,id);active(n,compact)
   if n then
    local reset=id:find('reset',1,true);local text=id:find('text',1,true)
    n.x=px(reset and (text and 256 or 248) or (text and 222 or 214))
    n.y=-px(text and 5 or 2)
    if not text then n.w=px(28);n.h=px(24) end
   end
  end
  local name=ui(index,'name');if name then active(name,compact);name.x=px(6);name.y=-px(3);name:setLineMaxW(px(104)) end
  local countdown=ui(index,'countdown')
  if countdown then
   active(countdown,true);countdown.x=compact and px(118) or 183;countdown.y=compact and -px(3) or 0;countdown:setLineMaxW(compact and px(90) or 150)

  end
 end
 local height=compact and (px(8)+math.max(1,count)*px(28)) or 412
 content.w=width-2;content.h=height;window.w=width;window.h=20+height
 local header=getUI(ROOT..':header_opened');if header then header.w=width-2 end
 for _,path in ipairs({':header_opened:back',':content:back'}) do
  local back=getUI(ROOT..path);if back then back.w=width-2;if path==':content:back' then back.h=height end end
 end
 for _,id in ipairs({'close','close_back','close_text','compact','compact_back','compact_text'}) do
  local n=getUI(ROOT..':header_opened:'..id)
  if n then n.x=width-(id:match('^close') and 30 or 58)+(id:match('_text$') and 5 or 0) end
 end
 local mark=getUI(ROOT..':header_opened:compact_text');if mark then mark.hardtext=compact and '+' or '−' end
 local title=getUI(ROOT..':header_opened:title');if title then title:setLineMaxW(width-70) end
 local hint=getUI(ROOT..':content:hint');active(hint,not compact)
 local note=getUI(ROOT..':content:note');active(note,not compact)
 local empty=getUI(ROOT..':content:empty');if empty then active(empty,compact and count==0);empty.hardtext=T:texts().idle_note end
 T.layoutCompact=compact;T.layoutSignature=signature
 window:invalidateCoords()
end
function T:texts() return words[PadUI:language()] or words.en end
function T:format(seconds)
 seconds=math.max(0,math.ceil(seconds))
 local hours=math.floor(seconds/3600)
 if hours>0 then return string.format('%02d:%02d:%02d',hours,math.floor(seconds/60)%60,seconds%60) end
 return string.format('%02d:%02d',math.floor(seconds/60),seconds%60)
end
function T:duration(index)
 local value=tonumber(getDbProp(SAVE..index..':SECONDS')) or 0
 return value>=1 and value<=86400 and math.floor(value) or index*300
end
function T:inputs(index,seconds)
 local m,s=ui(index,'minutes'),ui(index,'seconds')
 if m then m.input_string=tostring(math.floor(seconds/60)) end
 if s then s.input_string=tostring(seconds%60) end
end
function T:read(index)
 local m,s=ui(index,'minutes'),ui(index,'seconds')
 local mins=tonumber(m and m.input_string or '')
 local secs=tonumber(s and s.input_string or '')
 if not mins or not secs or mins<0 or secs<0 or mins~=math.floor(mins) or secs~=math.floor(secs) or secs>59 then return nil end
 local total=mins*60+secs
 if total<1 or total>86400 then return nil end
 return total
end
function T:state(index)
 T.states=T.states or {}
 if not T.states[index] then
  T.states[index]={remaining=T:stopwatch(index) and 0 or T:duration(index),status='idle'}
  T:inputs(index,T.states[index].remaining)
  local edit=ui(index,'name_input');if edit then edit.input_string=T:name(index) end
 end
 return T.states[index]
end
function T:saveInput(index)
 local seconds=T:read(index)
 if not seconds then
  notify('PadUI: '..T:texts().invalid);return nil
 end
 setDbProp(SAVE..index..':SECONDS',seconds)
 return seconds
end
function T:toggle(index,saved)
 index=slot(index);if not index or not game or not game.InGameDbInitialized then return end
 T:tick(true)
 local state=T:state(index)
 if state.status=='running' then state.status='paused'
 elseif state.status=='paused' then state.status='running';state.lastMs=nltime.getLocalTime()
 else
  local seconds=T:stopwatch(index) and 0 or (saved and T:duration(index) or T:saveInput(index));if seconds==nil then return end
  state.remaining=seconds;state.status='running';state.lastMs=nltime.getLocalTime()
 end
 T:refresh()
end
function T:reset(index,saved)
 index=slot(index);if not index then return end
 T:state(index)
 local seconds=T:stopwatch(index) and 0 or (saved and T:duration(index) or T:saveInput(index));if seconds==nil then return end
 T.states[index]={remaining=seconds,status='idle'}
 T:refresh()
end
function T:preset(index,seconds)
 index=slot(index);seconds=tonumber(seconds)
 if not index or (seconds~=60 and seconds~=300 and seconds~=900) then return end
 T:state(index);setDbProp(SAVE..index..':SECONDS',seconds)
 T.states[index]={remaining=T:stopwatch(index) and 0 or seconds,status='idle'}
 T:inputs(index,seconds);T:refresh()
end
function T:refresh()
 local savedScale=tonumber(getDbProp('UI:SAVE:PADUI:TIMER_SCALE')) or 100
 if savedScale<50 or savedScale>150 then savedScale=100 end
 savedScale=math.max(50,math.min(150,math.floor(savedScale/25+0.5)*25))
 T.scale=tonumber(getDbProp(SAVE..'COMPACT'))==1 and savedScale/100 or 1
 local text=T:texts()
 T.runningCount=0
 local empty=getUI(ROOT..':content:empty');if empty then empty.hardtext=text.idle_note end
 local title=getUI(ROOT..':header_opened:title');if title then title.hardtext=text.title;title.color=PadUI:accent() end
 local hint=getUI(ROOT..':content:hint');if hint then hint.hardtext=text.hint end
 local note=getUI(ROOT..':content:note');if note then note.hardtext=text.note end
 for index=1,T.count do
  local state=T:state(index)
  if state.status=='running' then T.runningCount=T.runningCount+1 end
  local name=ui(index,'name');if name then name.hardtext=T:name(index);name.color=PadUI:accent() end
  local countdown=ui(index,'countdown')
  if countdown then
   countdown.hardtext=T:format(T:stopwatch(index) and math.floor(state.remaining) or state.remaining)
   active(countdown,true)
   countdown.color=state.status=='done' and '255 115 95 255' or '245 235 210 255'
  end
  local mode=ui(index,'mode_text');if mode then mode.hardtext=text.mode..text[T:stopwatch(index) and 'stopwatch' or 'countdown'] end
  local status=ui(index,'status');if status then status.hardtext=text[state.status=='done' and 'done' or state.status] end
  local label=ui(index,'start_text')
  if label then label.hardtext=text[state.status=='running' and 'pause' or (state.status=='paused' and 'resume' or 'start')] end
  local reset=ui(index,'reset_text');if reset then reset.hardtext=text.reset end
  local mini=ui(index,'mini_start_text');if mini then mini.hardtext=state.status=='running' and 'II' or '>' end
  local start=ui(index,'mini_start');if start then start.tooltip=T:name(index)..': '..text[state.status=='running' and 'pause' or (state.status=='paused' and 'resume' or 'start')] end
  local resetButton=ui(index,'mini_reset');if resetButton then resetButton.tooltip=T:name(index)..': '..text.reset end
  local check=ui(index,'show_mini');if check then check.tooltip=text.mini_tip end
  local mark=ui(index,'show_mini_mark');if mark then mark.hardtext=T:miniVisible(index) and 'X' or '' end
  local label=ui(index,'show_mini_label');if label then label.hardtext=text.mini end
 end
 PadUI:setText('ui:interface:gestion_windows:inventory:padui_timers:text',text.title)
 local button=getUI(ROOT..':header_opened:compact');if button then button.tooltip=text.compact end
 for index=1,T.count do local edit=ui(index,'name_input');if edit then edit.tooltip=text.name_tip end end
 T:layout()
 T.lastLanguage=PadUI:language()
end
function T:tick(force)
 if not game or not game.InGameDbInitialized then return end
 -- Idle, paused and completed timers need no time calculation or UI writes.
 if not force and T.runningCount==0 and T.lastLanguage==PadUI:language() then return end
 local now=nltime.getLocalTime()
 if not force and T.lastTick and now>=T.lastTick and now-T.lastTick<100 then return end
 T.lastTick=now
 local changed=false
 local finished={}
 for index=1,T.count do
  local state=T:state(index)
  if state.status=='running' then
   local elapsed=math.max(0,now-(state.lastMs or now))/1000
   local stopwatch=T:stopwatch(index)
   local previous=stopwatch and math.floor(state.remaining) or math.ceil(state.remaining)
   state.remaining=stopwatch and (state.remaining+elapsed) or math.max(0,state.remaining-elapsed);state.lastMs=now
   if not stopwatch and state.remaining==0 then
    state.status='done';changed=true
    finished[#finished+1]=index
   elseif previous~=(stopwatch and math.floor(state.remaining) or math.ceil(state.remaining)) then changed=true end
  end
 end
 local window=getUI(ROOT)
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_TIMERS',window and window.active and 1 or 0)
 if changed or force or T.lastLanguage~=PadUI:language() then T:refresh() end
 -- Render 00:00 and the final state first. Notify only on this transition.
 for _,index in ipairs(finished) do
  notify('PadUI: '..string.format(T:texts().message,T:name(index)))
 end
end
function T:onActive()
 setDbProp('UI:VARIABLES:ISACTIVE:PADUI_TIMERS',1)
 T:tick(true)
end
function T:start()
 for index=1,T.count do T:state(index) end
 T:refresh()
end
