--[[===================================
	DESCRIPTION:
	Contrains the tags used in oUF_Rain
	===================================--]]

local _, ns = ...
local SiValue = ns.SiValue

oUF.Tags["rain:namecolor"] = function(unit)
	local color
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		color = {0.75, 0.75, 0.75}
	elseif (UnitIsPlayer(unit)) then
		color = oUF.colors.class[select(2, UnitClass(unit))]
	elseif (unit == "pet") then
		local happiness = GetPetHappiness()
		if happiness then
			color = ns.colors.happiness[happiness]
		else
			color = {0.33, 0.59, 0.33}
		end
	else
		local reaction = UnitReaction("player", unit)
		color = oUF.colors.reaction[reaction and reaction or 4]
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

oUF.Tags["rain:power"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	local cur, max = UnitPower(unit), UnitPowerMax(unit)
	
	if (cur == 0 or max == 0) then return end
	
	local powerValue = ""
	local pType = UnitPowerType(unit)
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
	
	return powerValue
end
oUF.TagEvents["rain:power"] = oUF.TagEvents.missingpp

oUF.Tags["rain:name"] = function(unit, r) -- TODO: what is r supposed to be?
	local color = oUF.Tags["rain:namecolor"](unit)
    local name = UnitName(r or unit)
    return color..(name or "").."|r"
end
oUF.TagEvents["rain:name"] = "UNIT_NAME_UPDATE UNIT_FACTION UNIT_CONNECTION UNIT_POWER"

oUF.Tags["rain:altpower"] = function(unit)
	-- XXX Temp fix for vehicle
	if unit == "vehicle" then unit = "player" end
	-- XXX
	if (unit ~= "player") then return end
	
	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)
	local perc = math.floor(cur / max * 100 + 0.5)
	
	return cur .. " - " .. perc .. "%"
end
oUF.TagEvents["rain:altpower"] = "UNIT_POWER UNIT_MAXPOWER"