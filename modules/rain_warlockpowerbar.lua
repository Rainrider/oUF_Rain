local _, ns = ...
local oUF = ns.oUF or oUF

-- specs
local SPEC_WARLOCK_AFFLICTION = SPEC_WARLOCK_AFFLICTION
local SPEC_WARLOCK_DEMONOLOGY = SPEC_WARLOCK_DEMONOLOGY
local SPEC_WARLOCK_DESTRUCTION = SPEC_WARLOCK_DESTRUCTION

-- spell IDs
local WARLOCK_SOULBURN = WARLOCK_SOULBURN
local WARLOCK_BURNING_EMBERS = WARLOCK_BURNING_EMBERS
local WARLOCK_GREEN_FIRE = WARLOCK_GREEN_FIRE

-- powerType
local SPELL_POWER_SOUL_SHARDS = SPELL_POWER_SOUL_SHARDS
local SPELL_POWER_DEMONIC_FURY = SPELL_POWER_DEMONIC_FURY
local SPELL_POWER_BURNING_EMBERS = SPELL_POWER_BURNING_EMBERS

--
local MAX_POWER_PER_EMBER = MAX_POWER_PER_EMBER
local spec = 0

oUF.colors.warlock = {
	["SOUL_SHARDS"] = {1, 0, 1},
	["BURNING_EMBERS"] = {1, 0, 0},
	["BURNING_EMBERS_GREEN"] = {0, 1, 0},
	["DEMONIC_FURY"] = {0, 1, 1},
}

local Path
local Visibility
Visibility = function(self, event)
	local element = self.WarlockPowerBar

	spec = GetSpecialization()
	local power = 0
	local maxPower = 0
	local powerType
	local color
	local r, g, b
	local show

	-- oUF will refresh the unit on vehicle so no need to register the events
	if (spec and not UnitHasVehicleUI("player")) then
		if (spec == SPEC_WARLOCK_AFFLICTION) then
			if (IsPlayerSpell(WARLOCK_SOULBURN)) then
				self:UnregisterEvent("SPELLS_CHANGED", Visibility)

				show = true
				powerType = "SOUL_SHARDS"
				power = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
				maxPower = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)
				color = self.colors.warlock[powerType]
				r, g, b = color[1], color[2], color[3]

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
			else
				self:RegisterEvent("SPELLS_CHANGED", Visibility, true)
			end
		elseif (spec == SPEC_WARLOCK_DEMONOLOGY) then
			self:UnregisterEvent("SPELLS_CHANGED", Visibility)

			show = true
			powerType = "DEMONIC_FURY"
			power = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
			maxPower = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)
			color = self.colors.warlock[powerType]
			r, g, b = color[1], color[2], color[3]

			element[1]:SetStatusBarColor(r, g, b)
			element[1]:SetMinMaxValues(0, maxPower)

			if (element[1].bg) then
				local mult = element[1].bg.multiplier or 1
				element[1].bg:SetVertexColor(r * mult, g * mult, b * mult)
			end

			for i = 2, 4 do
				element[i]:Hide()
			end
		elseif (spec == SPEC_WARLOCK_DESTRUCTION) then
			self:RegisterEvent("SPELLS_CHANGED", Visibility, true)

			if (IsPlayerSpell(WARLOCK_BURNING_EMBERS)) then
				show = true
				powerType = "BURNING_EMBERS"
				power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
				maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS)

				if (IsSpellKnown(WARLOCK_GREEN_FIRE)) then
					color = self.colors.warlock["BURNING_EMBERS_GREEN"]
					r, g, b = color[1], color[2], color[3]
				else
					color = self.colors.warlock[powerType]
					r, g, b = color[1], color[2], color[3]
				end

				for i = 1, 4 do
					element[i]:SetStatusBarColor(r, g, b)
					element[i]:SetMinMaxValues(MAX_POWER_PER_EMBER * i - MAX_POWER_PER_EMBER, MAX_POWER_PER_EMBER * i)

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
		end
	end

	if (not show) then
		for i = 1, 4 do
			element[i]:Hide()
		end
	end

	if (element.PostUpdateVisibility) then
		element:PostUpdateVisibility(spec, power, maxPower)
	end

	if (show) then
		return Path(self, "Visibility", self.unit, powerType)
	end
end

local Update = function(self, event, unit, powerType)
	if (unit ~= "player") then return end

	if (powerType and powerType ~= "SOUL_SHARDS" and powerType ~= "DEMONIC_FURY" and powerType ~= "BURNING_EMBERS" or not powerType) then return end

	local element = self.WarlockPowerBar
	local power = 0
	local maxPower = 0

	if (powerType == "SOUL_SHARDS" and spec == 1) then
		power = UnitPower("player", SPELL_POWER_SOUL_SHARDS)
		maxPower = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)

		for i = 1, maxPower do
			if (i <= power) then
				element[i]:SetValue(1)
			else
				element[i]:SetValue(0)
			end
		end
	elseif (powerType == "DEMONIC_FURY" and spec == 2) then
		power = UnitPower("player", SPELL_POWER_DEMONIC_FURY)
		maxPower = UnitPowerMax("player", SPELL_POWER_DEMONIC_FURY)

		element[1]:SetValue(power)
	elseif (powerType == "BURNING_EMBERS" and spec == 3) then
		power = UnitPower("player", SPELL_POWER_BURNING_EMBERS, true)
		maxPower = UnitPowerMax("player", SPELL_POWER_BURNING_EMBERS)

		for i = 1, maxPower do
			element[i]:SetValue(power)
		end
	end

	if (element.PostUpdate) then
		element:PostUpdate(powerType, power, maxPower)
	end
end

Path = function(self, ...)
	return (self.WarlockPowerBar.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Visibility(element.__owner, "ForceUpdate")
end

local Enable = function(self, unit)
	if (unit ~= "player") then return end

	local element = self.WarlockPowerBar

	if (element) then
		element.__owner = self
		element.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_POWER", Path)
		self:RegisterEvent("UNIT_DISPLAYPOWER", Path)
		self:RegisterEvent("PLAYER_TALENT_UPDATE", Visibility, true)

		return true
	end
end

local Disable = function(self)
	local element = self.WarlockPowerBar

	if (element) then
		self:UnregisterEvent("UNIT_POWER", Path)
		self:UnregisterEvent("UNIT_DISPLAYPOWER", Path)
		self:UnregisterEvent("PLAYER_TALENT_UPDATE", Visibility)
		self:UnregisterEvent("SPELLS_CHANGED", Visibility)

		for i = 1, 4 do
			element[i]:Hide()
		end
	end
end

oUF:AddElement("Rain_WarlockPowerBar", Visibility, Enable, Disable)