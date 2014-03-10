local _, ns = ...

local PlayerWhiteList = {
	-- raid buffs
	[2825]   = true, -- Bloodlust
	[32182]  = true, -- Heroism
	[80353]  = true, -- Time Warp
	[90355]  = true, -- Ancient Hysteria
	[1022]   = true, -- Hand of Protection
	-- enchant procs where blizz forgot to tag the caster as the player
	[116631] = true, -- Colossus
	[120032] = true, -- Dancing Steel (agi)
	[118335] = true, -- Dancing Steel (str) ???
	[104993] = true, -- Jade Spirit ???
	[116660] = true, -- River's Song ???
}

--- [encounterID] = {
---		debuffID = stackSize (0 means spot away when debuff expires)
--- }

local TankSwapDebuffs = {
	----------------------
	-- MOGU'SHAN VAULTS --
	----------------------
	-- Feng the Accursed
	[1390] = {
		[131788] = 2, -- Lightning Lash
		[116942] = 2, -- Flaming Spear
		[131790] = 2, -- Arcane Shock
	},
	-- Gara'jal the Spiritbinder
	[1434] = {
		[122151] = 0, -- Voodoo Dolls (Probably unneeded)
	},
	 -- Elegon
	[1500] = {
		[117878] = 10, -- Overcharged (not in LFR)
	},
	-------------------
	-- HEART OF FEAR --
	-------------------
	-- Blade Lord Ta'yak
	[1504] = {
		[123474] = 2, -- Overwhelming Assault
	},
	 -- Amber-Shaper Un'sok
	[1499] = {
		[122370] = 1, -- Reshape Life
		[121949] = 1, -- Parasitic Growth TODO: can it be applied to tanks?
	},
	 -- Grand Empress Shek'zeer
	[1501] = {
		[123707] = 4, -- Eyes of the Empress
	},
	-------------------------------
	-- TERRACE OF ENDLESS SPRING --
	-------------------------------
	-- Tsulong 742
	[1505] = {
		[122752] = 1, -- Shadow Breath
	},
	-- Lei Shi 729
	[1506] = {
		[123121] = 30, -- Spray
	},
	-----------------------
	-- THRONE OF THUNDER --
	-----------------------
	-- Jin'rokh the Breaker
	[1577] = {
		[138349] = 1, -- Static Wound
	},
	-- Horridon
	[1575] = {
		[136767] = 6, -- Triple Puncture
	},
	-- Council of Elders
	[1570] = {
		[136903] = 12, -- Frigid Assault
	},
	-- Ji-Kun
	[1573] = {
		[134366] = 3, -- Talon Rake
		[140092] = 10, -- Infected Talons
	},
	-- Durumu the Forgotten
	[1572] = {
		[133767] = 4, -- Serious Wound
	},
	-- Primordius
	[1574] = {
		[136050] = 6, -- Malformed Blood
	},
	-- Dark Animus
	[1576] = {
		[136962] = 1, -- Anima Ring
	},
	-- Iron Qon
	[1559] = {
		[134691] = 5, -- Impale
	},
	-- Twin Consorts
	[1560] = {
		[137375] = 1, -- Beast of Nightmares
		[137408] = 4, -- Fan of Flames
	},
	-- Lei Shen
	[1579] = {
		[134916] = 1, -- Decapitate
		[136478] = 1, -- Fusion Slash
		[136914] = 10, -- Electrical Shock
		[136913] = 10, -- Overwhelming Power TODO: which one get applied to the tank
	},
	------------------------
	-- Siege of Orgrimmar --
	------------------------
	-- Immerseus
	[1602] = {
		[143436] = 1, -- Corrosive Blast
	},
	-- Norushen
	[1624] = {
		[146124] = 1, -- Self Doubt
	},
	-- Sha of Pride
	[1604] = {
		[144358] = 5, -- Wounded Pride
	},
	-- Galakras
	[1622] = {
		[147029] = 3, -- Flames of Galakrond
	},
	-- Iron Juggernaut
	[1600] = {
		[144467] = 4, -- Ignite Armor
	},
	-- Kor'kron Dark Shaman
	[1606] = {
		[144215] = 1, -- Froststorm Strike
	},
	-- General Nazgrim
	[1603] = {
		[143494] = 5, -- Sundering Blow
	},
	-- Malkorok
	[1595] = {
		[142990] = 3, -- Fatal Strike ??? stacks
	},
	-- Thok the Bloodthirsty
	[1599] = {
		[143766] = 3, -- Panic (applied by Fearsome Roar)
		[143780] = 3, -- Acid Breath
		[143773] = 3, -- Freezing Breath
		 [83855] = 3, -- Scorching Breath ??? id
	},
	-- Siegecrafter Blackfuse
	[1601] = {
		[143385] = 3, -- Electrostatic Charge
	},
	-- Paragons of the Klaxxi
	[1593] = {
		-- Skeer the Bloodseeker
		[143275] = 3, -- Hewn (only if Rik'kal lives) ??? stacks
		-- Rik'kal the Dissector
		[143279] = 3, -- Genetic Alteration (only if Skeer lives) ??? stacks
		-- Xaril the Poisoned Mind
		[142929] = 3, -- Tenderizing Strikes (only of Kil'ruk lives) ??? stacks
		-- Kil'ruk the Wind-Reaver
		[142931] = 3, -- Exposed Veins (only if Xaril lives) ??? stackSize
	},
	-- Garrosh Hellscream
	[1623] = {
		[145183] = 8, -- Gripping Despair
		[145195] = 8, -- Empowered Gripping Despair
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

local _, playerClass = UnitClass("player")

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
				if(aura.isPlayer or isBossDebuff or DebuffIDs[spellID]) then
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
			UpdateTaunts(true)
			self:RegisterEvent("ENCOUNTER_START")
			self:RegisterEvent("ENCOUNTER_END")
		else
			UpdateTaunts()
			self:UnregisterEvent("ENCOUNTER_START")
			self:UnregisterEvent("ENCOUNTER_END")
		end
	end
end

function Frame:SPELLS_CHANGED()
	UpdateDisarms(CanDisarm[playerClass]() or nil)
end

function Frame:PLAYER_ENTERING_WORLD()
	self:PLAYER_SPECIALIZATION_CHANGED("player")
	self:SPELLS_CHANGED()
	if (not IsEncounterInProgress()) then
		ns.db.encounterID = nil
	end
	if (ns.db.encounterID) then
		self:ENCOUNTER_START(ns.db.encounterID)
	end
end

function Frame:ENCOUNTER_START(encounterID, name, difficultyID, size)
	ns.db.encounterID = encounterID
	table.wipe(TankDebuffs)
	local currentEncounterDebuffs = TankSwapDebuffs[encounterID]
	if currentEncounterDebuffs then
		for spellID, stackCount in pairs(currentEncounterDebuffs) do
			TankDebuffs[spellID] = stackCount
		end
	end
	print("Tracking following debuffs for", name)
	for spellID in pairs(TankDebuffs) do
		print(string.gsub(GetSpellLink(spellID), "|", "\124"))
	end
end

function Frame:ENCOUNTER_END(encounterID, name, difficultyID, size, success)
	ns.db.encounterID = nil
	table.wipe(TankDebuffs)
end