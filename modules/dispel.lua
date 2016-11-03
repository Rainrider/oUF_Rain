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
local oUF = ns.oUF or _G.oUF
local _, playerClass = _G.UnitClass("player")
local IsSpellKnown = _G.IsSpellKnown
local UnitDebuff = _G.UnitDebuff
local UnitCanAssist = _G.UnitCanAssist

local debuffTypeColor = {}
for dispelType, color in pairs(_G["DebuffTypeColor"]) do
	debuffTypeColor[dispelType] = {color.r, color.g, color.b}
end

local dispels = {}

local dispelFuncs = {
	["DRUID"] = function()
		table.wipe(dispels)
		if (IsSpellKnown(2782)) then       -- Remove Corruption
			dispels.Curse = true
			dispels.Poison = true
		elseif (IsSpellKnown(88423)) then  -- Nature's Cure
			dispels.Curse = true
			dispels.Magic = true
			dispels.Poison = true
		end
	end,
	["MONK"] = function()
		table.wipe(dispels)
		if (IsSpellKnown(218164)) then     -- Detox (BM, WW)
			dispels.Disease = true
			dispels.Poison = true
		elseif (IsSpellKnown(115450)) then -- Detox (MW)
			dispels.Disease = true
			dispels.Magic = true
			dispels.Poison = true
		end
	end,
	["PALADIN"] = function()
		table.wipe(dispels)
		if (IsSpellKnown(213644)) then     -- Cleanse
			dispels.Disease = true
			dispels.Poison = true
		elseif (IsSpellKnown(4987)) then   -- Cleanse Toxins
			dispels.Disease = true
			dispels.Magic = true
			dispels.Poison = true
		end
	end,
	["PRIEST"] = function()
		table.wipe(dispels)
		if (IsSpellKnown(213634)) then     -- Purify Disease
			dispels.Disease = true
		elseif (IsSpellKnown(527)) then    -- Purify
			dispels.Disease = true
			dispels.Magic = true
		end
	end,
	["SHAMAN"] = function()
		table.wipe(dispels)
		if (IsSpellKnown(51886)) then      -- Cleanse Spirit
			dispels.Curse = true
		elseif (IsSpellKnown(77130)) then  -- Purify Spirit
			dispels.Curse = true
			dispels.Magic = true
		end
	end,
	["WARLOCK"] = function()
		table.wipe(dispels)
		if (IsSpellKnown(89808, true)      -- Singe Magic (Imp ability)
			or IsSpellKnown(111859)) then  -- Grimoire: Imp
			dispels.Magic = true
		end
	end,
}

local UpdateDispels = dispelFuncs[playerClass]

local Update = function(self, _, unit)
	local element = self.DispelHighlight

	local texture, dispelType
	local r, g, b = 1, 1, 1

	local i = 1
	local canAssist = UnitCanAssist("player", unit)
	while (canAssist) do
		_, _, texture, _, dispelType = UnitDebuff(unit, i)
		if (not texture) then
			break
		elseif (dispels[dispelType]) then
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
		return element:PostUpdate(unit, dispelType, texture)
	end
end

local Path = function(self, ...)
	return (self.DispelHighlight.Override or Update)(self, ...)
end

local ForceUpdate = function(element)
	UpdateDispels()
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	local element = self.DispelHighlight

	if (not element or not UpdateDispels) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate

	UpdateDispels()

	self:RegisterEvent("SPELLS_CHANGED", UpdateDispels, true)
	self:RegisterEvent("UNIT_AURA", Path)

	return true
end

local Disable = function(self)
	if (self.DispelHighlight) then
		self:UnregisterEvent("UNIT_AURA", Path)
		self:UnregisterEvent("SPELLS_CHANGED", UpdateDispels)
	end
end

oUF:AddElement("DispelHighlight", Path, Enable, Disable)
