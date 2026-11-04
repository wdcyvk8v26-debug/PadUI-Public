-- Pure Lua 5.1 behavioral regression harness for PadUI Action Dock.
-- Not a renderer: tests drag coupling, top/bottom choices, persist/rollback.
local ROOT = "ui:interface:"
local MAIN = ROOT .. "gestionsets"
local ALT = ROOT .. "gestionsets2"
local SAVE = "UI:SAVE:PADUI:ACTION_DOCK:"
local MODE = "UI:SAVE:GESTIONSETS2_MODE"
local db = {[MODE]=2}
local nodes = {}
local function widget(props)
    local w=props or {}
    function w:updateCoords()
        self.x_real=self.x or 0
        self.y_real=self.y or 0
        self.w_real=self.w or 0
        self.h_real=self.h or 0
    end
    function w:setParentPos(other)
        self.parentPos=other
    end
    function w:setPosRef(ref)
        self.posref=ref
    end
    w:updateCoords()
    return w
end
nodes[ROOT:sub(1,-2)] = widget({w=1920,h=1080})
nodes[MAIN]=widget({x=128,y=330,w=410,h=48,active=false})
nodes[ALT]=widget({x=620,y=245,w=68,h=300,active=true})
local callbacks={}
local function ensure(path)
    if nodes[path] then return nodes[path] end
    local n=widget({active=true,w=24,h=24,x=0,y=0})
    if path:find("padui_dock_chrome",1,true) or
       path:find("padui_slot_chrome",1,true) then n.active=false end
    if path:find("padui_back",1,true) or
       path:find("padui_accent",1,true) then n.active=true end
    nodes[path]=n
    return n
end
function getUI(path)
    if not path:find(ROOT,1,true) and path~=ROOT:sub(1,-2) then
        error("Unknown UI group path: " .. tostring(path))
    end
    return ensure(path)
end
function getDbProp(key) return db[key] or 0 end
function setDbProp(key,val) db[key]=val end
function debugInfo(str) callbacks[#callbacks+1]=str end
function runAH(obj,kind,proc)
    assert(kind=="proc", "Expected native proc call")
    if proc=="gestionsets2_proc_horiz" then
        nodes[ALT].w=315
        nodes[ALT].h=52
    elseif proc=="gestionsets2_proc_vert" then
        nodes[ALT].w=68
        nodes[ALT].h=300
    elseif proc=="gestionsets2_proc_mode" then
        if getDbProp(MODE)==1 then
            nodes[ALT].w=315
            nodes[ALT].h=52
        else
            nodes[ALT].w=68
            nodes[ALT].h=300
        end
    else
        error("Unexpected Ryzom proc: "..tostring(proc))
    end
end
game={InGameDbInitialized=true,castUpdateCount=0}
function game:updateCurrentActionPosition()
    self.castUpdateCount=self.castUpdateCount+1
end

dofile("user/padui_action_dock.lua")
local D=PadUIActionDock

local function eq(actual,expected,description)
    assert(actual==expected,description..": "..tostring(actual)..
        " instead of "..tostring(expected))
end
local function attached(side)
    local main,alt=nodes[MAIN],nodes[ALT]
    eq(main.x_real,alt.x_real,"Dock horizontal alignment")
    if side==0 then
        eq(alt.y_real+alt.h_real,main.y_real,
            "Second bar must touch below main bar")
    else
        eq(main.y_real+main.h_real,alt.y_real,
            "Second bar must touch above main bar")
    end
end
-- Default below, still 20+20 native controls, no synthetic sheet creation.
assert(D:joinBelow())
eq(db[SAVE.."SIDE"],0,"Below placement saved")
eq(db[SAVE.."ENABLED"],1,"Dock enabled")
eq(nodes[MAIN].w,410,"Compact native overall width")
attached(0)
eq(db[SAVE.."SECOND_X"],620,"Original alt X saved")
eq(db[SAVE.."SECOND_Y"],245,"Original alt Y saved")

-- Moving MAIN must update ALT, including the original castbar callback.
local main,alt=nodes[MAIN],nodes[ALT]
main.x=main.x+47; main.y=main.y+24; main:updateCoords()
D:onMainMoved()
attached(0)
eq(main.x_real,175,"Main drag X")
eq(main.y_real,354,"Main drag Y")
assert(game.castUpdateCount>0,"Castbar position callback missing")

-- Moving ALT must update MAIN (this was missing in 0.3).
alt.x=alt.x-31; alt.y=alt.y+18; alt:updateCoords()
D:onAltMoved()
attached(0)
eq(main.x_real,144,"Second bar drag moves main X")
eq(main.y_real,372,"Second bar drag moves main Y")

-- User can switch position without detaching or losing original memory data.
assert(D:joinAbove())
eq(db[SAVE.."SIDE"],1,"Above placement saved")
attached(1)
main.x=main.x+20; main.y=main.y-40; main:updateCoords()
D:onMainMoved()
attached(1)
alt.x=alt.x+40; alt.y=alt.y+15; alt:updateCoords()
D:onAltMoved()
attached(1)

-- The two scale modes actually change native UI frame geometry.
D:setSpacing(1)
eq(nodes[MAIN].w,490,"Wide overall width")
eq(nodes[ALT].w,490,"Wide second width")
eq(nodes[MAIN..":shortcuts:s9"].x,324,"Wide slot 10 x")
attached(1)
D:setTheme(2)
eq(nodes[MAIN..":padui_dock_chrome:padui_mode"].hardtext,
    "EMBER / 36","Status label updates")
eq(nodes[ALT..":header_closed:padui_dock_chrome:branding"].active,
    false,"Second titlebar must be hidden")
eq(nodes[ALT..":header_closed:padui_dock_chrome:aux_label"].active,
    false,"Large EXTRA label must be hidden")
D:setGlass(2)
eq(nodes[MAIN..":padui_dock_chrome:glass"].color,
    "26 15 22 155","Glass transparency updates")

-- Moving to extreme top must clamp whole joined dock on-screen.
main.y=1040; main:updateCoords()
D:onMainMoved()
attached(1)
assert(alt.y_real+alt.h_real<=1080,"Joined dock exceeded screen top")

-- Detach: native bar mode, remembered independent position and activation.
assert(D:disable())
eq(db[SAVE.."ENABLED"],0,"Dock disabled")
eq(db[SAVE.."BACKUP_VALID"],0,"Snapshot cleaned")
eq(db[MODE],2,"Native vertical second bar restored")
eq(alt.x,620,"Independent alt original X restored")
eq(alt.y,245,"Independent alt original Y restored")
eq(main.active,false,"Original main active state restored")
eq(alt.active,true,"Original alt active state restored")
eq(nodes[MAIN].w,410,"Main native width restored")
eq(nodes[MAIN..":shortcuts:s10"].y,-26,
    "Native 28x26 row geometry restored")
local saveX=main.x
alt.x=alt.x+12; alt:updateCoords(); D:onAltMoved()
eq(main.x,saveX,"Detached bars move independently")

-- Saved preferences remain available when the user opts in again.
assert(D:joinBelow())
attached(0)
eq(db[SAVE.."SIDE"],0,"Below reselect")
assert(D:disable())
print("PASS: native 40-slot dock two-way dragging, below/above choices,")
print("      wide spacing, theme, glass and exact independent-bar rollback")
