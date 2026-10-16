-- Regression tests with strict native-UI stand-ins; not a NeL renderer test.
local fixture=dofile(assert(arg[1], 'Run through tests/run_team_tests.py'))
local U,D,strings,actions,hooks={}, {}, {}, {}, {}
local ownName,mouse,sw,sh='SelfTest',false,1920,1080
local backend={writes=0,dbWrites=0,lookups=0,parses=0,panels=0}
local SAVE='UI:SAVE:PADUI:TEAM_MODULAR:'
local LEGACY='ui:interface:team_compact'
local DRIVER='ui:interface:padui_team_driver'
local PAGE='ui:interface:padui_settings:content:page3'
local CARD='ui:interface:padui_team_member'
local copy
copy=function(t) local c={};for k,v in pairs(t) do c[k]=type(v)=='table' and copy(v) or v end;return c end
local exported={id=true,active=true,x=true,y=true,w=true,h=true,x_real=true,y_real=true,w_real=true,h_real=true,locked=true,hardtext=true,textid=true,color=true,tooltip=true,on_active=true,on_active_params=true,on_deactive=true,on_deactive_params=true}
local execute=loadstring or load
local function node(id,attrs)
 local p=copy(attrs or {})
 p.id=id
 for _,k in ipairs({'x','y','w','h','x_real','y_real','w_real','h_real','textid'}) do p[k]=p[k] or 0 end
 if p.active==nil then p.active=true end
 if p.locked==nil then p.locked=false end
 for _,k in ipairs({'hardtext','color','tooltip','on_active','on_active_params','on_deactive','on_deactive_params'}) do p[k]=p[k] or '' end
 local methods={
  find=function(self,child) return U[id..':'..child] end,
  addGroup=function(self,child) assert(U[child.id]);p.added=child.id end,
  invalidateCoords=function() p.invalid=(p.invalid or 0)+1 end,
  setLineMaxW=function(self,w) assert(type(w)=='number');p.lineMaxW=w;backend.writes=backend.writes+1 end
 }
 local obj=setmetatable({}, {
  __index=function(_,key)
   if methods[key] then return methods[key] end
   assert(exported[key], 'Unexported Lua UI property '..tostring(key)..' on '..id)
   return p[key]
  end,
  __newindex=function(_,key,value)
   assert(exported[key], 'Unexported Lua UI property '..tostring(key)..' on '..id)
   assert(key~='textid', 'Do not assign a SERVER-bound textid')
   local old=p[key];p[key]=value;backend.writes=backend.writes+1
   if key=='active' and old~=value then
    local handler=value and p.on_active or p.on_deactive
    local params=value and p.on_active_params or p.on_deactive_params
    if handler=='lua' and params~='' then assert(execute(params))() end
   end
  end
 })
 U[id]=obj
 return obj,p
end
local raw={}
local function add(id,props) local n,p=node(id,props);raw[id]=p;return n end
local function materialize(def)
 for id,props in pairs(def) do assert(not U[id], 'duplicate native id '..id);add(id,props) end
end
function getUI(id) backend.lookups=backend.lookups+1;return U[id] end
function getDbProp(p) return D[p] or 0 end
function addDbProp(p,v) assert(p:match('^UI:SAVE:'),p);D[p]=v end
function setDbProp(p,v)
 assert(p:match('^UI:'), 'SERVER write '..p)
 assert(D[p]~=nil, 'undeclared DB '..p)
 D[p]=v;backend.dbWrites=backend.dbWrites+1
end
function getPlayerName() assert(game.InGameDbInitialized,'early player access');return ownName end
function isPlayerReady() return game.InGameDbInitialized end
function getTargetName() return 'No target' end
function getWindowSize() return sw,sh end
function getMouseDown() return mouse end
function getUICaller() return nil end
function debugInfo() end
function displaySystemInfo() end
function setOnDraw(w,code) assert(w);hooks[w.id]=code end
function parseInterfaceFromString(xml)
 assert(xml:find('padui_team_member9',1,true))
 backend.parses=backend.parses+1;materialize(fixture.roots);return true
end
function createGroupInstance(name,parent,params)
 assert(name=='padui_modular_team_settings' and parent==PAGE)
 backend.panels=backend.panels+1;materialize(fixture.panel)
 return U[PAGE..':modular_team']
