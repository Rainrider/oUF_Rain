--[[==========================
	DESCRIPTION:
	Configuration for oUF_Rain
	==========================--]]
local _, ns = ...

ns.config = {
	-- true to show; false to hide
	showParty = true,
	horizParty = true,				-- true for horizontal party layout, false for vertical
	showPartyTargets = true,
	showPartyPets = true,
	showRaid = true,				-- NYI
	showMT = true,					-- true to show maintanks; false to hide them
	showMTT = true,					-- true to show maintanks' targets; false to hide them
	
	-- aura filtering
	onlyShowPlayerBuffs = false,	-- true to show only player buffs; false to show all buffs (for friendly targets only)
	onlyShowPlayerDebuffs = false,	-- true to show only player debuffs; false to show only player class debuffs
	
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