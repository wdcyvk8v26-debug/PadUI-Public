-- PadUI item-to-equipped comparison, called by the native validated tooltip.
PadUICompare=PadUICompare or {}
local C=PadUICompare
local BAG='LOCAL:INVENTORY:BAG:'
local words={
 de={compare='Vergleich mit',empty='Slot leer',loading='Itemdetails werden geladen …',same='Keine Wertänderung',quality='Qualität',two='Zweihand: linke Hand wird frei. Werte unten gelten für das rechte Gegenstück.',slots={head='Kopf',chest='Brust',legs='Beine',feet='Füße',arms='Arme',hands='Hände',anklel='Knöchel links',ankler='Knöchel rechts',earl='Ohr links',earr='Ohr rechts',wristl='Handgelenk links',wristr='Handgelenk rechts',fingerl='Finger links',fingerr='Finger rechts',necklace='Hals',headdress='Kopfschmuck',handr='Rechte Hand',handl='Linke Hand'},stats={HpBuff='HP',SapBuff='Sap',StaBuff='Ausdauer',FocusBuff='Fokus',DodgeModifier='Dodge',ParryModifier='Parry',CurrentDamage='Schaden',Range='Reichweite',ProtectionFactor='Schutzfaktor',MaxSlashingProtection='Schutz: Schnitt',MaxPiercingProtection='Schutz: Stich',MaxBluntProtection='Schutz: Schlag',WearEquipmentMalus='Ausrüstungsmalus'}},
 en={compare='Compared with',empty='Empty slot',loading='Loading item details …',same='No stat changes',quality='Quality',two='Two-handed: left hand becomes empty. Values below compare the right-hand item.',slots={head='Head',chest='Chest',legs='Legs',feet='Feet',arms='Arms',hands='Hands',anklel='Left ankle',ankler='Right ankle',earl='Left ear',earr='Right ear',wristl='Left wrist',wristr='Right wrist',fingerl='Left finger',fingerr='Right finger',necklace='Neck',headdress='Headdress',handr='Right hand',handl='Left hand'},stats={HpBuff='HP',SapBuff='Sap',StaBuff='Stamina',FocusBuff='Focus',DodgeModifier='Dodge',ParryModifier='Parry',CurrentDamage='Damage',Range='Range',ProtectionFactor='Protection factor',MaxSlashingProtection='Slashing protection',MaxPiercingProtection='Piercing protection',MaxBluntProtection='Blunt protection',WearEquipmentMalus='Equipment penalty'}},
 fr={compare='Comparaison avec',empty='Emplacement vide',loading='Chargement des détails …',same='Aucune variation',quality='Qualité',two='Deux mains : la main gauche sera vide. Comparaison avec l’objet de la main droite.',slots={head='Tête',chest='Torse',legs='Jambes',feet='Pieds',arms='Bras',hands='Mains',anklel='Cheville gauche',ankler='Cheville droite',earl='Oreille gauche',earr='Oreille droite',wristl='Poignet gauche',wristr='Poignet droit',fingerl='Doigt gauche',fingerr='Doigt droit',necklace='Cou',headdress='Coiffe',handr='Main droite',handl='Main gauche'},stats={HpBuff='PV',SapBuff='Sève',StaBuff='Endurance',FocusBuff='Concentration',DodgeModifier='Esquive',ParryModifier='Parade',CurrentDamage='Dégâts',Range='Portée',ProtectionFactor='Facteur de protection',MaxSlashingProtection='Protection tranchante',MaxPiercingProtection='Protection perforante',MaxBluntProtection='Protection contondante',WearEquipmentMalus='Malus d’équipement'}}
}
local fields={'HpBuff','SapBuff','StaBuff','FocusBuff','DodgeModifier','ParryModifier','CurrentDamage','Range','ProtectionFactor','MaxSlashingProtection','MaxPiercingProtection','MaxBluntProtection','WearEquipmentMalus'}
C.slots={}
for _,key in ipairs({'head','chest','legs','feet','arms','hands'}) do
 C.slots[#C.slots+1]={key=key,path='ui:interface:inventory:content:equip:armors:'..key}
end
for _,pair in ipairs({{'headdress','headdress'},{'earl','earing_l'},{'earr','earing_r'},
 {'necklace','neck'},{'wristl','bracelet_l'},{'wristr','bracelet_r'},
 {'fingerl','ring_l'},{'fingerr','ring_r'},{'anklel','anklet_l'},{'ankler','anklet_r'}}) do
 C.slots[#C.slots+1]={key=pair[1],path='ui:interface:inventory:content:equip:jewelry:'..pair[2]}
end
for _,key in ipairs({'handr','handl'}) do C.slots[#C.slots+1]={key=key,path='ui:interface:inventory:content:equip:'..key} end
local function db(path) return tonumber(getDbProp(path)) or 0 end
local function utf8(value)
 if type(value)=='string' then return value end
 local ok,result=pcall(function()return value:toUtf8()end)
 return ok and result or ''
end
function C:index(control)
 local path=tostring(control.sheet or '')
 local index=tonumber(path:match('^LOCAL:INVENTORY:BAG:(%d+)$'))
 if index then return index end
 if path:match('^LOCAL:INVENTORY:EQUIP:') or path:match('^LOCAL:INVENTORY:HAND:') then
  local ref=db(path..':INDEX_IN_BAG');return ref>0 and ref-1 or nil
 end
end
function C:compatible(source,destination)
 local before=destination.can_drop
 destination.can_drop=false
 local ok=pcall(function()runAH(destination,'isitem_slot','src='..source.id)end)
 local result=ok and destination.can_drop==true
 destination.can_drop=before
 return result
end
function C:read(index,probe)
 if index==nil or index<0 or db(BAG..index..':SHEET')==0 then return nil end
 local ctrl=getUI('ui:interface:padui_compare_probe:item'..probe)
 if not ctrl then return nil end
 local ok,info,name=pcall(function()
  ctrl.sheet=BAG..index;ctrl:invalidateCoords();ctrl:updateCoords()
  return ctrl:getItemInfo(),utf8(ctrl:getName())
 end)
 if not ok or type(info)~='table' or (tonumber(info.HpMax) or 0)<=0 then
  -- The native waiter requests details asynchronously; never compare its empty cache.
  pcall(function()ctrl:waitInfo()end)
  return nil
 end
 return info,name
end
local function number(value)
 if value==math.floor(value) then return tostring(value) end
 return string.format('%.2f',value)
end
function C:delta(field,new,old,label)
 new=tonumber(new);old=tonumber(old)
 if not new or not old then return nil end
 local difference=new-old
 if math.abs(difference)<0.0001 then return nil end
 local good=field=='WearEquipmentMalus' and difference<0 or (field~='WearEquipmentMalus' and difference>0)
 local tag=good and '@{6F6F}' or '@{F76F}'
 return label..': '..number(old)..' → '..number(new)..' ('..tag..(difference>0 and '+' or '')..number(difference)..'@{FFFF})'
end
function C:append(source,original)
 if db('UI:SAVE:PADUI:COMPARE_OFF')==1 then return original end
 local index=C:index(source)
 if index==nil then return original end
 local ok,current=pcall(function()return source:getItemInfo()end)
 if not ok or type(current)~='table' or (tonumber(current.HpMax) or 0)<=0 then return original end
 local text=words[PadUI:language()] or words.en
 local matches={}
 for _,slot in ipairs(C.slots) do
  local control=getUI(slot.path)
  if control and C:compatible(source,control) then matches[#matches+1]={slot=slot,control=control} end
 end
 if #matches==0 then return original end
 local output={utf8(original)}
 local sheet=db(BAG..index..':SHEET')
 local twoOk,two=pcall(function()return runExpr('is2HandItem('..sheet..')')end)
 if twoOk and two==true then output[#output+1]=text.two end
 local probe=0
 for _,match in ipairs(matches) do
  local peer=C:index(match.control)
  if peer~=index then
   probe=probe+1
   if probe>2 then break end
   local old,name
   if peer~=nil then old,name=C:read(peer,probe) end
   output[#output+1]='\n'..text.compare..' '..text.slots[match.slot.key]..(name and name~='' and (' — '..name) or '')
   if peer~=nil and not old then output[#output+1]=text.loading
   else
    if peer==nil then
     output[#output+1]=text.empty;old={}
     for _,field in ipairs(fields) do old[field]=0 end
    end
    local count=0
    for _,field in ipairs(fields) do
     local line=C:delta(field,current[field],old[field],text.stats[field])
     if line then output[#output+1]=line;count=count+1 end
    end
    local line=C:delta('QUALITY',db(BAG..index..':QUALITY'),peer~=nil and db(BAG..peer..':QUALITY') or 0,text.quality)
    if line then output[#output+1]=line;count=count+1 end
    if count==0 then output[#output+1]=text.same end
   end
  end
 end
 return table.concat(output,'\n')
end
function C:tooltip(source,original)
 local ok,result=pcall(function()return C:append(source,original)end)
 if not ok then return original end
 -- Older clients expect the tooltip hook to return a ucstring userdata.
 if type(original)~='string' then
  local converted,value=pcall(function()return ucstring(result)end)
  return converted and value or original
 end
 return result
end
