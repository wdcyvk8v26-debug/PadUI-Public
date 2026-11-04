-- Ryzom Lua 5.1 behavior simulation for Unified Action Dock 0.5.
-- It does not render real UI, but checks the two original widget paths,
-- four-row slot alignment, one/two selectors, user-input page syncing and undo.
local ROOT="ui:interface:"
local MAIN=ROOT.."gestionsets"
local ALT=ROOT.."gestionsets2"
local MAIN_SLOT=MAIN..":shortcuts:s0"
local ALT_SLOT=ALT..":header_closed:shortcuts:s0"
local SAVE="UI:SAVE:PADUI:ACTION_DOCK:"
local ALT_MODE="UI:SAVE:GESTIONSETS2_MODE"
local PAGE_MAIN="UI:PHRASE:SELECT_MEMORY"
local PAGE_ALT="UI:PHRASE:SELECT_MEMORY_2"
local db={
 [ALT_MODE]=2, [PAGE_MAIN]=3, [PAGE_ALT]=5,
 [SAVE.."PAGE_SYNC"]=1, [SAVE.."SECOND_MOVABLE"]=1,
 [SAVE.."SIDE"]=0
}
local nodes={}
local D=nil
local function widget(props)
    local w=props or {}
    function w:updateCoords()
        if self.id==MAIN_SLOT then
            local root=nodes[MAIN]
            self.x_real=root.x+58+(self.x or 0)
            self.y_real=root.y+root.h-20+(self.y or 0)
        elseif self.id==ALT_SLOT then
            local root=nodes[ALT]
            self.x_real=root.x+86+(self.x or 0)
            self.y_real=root.y+30+(self.y or 0)
        else
            self.x_real=self.x or 0
            self.y_real=self.y or 0
        end
        self.w_real=self.w or 0
        self.h_real=self.h or 0
    end
    function w:setParentPos(other) self.parentPos=other end
    function w:setPosRef(ref) self.posref=ref end
    w:updateCoords()
    return w
end
nodes[ROOT:sub(1,-2)]=widget({w=1920,h=1080})
nodes[MAIN]=widget({x=128,y=330,w=410,h=48,active=false,movable=true})
nodes[ALT]=widget({x=620,y=245,w=68,h=300,active=true,movable=true})
local log={}
local function ensure(path)
    if nodes[path] then
        nodes[path]:updateCoords()
        return nodes[path]
    end
    local n=widget({active=true,w=24,h=24,x=0,y=0,id=path})
    if path:find("padui_dock_chrome",1,true) or
       path:find("padui_slot_chrome",1,true) then n.active=false end
    if path:find("padui_back",1,true) or
       path:find("padui_accent",1,true) then n.active=true end
    nodes[path]=n
    n:updateCoords()
    return n
end
function getUI(path)
    assert(path:find(ROOT,1,true) or path==ROOT:sub(1,-2),
        "invalid UI path: "..tostring(path))
    return ensure(path)
end
function getDbProp(key) return db[key] or 0 end
function setDbProp(key,value)
    db[key]=value
    -- Model callbacks queued by native XML link observers.
    if D then
        if key==PAGE_MAIN then D:onPrimaryPageChanged()
        elseif key==PAGE_ALT then D:onSecondaryPageChanged() end
    end
