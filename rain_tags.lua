local siValue = function(val)
	if(val >= 1e6) then
		return ("%.1f".."m"):format(val / 1e6)--:gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f".."k"):format(val / 1e3)--:gsub('%.', 'k')
	else
		return val
	end
end

oUF.Tags['rain:health'] = function(unit)
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
oUF.TagEvents['rain:health'] = oUF.TagEvents.missinghp

oUF.Tags['rain:perpp'] = function(unit)
	local pType = UnitPowerType(unit)
	if (pType ~= 0) then return end

	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if (min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	local ret = math.floor(min / max * 100 + 0.5)
	if (ret == 100) then return end
	
	return ret .. "% - "
end
oUF.TagEvents['rain:perpp'] = oUF.TagEvents.perpp

oUF.Tags['rain:power'] = function(unit)
	local min, max = UnitPower(unit), UnitPowerMax(unit)
	if(min == 0 or max == 0 or not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end
	
	return siValue(min)
end
oUF.TagEvents['rain:power'] = oUF.TagEvents.missingpp