end
function runAH(caller,handler,params)
 actions[#actions+1]={handler,params}
 assert(handler~='set' or not params:find('SERVER:',1,true),'SERVER action')
end
PadUI={language=function()return 'en'end,accent=function(_,alpha)return '110 235 225 '..tostring(alpha or 255)end,tr=function(_,key)return key end}
PadUISettings={windows={{'team_compact','TEAM_COMPACT','team'}},texts=function()return {team='Team'}end,withTransparency=function(_,c)return c end,
 refresh=function()
  U['ui:interface:padui_settings:content:page1:window1_text'].hardtext=U[LEGACY].active and '[x] Team' or '[ ] Team'
 end,
 toggleWindow=function() error('Legacy toggle must be intercepted') end}
game={InGameDbInitialized=false}
add(LEGACY,{active=true,x_real=24,y_real=900,h_real=50})
for i=0,7 do add(LEGACY..':content:name_source'..i,{hardtext=''}) end
add('ui:interface:team_list',{active=false})
add(PAGE,{})
add('ui:interface:padui_settings:content:page1:window1_text',{})
for _,id in ipairs({'team_layout_text','team_layout0','team_layout0_text','team_layout0_back','team_layout1','team_layout1_text','team_layout1_back','team_scale_slider','team_scale_text','team_scale_value','item_layout_text','timer_scale_text','timer_scale_slider','timer_scale_value','layout_note'}) do add(PAGE..':'..id,{}) end
for i=0,2 do for _,suffix in ipairs({'','_back','_text'}) do add(PAGE..':item_layout'..i..suffix,{}) end end
D['UI:VARIABLES:ISACTIVE:TEAM_COMPACT']=1
D['UI:SAVE:PADUI:TEAM_SCALE']=100
D['UI:SAVE:PADUI:TEAM_LAYOUT']=0
D['UI:SAVE:PADUI:HIDE_SELF']=0
D['UI:SAVE:TEAM_COMPACT:SORT']=0
D['UI:VARIABLES:USER:HP_RATIO']=1024
D['UI:VARIABLES:USER:SAP_RATIO']=1024
D['UI:VARIABLES:USER:STA_RATIO']=1024
D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']=0
local function syncNames()
 for i=0,7 do
  local n=raw[DRIVER..':name_source'..i]
  if n then
   n.textid=D['SERVER:GROUP:'..i..':NAME'] or 0
   n.hardtext=strings[n.textid] or ''
  end
 end
end
local function frame()
 D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']=D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']+100
 syncNames();RyzomTeamUI:update()
 assert(not RyzomTeamUI.failed,RyzomTeamUI.failed)
end
local function populate(n)
 for i=0,7 do
  local p='SERVER:GROUP:'..i..':'
  D[p..'NAME']=i<n and 100+i or 0
  D[p..'UID']=i<n and 200+i or 0
  D[p..'PRESENT']=1
  strings[100+i]='Member'..i
  for _,score in ipairs({'HP','SAP','STA'}) do D['UI:VARIABLES:BARS:TEAM:'..i..':'..score]=127 end
 end
end
local count=0
local function test(name,fn)
 local ok,err=pcall(fn)
 if not ok then error('FAIL '..name..': '..tostring(err)) end
 count=count+1;print('PASS '..name)
end
local function visible()
 local n=0;for i=1,9 do if U[CARD..i] and U[CARD..i].active then n=n+1 end end;return n
end
local function memberView(uid) for _,v in ipairs(RyzomTeamUI.cards) do if v.member and v.member.uid==uid then return v end end end
local function snapshot(t) return t.stats.sorts,t.stats.layouts,backend.writes,backend.dbWrites end
populate(0)
dofile('user/team_compact.lua')
local T=RyzomTeamUI

