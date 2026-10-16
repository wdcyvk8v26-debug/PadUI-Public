-- Strict UI stand-ins, not the NeL renderer or a live-client test.
-- Run from the repository root: texlua tests/test_team_roles.lua
local U,raw,D={}, {}, {}
local stats={writes=0,builds=0,parses=0,network=0,dbWrites=0,baseUpdates=0}
local MENU='ui:interface:team_compact_menu'
local nativeMode='string'
local execute=loadstring or load
local exported={id=true,active=true,x=true,y=true,w=true,h=true,hardtext=true,color=true,tooltip=true,grayed=true,checked=true}
local node
node=function(id,attrs)
 local p={id=id,active=true,x=0,y=0,w=1,h=1,hardtext='',tooltip='',color=''}
 for k,v in pairs(attrs or {})do p[k]=v end
 local methods={}
 local o=setmetatable({}, {
  __index=function(_,k)
   if methods[k]then return methods[k]end
   assert(exported[k],'Unsupported native property '..tostring(k))
   if (k=='w' or k=='h')and not p.active then return 0 end
   return p[k]
  end,
  __newindex=function(_,k,v)
   assert(exported[k],'Unsupported native setter '..tostring(k))
   p[k]=v;stats.writes=stats.writes+1
  end
 })
 p.children={}
 methods.find=function(_,child)return p.children[child]or U[id..':'..child]end
 methods.addGroup=function(_,g)
  local leaf=g.id:match('([^:]+)$')
  assert(not p.children[leaf],'Duplicate child '..leaf)
  p.children[leaf]=g
 end
 methods.setLineMaxW=function(_,w)assert(w>0);p.maxw=w;stats.writes=stats.writes+1 end
 methods.invalidateCoords=function()end
 U[id]=o;raw[o]=p;p.methods=methods
 return o
