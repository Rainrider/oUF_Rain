local _, ns = ...
local oUF = ns.oUF or oUF

local _, playerClass = UnitClass("player")

local DefaultTextures = {
	"Interface\\Icons\\Ability_Warrior_Sunder",
	"INTERFACE\\ICONS\\ability_deathknight_brittlebones",
	"Interface\\Icons\\warlock_curse_shadow",
	"Interface\\Icons\\INV_Relics_TotemofRage",
	"Interface\\Icons\\warlock_curse_weakness",
	"Interface\\Icons\\Ability_CriticalStrike",
}

local TooltipTexts = {
	"Weakened Armor",
	"Physical Vulnerability",
	"Magic Vulnerability",
	"Weakened Blows",
	"Slow Casting",
	"Mortal Wounds",
}

local ClassDebuffCategories = {
	["DEATHKNIGHT"] = {
		[1] = {4, 5}, -- Blood
		[2] = {2, 5}, -- Frost
		[3] = {2, 5}, -- Unholy
	},
	["DRUID"] = {
		[1] = {1}, -- Balance
		[2] = {1, 4}, -- Feral
		[3] = {1, 4}, -- Guardian
		[4] = {1}, -- Restoration
	},
	["HUNTER"] = {
		[1] = {1, 2, 3, 4, 5, 6}, -- Beastmaster
		[2] = {1, 2, 3, 4, 5, 6}, -- Markmanship
		[3] = {1, 2, 3, 4, 5, 6}, -- Survival
	},
	["MAGE"] = {
		[1] = {5}, -- Arcane
		[2] = {}, -- Fire
		[3] = {}, -- Frost
	},
	["MONK"] = {
		[1] = {4}, -- Brewmaster
		[2] = {}, -- Mistweaver
		[3] = {6}, -- Windwalker
	},
	["PALADIN"] = {
		[1] = {}, -- Holy
		[2] = {4}, -- Protection
		[3] = {2, 4}, -- Retribution
	},
	["PRIEST"] = {
		[1] = {}, -- Discipline
		[2] = {}, -- Holy
		[3] = {}, -- Shadow
	},
	["ROGUE"] = {
		[1] = {1, 3, 5, 6}, -- Assasination
		[2] = {1, 3, 5, 6}, -- Combat
		[3] = {1, 3, 5, 6}, -- Subtlety
	},
	["SHAMAN"] = {
		[1] = {4}, -- Elemental
		[2] = {4}, -- Enchancement
		[3] = {}, -- Restoration
	},
	["WARLOCK"] = {
		[1] = {3, 4, 5}, -- Affliction
		[2] = {3, 4, 5, 6}, -- Demonology
		[3] = {3, 4, 5}, -- Destruction
	},
	["WARRIOR"] = {
		[1] = {1, 2, 4, 6}, -- Arms
		[2] = {1, 2, 4, 6}, -- Fury
		[3] = {1, 4}, -- Protection
	},
}

local DebuffsPerCategory = {
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
		31589,		-- Slow (Arcane Mage)
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

local OnEnter = function(self)
	if (not self:IsVisible()) then return end
	GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT")
	GameTooltip:SetText(TooltipTexts[self.id], 1, 1, 1)
	GameTooltip:Show()
end

local OnLeave = function(self)
	GameTooltip:Hide()
end

local TrackedDebuffs = {}

local Update = function(self, event, unit)
	if (self.unit ~= unit) then return end

	local element = self.MissingGroupDebuffs

	for i = 1, #TrackedDebuffs do
		local Debuffs = TrackedDebuffs[i]
		for j = 2, #Debuffs do
			if (UnitDebuff(unit, Debuffs[j])) then
				element[Debuffs[1]]:Hide()
				break
			elseif (j == #Debuffs) then
				element[Debuffs[1]]:Show()
			end
		end
	end
end

local ToggleUpdate = function(self, event, unit)
	local hide = false
	if (UnitInRaid("player") or UnitInParty("player")) then
		if (UnitCanAttack("player", self.unit)) then
			self:RegisterEvent("UNIT_AURA", Update)
		else
			self:UnregisterEvent("UNIT_AURA", Update)
			hide = true
		end
	else
		hide = true
	end

	if (hide) then
		local element = self.MissingGroupDebuffs
		for i = 1, 6 do
			element[i]:Hide()
		end
	else
		Update(self, event, unit)
	end

end

local UpdateTrackedDebuffs = function(self, event, unit)
	if (unit and unit ~= "player") then return end

	table.wipe(TrackedDebuffs)

	local element = self.MissingGroupDebuffs
	for i = 1, 6 do
		element[i]:Hide()
	end

	local playerSpec = GetSpecialization("player") or 0
	if (playerSpec == 0) then return end

	local CategoriesOfInterest = ClassDebuffCategories[playerClass][playerSpec]

	for i = 1, #CategoriesOfInterest do
		local category = CategoriesOfInterest[i]

		local DebuffIDs = DebuffsPerCategory[category]
		TrackedDebuffs[i] = {}
		TrackedDebuffs[i][1] = category
		for j = 1, #DebuffIDs do
			local spellName = GetSpellInfo(DebuffIDs[j])
			TrackedDebuffs[i][j + 1] = spellName
		end
	end

	ToggleUpdate(self, event, unit)
end

local ForceUpdate = function(self, ...)
	return UpdateTrackedDebuffs(self, "ForceUpdate", ...)
end

local Enable = function(self, unit)
	local element = self.MissingGroupDebuffs
	if (not element) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	for i = 1, 6 do
		local button = element[i]
		button.id = i
		if (not button:GetScript("OnEnter")) then
			button:SetScript("OnEnter", OnEnter)
		end
		if (not button:GetScript("OnLeave")) then
			button:SetScript("OnLeave", OnLeave)
		end
		local icon = button.icon
		if (icon:IsObjectType("Texture") and not icon:GetTexture()) then
			icon:SetTexture(DefaultTextures[i])
			icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		end
	end

	self:RegisterEvent("GROUP_ROSTER_UPDATE", ToggleUpdate, true)
	self:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED", UpdateTrackedDebuffs)

	UpdateTrackedDebuffs(self, "OnEnable", "player")

	return true
end

local Disable = function(self)
	local element = self.MissingGroupDebuffs

	if (not element) then return end

	self:UnregisterEvent("UNIT_AURA", Update)
	self:UnregisterEvent("GROUP_ROSTER_UPDATE", ToggleUpdate)
	self:UnregisterEvent("PLAYER_SPECIALIZATION_CHANGED", UpdateTrackedDebuffs)

	for i = 1, 6 do
		element[i]:Hide()
	end
end

oUF:AddElement("MissingGroupDebuffs", ToggleUpdate, Enable, Disable)