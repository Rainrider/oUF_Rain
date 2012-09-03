local _, ns = ...

local debuffs = {
	["DEADKNIGHT"] = {
		[1] = function() return end, -- Blood
		[2] = function() return end, -- Frost
		[3] = function() return end, -- Unholy
	},
	["DRUID"] = {
		[1] = function() return end, -- Balance
		[2] = function() return 1, 3, 6 end, -- Feral
		[3] = function() return end, -- Restoration
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
		[1] = function() return 2 end, -- Arms
		[2] = function() return 2 end, -- Fury
		[3] = function() return 1, 6 end, -- Protection
	},
}

local sharedDebuffs = {
	[1] = {	-- Armor
		["DRUID"] = {
			91565, -- Faerie Fire === DDD ===
		},
		["HUNTER"] = {
			35387, -- Corrosive Spit (serpent ability)
			50498, -- Tear Armor (raptor ability)
		},
		["ROGUE"] = {
			8647, -- Expose Armor === DDD ===
		},
		["WARRIOR"] = {
			58567, -- Sunder Armor === DDD ===
		},
	},
	[2] = {	-- Attack Speed
		["DEATHKNIGHT"] = {
			55095, -- Frost Fever (Passive) === DDD ===
		},
		["DRUID"] = {
			58180, -- Infected Wounds (Feral talent. Passive) === DDD ===
			16914, -- Hurricane === DDD ===
		},
		["HUNTER"] = {
			90315, -- Tailspin (Fox)
			54404, -- Dust Cloud (Tallstrider)
		},
		["SHAMAN"] = {
			8042, -- Earth Shock === DDD ===
		},
		["WARRIOR"] = {
			6343, -- Thunder Clap === DDD ===
		},
	},
	[3] = {	-- Bleed Damage
		["DRUID"] = {
			33878, -- Mangle (bear)
			33876, -- Mangle (cat)
		},
		["HUNTER"] = {
			50271, -- Tendon Rip (hyena ability)
			35290, -- Gore (boar ability)
			57386, -- Stampede (rhino ability)
		},
		["ROGUE"] = {
			16511, -- Hemorrhage
		},
		["WARRIOR"] = {
			29836, -- Blood Frenzy (Arms talent. Passive)
		}
	},
	[4] = {	-- Casting Speed
		["DEATHKNIGHT"] = {
			73975, -- Necrotic Strike
		},
		["HUNTER"] = {
			50274, -- Spore Cloud (sporebat ability)
			58604, -- Lava Breath (core hound ability)
		},
		["MAGE"] = {
			31589, -- Slow
		},
		["ROGUE"] = {
			5761, -- Mind-Numbing Poison
		},
		["WARLOCK"] = {
			1714, -- Curse of Tongues === DDD ===
		},
	},
	[5] = {	-- Healing
		["HUNTER"] = {
			82654, -- Widow Venom === DDD ===
			54680, -- Monstrous Bite (devilsaur ability)
		},
		["PRIEST"] = {
			15313, -- Improved Mind Blast
		},
		["ROGUE"] = {
			13219, -- Wound Poison
		},
		["WARLOCK"] = {
			30213, -- Legion Strike (felguard ability)
		},
		["WARRIOR"] = {
			12294, -- Mortal Strike (Arms bonus talent)
			46910, -- Furious Attacks (Fury Talent, passive)
		},
	},
	[6] = {	-- Physical Damage Dealt
		["DEATHKNIGHT"] = {
			81130, -- Scarlet Fever (Blood Talent) === DDD ===
		},
		["DRUID"] = {
			99, -- Demoralizing Roar === DDD ===
		},
		["HUNTER"] = {
			50256, -- Demoralizing Roar (bear pet ability)
			24423, -- Demoralizing Screech (carrion bird ability)
		},
		["PALADIN"] = {
			26017, -- Vindication
		},
		["WARLOCK"] = {
			702, -- Curse of Weakness === DDD ===
		},
		["WARRIOR"] = {
			1160, -- Demoralizing Shout === DDD ===
		},
	},
	[7] = {	-- Physical Damage Taken
		--[[
			All class abilities providing this are talents that
			improve class debuffs
		--]]
	},
	[8] = {	-- Spell Crit Taken
		["MAGE"] = {
			22959, -- Critical Mass
			2948, -- Scorch
		},
		["WARLOCK"] = {
			17800, -- Shadow and Flame === DDD ===
		},
	},
	[9] = {	-- Spell Damage Taken
		["DEATHKNIGHT"] = {
			51160, -- Ebon Plague (Unholy talent. Passive)
		},
		["DRUID"] = {
			48506, -- Earth and Moon (passive)
		},
		["HUNTER"] = {
			34889, -- Fire Breath (dragonhawk ability)
			24844, -- Lightning Breath (wind serpent ability)
		},
		["ROGUE"] = {
			58410, -- Master Poisoner (passive)
		},
		["WARLOCK"] = {
			1490, -- Curse of the Elements === DDD ===
		},
	},
}

