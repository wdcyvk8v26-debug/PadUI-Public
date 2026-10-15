-- PadUI: shared translations and native UI integration. Lua 5.1 compatible.

-- Safe wrappers for getPlayerName and getPlayerPos to prevent SIGSEGV
-- on Linux/POSIX when invoked before the character entity is spawned.
if not _G.__padui_safe_player_wrapped then
	_G.__padui_safe_player_wrapped = true
	local _orig_getPlayerName = getPlayerName
	local _orig_getPlayerPos = getPlayerPos

	function isPlayerReady()
		return game ~= nil and game.InGameDbInitialized == true
	end

	function getPlayerName()
		if not (game and game.InGameDbInitialized) then
			return ""
		end
		if _orig_getPlayerName then
			local name = _orig_getPlayerName()
			if name and name ~= "" then
				return name
			end
		end
		return ""
	end

	function getPlayerPos()
		if game and game.InGameDbInitialized and _orig_getPlayerPos then
			return _orig_getPlayerPos()
		end
		return 0, 0, 0
	end
end

PadUI = PadUI or {}
local P = PadUI
 P.version = "0.8.10"
P.texts = {
 de = {
  item_assigned="Belegt",
  skill_tree="Skillbaum auswählen", skill_fight="Kampf", skill_magic="Magie", skill_craft="Handwerk", skill_harvest="Ernte", skill_back="Zurück zu den vier Skillbäumen",
  skill_choose="Skill auswählen", skill_level="Level", skill_progress="zum nächsten Level", skill_tip="Linksklick: Skill wählen / Rechtsklick: Auswahl entfernen", skill_max="Maximum dieses Zweigs erreicht", skill_empty="Noch keine erlernten Skills verfügbar", skill_previous="Vorherige Seite", skill_next="Nächste Seite", skill_clear="Auswahl entfernen",
  hide_self="Eigenen Charakter ausblenden", show_self="Eigenen Charakter anzeigen", humidity="Feucht.", humidity_tip="Aktuelle Feuchtigkeit wie in der Wetteranzeige auf der Karte.",
  team="PadUI Team", inventory="PadUI Tasche", items="PadUI Itemleiste",
  waiting="Warte auf Spieldaten", self="Du", absent="Abwesend", ko="KO", target="Ziel", leader="Leitung",
  sort_name="Sort.: Name", sort_hp="Sort.: HP", sort_missing="Sort.: fehlt",
  name_order="Name: A–Z", hp_order="HP: meiste zuerst (%)", missing_order="Fehlende HP: meiste zuerst (%)",
  sort_tip="Sortierung nach Name, HP oder fehlendem HP-Anteil", sap="S ", stamina="A ",
  dodge="Ausw.", parry="Parade", base="Basis", modifier="Erfolgsmod.", active="aktiv", activate="Klick zum Aktivieren",
  volume_tip="Volumen / maximales Volumen. Klick öffnet das Inventar.",
  item_tip="Linksklick: benutzen / anlegen / Details. Rechtsklick: Optionen. Item hierher ziehen: belegen.",
  empty_tip="Item aus der Tasche hierher ziehen oder klicken, um eines auszuwählen.",
  missing_tip="Dieses Item ist nicht in der Tasche. Die Verknüpfung bleibt gespeichert.",
  choose="Item auswählen", clear="Verknüpfung entfernen", details="Details", use="Benutzen / Anlegen", close="Schließen",
  language_tip="PadUI-Sprache wechseln: Auto, Deutsch, English, Français", auto="Auto",
  not_found="Item nicht in der Tasche gefunden.", locked="Dieses Item ist gesperrt.", crafting="Handitems können während des Craftens nicht gewechselt werden."
 },
 en = {
  item_assigned="Assigned",
  skill_tree="Choose skill tree", skill_fight="Fight", skill_magic="Magic", skill_craft="Craft", skill_harvest="Harvest", skill_back="Back to the four skill trees",
  skill_choose="Choose skill", skill_level="Level", skill_progress="towards next level", skill_tip="Left click: choose skill / Right click: clear selection", skill_max="Maximum of this branch reached", skill_empty="No learned skills available yet", skill_previous="Previous page", skill_next="Next page", skill_clear="Clear selection",
  hide_self="Hide own character", show_self="Show own character", humidity="Humidity", humidity_tip="Current humidity, as shown by the map weather display.",
  team="PadUI Team", inventory="PadUI Bag", items="PadUI Item bar",
  waiting="Waiting for game data", self="You", absent="Away", ko="KO", target="Target", leader="Leader",
  sort_name="Sort: Name", sort_hp="Sort: HP", sort_missing="Sort: missing",
  name_order="Name: A–Z", hp_order="HP: highest first (%)", missing_order="Missing HP: highest first (%)",
  sort_tip="Sort by name, HP or missing HP percentage", sap="S ", stamina="St ",
  dodge="Dodge", parry="Parry", base="Base", modifier="Success mod.", active="active", activate="Click to activate",
  volume_tip="Bulk / maximum bulk. Click to open the inventory.",
  item_tip="Left click: use / equip / details. Right click: options. Drop a bag item here to assign it.",
  empty_tip="Drop an item from your bag here, or click to choose one.",
  missing_tip="This item is not in your bag. Its shortcut stays saved.",
  choose="Choose item", clear="Remove shortcut", details="Details", use="Use / Equip", close="Close",
  language_tip="Change PadUI language: Auto, Deutsch, English, Français", auto="Auto",
  not_found="Item not found in your bag.", locked="This item is locked.", crafting="Hand items cannot be changed while crafting."
 },
 fr = {
  item_assigned="Affecté",
  skill_tree="Choisir un arbre", skill_fight="Combat", skill_magic="Magie", skill_craft="Artisanat", skill_harvest="Récolte", skill_back="Retour aux quatre arbres",
  skill_choose="Choisir une compétence", skill_level="Niveau", skill_progress="vers le niveau suivant", skill_tip="Clic gauche : choisir / Clic droit : retirer", skill_max="Maximum de cette branche atteint", skill_empty="Aucune compétence apprise disponible", skill_previous="Page précédente", skill_next="Page suivante", skill_clear="Retirer la sélection",
  hide_self="Masquer son personnage", show_self="Afficher son personnage", humidity="Humidité", humidity_tip="Humidité actuelle, comme dans la météo de la carte.",
  team="PadUI Équipe", inventory="PadUI Sac", items="PadUI Barre d’objets",
  waiting="En attente des données", self="Vous", absent="Absent", ko="KO", target="Cible", leader="Chef",
  sort_name="Tri : nom", sort_hp="Tri : PV", sort_missing="Tri : manque",
  name_order="Nom : A–Z", hp_order="PV : plus élevés d’abord (%)", missing_order="PV manquants : plus élevés d’abord (%)",
  sort_tip="Trier par nom, PV ou pourcentage de PV manquants", sap="S ", stamina="E ",
  dodge="Esquive", parry="Parade", base="Base", modifier="Mod. réussite", active="actif", activate="Cliquer pour activer",
  volume_tip="Encombrement / encombrement maximal. Cliquer pour ouvrir l’inventaire.",
  item_tip="Clic gauche : utiliser / équiper / détails. Clic droit : options. Glisser un objet du sac ici pour l’affecter.",
  empty_tip="Glisser un objet du sac ici ou cliquer pour en choisir un.",
  missing_tip="Cet objet n’est pas dans votre sac. Son raccourci reste enregistré.",
  choose="Choisir un objet", clear="Retirer le raccourci", details="Détails", use="Utiliser / Équiper", close="Fermer",
  language_tip="Changer la langue de PadUI : Auto, Deutsch, English, Français", auto="Auto",
  not_found="Objet introuvable dans votre sac.", locked="Cet objet est verrouillé.", crafting="Les objets en main ne peuvent pas être changés pendant la fabrication."
 }
}

