local _, ns = ...
local oUF = ns.oUF or oUF

-- specs
local SPEC_WARLOCK_AFFLICTION = SPEC_WARLOCK_AFFLICTION
local SPEC_WARLOCK_DESTRUCTION = SPEC_WARLOCK_DESTRUCTION
local SPEC_WARLOCK_DEMONOLOGY = SPEC_WARLOCK_DEMONOLOGY

-- prereq spell IDs
local WARLOCK_SOULBURN = WARLOCK_SOULBURN -- IsPlayerSpell
local WARLOCK_BURNING_EMBERS = WARLOCK_BURNING_EMBERS	-- IsPlayerSpell

-- powerType
local SPELL_POWER_SOUL_SHARDS = SPELL_POWER_SOUL_SHARDS
local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY
local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS

--
local MAX_POWER_PER_EMBER = MAX_POWER_PER_EMBER
local spec = 0
local pType

local warlockColors = {
	["SOUL_SHARDS"] = {1, 0, 1},
	["BURNING_EMBERS"] = {1, 0, 0},
	["DEMONIC_FURY"] = {0, 1, 1},
}

-- TODO: prereq spells
local Visibility = function(self)
	local element = self.WarlockPowerBar

	spec = GetSpecialization()
	local power
	local maxPower
	local r, g, b

	if (spec) then
		if (spec == SPEC_WARLOCK_AFFLICTION) then
			pType = "SOUL_SHARDS"
			power = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
			maxPower = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)

			r, g, b = unpack(warlockColors["SOUL_SHARDS"])

			for i = 1, 4 do
				element[i]:SetStatusBarColor(r, g, b)
				element[i]:SetMinMaxValues(0, 1)

				if (element[i].bg) then
					local mult = element[i].bg.multiplier or 1
					element[i].bg:SetVertexColor(r * mult, g * mult, b * mult)
				end

				if (i <= maxPower) then
					element[i]:Show()
				else
					element[i]:Hide()
				end
			end
		elseif (spec == SPEC_WARLOCK_DEMONOLOGY) then
			pType = "DEMONIC_FURY"
			power = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
			maxPower = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)

			r, g, b = unpack(warlockColors["DEMONIC_FURY"])

			element[1]:SetStatusBarColor(r, g, b)
			element[1]:SetMinMaxValues(0, maxPower)
			element[1]:SetAlpha(1)

			if (element[1].bg) then
				local mult = element[1].bg.multiplier or 1
				element[1].bg:SetVertexColor(r * mult, g * mult, b * mult)
			end

			for i = 2, 4 do
				element[i]:Hide()
			end
		elseif (spec == SPEC_WARLOCK_DESTRUCTION) then
			pType = "BURNING_EMBERS"
			power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
			maxPower = math.floor(UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS, true) / MAX_POWER_PER_EMBER)

			r, g, b = unpack(warlockColors["BURNING_EMBERS"])

			for i = 1, 4 do
				element[i]:SetStatusBarColor(r, g, b)
				element[i]:SetMinMaxValues(MAX_POWER_PER_EMBER * i - MAX_POWER_PER_EMBER, MAX_POWER_PER_EMBER * i)
				element[i]:SetAlpha(1)

				if (element[i].bg) then
					local mult = element[i].bg.multiplier or 1
					element[i].bg:SetVertexColor(r * mult, g * mult, b * mult)
				end

				if (i <= maxPower) then
					element[i]:Show()
				else
					element[i]:Hide()
				end
			end
		end

		element.maxPower = maxPower
		--element:ForceUpdate()
	else
		for i = 1, 4 do
			element[i]:Hide()
		end
	end

	if (element.PostUpdateVisibility) then
		element:PostUpdateVisibility(spec, power, maxPower)
	end
end

local Update = function(self, event, unit, powerType)
	if (unit ~= "player") then return end

	if not powerType then
		powerType = pType
	end

	if (powerType and powerType ~= "SOUL_SHARDS" and powerType ~= "DEMONIC_FURY" and powerType ~= "BURNING_EMBERS") then return end

	local element = self.WarlockPowerBar
	local power
	local maxPower

	if (powerType == "SOUL_SHARDS" and spec == 1) then
		power = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
		maxPower = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)

		if maxPower ~= element.maxPower then
			Visibility(self)
		end

		for i = 1, maxPower do
			element[i]:SetValue(1)
			if (i <= power) then
				element[i]:SetAlpha(1)
			else
				element[i]:SetAlpha(0.3)
			end
		end
	elseif (powerType == "DEMONIC_FURY" and spec == 2) then
		power = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
		maxPower = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)

		element[1]:SetValue(power)
	elseif (powerType == "BURNING_EMBERS" and spec == 3) then
		power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
		maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS)

		if maxPower ~= element.maxPower then
			Visibility(self)
		end

		for i = 1, maxPower do
			element[i]:SetValue(power)
		end
	end

	if (element.PostUpdate) then
		element:PostUpdate(powerType, power, maxPower)
	end
end

local Path = function(self, ...)
	return (self.WarlockPowerBar.Override or Update) (self, ...)
end

local ForceUpdate = function(element, ...)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	local element = self.WarlockPowerBar

	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Visibility, true)

		Visibility(self)

		return true
	end
end

local Disable = function(self)
	local element = self.WarlockPowerBar

	if (element) then
		self:UnregisterEvent("UNIT_POWER", Path)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Visibility)
	end
end

oUF:AddElement("Rain_WarlockPowerBar", Path, Enable, Disable)