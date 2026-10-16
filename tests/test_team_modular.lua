-- Native-behavior stand-ins, NOT a Ryzom renderer or OS mouse-capture test.
local fixture=dofile(assert(arg[1],'Run through tests/run_team_tests.py'))
local U,R,D,strings,actions,hooks={},{},{},{},{},{}
local SAVE='UI:SAVE:PADUI:TEAM_MODULAR:'
local LEGACY='ui:interface:team_compact'
local DRIVER='ui:interface:padui_team_driver'
local CARD='ui:interface:padui_team_member'
local PAGE='ui:interface:padui_settings:content:page3'
local ownName,sw,sh='SelfTest',1920,1080
local mouse,px,py,mx,my,over,caller,capture=false,-1,-1,-1,-1,nil,nil,nil
local stats={writes=0,dbWrites=0,parses=0,panels=0,unsignedReads=0,idSets=0}
local execute=loadstring or load
local exported={id=true,active=true,opened=true,locked=true,movable=true,x=true,y=true,w=true,h=true,x_real=true,y_real=true,w_real=true,h_real=true,
 hardtext=true,textid=true,textid_dblink=true,color=true,tooltip=true,on_active=true,on_active_params=true,on_deactive=true,on_deactive_params=true}
local function nativeCoords()
 for i=1,9 do
  local id=CARD..i;local p=R[id]
  if p and p.setup then
   local h=R[id..':header_opened']
   p.w_real=p.w;p.h=h.h;p.h_real=h.h
   p.x_real=p.x;p.y_real=p.y-p.h_real
   h.active=p.opened;h.x_real=p.x;h.y_real=p.y-h.h;h.w_real=p.w;h.h_real=h.h
   for _,suffix in ipairs({'target_button','target_top','target_bottom','target_rim','grip','grip_h','grip_v'}) do
    local b=R[id..':header_opened:'..suffix]
    if b then b.x_real=h.x_real+b.x;b.y_real=p.y+b.y-b.h;b.w_real=b.w;b.h_real=b.h end
   end
   local mover=R[id..':mover']
   if mover then
    -- NeL overwrites width on every container update, not height/y. TM TM.
    mover.w=p.w-8;mover.w_real=mover.w;mover.h_real=mover.h
    mover.x_real=p.x+4;mover.y_real=p.y+mover.y-mover.h
   end
  end
 end
end
local add
add=function(id,attrs)
 local p={};for k,v in pairs(attrs or {}) do p[k]=v end
 p.id=id;p.textid_dblink=p.dbBinding or '';p.initialized=false
 for _,k in ipairs({'x','y','w','h','x_real','y_real','w_real','h_real','textid'}) do p[k]=p[k] or 0 end
 for _,k in ipairs({'hardtext','color','tooltip','on_active','on_active_params','on_deactive','on_deactive_params'}) do p[k]=p[k] or '' end
 if p.active==nil then p.active=true end
 if p.locked==nil then p.locked=false end
 -- Dynamic XML stores OpenAtStart; it does NOT open the container.
 if p.type=='container' then p.opened=false;p.setup=false end
 local methods={
  find=function(_,child)return U[id..':'..child]end,
  addGroup=function(_,child)assert(U[child.id])end,
  setLineMaxW=function(_,v)assert(type(v)=='number');stats.writes=stats.writes+1 end,
  invalidateCoords=function()end,
  updateCoords=function()
   if p.type=='container' and p.movable and not U[id..':mover'] then add(id..':mover',{type='mover',y=-4,h=22}) end
   p.setup=true;nativeCoords()
  end
 }
 local obj=setmetatable({}, {
  __index=function(_,k)
   if k=='textid' then stats.unsignedReads=stats.unsignedReads+1;error('UInt32 getter triggers native STOP') end
   if methods[k] then return methods[k] end
   assert(exported[k],'Unexported property '..tostring(k)..' on '..id)
   return p[k]
  end,
  __newindex=function(_,k,v)
   assert(exported[k],'Unexported property '..tostring(k)..' on '..id)
   if k=='textid' then
    assert(p.type=='text_id' and p.textid_dblink=='','DB-bound text ID write')
    assert(type(v)=='number' and v>=0 and v<=4294967295 and v==math.floor(v))
    if p.textid~=v then p.initialized=false end
    stats.idSets=stats.idSets+1
   end
   if k=='opened' then assert(p.setup,'Open before native setup') end
   local old=p[k];p[k]=v;stats.writes=stats.writes+1
   if k=='opened' then nativeCoords() end
   if k=='active' and old~=v then
    local ah=v and p.on_active or p.on_deactive
    local params=v and p.on_active_params or p.on_deactive_params
    if ah=='lua' and params~='' then assert(execute(params))() end
   end
  end
 })
 U[id],R[id]=obj,p
 return obj