local crowdControl = {
	["DRUID"] = {
		33786, -- Cyclone === DDD ===
		2637, -- Hibernate == DDD ===
	},
	["HUNTER"] = {
		3355, -- Freezing Trap === DDD ===
		19386, -- Wyvern Sting === DDD ===
	},
	["MAGE"] = {
		118, -- Polymorph
		61305, -- Polymorph (Black Cat)	
		28272, -- Polymorph (Pig)
		61721, -- Polymorph (Rabbit)
		61780, -- Polymorph (Turkey)
		28271, -- Polymorph (Turtle)
	},
	["PALADIN"] = {
		20066, -- Repentance
		10326, -- Turn Evil
	},
	["PRIEST"] = {
		9484, -- Shackle Undead
	},
	["ROGUE"] = {
		6770, -- Sap === DDD ===
	},
	["SHAMAN"] = {
		76780, -- Bind Elemental
		51514, -- Hex
	},
	["WARLOCK"] = {
		710, -- Banish === DDD ===
		5782, -- Fear === DDD ===
		5484, -- Howl of Terror === DDD ===
		6358, -- Seduction === DDD ===
	},
	["WARRIOR"] = {
		20511, -- Intimidating Shout === DDD ===
	},
}

local disarm = {
	["HUNTER"] = {
		50541, -- Clench (Scorpid)
		91644, -- Snatch (Bird of Prey)
	},
	["PRIEST"] = {
		64058, -- Psychic Horror
	},
	["ROGUE"] = {
		51722, -- Dismantle === both ===
	},
	["WARRIOR"] = {
		676, -- Disarm === both ===
	},
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
	wipe(ns.debuffIDs)
	for i = 1, select('#', ...) do
		local debuffGroup = select(i, ...)
		print(debuffGroup)
		for class, tab in pairs(sharedDebuffs[debuffGroup]) do
			if (class ~= playerClass) then
				for _, spellID in ipairs(tab) do
					ns.debuffIDs[spellID] = true
					print("Debuff added for class", class, ":", GetSpellLink(spellID))
				end
			end
		end
	end
end

local GetCC = function()
	for class, tab in pairs(crowdControl) do
		if (class ~= playerClass) then
			for _, spellID in ipairs(tab) do
				ns.debuffIDs[spellID] = true
				print("CC added for class", class, ":", GetSpellLink(spellID))
			end
		end
	end
end

local GetDisarm = function()
	local isDisarmCapable = false
	for class in pairs(disarm) do
		if (class == playerClass) then
			isDisarmCapable = true
			break
		end
	end
	if (isDisarmCapable) then
		for class, tab in pairs(disarm) do
			if (class ~= playerClass) then
				for _, spellID in ipairs(tab) do
					ns.debuffIDs[spellID] = true
					print("Diarm added for class", class, ":", GetSpellLink(spellID))
				end
			end
		end
	end
end

local Update = function(self, event, ...)
	local primaryTalentTree = GetPrimaryTalentTree()
	if (primaryTalentTree) then
		GetSharedDebuffs(debuffs[playerClass][primaryTalentTree]())
		if (event == "PLAYER_TALENT_UPDATE") then
			self:UnregisterEvent("PLAYER_TALENT_UPDATE")
		end
	end
	GetCC()
	GetDisarm()
	if event == "PLAYER_TALENT_UPDATE" then
		
	end
end

local EventListener = CreateFrame("Frame")
EventListener:RegisterEvent("PLAYER_TALENT_UPDATE")
EventListener:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
EventListener:SetScript("OnEvent", Update)
