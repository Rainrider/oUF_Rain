local _, ns = ...

local ClassDebuffs = {
	["DEADKNIGHT"] = {
		[1] = {}, -- Blood
		[2] = {}, -- Frost
		[3] = {}, -- Unholy
	},
	["DRUID"] = {
		[1] = {}, -- Balance
		[2] = {}, -- Feral
		[3] = {}, -- Guardian
		[4] = {}, -- Restoration
	},
	["HUNTER"] = {
		[1] = {}, -- Beastmaster
		[2] = {}, -- Markmanship
		[3] = {}, -- Survival
	},
	["MAGE"] = {
		[1] = {}, -- Arcane
		[2] = {}, -- Fire
		[3] = {}, -- Frost
	},
	["MONK"] = {
		[1] = {}, -- Brewmaster
		[2] = {}, -- Mistweaver
		[3] = {}, -- Windwalker
	},
	["PALADIN"] = {
		[1] = {}, -- Holy
		[2] = {}, -- Protection
		[3] = {}, -- Retribution
	},
	["PRIEST"] = {
		[1] = {}, -- Discipline
		[2] = {}, -- Holy
		[3] = {}, -- Shadow
	},
	["ROGUE"] = {
		[1] = {}, -- Assasination
		[2] = {}, -- Combat
		[3] = {}, -- Subtlety
	},
	["SHAMAN"] = {
		[1] = {}, -- Elemental
		[2] = {}, -- Enchancement
		[3] = {}, -- Restoration
	},
	["WARLOCK"] = {
		[1] = {}, -- Affliction
		[2] = {}, -- Demonology
		[3] = {}, -- Destruction
	},
	["WARRIOR"] = {
		[1] = {}, -- Arms
		[2] = {}, -- Fury
		[3] = {}, -- Protection
	},
}

local SharedDebuffs = {
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

local Disarm = {
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

local CanDisarm = {
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

ns.DebuffIDs = {}
local _, playerClass = UnitClass("player")

local GetSharedDebuffs = function(...)
	for i = 1, select('#', ...) do
		local debuffGroup = select(i, ...)

		if (debuffGroup) then
			for _, spellID in ipairs(SharedDebuffs[debuffGroup]) do
				ns.DebuffIDs[spellID] = true
			end
		end
	end
end

local GetDisarm = function()
	if (CanDisarm[playerClass]) then
		for _, spellID in ipairs(Disarm) do
			ns.DebuffIDs[spellID] = true
		end
	end
end

local Update = function(self, event, ...)
	local spec = GetSpecialization()
	if (spec) then
		wipe(ns.DebuffIDs)
		GetSharedDebuffs(unpack(ClassDebuffs[playerClass][spec]))
	end
	GetDisarm()
end

local EventListener = CreateFrame("Frame")
EventListener:RegisterEvent("PLAYER_TALENT_UPDATE")
EventListener:RegisterEvent("PLAYER_ENTERING_WORLD")
EventListener:SetScript("OnEvent", Update)
