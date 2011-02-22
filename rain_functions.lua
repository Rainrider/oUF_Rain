--[[========================================================================
	DESCRIPTION:
	Contrains the pre and post update and some helper functions for oUF_Rain
	========================================================================--]]

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
		["POWER_TYPE_SUN_POWER"] = {0.65, 0.63, 0.35},
	}, {__index = oUF.colors.power}),
	happiness = setmetatable({
		[1] = {0.69, 0.31, 0.31},
		[2] = {0.65, 0.63, 0.35},
		[3] = {0.33, 0.59, 0.33},
	}, {__index = oUF.colors.happiness}),
}, {__index = oUF.colors})
ns.colors = colors

--[[ HELPER FUNCTIONS ]]--

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

local CustomCastTimeText = function(self, duration)
	self.Time:SetText(("%.1f / %.1f"):format(self.channeling and duration or self.max - duration, self.max))
end
ns.CustomCastTimeText = CustomCastTimeText

local CustomCastDelayText = function(self, duration)
	self.Time:SetText(("%.1f |cffaf5050%s %.1f|r"):format(self.channeling and duration or self.max - duration, self.channeling and "- " or "+", self.delay))
end
ns.CustomCastDelayText = CustomCastDelayText

--[[PRE AND POST FUNCTIONS]]--

local function PostCastStart(castbar, unit, name, rank, castid)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	end
end
ns.PostCastStart = PostCastStart

local function PostCastInterruptible(castbar, unit)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	end
end
ns.PostCastInterruptible = PostCastInterruptible

local function PostCastNotInterruptible(castbar, unit)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	end
end
ns.PostCastNotInterruptible = PostCastNotInterruptible

local function PostChannelStart(castbar, unit, name)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	end
end
ns.PostchannelStart = PostChannelStart

local function PostUpdateHealth(health, unit, cur, max)
	if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		local class = select(2, UnitClass(unit))
		local color = UnitIsPlayer(unit) and oUF.colors.class[class] or {0.84, 0.75, 0.65}

		health:SetValue(0)
		health.bg:SetVertexColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5)
		health.value:SetTextColor(0.75, 0.75, 0.75)
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		health:SetStatusBarColor(unpack(oUF.colors.tapped))
		health.bg:SetVertexColor(0.15, 0.15, 0,15)
	else
		local r, g, b
		r, g, b = oUF.ColorGradient(cur/max, 0.69, 0.31, 0.31, 0.71, 0.43, 0.27, 0.17, 0.17, 0.24)

		health:SetStatusBarColor(r, g, b)
		health.bg:SetVertexColor(0.15, 0.15, 0.15)
		
		r, g, b = oUF.ColorGradient(cur/max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)
		if cur ~= max then
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

local function PostUpdatePower(Power, unit, cur, max)
	if (unit ~= "player" and unit ~= "target" and unit ~= "vehicle") then return end
	local pType, pName = UnitPowerType(unit)
	local color = colors.power[pName]
	
	if color and Power.value then
		Power.value:SetTextColor(unpack(color))
	end
	
	if (unit == "target") then
		local self = Power.__owner
		self.Info:ClearAllPoints()
		if (Power.value:GetText()) then
			self.Info:SetPoint("TOP", 0, -3.5)
		else
			self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
			self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", 0, 0)
		end
	end
end
ns.PostUpdatePower = PostUpdatePower

local function PostUpdateAltPower(AltPower, min, cur, max)
	local self = AltPower.__owner
	
	local _, r, g, b = UnitAlternatePowerTextureInfo(self.unit, 2) -- 2 is statusbar index
	if(r) then
		AltPower:SetStatusBarColor(r, g, b)
	end
end
ns.PostUpdateAltPower = PostUpdateAltPower
