local _, ns = ...
local oUF = ns.oUF or oUF
assert(oUF, "oUF Experience was unable to locate oUF install")

for tag, func in pairs({
	["curxp"] = function(unit)
		return UnitXP(unit)
	end,
	["maxxp"] = function(unit)
		return UnitXPMax(unit)
	end,
	["perxp"] = function(unit)
		return math.floor(UnitXP(unit) / UnitXPMax(unit) * 100 + 0.5)
	end,
	["currested"] = function()
		return GetXPExhaustion()
	end,
	["perrested"] = function(unit)
		local rested = GetXPExhaustion()
		if (rested and rested > 0) then
			return math.floor(rested / UnitXPMax(unit) * 100 + 0.5)
		end
	end,
}) do
	oUF.Tags[tag] = func
	oUF.TagEvents[tag] = "PLAYER_XP_UPDATE PLAYER_LEVEL_UP UPDATE_EXHAUSTION"
end

local Unbeneficial = function(self, unit)
	if (UnitHasVehicleUI("player")) then
		return true
	end

	if (UnitLevel("player") == MAX_PLAYER_LEVEL) then
		return true
	end
end

local Update = function(self, event, unit)
	if (self.unit ~= unit) then return end

	local experience = self.Experience
	if (experience.PreUpdate) then experience:PreUpdate(unit) end

	if (Unbeneficial(self, unit)) then
		experience:Hide()
		return
	else
		experience:Show()
	end

	local min, max = UnitXP(unit), UnitXPMax(unit)

	experience:SetMinMaxValues(0, max)
	experience:SetValue(min)

	if (experience.Rested) then
		local exhaustion = GetXPExhaustion()
		if not exhaustion then exhaustion = 0 end
		experience.Rested:SetMinMaxValues(min, max)
		experience.Rested:SetValue(math.min(min + exhaustion, max))
	end

	if (experience.PostUpdate) then
		return experience:PostUpdate(unit, min, max)
	end
end

local Path = function(self, ...)
	return (self.Experience.Override or Update) (self, ...)
end

local ForceUpdate = function(element)
	return Path(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	local experience = self.Experience
	if (experience) then
		experience.__owner = self
		experience.ForceUpdate = ForceUpdate

		self:RegisterEvent("PLAYER_XP_UPDATE", Path)
		self:RegisterEvent("PLAYER_LEVEL_UP", Path)

		local rested = experience.Rested
		if (rested) then
			self:RegisterEvent("UPDATE_EXHAUSTION", Path)

			if (not rested:GetStatusBarTexture()) then
				rested:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
			end
		end

		if (not experience:GetStatusBarTexture()) then
			experience:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
		end

		return true
	end
end

local Disable = function(self)
	local experience = self.Experience
	if (experience) then
		self:UnregisterEvent("PLAYER_XP_UPDATE", Path)
		self:UnregisterEvent("PLAYER_LEVEL_UP", Path)

		if (experience.Rested) then
			self:UnregisterEvent("UPDATE_EXHAUSTION", Path)
		end
	end
end

oUF:AddElement("Rain_Experience", Path, Enable, Disable)
