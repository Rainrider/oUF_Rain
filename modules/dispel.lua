--[[ Element: DispelHighlight

 Highlights debuffs the player can dispel

 Widget

 DispelHighlight - An array consisting of up to 3 UI textures.

 Sub-Widgets

 texture     - A texture to be shown/hiden if a dispelable debuff is found.
               Will be colored in the dispel type color.
 icon        - A texture to hold the icon representing the first dispelable debuff found.
 iconOverlay - A border texture for the icon. Will be colored in the dispel type color.

 Notes

 All sub-widgets are optional.
--]]
local _, ns = ...
local oUF = ns.oUF or oUF
local _, playerClass = UnitClass("player")

local dispelList = {
	Curse = nil,
	Desease = nil,
	Magic = nil,
	Poison = nil,
}

local debuffTypeColor = {}
for dispelType, color in pairs(_G["DebuffTypeColor"]) do
	debuffTypeColor[dispelType] = {color.r, color.g, color.b}
end

local UpdateDispelList = {
	["DRUID"] = function()
		table.wipe(dispelList)
		if (IsSpellKnown(2782)) then         -- Remove Corruption
			dispelList.Curse = true
			dispelList.Poison = true
		elseif (IsSpellKnown(88432)) then    -- Nature's Cure
			dispelList.Curse = true
			dispelList.Magic = true
			dispelList.Poison = true
		end
	end,
	["MAGE"] = function()
		table.wipe(dispelList)
		if (IsSpellKnown(475)) then          -- Remove Curse
			dispelList.Curse = true
		end
	end,
	["MONK"] = function()
		table.wipe(dispelList)
		if (IsSpellKnown(115450)) then       -- Detox
			dispelList.Desease = true
			dispelList.Poison = true
			if (IsSpellKnown(115451)) then   -- Internal Medicine
				dispelList.Magic = true
			end
		end
	end,
	["PALADIN"] = function()
		table.wipe(dispelList)
		if (IsSpellKnown(4987)) then         -- Cleanse
			dispelList.Desease = true
			dispelList.Poison = true
			if (IsSpellKnown(53551)) then    -- Sacred Cleansing
				dispelList.Magic = true
			end
		end
	end,
	["PRIEST"] = function()
		table.wipe(dispelList)
		if (IsSpellKnown(527)) then          -- Purify
			dispelList.Desease = true
			dispelList.Magic = true
		end
	end,
	["SHAMAN"] = function()
		table.wipe(dispelList)
		if (IsSpellKnown(51886)) then        -- Cleanse Spirit
			dispelList.Curse = true
			if (IsPlayerSpell(77130)) then   -- Purify Spirit
				dispelList.Magic = true
			end
		end
	end,
	["WARLOCK"] = function()
		table.wipe(dispelList)
		local _, _, texture = GetSpellInfo(119898) -- Command Demon
		if (string.find(texture, "spell_fel_elementaldevastation") -- Singe Magic (Imp Sacrifice) NOTE: IsSpellKnown(132411) always returns false
			or IsSpellKnown(89808, true)           -- Singe Magic (Imp ability)
			or IsSpellKnown(115276, true)) then    -- Sear Magic (Fel Imp ability)
			dispelList.Magic = true
		end
	end,
}

local Update = function(self, event, unit)
	if (unit ~= self.unit) then return end

	local element = self.DispelHighlight

	local texture, dispelType
	local r, g, b = 1, 1, 1

	local i = 1
	local canAssist = UnitCanAssist("player", unit)
	while (canAssist) do
		_, _, texture, _, dispelType = UnitDebuff(unit, i)
		if (not texture) then
			break
		elseif (dispelList[dispelType]) then
			local color = debuffTypeColor[dispelType]
			r, g, b = color[1], color[2], color[3]
			break
		end
		i = i + 1
	end

	if (element.texture) then
		if (texture) then
			element.texture:SetVertexColor(r, g, b, 1)
		else
			element.texture:SetVertexColor(0, 0, 0, 0)
		end
	end

	if (element.icon) then
		if (texture) then
			element.icon:SetTexture(texture)
			if (element.iconOverlay) then
				element.iconOverlay:SetVertexColor(r, g, b, 1)
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
	return (self.DispelHighlight.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	return Path(self.__owner, "ForceUpdate", self.__owner.unit)
end

local Enable = function(self)
	local element = self.DispelHighlight

	if (not element or not UpdateDispelList[playerClass]) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	UpdateDispelList[playerClass]()

	self:RegisterEvent("SPELLS_CHANGED", UpdateDispelList[playerClass])
	self:RegisterEvent("UNIT_AURA", Path)

	return true
end

local Disable = function(self)
	if (self.DispelHighlight) then
		self:UnregisterEvent("UNIT_AURA", Path)
		self:UnregisterEvent("SPELLS_CHANGED", UpdateDispelList[playerClass])
	end
end

oUF:AddElement("DispelHighlight", Path, Enable, Disable)
