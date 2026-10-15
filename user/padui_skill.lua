-- One manually selected native skill, displayed below the player gauges.
PadUISkill = PadUISkill or {}
local S=PadUISkill
local ROOT="ui:interface:player:content:padui_skill"
local MODAL="ui:interface:padui_skill_choose"
local SAVE="UI:SAVE:PADUI:SKILL"
S.pageSize=14
S.codes={"SC","SCA","SCAH","SCAHB","SCAHBE","SCAHBEM","SCAHG","SCAHGE","SCAHGEM","SCAHH","SCAHHE","SCAHHEM","SCAHP","SCAHPE","SCAHPEM","SCAHS","SCAHSE","SCAHSEM","SCAHV","SCAHVE","SCAHVEM","SCAL","SCALB","SCALBE","SCALBEM","SCALG","SCALGE","SCALGEM","SCALP","SCALPE","SCALPEM","SCALS","SCALSE","SCALSEM","SCALV","SCALVE","SCALVEM","SCAM","SCAMB","SCAMBE","SCAMBEM","SCAMG","SCAMGE","SCAMGEM","SCAMP","SCAMPE","SCAMPEM","SCAMS","SCAMSE","SCAMSEM","SCAMV","SCAMVE","SCAMVEM","SCAS","SCASB","SCASBE","SCASBEM","SCASS","SCASSE","SCASSEM","SCJ","SCJA","SCJAA","SCJAAE","SCJAAEM","SCJB","SCJBA","SCJBAE","SCJBAEM","SCJD","SCJDA","SCJDAE","SCJDAEM","SCJE","SCJEA","SCJEAE","SCJEAEM","SCJP","SCJPA","SCJPAE","SCJPAEM","SCJR","SCJRA","SCJRAE","SCJRAEM","SCM","SCM1","SCM1A","SCM1AE","SCM1AEM","SCM1D","SCM1DE","SCM1DEM","SCM1M","SCM1ME","SCM1MEM","SCM1P","SCM1PE","SCM1PEM","SCM1S","SCM1SE","SCM1SEM","SCM1T","SCM1TE","SCM1TEM","SCM2","SCM2A","SCM2AE","SCM2AEM","SCM2M","SCM2ME","SCM2MEM","SCM2P","SCM2PE","SCM2PEM","SCM2S","SCM2SE","SCM2SEM","SCMC","SCMCA","SCMCAE","SCMCAEM","SCR","SCR1","SCR1P","SCR1PE","SCR1PEM","SCR2","SCR2A","SCR2AE","SCR2AEM","SCR2L","SCR2LE","SCR2LEM","SCR2R","SCR2RE","SCR2REM","SF","SFM","SFM1","SFM1B","SFM1BM","SFM1BMM","SFM1BS","SFM1BSM","SFM1P","SFM1PS","SFM1PSM","SFM1S","SFM1SA","SFM1SAM","SFM1SS","SFM1SSM","SFM2","SFM2B","SFM2BM","SFM2BMM","SFM2P","SFM2PP","SFM2PPM","SFM2S","SFM2SA","SFM2SAM","SFM2SS","SFM2SSM","SFMC","SFMCA","SFMCAD","SFMCADM","SFMCAH","SFMCAHM","SFR","SFR1","SFR1A","SFR1AP","SFR1APM","SFR2","SFR2A","SFR2AA","SFR2AAM","SFR2AL","SFR2ALM","SFR2AR","SFR2ARM","SH","SHF","SHFD","SHFDA","SHFDAE","SHFDAEM","SHFF","SHFFA","SHFFAE","SHFFAEM","SHFJ","SHFJA","SHFJAE","SHFJAEM","SHFL","SHFLA","SHFLAE","SHFLAEM","SHFP","SHFPA","SHFPAE","SHFPAEM","SM","SMD","SMDA","SMDAA","SMDAAE","SMDAAEM","SMDH","SMDHA","SMDHAE","SMDHAEM","SMO","SMOA","SMOAA","SMOAAE","SMOAAEM","SMOE","SMOEA","SMOEAE","SMOEAEM"}
-- Native enum boundary, resolved through the client rather than an assumed ID.
S.count=getSkillIdFromName("SMOEAEM")+1
local function db(p) return tonumber(getDbProp(p)) or 0 end
local function utf8(value)
 if type(value)=="string" then return value end
 local ok,text=pcall(function() return value:toUtf8() end)
 return ok and text or ""
end
function S:name(id)
 return utf8(getSkillLocalizedName(id))
end
function S:valid(id)
 return id and id==math.floor(id) and id>=0 and id<S.count
end
function S:update()
 if not game or not game.InGameDbInitialized then return end
 local now=nltime.getLocalTime()
 if S.lastRefresh and now>=S.lastRefresh and now-S.lastRefresh<250 then return end
 S.lastRefresh=now
 local group=getUI(ROOT)
 if not group then return end
 local id=db(SAVE)-1
 local label=getUI(ROOT..":name")
 local level=getUI(ROOT..":level")
 local fill=getUI(ROOT..":fill")
 local back=getUI(ROOT..":back")
 local button=getUI(ROOT..":choose")
 if S:valid(id) then
  local path="SERVER:CHARACTER_INFO:SKILLS:"..id..":"
  local base=db(path.."BaseSKILL")
  local progress=math.max(0,math.min(255,db(path.."PROGRESS_BAR")))
  local maxed=runExpr("isSkillAtMax("..id..",@UI:VARIABLES:TRACK_SKILL_CHANGE)")==true
  label.hardtext=S:name(id)
  level.hardtext=tostring(base)
  fill.w=maxed and 188 or math.floor(188*progress/255+0.5)
  fill.color=maxed and "145 155 20 255" or "25 145 140 255"
  back.active=true;fill.active=true
  button.tooltip=S:name(id).." / "..PadUI:tr("skill_level").." "..base.."\n"
   ..(maxed and PadUI:tr("skill_max") or (math.floor(100*progress/255+0.5).."% / "..PadUI:tr("skill_progress")))
   .."\n"..PadUI:tr("skill_tip")
 else
  label.hardtext=PadUI:tr("skill_choose")
  level.hardtext="";back.active=false;fill.active=false
  button.tooltip=PadUI:tr("skill_tip")
 end
