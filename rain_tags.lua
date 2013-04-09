--[[===================================
	DESCRIPTION:
	Contrains the tags used in oUF_Rain
	===================================--]]

local _, ns = ...
local SiValue = ns.SiValue
local playerClass = ns.playerClass

-- local references for some lua function
local floor = math.floor
local format = string.format

-- local references for some Blizz functions
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitIsDead = UnitIsDead
local UnitIsGhost = UnitIsGhost
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPower = UnitPower
local UnitPowerMax = UnitPowerMax
local UnitPowerType = UnitPowerType
local UnitIsPlayer = UnitIsPlayer
local UnitIsUnit = UnitIsUnit
local UnitIsFriend = UnitIsFriend
local UnitName = UnitName

local ColorGradient = oUF.ColorGradient

local tags = oUF.Tags.Methods
local tagEvents = oUF.Tags.Events
local tagSharedEvents = oUF.Tags.SharedEvents

tags["rain:namecolor"] = function(unit)
	local color = {1, 1, 1}
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		color = {0.75, 0.75, 0.75}
	elseif (UnitIsPlayer(unit)) then
		local _, unitClass = UnitClass(unit)
		if (unitClass) then
			color = ns.colors.class[unitClass]
		end
	else
		local reaction = UnitReaction(unit, "player")
		color = ns.colors.reaction[reaction or 4]
	end

	return format("|cff%02x%02x%02x", color[1] * 255, color[2] * 255, color[3] * 255)
end

tags["rain:healthSmall"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if (cur == 0 or max == 0) then return end

	local r, g, b = ColorGradient(cur, max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)

	if (cur == max) then
		return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, SiValue(max))
	end
	if (UnitIsFriend("player", unit) and unit ~= "pet") then
		return format("|cff%02x%02x%02x-%s|r", r * 255, g * 255, b * 255, SiValue(max - cur))
	end

	return format("|cff%02x%02x%02x%d%%|r", r * 255, g * 255, b * 255, floor(cur / max * 100 + 0.5))
