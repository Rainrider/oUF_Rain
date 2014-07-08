local _, ns = ...

local Debug = ns.Debug

local LPS = LibStub("LibPlayerSpells-1.0")

local _, playerClass = UnitClass("player")

local PlayerWhiteList = {
	-- raid buffs
	[  2825] = true, -- Bloodlust
	[ 32182] = true, -- Heroism
	[ 80353] = true, -- Time Warp
	[ 90355] = true, -- Ancient Hysteria
	[146555] = true, -- Drums of Rage
	[  1022] = true, -- Hand of Protection
	[ 20707] = true, -- Soulstone
	-- enchant procs where blizz forgot to tag the caster as the player
	[116631] = true, -- Colossus
	[120032] = true, -- Dancing Steel (agi)
	[118335] = true, -- Dancing Steel (str) ???
	[104993] = true, -- Jade Spirit ???
	[116660] = true, -- River's Song ???
}

local ImportantDebuffs = {
	[ 6788] = playerClass == "PRIEST", -- Weakened Soul
	[25771] = playerClass == "PALADIN", -- Forbearance
	[80354] = true, -- Temporal Displacement (applied by Time Warp)
	[95809] = true, -- Insanity (applied by Ancient Hysteria)
	[57724] = true, -- Sated (applied by Bloodlust)
	[57723] = true, -- Exhaustion (applied by Heroism and Drums of Rage)
}