end
-- Native database links call this for every skill/selection change. Events
-- must bypass the draw throttle: the final change can occur in the same frame.
function S:refresh()
 if not PadUI then return end
 S.lastRefresh=nil
 S:update()
end
function S:choose()
 S:showRoots()
 runAH(getUICaller(),"enter_modal","group="..MODAL)
end
function S:showRoots()
 S.branch=nil
 S.entries={
  {branch="SF",name=PadUI:tr("skill_fight")},
  {branch="SM",name=PadUI:tr("skill_magic")},
  {branch="SC",name=PadUI:tr("skill_craft")},
  {branch="SH",name=PadUI:tr("skill_harvest")}
 }
 S.page=1;S:renderPage()
end
function S:filter(branch)
 if branch~="SF" and branch~="SM" and branch~="SC" and branch~="SH" then return end
 S.branch=branch
 local learned={}
 for _,code in ipairs(S.codes) do
  if code:sub(1,2)==branch then
   local id=getSkillIdFromName(code)
   if S:valid(id) then
    local base=db("SERVER:CHARACTER_INFO:SKILLS:"..id..":BaseSKILL")
    if base>0 then learned[#learned+1]={id=id,code=code,name=S:name(id),level=base} end
   end
  end
 end
 S.entries={}
 for _,entry in ipairs(learned) do
  local expanded=false
  for _,other in ipairs(learned) do
   if #other.code>#entry.code and other.code:sub(1,#entry.code)==entry.code then
    expanded=true;break
   end
  end
  -- Leaves of the learned tree: retain progressing branches whose children
  -- have not been learned yet, but remove their already-expanded ancestors.
  if not expanded then S.entries[#S.entries+1]=entry end
 end
 table.sort(S.entries,function(a,b)
  if a.name==b.name then return a.id<b.id end
  return a.name<b.name
 end)
 S.page=1
 S:renderPage()
end
function S:renderPage()
 local pages=math.max(1,math.ceil(#S.entries/S.pageSize))
 S.page=math.max(1,math.min(pages,S.page or 1))
 getUI(MODAL).h=S.branch and 318 or 142
 local footer=S.branch and -286 or -112
 for _,id in ipairs({"previous","next","back","clear"}) do
  getUI(MODAL..":"..id).y=footer
  getUI(MODAL..":"..id.."_text").y=footer-4
 end
 local keys={SF="skill_fight",SM="skill_magic",SC="skill_craft",SH="skill_harvest"}
 getUI(MODAL..":title").hardtext=PadUI:tr(S.branch and keys[S.branch] or "skill_tree")
  ..(S.branch and ("  "..S.page.." / "..pages) or "")
 getUI(MODAL..":empty").active=#S.entries==0
 getUI(MODAL..":empty").hardtext=PadUI:tr("skill_empty")
 for row=1,S.pageSize do
  local entry=S.entries[(S.page-1)*S.pageSize+row]
  local group=getUI(MODAL..":row"..row)
  group.active=entry~=nil
  if entry then
   getUI(MODAL..":row"..row..":name").hardtext=entry.name
   getUI(MODAL..":row"..row..":level").hardtext=entry.level and tostring(entry.level) or ">"
   getUI(MODAL..":row"..row..":button").tooltip=entry.name
  end
 end
 getUI(MODAL..":previous").tooltip=PadUI:tr("skill_previous")
 getUI(MODAL..":next").tooltip=PadUI:tr("skill_next")
 getUI(MODAL..":previous").active=S.branch~=nil and S.page>1
 getUI(MODAL..":previous_text").active=S.branch~=nil and S.page>1
 getUI(MODAL..":next").active=S.branch~=nil and S.page<pages
 getUI(MODAL..":next_text").active=S.branch~=nil and S.page<pages
 getUI(MODAL..":back").active=S.branch~=nil
 getUI(MODAL..":back_text").active=S.branch~=nil
 getUI(MODAL..":back").tooltip=PadUI:tr("skill_back")
 getUI(MODAL..":close").tooltip=PadUI:tr("close")
 getUI(MODAL..":clear_text").hardtext=PadUI:tr("skill_clear")
end
function S:turn(delta)
 S.page=(S.page or 1)+delta;S:renderPage()
end
function S:selectRow(row)
 if not S.entries then return end
 local entry=S.entries[((S.page or 1)-1)*S.pageSize+row]
 if not entry then return end
 if entry.branch then S:filter(entry.branch);return end
 setDbProp(SAVE,entry.id+1)
 runAH(getUICaller(),"leave_modal","")
 S.lastRefresh=nil;S:update()
end
function S:clear(closeModal)
 setDbProp(SAVE,0)
 if closeModal then runAH(getUICaller(),"leave_modal","") end
 S.lastRefresh=nil;S:update()
end
function S:start()
 local group=getUI(ROOT)
 if group then setOnDraw(group,"PadUISkill:update()") end
 S.lastRefresh=nil;S:update()
end
