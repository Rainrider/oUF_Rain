--[[
	self.DebuffHighlight = Table
	self.DebuffHighlight.texture = Texture (will be colored by debuff type)
	self.DebuffHighlight.filter = boolean (true = only debuffs player can dispell)
	self.DebuffHighlight.icon = Texture (for the debuff icon)
	self.DebuffHighlight.iconOverlay = Texture (for icon border)
--]]
local _, playerClass = UnitClass("player")

local dispelList = {
	Curse = false,
	Desease = false,
	Magic = false,
	Poison = false,
}

local debuffTypeColor = {}
for dispelType, color in pairs(_G["DebuffTypeColor"]) do
	debuffTypeColor[dispelType] = {color.r, color.g, color.b}
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

	local element = self.DebuffHighlight

	local dispelType, texture, isBossDebuff = GetDebuffInfo(unit, element.filter)
	local color = debuffTypeColor[dispelType] or debuffTypeColor["none"]

	if (element.texture) then
		if (texture) then
			element.texture:SetVertexColor(color[1], color[2], color[3], 1)
		else
			element.texture:SetVertexColor(0, 0, 0, 0)
		end
	end

	if (isBossDebuff and element.icon) then
		if (texture) then
			element.icon:SetTexture(texture)
			if (element.iconOverlay) then
				element.iconOverlay:SetVertexColor(color[1], color[2], color[3], 1)
			end
		else
			element.icon:SetTexture(nil)
			if (element.iconOverlay) then
				element.iconOverlay:SetVertexColor(0, 0, 0, 0)
			end
		end
	end

	if (element.PostUpdate) then
		return element:PostUpdate(unit, dispelType, texture, isBossDebuff)
	end
end

local Path = function(self, ...)
	return (self.DebuffHighlight.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(self.__owner, "ForceUpdate", self.__owner.unit)
end

local Enable = function(self)
	local element = self.DebuffHighlight

	if (not element or element.filter and not UpdateDispelList[playerClass]) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	if (element.filter and UpdateDispelList[playerClass]) then
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

oUF:AddElement("rain_dispel", Update, Enable, Disable)