end
local function materialize(def)
 for id,p in pairs(def) do assert(not U[id],'Duplicate UI id');add(id,p) end
end
function getUI(id)return U[id]end
function getDbProp(p)return D[p] or 0 end
function addDbProp(p,v)assert(p:match('^UI:SAVE:'));D[p]=v end
function setDbProp(p,v)assert(p:match('^UI:') and D[p]~=nil,'Invalid DB write '..p);D[p]=v;stats.dbWrites=stats.dbWrites+1 end
function isPlayerReady()return game.InGameDbInitialized end
function getPlayerName()assert(isPlayerReady(),'Early player access');return ownName end
function getTargetName()return 'No target'end
function getWindowSize()return sw,sh end
function getMouseDown()return mouse,px,py end
function getMousePos()return mx,my end
function getCurrentWindowUnder()return over end
function getUICaller()return caller end
function debugInfo()end
function displaySystemInfo()end
function setOnDraw(w,s)hooks[w.id]=s end
function parseInterfaceFromString(s)
 assert(s:find('padui_team_member9',1,true));materialize(fixture.roots);stats.parses=stats.parses+1;return true
end
function createGroupInstance(name,parent)
 assert(name=='padui_modular_team_settings' and parent==PAGE)
 materialize(fixture.panel);stats.panels=stats.panels+1;return U[PAGE..':modular_team']
end
function runAH(_,ah,params)
 assert(not params:find('SERVER:',1,true),'Never write SERVER through an action')
 actions[#actions+1]={ah,params}
end
PadUI={language=function()return 'en'end,accent=function(_,a)return '110 235 225 '..tostring(a or 255)end,tr=function(_,k)return k end}
PadUISettings={windows={{'team_compact','TEAM_COMPACT','team'}},texts=function()return {team='Team'}end,withTransparency=function(_,v)return v end,
 refresh=function()U['ui:interface:padui_settings:content:page1:window1_text'].hardtext=U[LEGACY].active and '[x] Team' or '[ ] Team'end,
 toggleWindow=function()error('Legacy toggle not intercepted')end}
game={InGameDbInitialized=false}
add(LEGACY,{active=true,x_real=24,y_real=900,h_real=50})
for i=0,7 do add(LEGACY..':content:name_source'..i,{})end
add('ui:interface:team_list',{active=false});add(PAGE,{})
add('ui:interface:padui_settings:content:page1:window1_text',{})
for _,id in ipairs({'team_layout_text','team_layout0','team_layout0_text','team_layout0_back','team_layout1','team_layout1_text','team_layout1_back','team_scale_text','team_scale_slider','team_scale_value','item_layout_text','timer_scale_text','timer_scale_slider','timer_scale_value','layout_note'})do add(PAGE..':'..id,{})end
for i=0,2 do for _,suffix in ipairs({'','_back','_text'})do add(PAGE..':item_layout'..i..suffix,{})end end
D['UI:VARIABLES:ISACTIVE:TEAM_COMPACT']=1;D['UI:SAVE:PADUI:TEAM_SCALE']=100;D['UI:SAVE:PADUI:TEAM_LAYOUT']=0
D['UI:SAVE:PADUI:HIDE_SELF']=0;D['UI:SAVE:TEAM_COMPACT:SORT']=0;D['UI:SAVE:PADUI:FONT_DELTA']=0
for _,k in ipairs({'HP','SAP','STA'})do D['UI:VARIABLES:USER:'..k..'_RATIO']=1024 end
D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']=0
local function syncNames()
 for i=0,7 do
  local n=R[DRIVER..':name_source'..i]
  if n and not n.initialized then n.hardtext=strings[n.textid] or '';n.initialized=strings[n.textid]~=nil end
 end
end
local function frame(sameTick)
 if not sameTick then D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']=D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']+100 end
 nativeCoords();syncNames();RyzomTeamUI:update();nativeCoords()
 assert(not RyzomTeamUI.failed,RyzomTeamUI.failed)
