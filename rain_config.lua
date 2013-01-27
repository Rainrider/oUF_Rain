--[[==========================
	DESCRIPTION:
	Configuration for oUF_Rain
	==========================--]]
local _, ns = ...

ns.cfg = {
-- frame visibility
	-- true to show; false to hide
	showParty = true,
	showPartyTargets = true,
	showPartyPets = true,
	showRaid = true,
	showMT = true,					-- maintanks
	showMTT = true,					-- maintanks' targets

-- layout
	horizParty = true,				-- true for horizontal party layout; false for vertical

-- auras
	-- filtering
	showPlayerBuffs = true,			-- true to enable the display of player buffs left to the player frame; false to disable them
	onlyShowPlayerBuffs = false,		-- true to show only player buffs; false to show all buffs (for friendly targets only)
	onlyShowPlayerDebuffs = false,	-- true to show only player debuffs; false to show only player class debuffs (for enemies only)

	-- debuff highlightingt
	dispelTypeFilter = true,		-- true to highlight only debuffs the player can dispel; false to only highlight boss debuffs

-- class specific
	-- A value of 1 behind the spell means the buff/debuff should be applied by the player in order to be shown
	-- A maximum of 3 buffs and 3 debuffs per class allowed
	buffTable = {
		["DRUID"] = {
			[33763] = 1,	-- Life Bloom
		},
		["PRIEST"] = {
			[139] = 1,		-- Renew
			[33076] = 1,	-- Prayer of Mending
		},
		["SHAMAN"] = {
			[974] = 2,		-- Earth Shield
		},
	},

	debuffTable = {
		["PALADIN"] = {
			[25771] = 2,	-- Forbearance
		},
		["PRIEST"] = {
			[6788] = 2,		-- Weakened Soul
		},
	},

-- click casting spell
	-- use i.e. ["ENGLISH_CLASS_NAME"] = spellID,
	clickSpell = {
		["DEATHKNIGHT"] = 61999,-- Raise Ally (61999)
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

-- focus helper spells
	-- use i.e. bmSpell = spellID,
	bmSpell = 34026,	-- Kill Command (34026)
	mmSpell = 53209,	-- Chimera Shot (53209)
	svSpell = 53301,	-- Explosive Shot (53301)

-- other
	raidHealth = 1,					-- 0 - none; 1 - deficit; 2 - percent
}

ns.media = {
	FONT = [=[Interface\AddOns\oUF_Rain\media\fonts\russel square lt.ttf]=],
	FONT2 = [=[Interface\AddOns\oUF_Rain\media\fonts\neuropol x cd rg.ttf]=],
	TEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\normtexc]=],
	BTNTEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\buttonnormal]=],
	HIGHLIGHTTEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\highlighttex]=],
	BORDER = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
	STEALABLETEX = [=[Interface\AddOns\oUF_Rain\media\textures\stealableTex]=],
	OVERLAY = [=[Interface\AddOns\oUF_Rain\media\textures\smallshadertex]=],
	RAIDICONS = [=[Interface\AddOns\oUF_Rain\media\icons\raidicons]=],
	BACKDROP = {
		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		insets = {top = -1, bottom = -1, left = -1, right = -1},
	},
	BACKDROP2 = {
		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		edgeFile = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
		edgeSize = 2,
		insets = {top = 2, left = 2, bottom = 2, right = 2},
	},
	BORDERBACKDROP = {
		bgFile = nil,
		edgeFile = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
		edgeSize = 4,
		insets = {top = 2, left = 2, bottom = 2, right = 2},
	},
}

-- do not touch anything below
ns.playerClass = select(2, UnitClass("player"))