function P:accent(alpha)
 if PadUISettings then return PadUISettings:accent(alpha) end
 return "110 235 225 "..tostring(alpha or 255)
end
function P:language()
 local mode = tonumber(getDbProp("UI:SAVE:PADUI:LANGUAGE")) or 0
 if mode == 1 then return "de" elseif mode == 2 then return "en" elseif mode == 3 then return "fr" end
 local ok, lang = pcall(function() return getClientCfgVar("LanguageCode") end)
 lang = ok and tostring(lang):lower():sub(1,2) or "en"
 return P.texts[lang] and lang or "en"
end
function P:tr(key)
 return P.texts[P:language()][key] or P.texts.en[key] or key
end
function P:setText(path, text, property)
 local node = getUI(path)
 if node then node[property or "hardtext"] = text end
end
function P:buildMenu(path, entries)
 local menu = getUI(path)
 if not menu then return end
 local root = menu:getRootMenu()
 root:reset()
 for _, e in ipairs(entries) do
  local text = P:tr(e[1])
  local ok = pcall(function() root:addLine(text, "lua", e[2], e[1]) end)
  -- Older clients require ucstring for menu labels; newer clients use UTF-8 strings.
  if not ok then root:addLine(ucstring(text), "lua", e[2], e[1]) end
 end