end
function debugInfo(message) log[#log+1]=message end
function runAH(obj,kind,proc)
    assert(kind=="proc","Native Ryzom proc expected")
    local alt=nodes[ALT]
    if proc=="gestionsets2_proc_horiz" then
        alt.w=315;alt.h=52
        ensure(ALT..":select_memory_h").active=true
        ensure(ALT..":select_memory").active=false
    elseif proc=="gestionsets2_proc_mode" then
        if db[ALT_MODE]==1 then
            alt.w=315;alt.h=52
            ensure(ALT..":select_memory_h").active=true
            ensure(ALT..":select_memory").active=false
        else
            alt.w=68;alt.h=300
            ensure(ALT..":select_memory_h").active=false
            ensure(ALT..":select_memory").active=true
        end
    else
        error("Unexpected Ryzom proc: "..tostring(proc))
    end
end
game={InGameDbInitialized=true,castUpdates=0}
function game:updateCurrentActionPosition()
    self.castUpdates=self.castUpdates+1
end
dofile("user/padui_action_dock.lua")
D=PadUIActionDock
local function eq(actual,expected,message)
    assert(actual==expected,message..": got "..tostring(actual)..
        "; expected "..tostring(expected))
end
local function aligned(side)
    local p=getUI(MAIN_SLOT),q=getUI(ALT_SLOT)
    local pitch=db[SAVE.."SPACING"]==1 and 36 or 28
    eq(q.x_real,p.x_real,"All four rows share same first-column x")
    eq(q.y_real,p.y_real+(side==0 and -2*pitch or 2*pitch),
       "Actual native row 3 follows rows 1-2 without offset")
end
local function selectorCount(expected)
    eq(ensure(MAIN..":select_memory").active,true,"Primary native selector")
    eq(ensure(ALT..":select_memory_h").active,expected==2,
       "Second native selector visibility")
end

-- Test original 40 native slots are used through the standard Ryzom paths.
assert(D:joinBelow(),"Joining unified dock failed")
local main,alt=nodes[MAIN],nodes[ALT]
eq(main.w,410,"Compact unified width")
eq(main.h,144,"Master contains both two-row heights")
eq(alt.movable,false,"Secondary native window not independently draggable")
eq(ensure(MAIN..":padui_dock_chrome").active,true,
   "The visual master backdrop is visible")
eq(ensure(ALT..":header_closed:padui_dock_chrome").active,false,
   "There must be no second native backdrop")
eq(ensure(MAIN..":padui_dock_chrome:unified_title").active,true,
   "Unified title must be visible")
eq(db[PAGE_ALT],db[PAGE_MAIN],"Join must synchronize existing page values")
selectorCount(1)
aligned(0)

-- Changing main page also changes the ALT page (including keyboard shortcut).
setDbProp(PAGE_MAIN,6)
eq(db[PAGE_ALT],6,"Synchronous main -> alt")
setDbProp(PAGE_ALT,8)
eq(db[PAGE_MAIN],8,"Synchronous alt -> main")

-- With independent pages both page selectors exist, no db copying.
D:setPageSync(false)
selectorCount(2)
setDbProp(PAGE_MAIN,4)
eq(db[PAGE_ALT],8,"Independent pages should not be linked")
setDbProp(PAGE_ALT,2)
eq(db[PAGE_MAIN],4,"Independent alt should not move main")

-- On synchronizing again, main page wins and only one switch is shown.
D:setPageSync(true)
selectorCount(1)
eq(db[PAGE_ALT],4,"Restore synchronized pages")

-- One master drag moves all 40 native slots.
local originalX=main.x
main.x=main.x+46;main.y=main.y+27;main:updateCoords()
D:onMainMoved()
aligned(0)
eq(main.x,originalX+46,"Main drag persists")
assert(game.castUpdates>0,"Native current-action callback still required")

-- Secondary window is an overlay, not an independent drag area.
local masterX=main.x
alt.x=alt.x-25;alt:updateCoords()
D:onAltMoved()
eq(main.x,masterX,"Overlay cannot drag master")
aligned(0)

-- Optional above positioning preserves a unified 4x10 grid.
assert(D:joinAbove())
eq(db[SAVE.."SIDE"],1,"Above choice saved")
aligned(1)
assert(D:joinBelow())
aligned(0)

-- Width/theme/transparency change the actual master surface.
D:setSpacing(1)
eq(main.w,490,"36 px layout increases width")
eq(main.h,176,"4x10 unified wide height")
eq(ensure(MAIN..":shortcuts:s9").x,324,"10th real phrase slot spacing")
aligned(0)
D:setTheme(2)
eq(ensure(MAIN..":padui_dock_chrome:unified_title").color,
   "203 132 111 255","Copper theme tint")
D:setGlass(2)
eq(ensure(MAIN..":padui_dock_chrome:glass").color,
   "26 15 22 155","Glass alpha update from native palette")

-- Detaching restores native alternative vertical mode and original position.
assert(D:disable())
eq(db[SAVE.."ENABLED"],0,"Unified dock disabled")
eq(db[SAVE.."BACKUP_VALID"],0,"Original position backup cleared")
eq(alt.x,620,"ALT original x restored")
eq(alt.y,245,"ALT original y restored")
eq(alt.movable,true,"ALT native drag restored")
eq(db[ALT_MODE],2,"Original ALT vertical orientation restored")
eq(main.h,48,"Main native height restored")
eq(ensure(MAIN..":hands").y,0,"Main hands native anchor restored")
eq(main.active,false,"Main previous activation restored")
eq(alt.active,true,"ALT previous activation restored")
eq(ensure(MAIN..":shortcuts:s10").y,-26,"Main native row spacing restored")

-- Preferences survive: rejoin in independent mode after saved settings.
D:setPageSync(false)
assert(D:joinBelow())
selectorCount(2)
assert(D:disable())
print("PASS: unified visible master, 40 native slots, precise 4x10 alignment")
print("      one/two real page selectors, two-way DB page syncing, drag and undo")
