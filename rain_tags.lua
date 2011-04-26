--[[===================================
	DESCRIPTION:
	Contrains the tags used in oUF_Rain
	===================================--]]

local _, ns = ...
local SiValue = ns.SiValue
local playerClass = ns.config.playerClass

-- local references for some Blizz functions
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitIsFriend = UnitIsFriend
local UnitName = UnitName

oUF.Tags["rain:namecolor"] = function(unit)
	local color
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		color = {0.75, 0.75, 0.75}
	elseif (UnitIsPlayer(unit)) then
		color = oUF.colors.class[select(2, UnitClass(unit))]
	else
		local reaction = UnitReaction(unit, "player")
		color = oUF.colors.reaction[reaction or 4]
	end
	
	return ns.RGBtoHEX(color[1], color[2], color[3])
end

oUF.Tags["rain:healthSmall"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if (cur == 0 or max == 0) then return end

	if (cur == max) then
		return SiValue(max)
	end
	if (UnitIsFriend("player", unit) and unit ~= "pet") then
		return "-" .. SiValue(max - cur)
	end
	
	return math.floor(cur / max * 100 + 0.5) .. "%"
end
oUF.TagEvents["rain:healthSmall"] = oUF.TagEvents.perhp

oUF.Tags["rain:health"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if (cur == 0 or max == 0) then return end
	
	if (cur == max) then
		return SiValue(max)
	end
	
	if (UnitIsFriend("player", unit)) then
		return "-" .. SiValue(max - cur) .. " - " .. math.floor(cur / max * 100 + 0.5) .. "%"
	end
	
	return SiValue(cur) .. " - " .. math.floor(cur / max * 100 + 0.5) .. "%"
end
oUF.TagEvents["rain:health"] = oUF.TagEvents.missinghp

oUF.Tags["rain:druidmana"] = function(unit, pType)
	if unit ~= "player" or playerClass ~= "DRUID" or pType == 0 then return end
	
	local curMana, maxMana = UnitPower(unit, 0), UnitPowerMax(unit, 0)
	
	if curMana == maxMana then return end
	
	return ns.RGBtoHEX(unpack(oUF.colors.class[playerClass])) .. math.floor(curMana / maxMana * 100 + 0.5) .. "%|r"
end

oUF.Tags["rain:power"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	
	if (max == 0) then return end
	
	local powerValue = ""
	local pType, pName = UnitPowerType(unit)
	local druidMana = oUF.Tags["rain:druidmana"](unit, pType)
	if (pType == 0) then
		if (cur ~= max) then
			powerValue = math.floor(cur / max * 100 + 0.5) .. "%"
		end
	end
	if (UnitIsPlayer(unit) or UnitIsUnit(unit, "pet")) then
		if (powerValue ~= "") then
			powerValue = powerValue .." - " .. SiValue(cur)
		else
			powerValue = SiValue(cur)
		end
	else
		powerValue = SiValue(cur)
	end
	
	powerValue = ns.RGBtoHEX(unpack(ns.colors.power[pName])) .. powerValue .. "|r"
	
	if druidMana and cur > 0 then
		return powerValue .. " - " .. druidMana
	elseif druidMana and cur == 0 then
		return druidMana
	elseif cur > 0 then
		return powerValue
	end
end
oUF.TagEvents["rain:power"] = oUF.TagEvents.missingpp

oUF.Tags["rain:name"] = function(unit, r)
	local color = oUF.Tags["rain:namecolor"](unit)
    local name = UnitName(r or unit)
    return color..(name or "").."|r"
end
oUF.TagEvents["rain:name"] = "UNIT_NAME_UPDATE UNIT_FACTION UNIT_CONNECTION"

oUF.Tags["rain:altpower"] = function(unit)
	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
	
	if max == 0 then max = 1 end
	
	local perc = math.floor(cur / max * 100 + 0.5)
	
	return cur .. " - " .. perc .. "%"
end
oUF.TagEvents["rain:altpower"] = "UNIT_POWER UNIT_MAXPOWER"