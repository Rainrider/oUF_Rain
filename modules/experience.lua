local _, ns = ...
local oUF = ns.oUF or oUF

for tag, func in pairs({
	["curxp"] = function(unit)
		return UnitXP(unit)
	end,
	["maxxp"] = function(unit)
		return UnitXPMax(unit)
	end,
	["percxp"] = function(unit)
		return math.floor(UnitXP(unit) / UnitXPMax(unit) * 100 + 0.5)
	end,
	["currestedxp"] = function(unit)
		return GetXPExhaustion(unit)
	end,
	["percrestedxp"] = function(unit)
		return math.floor((GetXPExhaustion() or 0) / UnitXPMax(unit) * 100 + 0.5)
	end,
	["curhonor"] = function(unit)
		return UnitHonor(unit)
	end,
	["maxhonor"] = function(unit)
		return UnitHonorMax(unit)
	end,
	["perchonor"] = function(unit)
		return math.floor(UnitHonor(unit) / UnitHonorMax(unit) * 100 + 0.5)
	end,
	["currestedhonor"] = function(unit)
		return GetHonorExhaustion()
	end,
	["percrestedhonor"] = function(unit)
		return math.floor((GetHonorExhaustion() or 0) / UnitHonorMax(unit) * 100 + 0.5)
	end,
}) do
	oUF.Tags.Methods[tag] = func
end

for tag, events in pairs({
	["curxp"] = "PLAYER_XP_UPDATE",
	["maxxp"] = "PLAYER_LEVEL_UP",
	["percxp"] = "PLAYER_XP_UPDATE PLAYER_LEVEL_UP",
	["currestedxp"] = "UPDATE_EXHAUSTION",
	["percrestedxp"] = "UPDATE_EXHAUSTION PLAYER_LEVEL_UP",
	["curhonor"] = "HONOR_XP_UPDATE",
	["maxhonor"] = "HONOR_LEVEL_UPDATE",
	["perchonor"] = "HONOR_XP_UPDATE HONOR_LEVEL_UPDATE",
	["currestedhonor"] = "UPDATE_EXHAUSTION",
	["percrestedhonor"] = "UPDATE_EXHAUSTION HONOR_LEVEL_UPDATE",
}) do
	oUF.Tags.Events[tag] = events
end

local function UpdateTooltip(element)
	local _, max = element:GetMinMaxValues()
	local cur = element:GetValue()
	local perc = cur / max * 100
	local showHonor = element.showHonor
	local title = showHonor and HONOR_LEVEL_LABEL or UNIT_LEVEL_TEMPLATE
	local label = showHonor and HONOR or COMBAT_XP_GAIN
	local level = showHonor and UnitHonorLevel("player") or UnitLevel("player")
	local exhaustion = (showHonor and GetHonorExhaustion or GetXPExhaustion)() or 0

	GameTooltip:SetText(format(title, level))
	GameTooltip:AddLine(format("%s: %s / %s (%.1f%%)", label, BreakUpLargeNumbers(cur), BreakUpLargeNumbers(max), perc))
	GameTooltip:AddLine(format("%s (%.1f%%) %s", BreakUpLargeNumbers(max - cur), 100 - perc, GARRISON_FOLLOWER_XP_STRING))
	if(exhaustion > 0) then
		GameTooltip:AddLine(string.format("%s: %s (%.1f%%)", TUTORIAL_TITLE26, BreakUpLargeNumbers(exhaustion), exhaustion / max * 100))
	end
	GameTooltip:Show()
end

local function OnEnter(element)
	element:SetAlpha(element.inAlpha)
	GameTooltip:SetOwner(element, element.tooltipAnchor)
	element:UpdateTooltip()
end

local function OnLeave(element)
	GameTooltip:Hide()
	element:SetAlpha(element.outAlpha)
end

local function UpdateColor(element, showHonor)
	if(showHonor) then
		element:SetStatusBarColor(1, 0.24, 0)

		if(element.Rested) then
			element.Rested:SetStatusBarColor(1, 0.71, 0)
		end
	else
		element:SetStatusBarColor(0.58, 0.0, 0.55)

		if(element.Rested) then
			element.Rested:SetStatusBarColor(0.0, 0.39, 0.88)
		end
	end
end

