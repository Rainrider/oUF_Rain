local _, ns = ...
local oUF = ns.oUF or oUF

local origR, origG, origB, origA
local crowdControl = {
	-- DRUID
	[33786] = true,		-- Cyclone
	-- HUNTER
	[3355] = true,		-- Freezing Trap
	[19386] = true,		-- Wyvern Sting
	-- MAGE
	[118] = true,		-- Polymorph
	[61305] = true,		-- Polymorph (Black Cat)
	[28272] = true,		-- Polymorph (Pig)
	[61721] = true,		-- Polymorph (Rabbit)
	-- MONK
	[115078] = true,	-- Paralysis
	-- PALADIN
	[20066] = true,		-- Repentance
	[10326] = true,		-- Turn Evil
	-- PRIEST
	[9484] = true,		-- Shackle Undead
	-- ROGUE
	[2094] = true,		-- Blind
	[6770] = true,		-- Sap
	-- SHAMAN
	[51514] = true,		-- Hex
	-- WARLOCK
	[710] = true,		-- Banish
	[5484] = true,		-- Howl of Terror
	[118699] = true,	-- Fear
	[130616] = true,	-- Fear (with Glyph of Fear)
	[6358] = true,		-- Seduction (Succubus)
	[115268] = true,	-- Mesmerize (Shivarra)
}

local Update = function(self, event, unit)
	if (self.unit ~= unit) then return end

	local element = self.CCWarn
	local unitIsCrowdControlled

	for i = 1, 40 do
		local _, _, _, _, _, _, _, _, _, _, spellID = UnitDebuff(unit, i)
		if (not spellID) then
			break
		elseif (crowdControl[spellID]) then
			unitIsCrowdControlled = true
			break
		end
	end

	if (unitIsCrowdControlled) then
		element:SetVertexColor(0, 1, 1, 1)
	else
		element:SetVertexColor(origR, origG, origB, origA)
	end
end

local Path = function(self, ...)
	return (self.CCWarn.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self, unit)
	local element = self.CCWarn

	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		origR, origG, origB, origA = element:GetVertexColor()
		self:RegisterEvent("UNIT_AURA", Path)

		return true
	end
end

local Disable = function(self)
	local element = self.CCWarn

	if (element) then
		self:UnregisterEvent("UNIT_AURA", Path)
	end
end

oUF:AddElement("Rain_CCWarn", Path, Enable, Disable)
