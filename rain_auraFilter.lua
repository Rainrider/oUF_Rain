local _, ns = ...

--[[
	Criteria for inclusion:
		Actively applying
		Not part of standard rotation
		I.e. Frost DK will always use Frost Fever and thus always
		     apply Physical Vulnerability, so no need to see other debuffs in the category.
 --]]

local ClassDebuffs = {
	["DEATHKNIGHT"] = {
		[1] = {5}, -- Blood
		[2] = {5}, -- Frost
		[3] = {5}, -- Unholy
	},
	["DRUID"] = {
		[1] = {1}, -- Balance
		[2] = {1}, -- Feral
		[3] = {}, -- Guardian
		[4] = {1}, -- Restoration
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
		[1] = {1, 5}, -- Assasination
		[2] = {1, 5}, -- Combat
		[3] = {1, 5}, -- Subtlety
	},
	["SHAMAN"] = {
		[1] = {}, -- Elemental
		[2] = {}, -- Enchancement
		[3] = {}, -- Restoration
	},
	["WARLOCK"] = {
		[1] = {3, 4, 5}, -- Affliction
		[2] = {3, 4, 5}, -- Demonology
		[3] = {3, 4, 5}, -- Destruction
	},
	["WARRIOR"] = {
		[1] = {1}, -- Arms
		[2] = {1}, -- Fury
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
		126406,		-- Trample (Goat)
		58604,		-- Lava Breath (Core Hound)
	},
	[6] = {	-- Mortal Wounds
		115804,		-- Mortal Wounds
		82654,		-- Widow Venom (Hunter)
		8680,		-- Wound Poison (Rogue)
		54680,		-- Monstrous Bite (Devilsaur)
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

--[[
	The idea it to check for class and spec which are the interesting {de}buffs and throw their ids into a table
	which is then checked against in a custom aura filter

	GetSpecialization() returns 1, 2, 3, or 4, so a call to debuffs[playerClass][spec] should return
	the debuff groups of interest for the player.

	I.e. ClassDebuffs["DRUID"][2] shall return 1, 3 and 6 which are then looked up in SharedDebuffs
--]]

ns.DebuffIDs = {}
local _, playerClass = UnitClass("player")
local playerSpec = GetSpecialization() or 0

local UpdateSharedDebuffs = function(add, ...)
	for i = 1, select('#', ...) do
		local debuffGroup = select(i, ...)

		if (debuffGroup) then
			local Debuffs = SharedDebuffs[debuffGroup]
			for i = 1, #Debuffs do
				ns.DebuffIDs[Debuffs[i]] = add
			end
		end
	end
end

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
		-- removing old debuffs
		if (playerSpec ~= 0) then
			UpdateSharedDebuffs(nil, unpack(ClassDebuffs[playerClass][playerSpec]))
		end
		-- adding new debuffs
		playerSpec = GetSpecialization() or 0
		if (playerSpec ~= 0) then
			UpdateSharedDebuffs(true, unpack(ClassDebuffs[playerClass][playerSpec]))
		end

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