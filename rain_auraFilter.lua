local _, ns = ...

local Taunts = {
	-- Death Knight
	56222,		-- Dark Command
	49560,		-- Death Grip
	-- Druid
	6795,		-- Growl
	-- Hunter
	2649,		-- Growl (Pet)
	20736,		-- Distracting Shot
	-- Monk
	116189,		-- Provoke
	118635,		-- Provoke through the Black Ox Statue
	118585,		-- Leer of the Ox
	-- Paladin
	62124,		-- Reckoning
	31790,		-- Righteous Defense -- TODO: confirm debuff
	-- Rogue
	113612,		-- Growl (Symbiosis)
	-- Shaman
	73684,		-- Unleash Earth (Unleash Elements with Rockbiter Weapon Imbue)
	-- Warlock
	97827,		-- Provocation (Dark Apotheosis)
	17735,		-- Suffering (Voidwalker and Voidlord)
	-- Warrior
	355,		-- Taunt
	114198,		-- Mocking Banner
}

local Disarms = {
	-- HUNTER
	50541,		-- Clench (Scorpid)
	91644,		-- Snatch (Bird of Prey)
	-- MONK
	117368,		-- Grapple Weapon
	-- PRIEST
	64058,		-- Psychic Horror
	-- ROGUE
	51722,		-- Dismantle
	-- Warlock
	118093,		-- Disarm (Voidwalker or Voidlord)
	-- WARRIOR
	676,		-- Disarm
}

local CanDisarm = {
	["DEATHKNIGHT"] = function() end,
	["DRUID"] = function() end,
	["HUNTER"] = function() return IsSpellKnown(50541, true) or IsSpellKnown(91644, true) end,
	["MAGE"] = function() end,
	["MONK"] = function() return IsSpellKnown(117368) end,
	["PALADIN"] = function() end,
	["PRIEST"] = function() return IsSpellKnown(64044) end, -- Psychic Horror
	["ROGUE"] = function() return IsSpellKnown(51722) end,
	["SHAMAN"] = function() end,
	["WARLOCK"] = function() return IsSpellKnown(118093, true) end,
	["WARRIOR"] = function() return IsSpellKnown(676) end,
}

ns.DebuffIDs = {}
local _, playerClass = UnitClass("player")
local playerSpec = GetSpecialization() or 0

local UpdateDisarms = function(canDisarm)
	for i = 1, #Disarms do
		ns.DebuffIDs[Disarms[i]] = canDisarm
	end
end

local UpdateTaunts = function(addTaunt)
	for i = 1, #Taunts do
		ns.DebuffIDs[Taunts[i]] = addTaunt
	end
end

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("SPELLS_CHANGED")
Frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

function Frame:PLAYER_SPECIALIZATION_CHANGED(unit)
	if not unit or unit == "player" then
		local _, _, _, _, _, role = GetSpecializationInfo(playerSpec)
		UpdateTaunts(role == "TANK" or nil)
	end
end

function Frame:SPELLS_CHANGED()
	UpdateDisarms(CanDisarm[playerClass]() or nil)
end

function Frame:PLAYER_ENTERING_WORLD()
	self:PLAYER_SPECIALIZATION_CHANGED("player")
	self:SPELLS_CHANGED()
end