local function Update(self, event, unit)
	if (self.unit ~= unit) then return end

	local element = self.Experience
	if (element.PreUpdate) then element:PreUpdate(unit) end

	local showHonor = event == "HONOR_XP_UPDATE"
	local cur = (showHonor and UnitHonor or UnitXP)(unit)
	local max = (showHonor and UnitHonorMax or UnitXPMax)(unit)

	element:SetMinMaxValues(0, max)
	element:SetValue(cur)

	local exhaustion
	local rested = element.Rested
	if (rested) then
		exhaustion = (showHonor and GetHonorExhaustion or GetXPExhaustion)() or 0
		rested:SetMinMaxValues(cur, max)
		rested:SetValue(math.min(cur + exhaustion, max))
	end

	element.UpdateColor(element, showHonor)

	element.showHonor = showHonor

	if (element.PostUpdate) then
		return element:PostUpdate(unit, cur, max, exhaustion, showHonor)
	end
end

local function Path(self, ...)
	return (self.Experience.Override or Update) (self, ...)
end

local function Visibility(self, ...)
	local level = UnitLevel("player")
	local showXP = level < MAX_PLAYER_LEVEL and not IsXPUserDisabled()
	local showHonor = level >= MAX_PLAYER_LEVEL and (IsWatchingHonorAsXP() or InActiveBattlefield() or IsInActiveWorldPVP())

	if(showHonor) then
		self:RegisterEvent("HONOR_XP_UPDATE", Path)
		self:UnregisterEvent("PLAYER_XP_UPDATE", Path)

		if(self.Experience.Rested) then
			self:RegisterEvent("UPDATE_EXHAUSTION", Path, true)
		end
	elseif(showXP) then
		self:RegisterEvent("PLAYER_XP_UPDATE", Path, true)
		self:UnregisterEvent("HONOR_XP_UPDATE", Path)

		if(self.Experience.Rested) then
			self:RegisterEvent("UPDATE_EXHAUSTION", Path, true)
		end
	else
		self:UnregisterEvent("PLAYER_XP_UPDATE", Path)
		self:UnregisterEvent("HONOR_XP_UPDATE", Path)
		self:UnregisterEvent("UPDATE_EXHAUSTION", Path)
	end

	self.Experience:SetShown(showHonor or showXP)

	if(showHonor) then
		Path(self, "HONOR_XP_UPDATE", "player")
	elseif(showXP) then
		Path(self, "PLAYER_XP_UPDATE", "player")
	end
end

local function VisibilityPath(self, ...)
	return (self.Experience.Visibility or Visibility) (self, ...)
end

local function ForceUpdate(element)
	return VisibilityPath(element.__owner, "ForceUpdate", element.__owner.unit)
end

local function Enable(self, unit)
	local element = self.Experience
	if(not (element and unit == "player")) then return end

	element.__owner = self
	element.ForceUpdate = ForceUpdate
	element.UpdateColor = element.UpdateColor or UpdateColor

	self:RegisterEvent("PLAYER_LEVEL_UP", VisibilityPath, true)
	self:RegisterEvent("ZONE_CHANGED", VisibilityPath, true)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA", VisibilityPath, true)

	if (not element:GetStatusBarTexture()) then
		element:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
	end

	if (not element.Rested:GetStatusBarTexture()) then
		element.Rested:SetStatusBarTexture([=[Interface\TargetingFrame\UI-StatusBar]=])
	end

	if(element:IsMouseEnabled()) then
		element.UpdateTooltip = element.UpdateTooltip or UpdateTooltip
		element.tooltipAnchor = element.tooltipAnchor or "ANCHOR_BOTTOMRIGHT"
		element.inAlpha = element.inAlpha or 1
		element.outAlpha = element.outAlpha or 1

		element:SetAlpha(element.outAlpha)

		if(not element:GetScript("OnEnter")) then
			element:SetScript("OnEnter", OnEnter)
		end

		if(not element:GetScript("OnLeave")) then
			element:SetScript("OnLeave", OnLeave)
		end
	end

	return true
end

local function Disable(self)
	local element = self.Experience
	if (element) then
		self:UnregisterEvent("PLAYER_XP_UPDATE", Path)
		self:UnregisterEvent("HONOR_XP_UPDATE", Path)

		self:UnregisterEvent("PLAYER_LEVEL_UP", VisibilityPath)
		self:UnregisterEvent("ZONE_CHANGED", VisibilityPath)
		self:UnregisterEvent("ZONE_CHANGED_NEW_AREA", VisibilityPath)

		if (element.Rested) then
			self:UnregisterEvent("UPDATE_EXHAUSTION", Path)
		end

		element:Hide()
	end
end

oUF:AddElement("Rain_Experience", VisibilityPath, Enable, Disable)
