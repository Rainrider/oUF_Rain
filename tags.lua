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

local GHOST = GetSpellInfo(8326)
do
	if (GetLocale() == "deDE") then
		GHOST = "Geist"		-- Geisterscheinung my ass
	end
end

local tags = oUF.Tags.Methods
local tagEvents = oUF.Tags.Events
local tagSharedEvents = oUF.Tags.SharedEvents

local SmallUnitHealthTag = function(unit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	end

	local cur = UnitHealth(unit)

	if (cur <= 0) then
		if (UnitIsUnconscious(unit)) then
			return UNCONSCIOUS
		end
		if (UnitIsDead(unit)) then
			return string.upper(DEAD)
		end
	end

	if (UnitIsGhost(unit)) then
		return GHOST
	end

	local max = UnitHealthMax(unit)

	local r, g, b = ColorGradient(cur, max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)

	if (cur == max) then
		return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, SiValue(max))
	end
	if (unit ~= "pet" and UnitIsFriend("player", unit)) then
		return format("|cff%02x%02x%02x-%s|r", r * 255, g * 255, b * 255, SiValue(max - cur))
	end
	return format("|cff%02x%02x%02x%d%%|r", r * 255, g * 255, b * 255, floor(cur / max * 100 + 0.5))
end

tags["rain:namecolor"] = function(unit)
	local color = ns.colors.disconnected
	if (UnitIsPlayer(unit)) then
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

tags["rain:healthSmall"] = SmallUnitHealthTag
tagEvents["rain:healthSmall"] = "UNIT_CONNECTION UNIT_HEALTH UNIT_MAXHEALTH"

tags["rain:bossHealth"] = SmallUnitHealthTag
tagEvents["rain:bossHealth"] = "UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"

tags["rain:health"] = function(unit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	end

	local cur = UnitHealth(unit)

	if (cur <= 0) then
		if (UnitIsUnconscious(unit)) then
			return UNCONSCIOUS
		end
		if (UnitIsDead(unit)) then
			return string.upper(DEAD)
		end
	end

	if (UnitIsGhost(unit)) then
		return GHOST
	end

	local max = UnitHealthMax(unit)

	local r, g, b = ColorGradient(cur, max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)

	if (cur == max) then
		return format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, SiValue(max))
	end

	if (UnitIsFriend("player", unit)) then
		return format("|cff%02x%02x%02x-%s - %d%%|r", r * 255, g * 255, b * 255, SiValue(max - cur), floor(cur / max * 100 + 0.5))
	end

	return format("|cff%02x%02x%02x%s - %d%%|r", r * 255, g * 255, b * 255, SiValue(cur), floor(cur / max * 100 + 0.5))
end
tagEvents["rain:health"] = "UNIT_CONNECTION UNIT_HEALTH_FREQUENT UNIT_MAXHEALTH"

tags["rain:raidmissinghp"] = function(unit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	end

	local cur = UnitHealth(unit)

	if (cur <= 0) then
		if (UnitIsUnconscious(unit)) then
			return UNCONSCIOUS
		end
		if (UnitIsDead(unit)) then
			return string.upper(DEAD)
		end
	end

	if (UnitIsGhost(unit)) then
		return GHOST
	end

	local max = UnitHealthMax(unit)

	local missing = max - cur
	if (missing > 0) then
		return "-" .. SiValue(missing)
	end
end
tagEvents["rain:raidmissinghp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION UNIT_FACTION"

tags["rain:raidpercenthp"] = function(unit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	end

	local cur = UnitHealth(unit)

	if (cur <= 0) then
		if (UnitIsUnconscious(unit)) then
			return UNCONSCIOUS
		end
		if (UnitIsDead(unit)) then
			return string.upper(DEAD)
		end
	end

	if (UnitIsGhost(unit)) then
		return GHOST
	end

	local max = UnitHealthMax(unit)
	local percent = math.floor(cur / max * 100 + 0.5) -- chuck norris can divide by zero
	if (percent < 100 and percent > 0) then
		return percent .. "%"
	end
end
tagEvents["rain:raidpercenthp"] = "UNIT_HEALTH UNIT_MAXHEALTH UNIT_CONNECTION UNIT_FACTION"

tags["rain:altmana"] = function(unit)
	if (unit ~= "player" or UnitPowerType(unit) == 0) then return end

	local curMana, maxMana = UnitPower(unit, 0), UnitPowerMax(unit, 0)

	if (curMana == maxMana) then return end

	local color = ns.colors.power.MANA
	local r, g, b = color[1], color[2], color[3]
	return format("|cff%02x%02x%02x%d%%|r", r * 255, g * 255, b * 255, floor(curMana / maxMana * 100 + 0.5))
end
tagEvents["rain:altmana"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER"

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
tagEvents["rain:power"] = "UNIT_POWER_FREQUENT UNIT_MAXPOWER UNIT_DISPLAYPOWER"

tags["rain:pvp"] = function(unit)
	local prestige = UnitPrestige(unit)
	local status
	local color

	if (UnitIsPVPFreeForAll(unit)) then
		status = "FFA"
		color = ORANGE_FONT_COLOR_CODE
	elseif (UnitIsPVP(unit)) then
		status = "PvP"
		color = RED_FONT_COLOR_CODE
	end

	if (status) then
		if (prestige and prestige > 0) then
			status = format("%s %d", status, prestige)
		end

		return format("%s%s|r", color, status)
	end
end

tagEvents["rain:pvp"] = "UNIT_FACTION HONOR_PRESTIGE_UPDATE"

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
tagEvents["rain:name"] = "UNIT_NAME_UPDATE UNIT_FACTION"

tags["rain:altpower"] = function(unit)
	local cur = UnitPower(unit, ALTERNATE_POWER_INDEX)
	local max = UnitPowerMax(unit, ALTERNATE_POWER_INDEX)

	if (max == 0) then max = 1 end

	return format("%d - %d%%", cur, floor(cur / max * 100 + 0.5))
end
tagEvents["rain:altpower"] = "UNIT_POWER UNIT_MAXPOWER"

tags["rain:status"] = function(unit)
	if (not UnitIsConnected(unit)) then
		return PLAYER_OFFLINE
	elseif (UnitIsGhost(unit)) then
		return GHOST
	elseif (UnitIsDead(unit)) then
		return DEAD
	end
end
tagEvents["rain:status"] = "UNIT_CONNECTION UNIT_HEALTH"
