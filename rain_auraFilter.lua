local _, ns = ...

local debuffs = {
	["DEADKNIGHT"] = {
		[1] = function() return end, -- Blood
		[2] = function() return end, -- Frost
		[3] = function() return end, -- Unholy
	},
	["DRUID"] = {
		[1] = function() return end, -- Balance
		[2] = function() return end, -- Feral
		[3] = function() return end, -- Guardian
		[4] = function() return end, -- Restoration
	},
	["HUNTER"] = {
		[1] = function() return end, -- Beastmaster
		[2] = function() return end, -- Markmanship
		[3] = function() return end, -- Survival
	},
	["MAGE"] = {
		[1] = function() return end, -- Arcane
		[2] = function() return end, -- Fire
		[3] = function() return end, -- Frost
	},
	["MONK"] = {
		[1] = function() return end, -- Brewmaster
		[2] = function() return end, -- Mistweaver
		[3] = function() return end, -- Windwalker
	},
	["PALADIN"] = {
		[1] = function() return end, -- Holy
		[2] = function() return end, -- Protection
		[3] = function() return end, -- Retribution
	},
	["PRIEST"] = {
		[1] = function() return end, -- Discipline
		[2] = function() return end, -- Holy
		[3] = function() return end, -- Shadow
	},
	["ROGUE"] = {
		[1] = function() return end, -- Assasination
		[2] = function() return end, -- Combat
		[3] = function() return end, -- Subtlety
	},
	["SHAMAN"] = {
		[1] = function() return end, -- Elemental
		[2] = function() return end, -- Enchancement
		[3] = function() return end, -- Restoration
	},
	["WARLOCK"] = {
		[1] = function() return end, -- Affliction
		[2] = function() return end, -- Demonology
		[3] = function() return end, -- Destruction
	},
	["WARRIOR"] = {
		[1] = function() return end, -- Arms
		[2] = function() return end, -- Fury
		[3] = function() return end, -- Protection
	},
}

local sharedDebuffs = {
	[1] = {	-- Weakened Armor
		113746,	-- Weakened Armor
	},
	[2] = {	-- Physical Vulnerability
		81326,		-- Physical Vulnerability
		35290,		-- Gore (Boar)
		50518,		-- Ravage (Ravager)
		57386,		-- Stampede (Rhino)
		55749,		-- Acid Spit (Worm)
	},
	[3] = {	-- Magic Vulnerability
		93968,		-- Master Poisoner (Rogue)
		1490,		-- Curse of the Elements (Warlock)
		34889,		-- Fire Breath (Dragonhawk)
		24844,		-- Lithning Breath (Wind Serpent)
	},
	[4] = {	-- Weakened Blows
		115798,		-- Weakened Blows
		109466,		-- Curse of Enfeeblement (Warlock)
		50256,		-- Demoralizing Roar (Bear)
		24423,		-- Demoralizing Screech (Carrion Bird)
	},
	[5] = {	-- Slow Casting
		73975,		-- Necrotic Strike (DK)
		109466,		-- Curse of Enfeeblement (Warlock)
		5760,		-- Mind-numbling Poison (Rogue)
		50274,		-- Spore Cloud (Spore Bat)
		90315,		-- Tailspin (Fox)
		126402,		-- Trample (Goat)						-- TODO
		58604,		-- Lava Breath (Core Hound)
	},
	[6] = {	-- Mortal Wounds
		115804,		-- Mortal Wounds
		82654,		-- Widow Venom (Hunter)
		8680,		-- Wound Poison (Rogue)
		54680,		-- Monstrous Bite (Devilsaur)
	},
}

local crowdControl = {
	-- DRUID
	33786,		-- Cyclone
	2637,		-- Hibernate
	-- HUNTER
	3355,		-- Freezing Trap
	19386,		-- Wyvern Sting
	1513,		-- Scare Beast
	-- MAGE
	118,		-- Polymorph
	61305,		-- Polymorph (Black Cat)
	28272,		-- Polymorph (Pig)
	61721,		-- Polymorph (Rabbit)		-- TODO
	28271,		-- Polymorph (Turtle)		-- TODO
	-- MONK
	115078,		-- Paralysis
	-- PALADIN
	20066,		-- Repentance
	10326,		-- Turn Evil
	-- PRIEST
	9484,		-- Shackle Undead
	113792,		-- Psychic Terror (Psyfiend)
	-- ROGUE
	2094,		-- Blind
	6770,		-- Sap
	-- SHAMAN
	76780,		-- Bind Elemental
	51514,		-- Hex
	-- WARLOCK
	710,		-- Banish
	5484,		-- Howl of Terror
	118699,		-- Blood Fear / Fear
	6358,		-- Seduction (Succubus)
	115268,		-- Mesmerize (Shivarra)
}

local disarm = {
	-- HUNTER
	50541,		-- Clench (Scorpid)			-- TODO
	91644,		-- Snatch (Bird of Prey)
	-- MONK
	117368,		-- Grapple Weapon
	-- PRIEST
	64058,		-- Psychic Horror
	-- ROGUE
	51722,		-- Dismantle
	-- WARRIOR
	676,		-- Disarm
}

local canDisarm = {
	["DEATHKNIGHT"] = false,
	["DRUID"] = false,
	["HUNTER"] = true,
	["MAGE"] = false,
	["MONK"] = true,
	["PALADIN"] = false,
	["PRIEST"] = true,
	["ROGUE"] = true,
	["SHAMAN"] = false,
	["WARLOCK"] = false,
	["WARRIOR"] = true,
}

--[[
	The idea it to check for class and spec which are the interesting {de}buffs and throw their ids into a table
	which is then checked against in a custom aura filter

	GetPrimaryTalentTree returns 1, 2 or 3, so a call to debuffs[playerClass][primaryTalentTree] should return
	the debuff groups of interest for the player.

	I.e. debuffs["DRUID"][2] shall return 1, 3 and 6 which are then looked up in sharedDebuffs
--]]

ns.debuffIDs = {}
local _, playerClass = UnitClass("player")

local GetSharedDebuffs = function(...)
	for i = 1, select('#', ...) do
		local debuffGroup = select(i, ...)

		if (debuffGroup) then
			for _, spellID in ipairs(sharedDebuffs[debuffGroup]) do
				ns.debuffIDs[spellID] = true
				print("Debuff added for class", playerClass, ":", GetSpellLink(spellID))
			end
		end
	end
end

local GetCC = function()
	for _, spellID in ipairs(crowdControl) do
		ns.debuffIDs[spellID] = true
	end
end

local GetDisarm = function()
	if (canDisarm[playerClass]) then
		for _, spellID in ipairs(disarm) do
			ns.debuffIDs[spellID] = true
			print("Diarm added:", GetSpellLink(spellID))
		end
	end
end

local Update = function(self, event, ...)
	local spec = GetSpecialization()
	if (spec) then
		wipe(ns.debuffIDs)
		GetSharedDebuffs(debuffs[playerClass][spec]())
	end
	GetCC()
	GetDisarm()
end

local EventListener = CreateFrame("Frame")
EventListener:RegisterEvent("PLAYER_TALENT_UPDATE")
EventListener:RegisterEvent("PLAYER_ENTERING_WORLD")
EventListener:SetScript("OnEvent", Update)
