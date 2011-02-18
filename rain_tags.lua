local _, ns = ...

local siValue = function(val)
	if(val >= 1e6) then
		return ("%.1f".."m"):format(val / 1e6)--:gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f".."k"):format(val / 1e3)--:gsub('%.', 'k')
	else
		return val
	end
end

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
	local color = {r = 1, g = 1, b = 1}
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		color = {r = 0.4, g = 0.4, b = 0.4}
	elseif (UnitIsPlayer(unit)) then
		color = RAID_CLASS_COLORS[select(2, UnitClass(unit))]
	else
		color = FACTION_BAR_COLORS[UnitReaction(unit, "player")]
	end
	
	return ns.RGBtoHEX(color.r, color.g, color.b)
end
oUF.TagEvents["rain:color"] = "UNIT_FACTION UNIT_CONNECTION"

oUF.Tags["rain:health"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local min, max = UnitHealth(unit), UnitHealthMax(unit)
	if (not UnitIsFriend("player", unit)) then
		return siValue(min)
	elseif (min ~= 0 and min ~= max) then
		return '-' .. siValue(max - min)
	else
		return siValue(max)
	end
end
oUF.TagEvents["rain:health"] = oUF.TagEvents.missinghp

oUF.Tags["rain:perpp"] = function(unit)
	local pType = UnitPowerType(unit)
	if (pType ~= 0) then return end

	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if (min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	local ret = math.floor(min / max * 100 + 0.5)
	if (ret == 100) then return end
	
	return ret .. "% - "
end
oUF.TagEvents["rain:perpp"] = oUF.TagEvents.perpp

oUF.Tags["rain:power"] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	return siValue(min)
end
oUF.TagEvents["rain:power"] = oUF.TagEvents.missingpp

oUF.Tags["rain:name"] = function(unit, r) -- TODO: what is r supposed to be?
	local color = oUF.Tags["rain:color"](unit)
    local name = UnitName(r or unit)
    return color..(name or "").."|r"
end
oUF.TagEvents["rain:name"] = "UNIT_NAME_UPDATE"