local _, ns = ...
local SiValue = ns.SiValue


oUF.Tags["rain:petcolor"] = function(unit)
	if UnitIsUnit(unit, "pet") then
		local color = ns.colors.happiness[3]
		local happiness = GetPetHappiness()
		if happiness then
			color = ns.colors.happiness[happiness]
		end
		return ns.RGBtoHEX(color[1], color[2], color[3])
	end
end
oUF.TagEvents["rain:petcolor"] = "UNIT_POWER"

oUF.Tags["rain:color"] = function(unit)
	local color = {1,  1,  1}
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		color = {0.75, 0.75, 0.75}
	elseif (UnitIsPlayer(unit)) then
		color = oUF.colors.class[select(2, UnitClass(unit))]
	else
		color = oUF.colors.reaction[UnitReaction(unit, "player")]
	end
	
	return ns.RGBtoHEX(color[1], color[2], color[3])
end
oUF.TagEvents["rain:color"] = "UNIT_FACTION UNIT_CONNECTION"

oUF.Tags["rain:perhp"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if (min == 0 or max == 0 or min == max) then return end
	
	return math.floor(min / max * 100 + 0.5)
end
oUF.TagEvents["rain:perhp"] = oUF.TagEvents.perhp

oUF.Tags["rain:health"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if (not UnitIsFriend("player", unit)) then
		return SiValue(min)
	elseif (min ~= 0 and min ~= max) then
		return '-' .. SiValue(max - min)
	else
		return SiValue(max)
	end
end
oUF.TagEvents["rain:health"] = oUF.TagEvents.missinghp

oUF.Tags["rain:perpp"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	local pType = UnitPowerType(unit)
	if (pType ~= 0) then return end

	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if (min == 0 or max == 0 or min == max) then return end
	
	return math.floor(min / max * 100 + 0.5)
end
oUF.TagEvents["rain:perpp"] = oUF.TagEvents.perpp

oUF.Tags["rain:power"] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if (min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	if (not UnitIsPlayer(unit)) then return end
	
	return SiValue(min)
end
oUF.TagEvents["rain:power"] = oUF.TagEvents.missingpp

oUF.Tags["rain:name"] = function(unit, r) -- TODO: what is r supposed to be?
	local color = oUF.Tags["rain:color"](unit)
    local name = UnitName(r or unit)
    return color..(name or "").."|r"
end
oUF.TagEvents["rain:name"] = "UNIT_NAME_UPDATE"

oUF.Tags["rain:altpower"] = function(unit)
	if (unit ~= "player") then return end
	
	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
	local perc = math.floor(cur / max * 100 + 0.5)
	
	return cur .. " - " .. perc .. "%"
end
oUF.TagEvents["rain:altpower"] = "UNIT_POWER UNIT_MAXPOWER"