end
local function populate(n)
 for i=0,7 do
  local p='SERVER:GROUP:'..i..':'
  D[p..'NAME']=i<n and 100+i or 0;D[p..'UID']=i<n and 200+i or 0;D[p..'PRESENT']=1
  strings[100+i]='Member'..i
  for _,k in ipairs({'HP','SAP','STA'})do D['UI:VARIABLES:BARS:TEAM:'..i..':'..k]=127 end
 end
end
local function member(uid)for _,v in ipairs(RyzomTeamUI.cards)do if v.member and v.member.uid==uid then return v end end end
local function visible()
 local n=0
 for i=1,9 do
  local p=R[CARD..i];local h=R[CARD..i..':header_opened']
  if p and p.active and p.opened and h.active and p.h_real>0 and p.y_real>=0 and p.y_real+p.h_real<=sh then n=n+1 end
 end
 return n
end
local function state()local t=RyzomTeamUI;return {t.stats.sorts,t.stats.layouts,stats.writes,stats.dbWrites,stats.idSets}end
local function unchanged(a)local b=state();for i=1,#a do assert(a[i]==b[i],'State counter '..i..' changed')end end
local function hit(b,x,y)return b and b.active and x>=b.x_real and x<b.x_real+b.w_real and y>b.y_real and y<=b.y_real+b.h_real end
local function press(v,offsetY,doFrame)
 nativeCoords();local b=R[v.nodes.target_button.id]
 px=b.x_real+30;py=b.y_real+b.h_real-(offsetY or 5)
 mx,my,mouse,over,capture=px,py,true,v.window,v.nodes.target_button
 if doFrame~=false then frame(true)end
end
local nativeStart
local function pick(v,x,y)
 if not v.window.active or not v.window.opened then return nil end
 -- Descendant controls beat the root mover; decorative views never capture.
 for _,id in ipairs({'target_button','target_top','target_bottom','target_rim'}) do
  if hit(R[v.nodes[id].id],x,y) then return v.nodes[id] end
 end
 if hit(R[v.nodes.mover.id],x,y) and not v.window.locked then return v.nodes.mover end
end
local function pressGrip(v,doFrame)
 nativeCoords();local g=R[v.nodes.grip.id]
 px,py=g.x_real+g.w_real/2,g.y_real+g.h_real/2
 mx,my,mouse,over=px,py,true,v.window
 capture=pick(v,px,py)
 assert(capture==v.nodes.mover,'Grip is not accessible to native capture')
 nativeStart={v=v,x=v.window.x,y=v.window.y}
 -- Run the actual generated XML handler, before the next frame.
 caller=capture;assert(execute(R[v.window.id].on_begin_move_params))();caller=nil
 if doFrame~=false then frame(true) end
end
local function move(dx,dy,doFrame)
 mx,my=px+dx,py+dy
 if capture and R[capture.id].type=='mover' and nativeStart then
  local v=nativeStart.v
  if v.window.active and not v.window.locked then
   v.window.x=nativeStart.x+dx;v.window.y=nativeStart.y+dy
   caller=capture;assert(execute(R[v.window.id].on_move_params))();caller=nil
   nativeCoords()
  end
 end
 if doFrame~=false then frame(true)end
end
local function release(doClick,frameFirst)
 mouse=false
 if frameFirst then frame(true)end
 if doClick~=false and capture and R[capture.id].type~='mover' then
  local b=R[capture.id]
  local winId=capture.id:match('^(.-):header_opened:')
  if R[winId].active and hit(b,mx,my) then
   caller=capture;assert(execute(b.params_l))();caller=nil
  end
 end
 capture=nil;nativeStart=nil;frame(true)