end
local function submenu(parent)
 local o=node('',{}) -- native luaAddSubMenu does not assign a named ID
 local p=raw[o];p.lines={}
 local methods=p.methods
 local function at(i)assert(type(i)=='number'and i>=0 and i<#p.lines,'Invalid menu index');return p.lines[i+1]end
 methods.getNumLine=function()return #p.lines end
 methods.getLineFromId=function(_,id)for i,l in ipairs(p.lines)do if l.id==id then return i-1 end end;return -1 end
 methods.addLine=function(_,text,ah,params,id,...)
  assert(select('#',...)==0,'addLine takes exactly four args')
  if nativeMode=='ucstring'then assert(type(text)=='table');text=text.value else assert(type(text)=='string')end
  local view=node(parent.id..':'..id,{hardtext=text})
  p.lines[#p.lines+1]={id=id,ah=ah,params=params,view=view}
  -- Native luaAddLine returns no object.
 end
 methods.addSeparator=function(_,...)assert(select('#',...)==0);p.lines[#p.lines+1]={separator=true}end
 methods.getSubMenu=function(_,i)return at(i).sub end
 methods.addSubMenu=function(_,i)local l=at(i);assert(not l.sub);l.sub=submenu(parent);return l.sub end
 for _,side in ipairs({'Left','Right'})do
  methods['getUserGroup'..side]=function(_,i)return at(i)[side]end
  methods['setUserGroup'..side]=function(_,i,g,...)
   assert(select('#',...)==0,'Ownership is implicit in Lua')
   local l=at(i);assert(not l[side],'Do not reinsert owned UI group')
   l[side]=g
  end
 end
 return o
end
node('ui:interface',{})
local function newMenu()
 local m=node(MENU,{})
 local root=submenu(m);raw[m].methods.getRootMenu=function()return root end
 for _,id in ipairs({'select','assist','trade'})do root:addLine(id,'lua','RyzomTeamUI:menuAction(\''..id..'\')',id)end
 return m,root
end
local menu,root=newMenu()
function getUI(id)return U[id]end
function getDbProp(id)return D[id]or 0 end
function setDbProp(id,v)assert(id=='UI:SAVE:PADUI:LANGUAGE');D[id]=v;stats.dbWrites=stats.dbWrites+1 end
function getClientCfgVar()return 'en'end
function getPlayerName()assert(game.InGameDbInitialized);return 'Tester'end
function getPlayerPos()assert(game.InGameDbInitialized);return 0,0,0 end
function debugInfo(msg)stats.lastError=msg end
function displaySystemInfo(msg)stats.lastMessage=msg end
function runAH(_,name,params)
 assert(name=='active_menu'or name=='team_target'or name=='self_target','Unexpected network action '..name)
 stats.network=stats.network+1;stats.lastAction=name;stats.lastParams=params
end
function ucstring(value)return {value=value}end
local partCount
function parseInterfaceFromString(xml)
 assert(xml:find('template name="padui_local_role_icon_v1"',1,true))
 assert(not xml:find('<ctrl',1,true),'Symbols must not capture mouse input')
 local n=0;for id in xml:gmatch('<view type="bitmap" id="p(%d+)"')do n=n+1;assert(tonumber(id)==n)end
 assert(n>0 and n<=64);partCount=n;stats.parses=stats.parses+1;return true
end
function createGroupInstance(template,parent,params)
 assert(template=='padui_local_role_icon_v1'and partCount)
 local group=node(parent..':'..params.id,{w=12,h=12})
 for i=1,partCount do node(group.id..':p'..i,{active=false})end
 stats.builds=stats.builds+1;return group
end
local T={cards={},rows={},character='Tester',uiReady=true,geometryKey='100:0',scale=1,cellW=200,stats={layouts=0,sorts=0}}
RyzomTeamUI=T
local function basePut(v,n,k,value)
 local ck=n..':'..k
 if v.cache[ck]~=value then v.nodes[n][k]=value;v.cache[ck]=value end
end
function T:render()
 for _,v in ipairs(self.cards)do if v.member then
  basePut(v,'name','hardtext',v.member.name)
  for _,id in ipairs({'target_button','target_top','target_bottom','target_rim'})do basePut(v,id,'tooltip',v.member.name)end
 end end
end
function T:update()
 stats.baseUpdates=stats.baseUpdates+1
 if game.InGameDbInitialized then
  if not self.hidden then self:render()end
 end
end
function T:validMember(m)
 if not m or not game.InGameDbInitialized then return false end
 if m.self then return self.character==m.name end
 local p='SERVER:GROUP:'..m.index..':'
 return D[p..'UID']==m.uid and D[p..'NAME']==m.nameId and D[p..'PRESENT']==1
end
function T:click(slot,side)
 local m=self.rows[tonumber(slot)]
 if not self:validMember(m)then return end
 if side=='right'then self.menuMember=m;runAH(nil,'active_menu','menu='..MENU)
 else runAH(nil,m.self and 'self_target'or'team_target',tostring(m.index))end
end
function T:beginNativeMove()end
function T:nativeMove()end
function T:arrange()end
local movement={T.beginNativeMove,T.nativeMove,T.arrange}
local function newCards()
 T.cards={};T.rows={}
 for i=1,9 do
  local id='ui:interface:padui_team_member'..i
  local window=node(id,{x=20+(i-1)*202,y=850,w=200,h=34})
  local header=node(id..':header_opened',{w=200,h=34})
  local v={slot=i,window=window,nodes={header=header},cache={},inputKey='100:0:true'}
  for _,name in ipairs({'name','target_button','target_top','target_bottom','target_rim','grip','mover'})do v.nodes[name]=node(header.id..':'..name,{x=name=='name'and 8 or 0,w=200,h=34})end
  raw[v.nodes.name].maxw=114;T.cards[i]=v
 end
end
newCards()
local function populate(n,showSelf)
 D['SERVER:USER:TEAM_MEMBER']=n>0 and 1 or 0
 for i=0,7 do
  local p='SERVER:GROUP:'..i..':'
  D[p..'UID']=200+i;D[p..'NAME']=i<n and 100+i or 0;D[p..'PRESENT']=1
 end
 for _,v in ipairs(T.cards)do v.member=nil end
 local offset=showSelf==false and 0 or 1
 if offset==1 then T.cards[1].member={self=true,name=T.character,key='self'}end
 for i=1,n do T.cards[i+offset].member={self=false,name='Member'..i,uid=199+i,nameId=99+i,index=i-1,key='uid:'..(199+i)}end
 for i,v in ipairs(T.cards)do T.rows[i]=v.member;v.cache={}end
end
D['UI:SAVE:PADUI:TEAM_MODULAR:LOCKED']=1
D['UI:SAVE:PADUI:LANGUAGE']=2
game={InGameDbInitialized=false}
populate(8)
dofile('user/padui_core.lua')
local R=PadUITeamRoles
local ntests=0
local function test(name,fn)
 local ok,err=pcall(fn);assert(ok,name..': '..tostring(err))
 ntests=ntests+1;print('PASS '..name)
end
local function render()T:update();assert(not R.failed,R.failed)end
local function setRole(slot,role)
 T:click(slot,'right');assert(not R.failed,R.failed)
 local n=stats.network;assert(R:assign(role));assert(stats.network==n,'Role assignment sent an action')
end
local function shapePixels(role,size)
 local pixels={}
 for _,r in ipairs(R:rectangles(role,size))do
  assert(r.x>=0 and r.y<=0 and r.x+r.w<=size and -r.y+r.h<=size)
  for y=-r.y,-r.y+r.h-1 do for x=r.x,r.x+r.w-1 do
   local k=y*size+x;assert(not pixels[k],'Overlapping icon rectangles');pixels[k]=r.color
  end end
 end
 return pixels
end
local function fingerprint(role,size,outline)
 local p=shapePixels(role,size);local s={}
 for i=0,size*size-1 do s[#s+1]=p[i]and(outline and '#'or p[i])or'.'end
 return table.concat(s)
end

test('parsing is pure and preserves safe early-player wrappers',function()
 assert(stats.builds==0 and stats.parses==0 and getPlayerName()=='')
 local x,y,z=getPlayerPos();assert(x==0 and y==0 and z==0)
end)
test('PadUI:start installs the addon without creating a second controller',function()
 PadUI:start();assert(T.update==T._paduiRolesUpdate and stats.builds==0)
 game.InGameDbInitialized=true;render();assert(stats.builds==9 and stats.parses==1)
 assert(T.beginNativeMove==movement[1]and T.nativeMove==movement[2]and T.arrange==movement[3])
end)
test('all nine cards reserve space even with no role',function()
 for _,v in ipairs(T.cards)do assert(v.nodes.name.x==24 and raw[v.nodes.name].maxw==98)end
 for _,icon in pairs(R.icons)do assert(icon.paintKey=='none:12');for _,p in ipairs(icon.nodes)do assert(not p.active)end end
end)
test('five different silhouettes at each of the four supported sizes',function()
 for _,size in ipairs({9,12,15,18})do
  local seen={}
  for _,role in ipairs({'tank','heal','melee','ele','affliction'})do
   local f=fingerprint(role,size,true);assert(not seen[f],role..' silhouette duplicate');seen[f]=true
   assert(next(shapePixels(role,size)))
  end
 end
end)
test('rectangle raster exactly matches each small and large source mask',function()
 for role,spec in pairs(R.art)do for _,size in ipairs({9,12,15,18})do
  local p=shapePixels(role,size);local mask=(size==9 or not spec.large)and spec.small or spec.large
  for y=0,size-1 do for x=0,size-1 do
   local c=mask[math.floor((y+.5)*#mask/size)+1]:sub(math.floor((x+.5)*#mask/size)+1,math.floor((x+.5)*#mask/size)+1)
   local color=c=='o'and'4 9 15 255'or(c=='h'and spec.light or spec.color)
   assert(p[y*size+x]==(c~='.'and color or nil))
  end end
 end end
end)
test('all rectangles fit preallocated bitmap pool',function()
 for role in pairs(R.art)do for _,size in ipairs({9,12,15,18})do assert(#R:rectangles(role,size)<=R.parts)end end
end)
test('existing target assist trade menu entries are untouched',function()
 T:click(2,'right');assert(not R.failed,R.failed)
 assert(root:getNumLine()==5)
 for i,id in ipairs({'select','assist','trade'})do assert(raw[root].lines[i].id==id and raw[root].lines[i].params=="RyzomTeamUI:menuAction('"..id.."')")end
 assert(stats.lastAction=='active_menu')
end)
test('submenu has matching graphics and marks No role initially',function()
 local sub=root:getSubMenu(root:getLineFromId('padui_roles'))
 assert(sub:getNumLine()==7)
 for _,role in ipairs(R.order)do
  local i=sub:getLineFromId('padui_role_'..role)
  assert(sub:getUserGroupLeft(i)and sub:getUserGroupRight(i))
  local count=0;local g=sub:getUserGroupRight(i)
  for p=1,R.parts do if g:find('p'..p).active then count=count+1 end end
  assert((count>0)==(role=='none'))
 end
end)
test('local role selection never sends chat or changes selected target',function()
 local n=stats.dbWrites
 for i,role in ipairs({'tank','heal','melee','ele','affliction'})do
  setRole(i,role);assert(R.roles[i==1 and'self'or('uid:'..(198+i)..':'..(98+i))]==role)
  assert(R.icons[i].paintKey==role..':12')
 end
 assert(stats.dbWrites==n)
end)
test('every generated role menu callback is executable and whitelisted',function()
 local sub=root:getSubMenu(root:getLineFromId('padui_roles'))
 for _,line in ipairs(raw[sub].lines)do if line.id then
  T:click(2,'right');local n=stats.network
  assert(execute(line.params))();assert(stats.network==n)
 end end
end)
test('role removal empties the graphic without moving the name',function()
 setRole(2,'tank');local x=T.cards[2].nodes.name.x;setRole(2,'none')
 assert(T.cards[2].nodes.name.x==x and R.icons[2].paintKey=='none:12')
end)
test('role changes leave window geometry, movement controls and layouts intact',function()
 local v=T.cards[3];local x,y,w,h=v.window.x,v.window.y,v.window.w,v.window.h
 local grip,mover=v.nodes.grip,v.nodes.mover
 local l,s=T.stats.layouts,T.stats.sorts
 for _,role in ipairs(R.order)do setRole(3,role)end
 assert(v.window.x==x and v.window.y==y and v.window.w==w and v.window.h==h)
 assert(v.nodes.grip==grip and v.nodes.mover==mover and T.stats.layouts==l and T.stats.sorts==s)
end)
test('selection still delegates to native actions',function()
 local n=stats.network;T:click(2,'left');assert(stats.network==n+1 and stats.lastAction=='team_target')
 T:click(1,'left');assert(stats.lastAction=='self_target')
end)
test('200 idle updates make no additional UI DB or network writes',function()
 render();local w,b,p,n,d=stats.writes,stats.builds,R.stats.paints,stats.network,stats.dbWrites
 for i=1,200 do render()end
 assert(stats.writes==w and stats.builds==b and R.stats.paints==p and stats.network==n and stats.dbWrites==d)
end)
test('role follows identity when display cards reorder',function()
 setRole(2,'tank');setRole(3,'heal')
 local a,b=T.cards[2],T.cards[3];a.member,b.member=b.member,a.member
 T.rows[2],T.rows[3]=a.member,b.member;a.cache={};b.cache={};render()
 assert(R.icons[2].paintKey=='heal:12'and R.icons[3].paintKey=='tank:12')
 a.member,b.member=b.member,a.member;T.rows[2],T.rows[3]=a.member,b.member;a.cache={};b.cache={};render()
end)
test('server slot reorder does not transfer or lose a role',function()
 setRole(2,'tank');T:click(2,'right')
 local a,b=T.cards[2].member,T.cards[3].member;a.index,b.index=b.index,a.index
 for _,field in ipairs({'UID','NAME','PRESENT'})do local p,q='SERVER:GROUP:0:'..field,'SERVER:GROUP:1:'..field;D[p],D[q]=D[q],D[p]end
 assert(R:assign('affliction'));render();assert(R.icons[2].paintKey=='affliction:12')
 populate(8);render()
end)
test('roster replacement cannot inherit a role or a pending menu assignment',function()
 setRole(2,'tank');T:click(2,'right')
 D['SERVER:GROUP:0:UID']=999;D['SERVER:GROUP:0:NAME']=999
 assert(not R:assign('heal'));render();assert(not R.roles['uid:200:100'])
 populate(8);render()
end)
test('same UID with a different name ID does not inherit a role',function()
 setRole(2,'tank');D['SERVER:GROUP:0:NAME']=789
 T.cards[2].member.nameId=789;render();assert(R.icons[2].paintKey=='none:12')
 populate(8);render()
end)
test('invalid roles and expired menu callbacks do nothing',function()
 T:click(2,'right');assert(not R:assign('check'));assert(not R:assign("tank'); error('bad"))
 assert(R:assign('tank'));assert(not R:assign('heal'))
end)
test('absent members cannot receive a pending assignment',function()
 T:click(2,'right');D['SERVER:GROUP:0:PRESENT']=0;assert(not R:assign('tank'))
 D['SERVER:GROUP:0:PRESENT']=1
end)
test('departed members are pruned and a new occupant stays unassigned',function()
 setRole(9,'ele');populate(7);render();assert(not R.roles['uid:207:107'])
 populate(8);render();assert(R.icons[9].paintKey=='none:12')
end)
test('hidden team still detects leaving and joining, discarding old roles',function()
 setRole(2,'tank');T.hidden=true
 D['SERVER:USER:TEAM_MEMBER']=0;T:update();assert(next(R.roles)==nil)
 D['SERVER:USER:TEAM_MEMBER']=1;T:update();T.hidden=false;render()
 assert(R.icons[2].paintKey=='none:12')
end)
test('character change and game disconnect discard roles',function()
 setRole(2,'tank');T:click(2,'right');T.character='Other';render();assert(next(R.roles)==nil and not R:assign('heal'))
 T.character='Tester';populate(8);render();setRole(2,'tank')
 game.InGameDbInitialized=false;T:update();assert(next(R.roles)==nil)
 game.InGameDbInitialized=true;newCards();populate(8);render();assert(R.icons[2].paintKey=='none:12')
end)
test('solo self card can preview every role without an invitation',function()
 populate(0);render()
 for _,role in ipairs(R.order)do setRole(1,role)end
 populate(8);render()
end)
test('hiding self does not erase its local role',function()
 setRole(1,'heal');populate(8,false);render();assert(R.roles.self=='heal')
 populate(8);render();assert(R.icons[1].paintKey=='heal:12')
end)
test('all scales reserve 12px plus 4px gap proportionally inside name row',function()
 for _,scale in ipairs({.75,1,1.25,1.5})do
  T.scale=scale;T.cellW=math.floor(200*scale+.5);T.geometryKey=tostring(scale)
  for _,v in ipairs(T.cards)do
   v.inputKey=tostring(scale);v.nodes.name.x=math.floor(8*scale+.5)
  end
  render()
  for _,v in ipairs(T.cards)do
   local icon=R.icons[v.slot]
   assert(icon.group.w==math.floor(12*scale+.5))
   assert(icon.group.h<=math.floor(13*scale+.5))
   assert(v.nodes.name.x==math.floor(8*scale+.5)+math.floor(12*scale+.5)+math.floor(4*scale+.5))
   assert(raw[v.nodes.name].maxw>0)
  end
  local writes=stats.writes;render();assert(stats.writes==writes)
 end
 T.scale=1;T.cellW=200;T.geometryKey='100:0';render()
end)
test('LOCK changes name budget but never movement handlers',function()
 D['UI:SAVE:PADUI:TEAM_MODULAR:LOCKED']=0
 for _,v in ipairs(T.cards)do v.inputKey='unlocked'end
 render();assert(raw[T.cards[1].nodes.name].maxw==86)
 D['UI:SAVE:PADUI:TEAM_MODULAR:LOCKED']=1
 for _,v in ipairs(T.cards)do v.inputKey='locked'end
 render();assert(raw[T.cards[1].nodes.name].maxw==98)
 assert(T.nativeMove==movement[2])
end)
test('session reset reapplies name budget even with identical geometry keys',function()
 raw[T.cards[1].nodes.name].maxw=114
 R:reset();render();assert(raw[T.cards[1].nodes.name].maxw==98)
end)
test('new native font alias receives position and width',function()
 local v=T.cards[1];v.nodes.name=node(v.nodes.header.id..':name_s12',{x=8})
 render();assert(v.nodes.name.x==24 and raw[v.nodes.name].maxw==98)
end)
test('DE EN FR menu labels and full role tooltips',function()
 for i=1,3 do
  D['UI:SAVE:PADUI:LANGUAGE']=i;T:click(2,'right');assert(R:assign('heal'));render()
  local tip=T.cards[2].nodes.target_button.tooltip
  assert(tip:find(i==1 and 'Heiler'or(i==2 and'Healer'or'Soins'),1,true))
  local parent=U[MENU..':padui_roles'].hardtext;assert(#parent>0)
 end
 D['UI:SAVE:PADUI:LANGUAGE']=2;render()
end)
test('current role has one graphical tick in the submenu',function()
 setRole(2,'ele');T:click(2,'right')
 local sub=root:getSubMenu(root:getLineFromId('padui_roles'));local selected=0
 for _,role in ipairs(R.order)do
  local mark=sub:getUserGroupRight(sub:getLineFromId('padui_role_'..role));local active=false
  for i=1,R.parts do if mark:find('p'..i).active then active=true end end
  if active then selected=selected+1;assert(role=='ele')end
 end
 assert(selected==1)
end)
test('opening menu repeatedly reuses groups and adds no duplicate entries',function()
 local builds,lines=stats.builds,root:getNumLine()
 for i=1,10 do T:click(2,'right')end
 assert(stats.builds==builds and root:getNumLine()==lines)
end)
test('legacy ucstring menu API is supported without duplicate rows',function()
 menu,root=newMenu();nativeMode='ucstring'
 T:click(2,'right');assert(not R.failed,R.failed);assert(root:getNumLine()==5)
 nativeMode='string'
end)
test('module restart does not stack wrappers or create duplicate glyphs',function()
 local u,r,c=T.update,T.render,T.click;local builds=stats.builds
 for i=1,5 do R:start()end
 assert(T.update==u and T.render==r and T.click==c and stats.builds==builds)
 dofile('user/padui_core.lua');R=PadUITeamRoles;PadUI:start();render()
 assert(T.update==u and T.render==r and T.click==c and stats.builds==builds and next(R.roles)==nil)
end)
test('role initialization failure leaves base targeting and update operational',function()
 R:reset();R.templateRoot=nil
 local original=parseInterfaceFromString
 parseInterfaceFromString=function()return false end
 R.icons={};render=function()T:update()end
 local n=stats.baseUpdates;render();assert(R.failed and stats.baseUpdates==n+1 and T.cards[2].nodes.name.x==8)
 n=stats.network;T:click(2,'left');assert(stats.network==n+1 and stats.lastAction=='team_target')
 parseInterfaceFromString=original
end)
print(string.format('PASS all %d local-role cases (%s)',ntests,_VERSION))