test('startup guard makes no early player/native GUI call',function()
 T:update();assert(backend.parses==0 and next(T.cards)==nil)
end)
test('balanced layouts for every count and every track count',function()
 for n=0,9 do for mode=0,1 do for tracks=1,9 do
  local p,c,r=T:grid(n,mode,tracks);assert(#p==n)
  if n==0 then assert(c==0 and r==0) else
   assert((mode==0 and c or r)==math.min(n,tracks))
   local seen,previous={},nil
   for i,v in ipairs(p) do
    assert(v.x>=0 and v.y>=0 and v.x<c and v.y<r)
    local key=v.x..':'..v.y;assert(not seen[key]);seen[key]=true
    if previous then
     assert(mode==0 and (v.x>previous.x or v.y==previous.y+1) or mode==1 and (v.y>previous.y or v.x==previous.x+1))
    end
    previous=v
   end
  end
 end end end
 local v=T:grid(7,0,2);assert(v[4].x==0 and v[4].y==3 and v[5].x==1 and v[5].y==0)
 local h=T:grid(7,1,2);assert(h[4].x==3 and h[4].y==0 and h[5].x==0 and h[5].y==1)
end)
test('nine native windows allocated once, single frame controller',function()
 game.InGameDbInitialized=true;frame();frame()
 assert(T.uiReady and backend.parses==1 and backend.panels==1)
 assert(visible()==1 and not U[LEGACY].active)
 assert(hooks[DRIVER]=='RyzomTeamUI:update()' and hooks[LEGACY]=='')
 local n=0;for _,s in pairs(hooks) do if s~='' then n=n+1 end end;assert(n==1)
end)
test('old visibility and settings checkbox are kept coherent',function()
 PadUISettings:refresh()
 assert(U['ui:interface:padui_settings:content:page1:window1_text'].hardtext=='[x] Team')
 PadUISettings:toggleWindow(1);assert(visible()==0 and D['UI:VARIABLES:ISACTIVE:TEAM_COMPACT']==0)
 U[LEGACY].active=true;assert(visible()==1 and not U[LEGACY].active)
 assert(D['UI:VARIABLES:ISACTIVE:TEAM_COMPACT']==1)
end)
test('hidden team does not scan member data',function()
 T:toggle();local n=T.stats.polls
 for i=1,20 do frame() end
 assert(T.stats.polls==n and visible()==0)
 T:toggle();assert(visible()==1)
end)
test('generated callbacks compile and layout labels support DE/EN/FR',function()
 for _,def in ipairs({fixture.roots,fixture.panel}) do
  for id,p in pairs(def) do for _,side in ipairs({'l','r'}) do
   if p['onclick_'..side]=='lua' then assert(execute(p['params_'..side])) end
  end end
 end
 for _,lang in ipairs({'de','fr','en'}) do
  PadUI.language=function()return lang end
  PadUISettings:refresh()
  assert(#U[PAGE..':modular_team:mode2:text'].hardtext>0)
 end
end)
test('all group sizes including empty group with self hidden',function()
 for n=0,8 do populate(n);frame();assert(visible()==n+1) end
 T:toggleSelf();assert(visible()==8)
 populate(0);frame();assert(visible()==0)
 T:toggleSelf();populate(8);frame();assert(visible()==9)
 assert(backend.parses==1 and backend.panels==1)
end)
test('steady state causes no extra sort, layout, UI setters or DB writes',function()
 frame();local sorts,layouts,writes,dbw=snapshot(T)
 for i=1,200 do frame() end
 assert(T.stats.sorts==sorts and T.stats.layouts==layouts)
 assert(backend.writes==writes,'redundant UI property writes')
 assert(backend.dbWrites==dbw,'writes to saved configuration while idle')
end)
test('second hook in same tick never repeats data collection',function()
 local polls=T.stats.polls
 T:update();T:update();assert(T.stats.polls==polls)
end)
test('HP change updates bars, without layout or name sort',function()
 local v=memberView(200);assert(v)
 local layouts,sorts=T.stats.layouts,T.stats.sorts
 local oldWidth=v.nodes.hp_fill.w
 D['UI:VARIABLES:BARS:TEAM:0:HP']=64;frame()
 assert(v.nodes.hp_fill.w<oldWidth)
 assert(T.stats.layouts==layouts and T.stats.sorts==sorts)
end)
test('HP sorting moves windows but preserves member-window identities',function()
 T:setSort('hp');local v=memberView(200);local slot=v.slot
 D['UI:VARIABLES:BARS:TEAM:0:HP']=1;frame()
 assert(memberView(200).slot==slot)
 assert(T.ordered[#T.ordered].uid==200)
 local s,l=T.stats.sorts,T.stats.layouts
 D['UI:VARIABLES:BARS:TEAM:0:HP']=2;frame()
 assert(T.stats.sorts==s+1 and T.stats.layouts==l,'same order must not relayout')
end)
test('horizontal/vertical track controls produce requested arrangement',function()
 T:setSort('name');T:setLayout(0)
 T:changeTracks(1);assert(T:trackCount(0)==2)
 local a,b=T.cards[T.ordered[1].viewSlot],T.cards[T.ordered[2].viewSlot]
 assert(a.x==b.x and b.y<a.y)
 T:setLayout(1);assert(T:trackCount(1)==2)
 assert(T.cards[T.ordered[1].viewSlot].y==T.cards[T.ordered[2].viewSlot].y)
 for i=1,15 do T:changeTracks(1) end;assert(T:trackCount(1)==9)
 for i=1,15 do T:changeTracks(-1) end;assert(T:trackCount(1)==1)
end)
test('free mode never swaps members on HP changes and restores placement',function()
 T:setLayout(2);local v=memberView(200);local x,y=v.x,v.y
 T:setSort('missing')
 D['UI:VARIABLES:BARS:TEAM:0:HP']=127;frame()
 assert(memberView(200)==v and v.x==x and v.y==y)
 T:setLayout(0);T:setLayout(2)
 assert(v.x==x and v.y==y)
 assert(D[SAVE..'FREE:'..v.slot..':SET']==1)
end)
test('dragging free window does not move any other member',function()
 T:toggleLock();assert(D[SAVE..'LOCKED']==0)
 local v=memberView(200);local other=memberView(201)
 local ox,oy=other.x,other.y
 mouse=true;v.window.x=333;v.window.y=-222;frame()
 assert(v.x==333 and v.y==-222 and other.x==ox and other.y==oy)
 mouse=false;frame();assert(D[SAVE..'FREE:'..v.slot..':X']==333)
end)
test('mouse-up includes the last movement before saving',function()
 local v=memberView(200)
 mouse=true;v.window.x=320;frame()
 mouse=false;v.window.x=333;frame()
 assert(v.x==333 and D[SAVE..'FREE:'..v.slot..':X']==333)
end)
test('auto drag moves whole grid and does not overwrite free layout',function()
 T:setLayout(0);local v=memberView(200);local other=memberView(201)
 local ox,oy=other.x,other.y
 mouse=true;v.window.x=v.x+17;v.window.y=v.y-19;frame()
 assert(other.x==ox+17 and other.y==oy-19)
 mouse=false;frame();T:setLayout(2)
 assert(v.x==333 and v.y==-222)
end)
test('reset moves free windows and leaves scale untouched',function()
 local scale=D['UI:SAVE:PADUI:TEAM_SCALE']
 T:resetPositions();assert(memberView(200).x~=333 or memberView(200).y~=-222)
 assert(D['UI:SAVE:PADUI:TEAM_SCALE']==scale)
end)
test('membership reorder does not remap a remaining free window',function()
 local v=memberView(200);local x,y=v.x,v.y
 for _,key in ipairs({'NAME','UID','PRESENT'}) do
  local a='SERVER:GROUP:0:'..key;local b='SERVER:GROUP:7:'..key
  D[a],D[b]=D[b],D[a]
 end
 frame();assert(memberView(200)==v and v.x==x and v.y==y and v.member.index==7)
end)
test('context-menu snapshot cannot target a replacement member',function()
 local v=memberView(200);T:click(v.slot,'right')
 local index=v.member.index
 D['SERVER:GROUP:'..index..':UID']=9900
 D['SERVER:GROUP:'..index..':NAME']=8800;strings[8800]='Replacement'
 frame();local n=#actions;T:menuAction('select');assert(#actions==n)
end)
test('click routes to correct server group index and ignores absent members',function()
 local v=memberView(201);T:click(v.slot,'left')
 assert(actions[#actions][1]=='team_target' and actions[#actions][2]==tostring(v.member.index))
 D['SERVER:GROUP:'..v.member.index..':PRESENT']=0
 local n=#actions;T:click(v.slot,'left');assert(#actions==n)
 D['SERVER:GROUP:'..v.member.index..':PRESENT']=1;frame()
end)
test('asynchronously unresolved labels cannot reuse the previous name',function()
 local v=memberView(201);local index=v.member.index
 D['SERVER:GROUP:'..index..':NAME']=9999
 D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']=D['UI:VARIABLES:CURRENT_SMOOTH_SERVER_TICK']+100
 T:update();assert(not memberView(201))
 frame();assert(not memberView(201))
 strings[9999]='New Name';frame();assert(memberView(201).member.name=='New Name')
end)
test('scaling/font change changes geometry once, all 75..150 percent',function()
 for _,scale in ipairs({75,100,125,150}) do for _,delta in ipairs({-1,0,1}) do
  D['UI:SAVE:PADUI:TEAM_SCALE']=scale;D['UI:SAVE:PADUI:FONT_DELTA']=delta;frame()
  assert(T.cellW==2*scale)
  assert(T.cards[1].nodes.target_button.x>0)
  assert(T.cards[1].nodes.target_button.x+T.cards[1].nodes.target_button.w==T.cellW)
  local _,l,w=snapshot(T);frame();assert(T.stats.layouts==l and backend.writes==w)
 end end
end)
test('viewport shrink clamps once; stable viewport does not repeat layouts',function()
 T:setLayout(1);sw,sh=640,480;frame()
 assert(T.overflow)
 local l=T.stats.layouts;frame();assert(T.stats.layouts==l)
 T:setLayout(2)
 for _,v in ipairs(T.cards) do if v.member then assert(v.x>=0 and v.x+T.cellW<=sw and v.y<=0 and -v.y+T.cellH<=sh) end end
 sw,sh=1920,1080;frame()
end)
test('module reload reuses native windows and does not stack settings wrappers',function()
 local oldRefresh=PadUISettings.refresh
 dofile('user/team_compact.lua');T=RyzomTeamUI;frame()
 assert(not T.failed and T.uiReady and backend.parses==1 and backend.panels==1)
 assert(PadUISettings.refresh==oldRefresh)
 assert(visible()==9)
end)
test('cold restart declares save leaves before native config restoration',function()
 local saved={}
 T:savePositions()
 for k,v in pairs(D) do if k:match('^UI:SAVE:') then saved[k]=v end end
 local savedX=D[SAVE..'FREE:1:X']
 game.InGameDbInitialized=false;T:update()
 for k in pairs(D) do if k:sub(1,#SAVE)==SAVE then D[k]=nil end end
 dofile('user/team_compact.lua');T=RyzomTeamUI
 assert(D[SAVE..'INIT']==0 and D[SAVE..'FREE:9:Y']~=nil)
 -- Mirror CInterfaceConfig::streamToDataBase: only existing leaves restored.
 for k,v in pairs(saved) do if D[k]~=nil then D[k]=v end end
 game.InGameDbInitialized=true;frame()
 assert(not T.failed and T:isEnabled() and T.cards[1].freeX==savedX)
 assert(T:mode()==2 and visible()==9)
end)
test('character change drops cached identities and restores that character preferences',function()
 game.InGameDbInitialized=false;T:update();assert(visible()==0)
 ownName='SecondCharacter';populate(0)
 for k in pairs(D) do if k:sub(1,#SAVE)==SAVE then D[k]=0 end end
 -- Fresh character's native UI visibility is normally restored before readiness.
 raw[LEGACY].active=true
 game.InGameDbInitialized=true;frame()
 assert(T.character==ownName and visible()==1 and T.rows[1].member==nil)
 assert(T.rows[1].self and T.rows[1].name==ownName)
 assert(D[SAVE..'LOCKED']==1)
end)
test('missing required native API fails safely and enables native team list',function()
 dofile('user/team_compact.lua');T=RyzomTeamUI
 local keep=addDbProp;addDbProp=nil
 T:update();assert(T.failed and U['ui:interface:team_list'].active and visible()==0)
 addDbProp=keep
end)
print(string.format('PASS all %d Lua regression cases (%s)',count,_VERSION))
