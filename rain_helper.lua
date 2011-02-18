local _, ns = ...

local colors = setmetatable({
	power = setmetatable({
		["MANA"] = {0.31, 0.45, 0.63},
		["RAGE"] = {0.69, 0.31, 0.31},
		["FOCUS"] = {0.71, 0.43, 0.27},
		["ENERGY"] = {0.65, 0.63, 0.35},
		["HAPPINESS"] = {0.19, 0.58, 0.58},
		["RUNES"] = {0.55, 0.57, 0.61},
		["RUNIC_POWER"] = {0, 0.82, 1},
		["AMMOSLOT"] = {0.8, 0.6, 0},
		["FUEL"] = {0, 0.55, 0.5},
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
		["HOLY_POWER"] = {0.95, 0.93, 0.15},	
		["SOUL_SHARDS"] = {0.5, 0.0, 0.56},
	}, {__index = oUF.colors.power}),
	happiness = setmetatable({
		[1] = {0.69, 0.31, 0.31},
		[2] = {0.65, 0.63, 0.35},
		[3] = {0.33, 0.59, 0.33},
	}, {__index = oUF.colors.happiness}),
}, {__index = oUF.colors})
ns.colors = colors

local SiValue = function(val)
	if(val >= 1e6) then
		return ("%.1f".."m"):format(val / 1e6)--:gsub('%.', 'm')
	elseif(val >= 1e4) then
		return ("%.1f".."k"):format(val / 1e3)--:gsub('%.', 'k')
	else
		return val
	end
end
ns.SiValue = SiValue

local function RGBtoHEX(r, g, b)
	if not r then r = 1 end
	if not g then g = 1 end
	if not b then b = 1 end
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end
ns.RGBtoHEX = RGBtoHEX

local function PutFontString(parent, fontName, fontHeight, fontStyle, justifyH)
	local fontString = parent:CreateFontString(nil, "OVERLAY")
	fontString:SetFont(fontName, fontHeight, fontStyle)
	fontString:SetJustifyH(justifyH)
	fontString:SetShadowColor(0, 0, 0)
	fontString:SetShadowOffset(0.75, -0.75)
	
	return fontString
end
ns.PutFontString = PutFontString

local function PostUpdateHealth(health, unit, min, max)
	if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		local class = select(2, UnitClass(unit))
		local color = UnitIsPlayer(unit) and oUF.colors.class[class] or {0.84, 0.75, 0.65}

		health:SetValue(0)
		health.bg:SetVertexColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5)
		health.value:SetTextColor(0.75, 0.75, 0.75)
--[[ This is included in the health tag
		if not UnitIsConnected(unit) then
			health.value:SetText("|cffD7BEA5".._G["PLAYER_OFFLINE"].."|r")
		elseif UnitIsDead(unit) then
			health.value:SetText("|cffD7BEA5".._G["DEAD"].."|r")
		elseif UnitIsGhost(unit) then
			health.value:SetText("|cffD7BEA5".."Ghost".."|r")
		end		--]]
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		health:SetStatusBarColor(unpack(oUF.colors.tapped))
		health.bg:SetVertexColor(0.15, 0.15, 0,15)
	else
		local r, g, b
		r, g, b = oUF.ColorGradient(min/max, 0.69, 0.31, 0.31, 0.71, 0.43, 0.27, 0.17, 0.17, 0.24)

		health:SetStatusBarColor(r, g, b)
		health.bg:SetVertexColor(0.15, 0.15, 0.15)
		
		-- TODO health value coloring / doable with tags?
		r, g, b = oUF.ColorGradient(min/max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)
		if min ~= max then
			health.value:SetTextColor(r, g, b)
		else
			health.value:SetTextColor(r, g, b)
		end
	end
end
ns.PostUpdateHealth = PostUpdateHealth

local function PreUpdatePower(power, unit)
	local _, pName = UnitPowerType(unit)
	
	local color = colors.power[pName]
	if color then
		power:SetStatusBarColor(unpack(color))
	end
end
ns.PreUpdatePower = PreUpdatePower

local function PostUpdatePower(Power, unit, min, max)
	if (unit ~= "player" and unit ~= "target") then return end

	local pType, pName = UnitPowerType(unit)
	local color = colors.power[pName]
	
	if color then
		Power.value:SetTextColor(unpack(color))
	end
	
	if (unit == "target") then
		local self = Power.__owner
		self.Info:ClearAllPoints()
		if (Power.value:GetText()) then
			self.Info:SetPoint("TOP", 0, -3.5)
		else
			self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
		end
	end
end
ns.PostUpdatePower = PostUpdatePower