end
tagEvents["rain:healthSmall"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"

tags["rain:health"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	if (cur == 0 or max == 0) then return end

	local r, g, b = ColorGradient(cur, max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)

	if (cur == max) then
		return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, SiValue(max))
	end

	if (UnitIsFriend("player", unit)) then
		return format("|cff%02x%02x%02x-%s - %d%%|r", r * 255, g * 255, b * 255, SiValue(max - cur), floor(cur / max * 100 + 0.5))
	end

	return format("|cff%02x%02x%02x%s - %d%%|r", r * 255, g * 255, b * 255, SiValue(cur), floor(cur / max * 100 + 0.5))
end
tagEvents["rain:health"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"

tags["rain:raidmissinghp"] = function(unit)
	local status = tags["rain:status"](unit)
	if (status) then
		return status
	else
		local missing = UnitHealthMax(unit) - UnitHealth(unit)
		if (missing > 0) then
			return "-" .. SiValue(missing)
		else
			return tags["rain:name"](unit)
		end
	end
end
tagEvents["rain:raidmissinghp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION UNIT_FACTION"

tags["rain:raidpercenthp"] = function(unit)
	local status = tags["rain:status"](unit)
	if (status) then
		return status
	else
		local percent = math.floor(UnitHealth(unit) / UnitHealthMax(unit) * 100 + 0.5) -- chuck norris can divide by zero
		if (percent < 100 and percent > 0) then
			return percent .. "%"
		else
			return tags["rain:name"](unit)
		end
	end
end
tagEvents["rain:raidpercenthp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION UNIT_FACTION"

tags["rain:altmana"] = function(unit)
	if (unit ~= "player" or UnitPowerType(unit) == 0) then return end

	local curMana, maxMana = UnitPower(unit, 0), UnitPowerMax(unit, 0)

	if (curMana == maxMana) then return end

	local r, g, b = unpack(ns.colors.power.MANA)
	return format("|cff%02x%02x%02x%d%%|r", r * 255, g * 255, b * 255, floor(curMana / maxMana * 100 + 0.5))
end
tagEvents["rain:altmana"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"

tags["rain:level"] = function(unit)
	if (UnitClassification(unit) == "worldboss") then return end
	local level
	if (UnitIsWildBattlePet(unit) or UnitIsBattlePetCompanion(unit)) then
		level = UnitBattlePetLevel(unit)
	else
		level = UnitLevel(unit)
	end
	if (level == UnitLevel("player")) then return end
	if (level < 0) then return "??" end
	return level
end
tagEvents["rain:level"] = "UNIT_LEVEL"

tags["rain:status"] = function(unit)
	if (UnitIsDead(unit)) then
		return _G["DEAD"]
	elseif (UnitIsGhost(unit)) then
		local ghost = GetSpellInfo(8326)
		if (GetLocale() == "deDE") then
			ghost = ghost:sub(1, 5)		-- Geisterscheinung my ass
		end
		return ghost
	elseif (not UnitIsConnected(unit)) then
		return _G["PLAYER_OFFLINE"]
	end
end
tagEvents["rain:status"] = "UNIT_HEALTH UNIT_CONNECTION"

tags["rain:power"] = function(unit)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then return end

	local cur, max = UnitPower(unit), UnitPowerMax(unit)

	if (max == 0) then return end

	local powerValue = ""
	local pType, pName = UnitPowerType(unit)

	if (pName == "MANA" and cur ~= max) then
		powerValue = floor(cur / max * 100 + 0.5) .. "%"
	end

	if (unit == "player") then
		if (powerValue ~= "") then -- player's mana not full
			powerValue = powerValue .." - " .. SiValue(cur)
		else -- player's mana full or other power type
			powerValue = SiValue(cur)
		end
	elseif (powerValue == "") then -- unit's power type is not mana
		powerValue = SiValue(cur)
	end

	local r, g, b = unpack(ns.colors.power[pName] or ns.colors.power[pType])
	return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, powerValue)
end
tagEvents["rain:power"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER"

tags["rain:role"] = function(unit)
	local xOffset = 0
	local yOffset = 0
	local dimX, dimY = 64, 64 -- dimensions of Interface\LFGFrame\UI-LFG-ICON-PORTRAITROLES.blp
	local role = UnitGroupRolesAssigned(unit)
	if (role and role ~= "NONE") then
		local left, right, top, bottom = GetTexCoordsForRoleSmallCircle(role) -- this returns ratios
		local cropFromLeft = dimX * left
		local cropFromRight = dimX * right
		local cropFromTop = dimY * top
		local cropFromBottom = dimY * bottom

		local icon = format("|TInterface\\LFGFrame\\UI-LFG-ICON-PORTRAITROLES.blp:14:14:%-d:%-d:%d:%d:%d:%d:%d:%d|t", xOffset, yOffset, dimX, dimY, cropFromLeft, cropFromRight, cropFromTop, cropFromBottom)
		return icon
	end
end
tagEvents["rain:role"] = "GROUP_ROSTER_UPDATE PLAYER_ROLES_ASSIGNED ROLE_CHANGED_INFORM"
tagSharedEvents.GROUP_ROSTER_UPDATE = true
tagSharedEvents.PLAYER_ROLES_ASSIGNED = true
tagSharedEvents.ROLE_CHANGED_INFORM = true

tags["rain:name"] = function(unit, r)
	local color = tags["rain:namecolor"](r or unit)
    local name = UnitName(r or unit)
	if (unit == "target") then
		name = ns.ShortenName(name, 18)
	elseif (unit:match("raid%d")) then
		name = ns.ShortenName(name, 8)
	else
		name = ns.ShortenName(name, 12)
	end
    return color..(name or "").."|r"
end
tagEvents["rain:name"] = "UNIT_NAME_UPDATE UNIT_FACTION UNIT_CONNECTION"

tags["rain:altpower"] = function(unit)
	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)

	if (max == 0) then max = 1 end

	local perc = floor(cur / max * 100 + 0.5)

	return cur .. " - " .. perc .. "%"
end
tagEvents["rain:altpower"] = "UNIT_POWER UNIT_MAXPOWER"