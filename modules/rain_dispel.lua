--[[
		self.DebuffHightlight = Frame (to create the textures with)
		self.DebuffHighlightFilter = boolean ( true = only debuffs player can dispell )

		self.DebuffHighlightBackdrop = Frame ( GetBackdrop() ~= nil ) - NYI
		self.DebuffHighlightBackdropBorder = boolean ( true = color backdrop border ) - NYI
		self.DebuffHighlightTexture = Texture ( GetTexture() ~= nil )
		self.DebuffHighlightIcon = Texture ( for the debuff icon )
		self.DebuffHighlightIconOverlay = Texture ( for icon border )
--]]
local playerClass = select(2, UnitClass("player"))

local dispelList = {
	Curse = false,
	Desease = false,
	Magic = false,
	Poison = false,
}

local debuffTypeColor = {}
for dispelType, color in pairs(_G["DebuffTypeColor"]) do
	debuffTypeColor[dispelType] = color
end

local ResetDispelList = function()
	for k,v in pairs(dispelList) do
		dispelList[k] = false
	end
end

local UpdateDispelList = {
	["DRUID"] = function()
		ResetDispelList()
		if (IsSpellKnown(2782)) then					-- Remove Corruption
			dispelList.Curse = true
			dispelList.Poison = true
		elseif (IsSpellKnown(88432)) then				-- Nature's Cure
			dispelList.Curse = true
			dispelList.Magic = true
			dispelList.Poison = true
		end
	end,
	["MAGE"] = function()
		ResetDispelList()
		if (IsSpellKnown(475)) then						-- Remove Curse
			dispelList.Curse = true
		end
	end,
	["MONK"] = function()
		ResetDispelList()
		if (IsSpellKnown(115450)) then					-- Detox
			dispelList.Desease = true
			dispelList.Poison = true
			if (IsSpellKnown(115451)) then				-- Internal Medicine
				dispelList.Magic = true
			end
		end
	end,
	["PALADIN"] = function()
		ResetDispelList()
		if (IsSpellKnown(4987)) then					-- Cleanse
			dispelList.Desease = true
			dispelList.Poison = true
			if (IsSpellKnown(53551)) then				-- Sacred Cleansing
				dispelList.Magic = true
			end
		end
	end,
	["PRIEST"] = function()
		ResetDispelList()
		if (IsSpellKnown(527)) then						-- Purify
			dispelList.Desease = true
			dispelList.Magic = true
		end
	end,
	["SHAMAN"] = function()
		ResetDispelList()
		if (IsSpellKnown(51886)) then					-- Cleanse Spirit
			dispelList.Curse = true
		elseif (IsSpellKnown(77130)) then				-- Purify Spirit
			dispelList.Curse = true
			dispelList.Magic = true
		end
	end,
	["WARLOCK"] = function()
		ResetDispelList()
		if (IsSpellKnown(89808, true) 					-- Single Magic (Imp ability)
			or IsSpellKnown(115276, true)) then			-- Sear Magic (Fel Imp ability)
			dispelList.Magic = true
		end
	end,
}

local GetDebuffInfo = function(unit, filter)
	if (not UnitCanAssist("player", unit)) then return end

	local i = 1
	while (true) do
		local name, _, texture, _, dispelType, _, _, _, _, _, _, _, isBossDebuff = UnitDebuff(unit, i)
		if (not texture) then break end
		if ((not filter and isBossDebuff) or (filter and dispelList[dispelType])) then
			return dispelType, texture, isBossDebuff
		end
		i = i + 1
	end
end

local CheckForPet = function(self, event, unit)
	if (unit ~= "player" or playerClass ~= "WARLOCK") then return end

	UpdateDispelList[playerClass]()
end

local Update = function(self, event, unit)
	if (unit ~= self.unit) then return end

	local color
	local dispelType, texture, isBossDebuff = GetDebuffInfo(unit, self.DebuffHighlightFilter)

	color = debuffTypeColor[dispelType] or debuffTypeColor["none"]

	if (self.DebuffHighlightTexture) then
		if (texture) then
			self.DebuffHighlightTexture:SetVertexColor(color.r, color.g, color.b, 1)
		else
			self.DebuffHighlightTexture:SetVertexColor(0, 0, 0, 0)
		end
	end

	if (self.DebuffHighlightIcon and isBossDebuff) then
		if (texture) then
			self.DebuffHighlightIcon:SetTexture(texture)
		else
			self.DebuffHighlightIcon:SetTexture(nil)
		end
		if (self.DebuffHighlightIconOverlay) then
			if (texture) then
				self.DebuffHighlightIconOverlay:SetVertexColor(color.r, color.g, color.b, 1)
			else
				self.DebuffHighlightIconOverlay:SetVertexColor(0, 0, 0, 0)
			end
		end
	end
end

local Enable = function(self)
	if (not self.DebuffHighlight) then return end

	-- exit if we filter by type and are not a dispeling class
	if (self.DebuffHighlightFilter and not UpdateDispelList[playerClass]) then return end

	if (self.DebuffHighlightFilter and UpdateDispelList[playerClass]) then
		UpdateDispelList[playerClass]()
		self:RegisterEvent("SPELLS_CHANGED", UpdateDispelList[playerClass])
		self:RegisterEvent("UNIT_PET", CheckForPet)
	end

	self:RegisterEvent("UNIT_AURA", Update)

	return true
end

local Disable = function(self)
	if (self.DebuffHighlight) then
		self:UnregisterEvent("UNIT_AURA")
		if (UpdateDispelList[playerClass]) then
			self:UnregisterEvent("SPELLS_CHANGED")
			self:UnregisterEvent("UNIT_PET")
		end
	end
end

oUF:AddElement("rain_dispell", Update, Enable, Disable)
