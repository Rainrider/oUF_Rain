--[[==========================
	DESCRIPTION:
	Configuration for oUF_Rain
	==========================--]]
local _, ns = ...

local cfg = CreateFrame("Frame", "raincfg")

-- frame visibility
-- true to show; false to hide
cfg.showParty = true
cfg.showPartyTargets = true
cfg.showPartyPets = true
cfg.showRaid = true
cfg.showMT = true					-- maintanks
cfg.showMTT = true					-- maintanks' targets

-- layout
cfg.horizParty = true				-- true for horizontal party layout; false for vertical

-- auras filtering
cfg.showPlayerBuffs = true			-- true to enable the display of player buffs left to the player frame; false to disable them
cfg.onlyShowPlayerBuffs = true		-- true to show only player buffs; false to show all buffs (for friendly targets only)
cfg.onlyShowPlayerDebuffs = false	-- true to show only player debuffs; false to show only player class debuffs (for enemies only)

-- class specific
-- A value of 1 behind the spell means the buff/debuff should be applied by the player in order to be shown
-- A maximum of 3 buffs and 3 debuffs per class allowed
cfg.buffTable = {
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
}

cfg.debuffTable = {
	["PALADIN"] = {
		[25771] = 2,	-- Forbearance
	},
	["PRIEST"] = {
		[6788] = 2,		-- Weakened Soul
	},
}

-- click casting spell
-- use i.e. ["ENGLISH_CLASS_NAME"] = spellID,
cfg.clickSpell = {
	["DEATHKNIGHT"] = 61999, -- Raise Ally (61999)
	["DRUID"] = 20484,       -- Rebirth (20484)
	["HUNTER"] = 34477,      -- Misdirection (34477)
	["MAGE"] = 475,          -- Remove Curse (475)
	["MONK"] = 115450,       -- Detox (115450)
	["PALADIN"] = 31789,     -- Righteous Defense (31789)
	["PRIEST"] = 73325,      -- Leap of Faith (73325)
	["ROGUE"] = 57934,       -- Tricks of the Trade (57934)
	["SHAMAN"] = 546,        -- Water Walking (546)
	["WARRIOR"] = 3411,      -- Intervene (3411)
	["WARLOCK"] = 109773,    -- Dark Intent (109773)
}

-- other
cfg.raidHealth = 1 			-- 0 - none; 1 - deficit; 2 - percent


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
ns.playerSpec = GetSpecialization() or 0

cfg:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
cfg:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
cfg:RegisterEvent("PLAYER_REGEN_ENABLED")
cfg:RegisterEvent("PLAYER_REGEN_DISABLED")
cfg:RegisterEvent("MODIFIER_STATE_CHANGED")

function cfg:PLAYER_SPECIALIZATION_CHANGED(unit)
	if (not unit or unit == "player") then
		ns.playerSpec = GetSpecialization() or 0
	end
end

function cfg:PLAYER_REGEN_DISABLED()
	cfg:UnregisterEvent("MODIFIER_STATE_CHANGED")
	cfg:MODIFIER_STATE_CHANGED("LSHIFT", 0)
end

function cfg:PLAYER_REGEN_ENABLED()
	cfg:RegisterEvent("MODIFIER_STATE_CHANGED")
	cfg:MODIFIER_STATE_CHANGED("LSHIFT", IsShiftKeyDown() and 1 or 0)
end

function cfg:MODIFIER_STATE_CHANGED(key, state)
	if (key ~= "LSHIFT" and key ~= "RSHIFT") then return end

	for i = 1, #oUF.objects do
		local object = oUF.objects[i]
		local unit = object.realUnit or object.unit
		if (unit == "target") then
			local buffs = object.Buffs
			if (state == 1) then
				buffs.onlyShowPlayer = nil
			else
				buffs.onlyShowPlayer = cfg.onlyShowPlayerBuffs
			end
			buffs:ForceUpdate()
			break
		end
	end
end

ns.cfg = cfg