end
local function unlock(t)if D[SAVE..'LOCKED']==1 then t:toggleLock();nativeCoords()end end
local function lock(t)if D[SAVE..'LOCKED']==0 then t:toggleLock();nativeCoords()end end
local count=0
local function test(name,fn)
 local ok,err=pcall(fn);if not ok then error('FAIL '..name..': '..tostring(err))end
 count=count+1;print('PASS '..name)
end
populate(0);dofile('user/team_compact.lua')
local T=RyzomTeamUI

test('startup guard makes no early player/native GUI calls',function()T:update();assert(stats.parses==0)end)
test('all balanced layouts: 0..9 members, both directions, 1..9 tracks',function()
 for n=0,9 do for mode=0,1 do for tracks=1,9 do
  local p,c,r=T:grid(n,mode,tracks);assert(#p==n)
  if n==0 then assert(c==0 and r==0)else
   assert((mode==0 and c or r)==math.min(n,tracks));local used={}
   for _,v in ipairs(p)do local k=v.x..':'..v.y;assert(not used[k] and v.x<c and v.y<r);used[k]=true end
  end
 end end end
 local p=T:grid(7,0,2);assert(p[4].y==3 and p[5].x==1)
 p=T:grid(7,1,2);assert(p[4].x==3 and p[5].y==1)
end)
test('nine reused native windows, explicitly opened, one frame controller',function()
 game.InGameDbInitialized=true;frame();frame()
 assert(visible()==1 and stats.parses==1 and stats.panels==1)
 for _,v in ipairs(T.cards)do assert(v.window.opened and v.window.movable)end
 assert(hooks[DRIVER]=='RyzomTeamUI:update()' and hooks[LEGACY]=='')
end)
test('visibility checkbox and native window-manager toggle agree',function()
 PadUISettings:refresh();assert(U['ui:interface:padui_settings:content:page1:window1_text'].hardtext=='[x] Team')
 PadUISettings:toggleWindow(1);assert(visible()==0)
 U[LEGACY].active=true;nativeCoords();assert(visible()==1 and not U[LEGACY].active)
end)
test('hidden team stops collecting data',function()
 T:toggle();local n=T.stats.polls;for i=1,20 do frame()end;assert(T.stats.polls==n);T:toggle();nativeCoords()
end)
test('DE EN FR lock labels and XML action handlers',function()
 for _,def in ipairs({fixture.roots,fixture.panel})do for _,p in pairs(def)do
  for _,side in ipairs({'l','r'})do if p['onclick_'..side]=='lua' then assert(execute(p['params_'..side]))end end
 end end
 for _,lang in ipairs({'de','fr','en'})do PadUI.language=function()return lang end;PadUISettings:refresh();assert(U[PAGE..':modular_team:lock:text'].hardtext:find('LOCK',1,true))end
end)
test('delayed invitation names never use the UInt32 getter',function()
 populate(1);strings[100]=nil;frame();frame();assert(visible()==1)
 strings[100]='Member0';frame();assert(visible()==2 and stats.unsignedReads==0)
end)
test('signed high-bit name ID uses only the unbound setter',function()
 D['SERVER:GROUP:0:NAME']=-2147483647;strings[2147483649]='HighBit';frame();frame()
 assert(member(200).member.name=='HighBit' and D['SERVER:GROUP:0:NAME']==-2147483647)
end)
test('rapid slot reuse discards previous member identity',function()
 populate(1);frame();frame();local old=member(200).member
 D['SERVER:GROUP:0:UID']=777;D['SERVER:GROUP:0:NAME']=777;strings[777]='Replacement'
 frame();assert(not member(200) and not T:validMember(old));frame();assert(member(777))
end)
test('all group sizes and optional self',function()
 for n=0,8 do populate(n);frame();frame();assert(visible()==n+1)end
 T:toggleSelf();nativeCoords();assert(visible()==8);populate(0);frame();assert(visible()==0)
 T:toggleSelf();populate(8);frame();frame();assert(visible()==9)
end)
test('steady state: no extra sorts, layouts, UI/DB/text-ID writes',function()
 frame();local s=state();for i=1,200 do frame()end;unchanged(s)
end)
test('same-tick hook does not collect twice',function()local n=T.stats.polls;frame(true);frame(true);assert(T.stats.polls==n)end)
test('HP changes update bars without a name sort or relayout',function()
 local v=member(200);local s,l,w=T.stats.sorts,T.stats.layouts,v.nodes.hp_fill.w
 D['UI:VARIABLES:BARS:TEAM:0:HP']=64;frame();assert(v.nodes.hp_fill.w<w and T.stats.sorts==s and T.stats.layouts==l)
end)
test('HP sort keeps member-to-window identity',function()
 T:setSort('hp');local v=member(200);D['UI:VARIABLES:BARS:TEAM:0:HP']=1;frame()
 assert(member(200)==v and T.ordered[#T.ordered].uid==200)
 local l=T.stats.layouts;D['UI:VARIABLES:BARS:TEAM:0:HP']=2;frame();assert(T.stats.layouts==l)
 T:setSort('name')
end)
test('horizontal and vertical tracks produce non-overlapping rectangles',function()
 for mode=0,1 do T:setLayout(mode)
  for tracks=1,4 do D[SAVE..(mode==0 and 'COLUMNS' or 'ROWS')]=tracks;T:requestUpdate();nativeCoords()
   for i,a in ipairs(T.cards)do if a.member then for j=i+1,9 do local b=T.cards[j]
    if b.member then assert(a.x+T.cellW<=b.x or b.x+T.cellW<=a.x or a.y-T.cellH>=b.y or b.y-T.cellH>=a.y)end
   end end end
  end
 end
end)
test('native BL TL positions equal saved top offsets plus screen height',function()
 for _,v in ipairs(T.cards)do if v.member then assert(v.window.y==sh+v.y and v.window.y_real==sh+v.y-T.cellH)end end
end)
test('free positions survive switching layouts and changing HP',function()
 T:setLayout(2);nativeCoords();local v=member(200);local x,y=v.x,v.y
 D['UI:VARIABLES:BARS:TEAM:0:HP']=127;frame();T:setLayout(0);T:setLayout(2)
 assert(v.x==x and v.y==y and D[SAVE..'FREE:'..v.slot..':SET']==1)
end)
test('name click targets while LOCK is on',function()
 lock(T);local v=member(200);local x,y=v.x,v.y;local n=#actions
 press(v);release();assert(#actions==n+1 and actions[#actions][1]=='team_target')
 assert(v.x==x and v.y==y)
end)
test('name click targets while LOCK is off',function()
 unlock(T);local v=member(200);local x,y=v.x,v.y;local n=#actions
 press(v);release();assert(#actions==n+1 and actions[#actions][2]==tostring(v.member.index))
 assert(v.x==x and v.y==y)
end)
test('small mouse jitter remains a click, without moving a window',function()
 local v=member(200);local x,y=v.x,v.y;local n=#actions
 press(v);move(2,1);release();assert(#actions==n+1 and v.x==x and v.y==y)
end)
test('free drag moves only that card and does not change target',function()
 local v,b=member(200),member(201);local x,y,bx,by=v.x,v.y,b.x,b.y;local n=#actions
 pressGrip(v);move(20,-30);assert(v.x==x+20 and v.y==y-30 and b.x==bx and b.y==by)
 release();assert(#actions==n and D[SAVE..'FREE:'..v.slot..':X']==v.x)
end)
test('drag back to the starting point is not a target click',function()
 local v=member(200);local n=#actions;pressGrip(v);move(30,-10);move(0,0);release();assert(#actions==n)
end)
test('a long hold without motion still selects on release',function()
 local v=member(200);local n=#actions;press(v);for i=1,20 do frame()end;release();assert(#actions==n+1)
end)
test('resource-bar press cannot start a drag and remains selectable',function()
 local v=member(200);local x,y=v.x,v.y;local n=#actions
 press(v,20);move(20,0);release();assert(v.x==x and v.y==y and #actions==n+1)
end)
test('LOCK prevents name drag but not name selection',function()
 lock(T);local v=member(200);local x,y=v.x,v.y;local n=#actions
 press(v);move(12,0);release();assert(v.x==x and v.y==y and #actions==n+1);unlock(T)
end)
test('automatic mode drags all cards together, preserving free layout',function()
 local v,b=member(200),member(201);local fx,fy=v.x,v.y;T:setLayout(0);nativeCoords()
 local x,y,bx,by=v.x,v.y,b.x,b.y;local n=#actions
 pressGrip(v);move(20,-10);assert(v.x==x+20 and b.x==bx+20 and b.y==by-10);release();assert(#actions==n)
 T:setLayout(2);nativeCoords();assert(v.x==fx and v.y==fy)
end)
test('last mouse-up position is applied even without a final move frame',function()
 local v=member(200);local x=v.x;local n=#actions
 pressGrip(v);move(20,0);move(30,0,false);release();assert(v.x==x+30 and #actions==n)
end)
test('release-frame before click callback cannot target after dragging',function()
 local v=member(200);local n=#actions;pressGrip(v);move(10,0);release(true,true);assert(#actions==n)
end)
test('quick native click between frames is still a target click',function()
 local v=member(200);local n=#actions;press(v,5,false);release();assert(#actions==n+1)
end)
test('quick drag between frames is not mistaken for a target click',function()
 local v=member(200);local x=v.x;local n=#actions;pressGrip(v,false);move(12,0,false);release()
 assert(v.x==x+12 and #actions==n)
end)
test('mouse release outside the old button still finishes and saves a drag',function()
 local v=member(200);local n=#actions;pressGrip(v);move(20,-10);move(100,-70,false);release(false)
 assert(not T.dragging and D[SAVE..'FREE:'..v.slot..':Y']==v.y and #actions==n)
end)
test('next quick click is not swallowed after releasing outside a button',function()
 local v=member(200);pressGrip(v);move(20,0);release(false)
 local other=member(201);local n=#actions;press(other,5,false);release()
 assert(#actions==n+1 and actions[#actions][2]==tostring(other.member.index))
end)
test('holding an automatic grid at a screen edge does not repeat layouts',function()
 T:setLayout(0);nativeCoords();local v=member(200);pressGrip(v);move(10000,-10000)
 local n=T.stats.layouts;for i=1,20 do frame(true)end;assert(T.stats.layouts==n)
 release();T:setLayout(2);nativeCoords()
end)
test('no accidental drag through an overlapping UI window',function()
 local v=member(200);local x,y=v.x,v.y;press(v,5,false);over=U[PAGE];frame(true);move(20,0);release(false)
 assert(v.x==x and v.y==y)
end)
test('mouse-down in the world cannot become a name drag when moved over UI',function()
 local v=member(200);local x,y=v.x,v.y
 mouse=true;px,py,mx,my=1,1,1,1;over=nil;frame(true)
 over=v.window;mx,my=v.window.x_real+30,v.window.y-5;frame(true);release(false)
 assert(v.x==x and v.y==y)
end)
test('name right-click keeps the member context menu',function()
 local v=member(200);caller=v.nodes.target_button;T:click(v.slot,'right');caller=nil
 assert(actions[#actions][1]=='active_menu' and T.menuMember.uid==200)
end)
test('HP sort does not move cards underneath a held name button',function()
 T:setLayout(0);T:setSort('hp');nativeCoords();local v=member(200);press(v);local x,y=v.x,v.y
 D['UI:VARIABLES:BARS:TEAM:'..v.member.index..':HP']=1;frame();assert(v.x==x and v.y==y)
 release();T:setSort('name');T:setLayout(2);nativeCoords()
end)
test('replacing a member while held cannot select or move the replacement',function()
 local v=member(200);local n=#actions;press(v)
 D['SERVER:GROUP:0:UID']=888;D['SERVER:GROUP:0:NAME']=888;strings[888]='NewMember'
 frame();frame();move(20,0);release();assert(#actions==n)
 populate(8);frame();frame()
end)
test('context-menu snapshot cannot target a replacement',function()
 local v=member(200);T:click(v.slot,'right');local n=#actions
 D['SERVER:GROUP:0:UID']=989;T:menuAction('select');assert(#actions==n)
 populate(8);frame();frame()
end)
test('absent member clicks are rejected',function()
 local v=member(201);D['SERVER:GROUP:'..v.member.index..':PRESENT']=0;local n=#actions
 press(v);release();assert(#actions==n);D['SERVER:GROUP:'..v.member.index..':PRESENT']=1;frame()
end)
test('server slot reorder preserves free window identity',function()
 local v=member(200);local x,y=v.x,v.y
 for _,k in ipairs({'UID','NAME','PRESENT'})do D['SERVER:GROUP:0:'..k],D['SERVER:GROUP:7:'..k]=D['SERVER:GROUP:7:'..k],D['SERVER:GROUP:0:'..k]end
 frame();frame();assert(member(200)==v and v.x==x and v.y==y)
 populate(8);frame();frame()
end)
test('turning LOCK on during a drag stops movement and swallows release',function()
 local v=member(200);local n=#actions;pressGrip(v);move(10,0);lock(T);local x,y=v.x,v.y
 move(20,0);release();assert(v.x==x and v.y==y and #actions==n);unlock(T)
end)
test('changing layout during a drag never targets a member',function()
 local v=member(200);local n=#actions;pressGrip(v);move(10,0);T:setLayout(1);nativeCoords();release();assert(#actions==n)
 T:setLayout(2);nativeCoords()
end)
test('hiding team cancels a held gesture',function()
 local v=member(200);local n=#actions;press(v);T:toggle();release(false);assert(#actions==n and visible()==0)
 T:toggle();nativeCoords()
end)
test('all scales and font offsets keep the whole locked card selectable',function()
 lock(T)
 for _,scale in ipairs({75,100,125,150})do for _,delta in ipairs({-1,0,1})do
  D['UI:SAVE:PADUI:TEAM_SCALE']=scale;D['UI:SAVE:PADUI:FONT_DELTA']=delta;frame()
  assert(T.cellW==2*scale)
  for _,v in ipairs(T.cards)do assert(v.nodes.target_button.x==0 and v.nodes.target_button.w==T.cellW and v.nodes.target_button.h==T.cellH)end
  local s=state();frame();unchanged(s)
 end end
 D['UI:SAVE:PADUI:TEAM_SCALE']=100;D['UI:SAVE:PADUI:FONT_DELTA']=0;frame();unlock(T)
end)
test('viewport resize while held cancels drag rather than saving resize as motion',function()
 local v=member(200);local n=#actions;pressGrip(v);sw,sh=1600,900;frame();move(30,0);release(false);assert(#actions==n)
 sw,sh=1920,1080;frame()
end)
test('free drag clamps to screen edges and persists clamped coordinates',function()
 local v=member(200);pressGrip(v);move(10000,-10000);release()
 assert(v.x==sw-T.cellW and v.y==-(sh-T.cellH))
 assert(D[SAVE..'FREE:'..v.slot..':X']==v.x and D[SAVE..'FREE:'..v.slot..':Y']==v.y)
 T:resetPositions();nativeCoords()
end)
test('position reset leaves size preference untouched',function()
 local scale=D['UI:SAVE:PADUI:TEAM_SCALE'];T:resetPositions();nativeCoords();assert(D['UI:SAVE:PADUI:TEAM_SCALE']==scale)
end)
test('every unlocked card pixel is a target area or the native grip at every scale',function()
 for _,scale in ipairs({75,100,125,150}) do
  D['UI:SAVE:PADUI:TEAM_SCALE']=scale;frame();unlock(T)
  local v=member(200);local g=R[v.nodes.grip.id]
  assert(g.w_real>=16 and g.h_real>=16)
  for x=0,T.cellW-1 do for y=0,T.cellH-1 do
   local sx,sy=v.window.x+x+0.5,v.window.y-y-0.5
   local control=pick(v,sx,sy)
   assert(control,'Uncovered card pixel')
   assert((control==v.nodes.mover)==hit(g,sx,sy),'Target button obscures grip or exposes another drag region')
  end end
  lock(T);nativeCoords()
  assert(not v.nodes.grip.active and not v.nodes.mover.active)
  assert(pick(v,g.x_real+5,g.y_real+5)==v.nodes.target_button)
 end
 D['UI:SAVE:PADUI:TEAM_SCALE']=100;frame();unlock(T)
end)
test('native dragging does not wait for a frame or a hover-window match',function()
 local v=member(200);local x,y=v.x,v.y
 pressGrip(v,false);over=nil
 move(1,-1,false)
 assert(v.x==x+1 and v.y==y-1 and T.nativeDrag)
 release();assert(not T.nativeDrag)
end)
test('repeated one-pixel native drags start immediately',function()
 local v=member(200);local x=v.x;local n=#actions
 for i=1,100 do pressGrip(v,false);over=nil;move(1,0,false);release() end
 assert(v.x==x+100 and #actions==n)
end)
test('native moves do not persist positions before mouse release',function()
 local v=member(200);local n=stats.dbWrites
 pressGrip(v);move(3,0);move(6,0);move(9,0)
 assert(stats.dbWrites==n)
 release();assert(stats.dbWrites>n and D[SAVE..'FREE:'..v.slot..':X']==v.x)
end)
test('an unlocked name press never moves a card even beyond the former threshold',function()
 local v=member(200);local x,y=v.x,v.y;local n=#actions
 press(v);move(30,0);release()
 assert(v.x==x and v.y==y and #actions==n+1)
end)
test('all four target rectangles select the same member',function()
 local v=member(200)
 for _,id in ipairs({'target_button','target_top','target_bottom','target_rim'}) do
  nativeCoords();local b=R[v.nodes[id].id]
  if b.h_real>0 then
   px,py=b.x_real+b.w_real/2,b.y_real+b.h_real/2
   mx,my,mouse,over,capture=px,py,true,v.window,pick(v,px,py)
   local n=#actions;frame(true);release()
   assert(#actions==n+1 and actions[#actions][2]==tostring(v.member.index))
  end
 end
end)

test('module reload reuses windows without stacking settings wrappers',function()
 local refresh=PadUISettings.refresh;dofile('user/team_compact.lua');T=RyzomTeamUI;frame();frame()
 assert(stats.parses==1 and stats.panels==1 and PadUISettings.refresh==refresh and visible()==9)
end)
test('cold restart restores only previously declared per-character leaves',function()
 T:savePositions();local saved={};for k,v in pairs(D)do if k:match('^UI:SAVE:')then saved[k]=v end end
 game.InGameDbInitialized=false;T:update();for k in pairs(D)do if k:sub(1,#SAVE)==SAVE then D[k]=nil end end
 dofile('user/team_compact.lua');T=RyzomTeamUI;assert(D[SAVE..'FREE:9:Y']~=nil)
 for k,v in pairs(saved)do if D[k]~=nil then D[k]=v end end
 game.InGameDbInitialized=true;frame();frame();assert(visible()==9 and T:mode()==2)
end)
test('changing character drops previous member identities',function()
 game.InGameDbInitialized=false;T:update();ownName='SecondCharacter';populate(0)
 for k in pairs(D)do if k:sub(1,#SAVE)==SAVE then D[k]=0 end end
 R[LEGACY].active=true;game.InGameDbInitialized=true;frame();assert(visible()==1 and T.rows[1].self)
end)
test('hot reload from old XML requires restart before name-ID writes',function()
 local n=U[DRIVER..':corner_drag_v2'];U[DRIVER..':corner_drag_v2']=nil;local sets=stats.idSets
 dofile('user/team_compact.lua');T=RyzomTeamUI;T:update()
 assert(T.failed and T.failed:find('fully restart Ryzom',1,true) and stats.idSets==sets)
 U[DRIVER..':corner_drag_v2']=n
end)
test('DB-bound prototype is rejected before assigning text IDs',function()
 R[DRIVER..':name_source0'].textid_dblink='SERVER:GROUP:0:NAME';local sets=stats.idSets
 dofile('user/team_compact.lua');T=RyzomTeamUI;T:update();assert(T.failed and stats.idSets==sets)
 R[DRIVER..':name_source0'].textid_dblink=''
end)
test('no UInt32 getter was used anywhere',function()assert(stats.unsignedReads==0)end)
test('missing native pointer API fails safely to native team window',function()
 dofile('user/team_compact.lua');T=RyzomTeamUI;local keep=getCurrentWindowUnder;getCurrentWindowUnder=nil
 T:update();nativeCoords();assert(T.failed and U['ui:interface:team_list'].active and visible()==0);getCurrentWindowUnder=keep
end)
print(string.format('PASS all %d regression cases (%s)',count,_VERSION))
