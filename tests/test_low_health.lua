-- Run with Lua 5.1+ from the repository root: lua tests/test_low_health.lua
-- Native GUI stand-ins, not a substitute for testing the Ryzom drawing order.
local HP='UI:VARIABLES:USER:HP_RATIO'
local EN='UI:SAVE:PADUI:LOW_HP:ENABLED'
local TH='UI:SAVE:PADUI:LOW_HP:THRESHOLD'
local root='ui:interface:padui_low_hp_overlay'
local db={[EN]=1,[TH]=25,[HP]=0}
local gui={
 [root]={active=false,w=1,h=1},
 [root..':tint']={color='185 15 15 12',w=1,h=1}
}
local now,ready=0,true
game={InGameDbInitialized=true}
nltime={getLocalTime=function()return now end}
function getDbProp(path)return db[path] end
function getUI(path)return gui[path] end
function isPlayerReady()return ready end
function getWindowSize()return 1920,1080 end
dofile('user/padui_low_health.lua')
local h=PadUILowHealth
local function tick(time,hp,force)
 now=time;db[HP]=hp
 h:update(force)
end
local function shown(value)assert(gui[root].active==value,'Overlay state mismatch')end

-- Uninitialized zero must not trigger a warning.
tick(0,0,true);shown(false)
tick(210,1024);shown(false)
tick(420,260);shown(false)
tick(630,256);shown(true)
assert(gui[root].w==1920 and gui[root..':tint'].h==1080)
-- Five-point hysteresis: keep warning at 28%, clear at 30%.
tick(840,287);shown(true)
tick(1050,308);shown(false)
tick(1260,286);shown(false)
tick(1470,255);shown(true)
-- Changing the threshold should be reflected immediately.
db[TH]=15
tick(1680,255,true);shown(false)
tick(1890,154);shown(false)
tick(2100,153);shown(true)
-- Disabled, invalid values, and logout never leave an active overlay.
db[EN]=0;tick(2310,150,true);shown(false)
db[EN]=1;db[HP]=-1;h:update(true);shown(false)
ready=false;tick(2520,0,true);shown(false)
ready=true;tick(2730,0,true);shown(false)
tick(2940,700,true);shown(false)
tick(3150,100,true);shown(true)
print('PASS low HP: initialization, thresholds, hysteresis, disable, logout')