end
function P:sortMenu()
 P:buildMenu("ui:interface:team_compact_sort_menu", {
  {"name_order", "RyzomTeamUI:setSort('name')"},
  {"hp_order", "RyzomTeamUI:setSort('hp')"},
  {"missing_order", "RyzomTeamUI:setSort('missing')"},
  {RyzomTeamUI:showSelf() and "hide_self" or "show_self", "RyzomTeamUI:toggleSelf()"}
 })
end
function P:localize(force)
 local lang = P:language()
 if not force and P.lastLanguage == lang then return end
 P.lastLanguage = lang
 P:setText("ui:interface:team_compact:content:waiting", P:tr("waiting"))
 P:setText("ui:interface:team_compact:content:sort_controls:sort_button", P:tr("sort_tip"), "tooltip")
 P:setText("ui:interface:inventory_compact:content:open_inventory", P:tr("volume_tip"), "tooltip")
 P:setText("ui:interface:gestion_windows:inventory:inventory_compact:text", P:tr("inventory"))
 P:setText("ui:interface:gestion_windows:inventory:padui_items:text", P:tr("items"))
 P:setText("ui:interface:gestion_windows:memory:team_compact:text", P:tr("team"))
 P:setText("ui:interface:padui_item_choose:choose_title", P:tr("choose"))
 P:setText("ui:interface:padui_item_choose:close", P:tr("close"), "tooltip")
end
function P:cycleLanguage()
 local value = tonumber(getDbProp("UI:SAVE:PADUI:LANGUAGE")) or 0
 setDbProp("UI:SAVE:PADUI:LANGUAGE", (value + 1) % 4)
 P:localize(true)
 if PadUISettings then PadUISettings:refresh() end
 if RyzomTeamUI then RyzomTeamUI.lastTick=nil; RyzomTeamUI:update() end
 if RyzomInventoryCompact then RyzomInventoryCompact.lastRefresh=nil; RyzomInventoryCompact:update() end
 if PadUIQuickbar then PadUIQuickbar.lastRefresh=nil; PadUIQuickbar:update() end
end
function P:start()
 P.Team, P.Inventory, P.Target, P.ActionTimer = RyzomTeamUI, RyzomInventoryCompact, RyzomTargetDistance, RyzomActionTimer
 P.Skill = PadUISkill
 P.Items = PadUIQuickbar
 P.Auras = PadUIAuras
 P.Settings = PadUISettings
 P.Timers = PadUITimers
 P.Mobs = PadUIMobs
 -- One failed window initializer must not prevent the others from starting.
 for _,name in ipairs({"Skill","Items","Auras","Settings","Timers","Mobs"}) do
  local module=P[name]
  if module then
   local ok,err=pcall(function() module:start() end)
   if not ok then debugInfo("PadUI initialization: "..tostring(err)) end
  end
 end
 P:localize(true)
end
