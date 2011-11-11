--[[==========================
	DESCRIPTION:
	Configuration for oUF_Rain
	==========================--]]
local _, ns = ...

ns.config = {
	showPlayerBuffs = true,			-- true to enable the display of player buffs left to the player frame; false to disable them

	-- true to show; false to hide
	showParty = true,
	horizParty = true,				-- true for horizontal party layout; false for vertical
	showPartyTargets = true,
	showPartyPets = true,
	showRaid = true,
	raidHealth = 1,					-- 0 - none; 1 - deficit; 2 - percent
	showMT = true,					-- maintanks
	showMTT = true,					-- maintanks' targets
	
	-- aura filtering
	onlyShowPlayerBuffs = false,	-- true to show only player buffs; false to show all buffs (for friendly targets only)
	onlyShowPlayerDebuffs = false,	-- true to show only player debuffs; false to show only player class debuffs (for enemies only)
	
	-- A value of 1 behind the spell means the buff/debuff should be applied by the player in order to be shown
	-- A maximum of 3 buffs and 3 debuffs per class allowed
	buffTable = {
		["DRUID"] = {
			[GetSpellInfo(33763)] = 1,	-- Life Bloom
		},
		["PRIEST"] = {
			[GetSpellInfo(139)] = 1,	-- Renew
			[GetSpellInfo(33076)] = 1,	-- Prayer of Mending
		},
		["SHAMAN"] = {
			[GetSpellInfo(974)] = 2,	-- Earth Shield
		},
	},

	debuffTable = {
		["PALADIN"] = {
			[GetSpellInfo(25771)] = 2,	-- Forbearance
		},
		["PRIEST"] = {
			[GetSpellInfo(6788)] = 2,	-- Weakened Soul
		},
	},

	-- debuff highlightingt
	dispelTypeFilter = true, -- true to highlight only debuffs the player can dispel; false to only highlight boss debuffs
	
	-- focus helper spells
	-- use i.e. bmSpell = spellID,
	bmSpell = 34026,	-- Kill Command (34026)
	mmSpell = 53209,	-- Chimera Shot (53209)
	svSpell = 53301,	-- Explosive Shot (53301)
	
	-- click casting spell
	-- use i.e. ["ENGLISH_CLASS_NAME"] = spellID,
	clickSpell = {
		["DEADKNIGHT"] = 61999,	-- Raise Ally (61999)
		["DRUID"] = 29166,		-- Innervate (29166)
		["HUNTER"] = 34477,		-- Misdirection (34477)
		["MAGE"] = 475,			-- Remove Curse (475)
		["PALADIN"] = 31789,	-- Righteous Defense (31789)
		["PRIEST"] = 73325,		-- Leap of Faith (73325)
		["ROGUE"] = 57934,		-- Tricks of the Trade (57934)
		["SHAMAN"] = 546,		-- Water Walking (546)
		["WARRIOR"] = 3411,		-- Intervene (3411)
		["WARLOCK"] = 80398,	-- Dark Intent (80398)
	},
	
	-- do not touch anything below
	playerClass = select(2, UnitClass("player")),
}