local TankSwapDebuffs = {
	----------------------
	-- MOGU'SHAN VAULTS --
	----------------------
	[896] = {
	-- Feng the Accursed
		[131788] =  2, -- Lightning Lash
		[116942] =  2, -- Flaming Spear
		[131790] =  2, -- Arcane Shock
	-- Gara'jal the Spiritbinder
		[122151] =  0, -- Voodoo Dolls (Probably unneeded)
	-- Elegon
		[117878] = 10, -- Overcharged (not in LFR)
	},
	-------------------
	-- HEART OF FEAR --
	-------------------
	[897] = {
	-- Blade Lord Ta'yak
		[123474] =  2, -- Overwhelming Assault
	-- Amber-Shaper Un'sok
		[122370] =  1, -- Reshape Life
		[121949] =  1, -- Parasitic Growth TODO: can it be applied to tanks?
	-- Grand Empress Shek'zeer
		[123707] =  4, -- Eyes of the Empress
	},
	-------------------------------
	-- TERRACE OF ENDLESS SPRING --
	-------------------------------
	[886] = {
	-- Tsulong
		[122752] =  1, -- Shadow Breath
	-- Lei Shi
		[123121] = 30, -- Spray
	},
	-----------------------
	-- THRONE OF THUNDER --
	-----------------------
	[930] = {
	-- Jin'rokh the Breaker
		[138349] =  1, -- Static Wound
	-- Horridon
		[136767] =  6, -- Triple Puncture
	-- Council of Elders
		[136903] = 12, -- Frigid Assault
	-- Ji-Kun
		[134366] =  3, -- Talon Rake
		[140092] = 10, -- Infected Talons
	-- Durumu the Forgotten
		[133767] =  4, -- Serious Wound
	-- Primordius
		[136050] =  6, -- Malformed Blood
	-- Dark Animus
		[136962] =  1, -- Anima Ring
	-- Iron Qon
		[134691] =  5, -- Impale
	-- Twin Consorts
		[137375] =  1, -- Beast of Nightmares
		[137408] =  4, -- Fan of Flames
	-- Lei Shen
		[134916] =  1, -- Decapitate
		[136478] =  1, -- Fusion Slash
		[136914] = 10, -- Electrical Shock
		[136913] = 10, -- Overwhelming Power TODO: which one get applied to the tank
	},
	------------------------
	-- SIEGE OF ORGRIMMAR --
	------------------------
	[953] = {
	-- Immerseus
		[143436] =  1, -- Corrosive Blast
	-- Norushen
		[146124] =  5, -- Self Doubt
	-- Sha of Pride
		[144358] =  1, -- Wounded Pride
	-- Galakras
		[147029] =  3, -- Flames of Galakrond
	-- Iron Juggernaut
		[144467] =  3, -- Ignite Armor
	-- Kor'kron Dark Shaman
		[144215] =  5, -- Froststorm Strike
	-- General Nazgrim
		[143494] =  3, -- Sundering Blow
	-- Malkorok
		[142990] = 12, -- Fatal Strike
	-- Thok the Bloodthirsty
		[143766] =  3, -- Panic (applied by Fearsome Roar)
		[143780] =  3, -- Acid Breath
		[143773] =  3, -- Freezing Breath
		[ 83855] =  3, -- Scorching Breath ??? id
	-- Siegecrafter Blackfuse
		[143385] =  3, -- Electrostatic Charge
	-- Paragons of the Klaxxi
		-- Skeer the Bloodseeker
		[143275] =  3, -- Hewn (only if Rik'kal lives) ??? stacks
		-- Rik'kal the Dissector
		[143279] =  3, -- Genetic Alteration (only if Skeer lives) ??? stacks
		-- Xaril the Poisoned Mind
		[142929] =  3, -- Tenderizing Strikes (only of Kil'ruk lives) ??? stacks
		-- Kil'ruk the Wind-Reaver
		[142931] =  3, -- Exposed Veins (only if Xaril lives) ??? stackSize
	-- Garrosh Hellscream
		[145183] =  3, -- Gripping Despair
		[145195] =  3, -- Empowered Gripping Despair
	},
}

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

local DebuffIDs = {}
local TankDebuffs = {}

local UpdateDisarms = function(canDisarm)
	for i = 1, #Disarms do
		DebuffIDs[Disarms[i]] = canDisarm
	end
end

local UpdateTaunts = function(addTaunt)
	for i = 1, #Taunts do
		DebuffIDs[Taunts[i]] = addTaunt
	end
end

local RaidAuras = {}

local PopulateFilterTable = function(method, FilterTable, anyOf, include, exclude, role)
	if (method == "LPS") then
		if (not LPS) then
			Debug("auraFilter", "|cffff0000LibPlayerSpells not found.|r")
			return
		end
		-- clean-up if the player respec'd
		for spellID, forRole in pairs(FilterTable) do
			if (forRole ~= true and forRole ~= role) then
				Debug("auraFilter", "Cleaning", spellID, GetSpellLink(spellID), "for role", forRole)
				FilterTable[spellID] = nil
			end
		end

		for buff, flags in LPS:IterateSpells(anyOf, include, exclude) do
			FilterTable[buff] = role
			Debug("auraFilter", "Watching", buff, GetSpellLink(buff), "for role", role)
		end
	elseif (method == "BigWigs") then
		if (not BigWigsLoader or not BigWigsLoader.RegisterMessage) then
			Debug("aurafilter", "|cffff0000BigWigs not found or BigWigs verion too low.|r")
			return
		end

		BigWigsLoader.RegisterMessage(RaidAuras, "BigWigs_OnBossLog", function(_, bossMod, event, ...)
			if (event ~= "SPELL_AURA_APPLIED" and event ~= "SPELL_AURA_APPLIED_DOSE" and event ~= "SPELL_CAST_SUCCESS") then return end
			for i = 1, select("#", ...) do
				local id = select(i, ...)
				Debug("auraFilter", "Watching", id, GetSpellLink(id), "for", bossMod:GetName())
				FilterTable[id] = bossMod
			end
		end)

		BigWigsLoader.RegisterMessage(RaidAuras, "BigWigs_OnBossDisable", function(_, bossMod)
			Debug("auraFilter", bossMod:GetName(), "disabled, cleaning the debuffs list")
			for id, mod in pairs(FilterTable) do
				if mod == bossMod then
					FilterTable[id] = nil
				end
			end
		end)

		Debug("auraFilter", "Using BigWigs for encounter debuffs")
	else
		Debug("auraFilter", "|cffff0000Filtering method", method, "unknown.|r")
	end
end

ns.CustomFilter = {
	player = function(Auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
		if (aura.isDebuff) then
			return true
		else
			if ((aura.isPlayer or caster == "pet") and duration <= 300 and duration > 0 or PlayerWhiteList[spellID]) then
				return true
			end
		end
	end,
	target = function(Auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
		if (caster == "pet") then
			aura.isPlayer = true
		end

		if (not UnitIsFriend("player", unit)) then
			if (aura.isDebuff) then
				if(aura.isPlayer or isBossDebuff or not UnitIsPlayer(caster) or DebuffIDs[spellID]) then
					return true
				end
			else
				return true
			end
		else
			if (aura.isDebuff) then
				return true
			else
				return (Auras.onlyShowPlayer and aura.isPlayer) or (not Auras.onlyShowPlayer and name)
			end
		end
	end,
	focus = function(Auras, unit, aura, _, _, _, count, _, duration, timeLeft, _, _, _, spellID)
		local stackCount = TankDebuffs[spellID]
		if (stackCount) then
			-- TODO: add flashing if stackCount == count
			return true
		end
	end,
	raid = function(_, _, _, _, _, _, _, _, _, _, _, _, _, spellID)
		if (RaidAuras[spellID]) then
			return true
		end
	end
}

local Frame = CreateFrame("Frame")
Frame:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
Frame:RegisterEvent("PLAYER_ENTERING_WORLD")
Frame:RegisterEvent("SPELLS_CHANGED")
Frame:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)

function Frame:PLAYER_SPECIALIZATION_CHANGED(unit)
	if not unit or unit == "player" then
		local _, _, _, _, _, role = GetSpecializationInfo(GetSpecialization() or 0) -- we can't rely on ns.playerSpec being correct
		if role == "TANK" then
			PopulateFilterTable("LPS", RaidAuras, "SURVIVAL", "AURA", "PERSONAL", role)
			UpdateTaunts(true)
			self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
		else
			PopulateFilterTable("LPS", RaidAuras, "SURVIVAL", "AURA", "PERSONAL", role) -- to issue a clean-up
			UpdateTaunts()
			self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
		end
	end
end

function Frame:SPELLS_CHANGED()
	UpdateDisarms(CanDisarm[playerClass]() or nil)
end

function Frame:ZONE_CHANGED_NEW_AREA()
	local mapID = GetCurrentMapAreaID()
	local EncounterDebuffs = TankSwapDebuffs[mapID]
	if (not EncounterDebuffs) then return end
	Debug("auraFilter", "Adding tank swap debuffs for", GetMapNameByID(mapID))
	for spellID, stackCount in pairs(EncounterDebuffs) do
		Debug("auraFilter", spellID, GetSpellLink(spellID), stackCount)
		TankDebuffs[spellID] = stackCount
	end
end

function Frame:PLAYER_ENTERING_WORLD()
	self:PLAYER_SPECIALIZATION_CHANGED("player")
	self:SPELLS_CHANGED()
	self:ZONE_CHANGED_NEW_AREA()
end
