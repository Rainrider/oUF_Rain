--[[========================================================================
	DESCRIPTION:
	Contrains the pre and post update and some helper functions for oUF_Rain
	========================================================================--]]

local _, ns = ...
local cfg = ns.config

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

local function ShortenName(name, shortenTo)
	if not name then return end
	if not shortenTo then
		shortenTo = 12
	end
	name = (string.len(name) > shortenTo) and string.gsub(name, "%s?(.[\128-\191]*)%S+%s", "%1. ") or name
	
	local bytes = string.len(name)
	if bytes <= shortenTo then
		return name
	else
		local length, currentIndex = 0, 1

		while currentIndex <= bytes do
			length = length + 1
			local char = string.byte(name, currentIndex)
			if char > 240 then
				currentIndex = currentIndex + 4
			elseif char > 225 then
				currentIndex = currentIndex + 3
			elseif char > 192 then
				currentIndex = currentIndex + 2
			else
				currentIndex = currentIndex + 1
			end

			if length == shortenTo then
				break
			end
		end

		if length == shortenTo and currentIndex <= bytes then
			return string.sub(name, 1, currentIndex - 1) .. "..." -- TODO: add the dots
		else
			return name
		end
	end
end
ns.ShortenName = ShortenName

local function RGBtoHEX(r, g, b)
	if not r then r = 1 end
	if not g then g = 1 end
	if not b then b = 1 end
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end
ns.RGBtoHEX = RGBtoHEX

local function FormatTime(s)
	local day, hour, minute = 86400, 3600, 60
	if s >= day then
		return format("%dd", floor(s/day + 0.5)), s % day
	elseif s >= hour then
		return format("%dh", floor(s/hour + 0.5)), s % hour
	elseif s >= minute then
		if s <= minute * 5 then
			return format("%d:%02d", floor(s/60), s % minute), s - floor(s)
		end
		return format("%dm", floor(s/minute + 0.5)), s % minute
	elseif s >= minute / 12 then
		return floor(s + 0.5), (s * 100 - floor(s * 100))/100
	end
	return format("%.1f", s), (s * 100 - floor(s * 100))/100
end

local function PutFontString(parent, fontName, fontHeight, fontStyle, justifyH)
	local fontString = parent:CreateFontString(nil, "OVERLAY")
	fontString:SetFont(fontName, fontHeight, fontStyle)
	fontString:SetJustifyH(justifyH and justifyH or "LEFT")
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

local CustomFilter = function(icons, unit, icon, name, rank, texture, count, dtype, duration, expiration, caster)
	if UnitCanAttack("player", unit) then
		local casterClass

		if caster then
			_, casterClass = UnitClass(caster)
		end
		if not icon.debuff or (casterClass and casterClass == cfg.playerClass) then	-- return all buffs and only debuffs cast by the players class
			return true
		end
	else
		local isPlayer

		if caster == "player" or caster == "pet" or caster == "vehicle" then
			isPlayer = true
		end
		
		if((icons.onlyShowPlayer and isPlayer) or (not icons.onlyShowPlayer and name)) then -- onlyShowPlayer or everything?
			icon.isPlayer = isPlayer
			icon.owner = caster
			return true
		end
	end
end

local function CreateAuraTimer(self, elapsed)
	if self.timeLeft then
		self.elapsed = (self.elapsed or 0) + elapsed
		if self.elapsed >= 0.1 then
			if not self.first then
				self.timeLeft = self.timeLeft - self.elapsed
			else
				self.timeLeft = self.timeLeft - GetTime()
				self.first = false
			end
			if self.timeLeft > 0 then
				local time = FormatTime(self.timeLeft)
					self.remaining:SetText(time)
				if self.timeLeft < 5 then
					self.remaining:SetTextColor(0.69, 0.31, 0.31)
				else
					self.remaining:SetTextColor(0.84, 0.75, 0.65)
				end
			else
				self.remaining:Hide()
				self:SetScript("OnUpdate", nil)
			end
			self.elapsed = 0
		end
	end
end

local function SortAuras(a, b)
	if (a and b) then
		return (a.timeLeft and a.timeLeft) > (b.timeLeft and b.timeLeft)
	end
end

local function Aura_OnEnter(self, icon)
	local r, g, b = icon.overlay:GetVertexColor()
	local iconW, iconH = icon:GetSize()
	local button
	
	if icon.debuff then
		button = self.Debuffs.Magnify
	else
		button = self.Buffs.Magnify
	end
	
	button:SetSize(iconW * 2, iconH * 2)
	button:SetPoint("CENTER", icon, "CENTER")
	
	button.icon:SetSize(iconW * 2, iconH * 2)
	button.icon:SetTexture(icon.icon:GetTexture())
	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	button.border:SetVertexColor(r, g, b)

	button:Show()
	
	if icon.debuff then
		self.Debuffs.Magnify = button
	else
		self.Buffs.Magnify = button
	end
end

local function Aura_OnLeave(self)
	self.Buffs.Magnify:Hide()
	self.Debuffs.Magnify:Hide()
end

local function AddThreatHighlight(self)
	local unit = self.unit

	local status = UnitThreatSituation(unit)
	if status and status > 0 then
		local r, g, b = GetThreatStatusColor(status)
	
		self.FrameBackdrop:SetBackdropBorderColor(r, g, b)
	else
		self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	end
end
ns.AddThreatHighlight = AddThreatHighlight

--[[PRE AND POST FUNCTIONS]]--

local function PostCastStart(castbar, unit, name, rank, castid)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
		castbar.Icon.Overlay:SetVertexColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
		castbar.Icon.Overlay:SetVertexColor(0.4, 0.4, 0.4)
	end
end
ns.PostCastStart = PostCastStart

local function PostCastInterruptible(castbar, unit)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
		castbar.IconOverlay:SetVertexColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
		castbar.Icon.Overlay:SetVertexColor(0.4, 0.4, 0.4)
	end
end
ns.PostCastInterruptible = PostCastInterruptible

local function PostCastNotInterruptible(castbar, unit)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
		castbar.Icon.Overlay:SetVertexColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
		castbar.Icon.Overlay:SetVertexColor(0.4, 0.4, 0.4)
	end
end
ns.PostCastNotInterruptible = PostCastNotInterruptible

local function PostChannelStart(castbar, unit, name)
	if castbar.interrupt and UnitCanAttack("player", unit) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
		castbar.Icon.Overlay:SetVertexColor(0.69, 0.31, 0.31)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
		castbar.Icon.Overlay:SetVertexColor(0.4, 0.4, 0.4)
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
	if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		Power:SetValue(0)
	end
	if (unit ~= "player" and unit ~= "target" and unit ~= "vehicle") then return end
	
	if (unit == "target") then
		local self = Power.__owner
		if self.Info then
			self.Info:ClearAllPoints()
			if (Power.value:GetText()) then
				self.Info:SetPoint("TOP", 0, -3.5)
			else
				self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
				self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", 0, 0)
			end
		end
	end
end
ns.PostUpdatePower = PostUpdatePower

local function PostUpdateAltPower(AltPower, min, cur, max)
	local unit = AltPower.__owner.unit

	local _, r, g, b = UnitAlternatePowerTextureInfo(unit, 2) -- 2 is statusbar index
	if(r) then
		AltPower:SetStatusBarColor(r, g, b)
	end
end
ns.PostUpdateAltPower = PostUpdateAltPower

local function PostCreateIcon(Icons, icon)
	-- remove OmniCC and CooldownCount timers
	icon.cd.noOCC = true
	icon.cd.noCooldownCount = true
	
	icon.count:SetPoint("BOTTOMRIGHT", 1, 1.5)
	icon.count:SetFont(cfg.FONT, 8, "OUTLINE")
	icon.count:SetTextColor(0.84, 0.75, 0.65)
	icon.count:SetJustifyH("RIGHT")
	
	icon.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	icon.overlay:SetTexture(cfg.BTNTEXTURE)
	icon.overlay:SetPoint("TOPLEFT", -3.5, 3.5)
	icon.overlay:SetPoint("BOTTOMRIGHT", 3.5, -3.5)
	icon.overlay:SetTexCoord(0, 1, 0, 1)
	--icon.overlay.Hide = function(self) end -- TODO unneeded?
	
	icon.remaining = PutFontString(icon, cfg.FONT, 8, "OUTLINE", "LEFT")
	icon.remaining:SetPoint("TOP", 0, 1)
	
	icon:HookScript("OnEnter", function() Aura_OnEnter(Icons.__owner, icon) end)
	icon:HookScript("OnLeave", function() Aura_OnLeave(Icons.__owner) end)
end

local function PreSetPosition(Auras)
	table.sort(Auras, SortAuras)
end

local PostUpdateIcon
do
	local playerUnits = {
		player = true,
		pet = true,
		vehicle = true,
	}

	PostUpdateIcon = function(icons, unit, icon, index, offset)
		local _, _, _, _, _, duration, expirationTime, unitCaster, _ = UnitAura(unit, index, icon.filter)
		
		if playerUnits[unitCaster] then
			if icon.debuff then
				icon.overlay:SetVertexColor(0.69, 0.31, 0.31)
			else
				icon.overlay:SetVertexColor(0.33, 0.59, 0.33)
			end
		else
			if UnitIsEnemy("player", unit) then
				if icon.debuff then
					icon.icon:SetDesaturated(true)
				end
			end
			icon.overlay:SetVertexColor(0.5, 0.5, 0.5)
		end
		
		if duration and duration > 0 then
			icon.remaining:Show()
			icon.timeLeft = expirationTime
			icon:SetScript("OnUpdate", CreateAuraTimer)
		else
			icon.remaining:Hide()
			icon.timeLeft = math.huge
			icon:SetScript("OnUpdate", nil)
		end

		icon.first = true
	end
end

local function PostUpdateTotems(Totems, slot, haveTotem, name, start, duration, icon)
	local delay = 0.5
	local total = 0

	if duration > 0 then
		local current = GetTime() - start
		if current > 0 then
			Totems[slot]:SetValue(1 - (current / duration))
			Totems[slot]:SetScript("OnUpdate", function(self, elapsed)
				total = total + elapsed
				if total >= delay then
					total = 0
					self:SetValue(1 - ((GetTime() - start) / duration))
				end
			end)
		end
	end
end
ns.PostUpdateTotems = PostUpdateTotems
--[[END OF PRE AND POST FUNCTIONS]]--

local function AddAuras(self, unit)
	self.Auras = CreateFrame("Frame", self:GetName().."_Auras", self)
	self.Auras:SetPoint("RIGHT", self, "LEFT", -9, 0)
	self.Auras.numBuffs = 6
	self.Auras.numDebuffs = 6
	self.Auras.spacing = 6
	self.Auras.size = (230 - 9 * self.Auras.spacing) / 10
	self.Auras:SetSize(12 * self.Auras.size + 11 * self.Auras.spacing, self.Auras.size)
	self.Auras.disableCooldown = true
	self.Auras.showType = true
	self.Auras.onlyShowPlayer = false
	self.Auras.PreSetPosition = PreSetPosition
	self.Auras.PostCreateIcon = PostCreateIcon
	self.Auras.PostUpdateIcon = PostUpdateIcon
end
ns.AddAuras = AddAuras

local function AddBuffs(self, unit)
	self.Buffs = CreateFrame("Frame", self:GetName().."_Buffs", self)
	self.Buffs.spacing = 6
	self.Buffs.size = (230 - 9 * self.Buffs.spacing) / 10
	self.Buffs.disableCooldown = true
	self.Buffs.showType = true
	self.Buffs.onlyShowPlayer = false
	self.Buffs.PreSetPosition = PreSetPosition
	self.Buffs.PostCreateIcon = PostCreateIcon
	self.Buffs.PostUpdateIcon = PostUpdateIcon
	
	if (unit == "player" or unit == "target") then
		self.Buffs:SetSize(self.Buffs.size * 10 + 9 * self.Buffs.spacing, 4 * self.Buffs.size + 3 * self.Buffs.spacing)
		self.Buffs["growth-y"] = "DOWN"
		
		if (unit == "player") then
			self.Buffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -9, -1)
			self.Buffs.initialAnchor = "TOPRIGHT"
			self.Buffs["growth-x"] = "LEFT"
		else
			self.Buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 9, -1)
			self.Buffs.initialAnchor = "TOPLEFT"
			self.Buffs["growth-x"] = "RIGHT"
		end
	end
	
	if (unit == "pet") then
		self.Buffs:SetPoint("RIGHT", self.Debuffs, "LEFT", -5, 0)
		self.Buffs.num = 6
		self.Buffs:SetSize(self.Buffs.num * self.Buffs.size + (self.Buffs.num - 1) * self.Buffs.spacing, self.Buffs.size)
		self.Buffs.initialAnchor = "RIGHT"
		self.Buffs["growth-x"] = "LEFT"
	end
	
	if unit:match("boss%d") then
		self.Buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 15, 0)
		self.Buffs.num = 6
		self.Buffs:SetSize(self.Buffs.num * self.Buffs.size + (self.Buffs.num - 1) * self.Buffs.spacing, self.Buffs.size)
		self.Buffs.initialAnchor = "LEFT"
		self.Buffs["growth-x"] = "RIGHT"
	end
	
	self.Buffs.Magnify = CreateFrame("Frame", nil, self)
	self.Buffs.Magnify:SetFrameLevel(self.Buffs:GetFrameLevel() + 3)
	
	self.Buffs.Magnify.icon = self.Buffs.Magnify:CreateTexture(nil, "ARTWORK")
	self.Buffs.Magnify.icon:SetPoint("CENTER")
	
	self.Buffs.Magnify.border = self.Buffs.Magnify:CreateTexture(nil, "OVERLAY")
	self.Buffs.Magnify.border:SetTexture(cfg.BTNTEXTURE)
	self.Buffs.Magnify.border:SetPoint("TOPLEFT", self.Buffs.Magnify.icon, -5, 5)
	self.Buffs.Magnify.border:SetPoint("BOTTOMRIGHT", self.Buffs.Magnify.icon, 5, -5)
end
ns.AddBuffs = AddBuffs

local function AddDebuffs(self, unit)
	self.Debuffs = CreateFrame("Frame", self:GetName().."_Debuffs", self)
	self.Debuffs.spacing = 6
	self.Debuffs.size = (230 - 9 * self.Debuffs.spacing) / 10
	self.Debuffs.showType = true
	self.Debuffs.disableCooldown = true
	self.Debuffs.onlyShowPlayer = false
	self.Debuffs.PreSetPosition = PreSetPosition
	self.Debuffs.PostCreateIcon = PostCreateIcon
	self.Debuffs.PostUpdateIcon = PostUpdateIcon
	
	if (unit == "player" or unit == "target") then
		self.Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -7.5)
		self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -7.5)
		self.Debuffs:SetSize(self:GetWidth(), self.Debuffs.size * 4 + self.Debuffs.spacing * 3)
		
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "DOWN"
		
		if (unit == "target") then
			self.Debuffs.CustomFilter = CustomFilter
		end
	end
	
	if (unit == "pet") then
		self.Debuffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -15, 0)
		self.Debuffs.num = 6
		self.Debuffs:SetSize(self.Debuffs.num * self.Debuffs.size + (self.Debuffs.num - 1) * self.Debuffs.spacing, self.Debuffs.size)
		
		self.Debuffs.initialAnchor = "RIGHT"
		self.Debuffs["growth-x"] = "LEFT"
	end
	
	if (unit == "targettarget") then
		self.Debuffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 15, 0)
		self.Debuffs.num = 6
		self.Debuffs:SetSize(self.Debuffs.num * self.Debuffs.size + (self.Debuffs.num - 1) * self.Debuffs.spacing, self.Debuffs.size)
		
		self.Debuffs.initialAnchor = "LEFT"
		self.Debuffs["growth-x"] = "RIGHT"
	end
	
	self.Debuffs.Magnify = CreateFrame("Frame", nil, self)
	self.Debuffs.Magnify:SetFrameLevel(self.Debuffs:GetFrameLevel() + 3)
	
	self.Debuffs.Magnify.icon = self.Debuffs.Magnify:CreateTexture(nil, "ARTWORK")
	self.Debuffs.Magnify.icon:SetPoint("CENTER")
	
	self.Debuffs.Magnify.border = self.Debuffs.Magnify:CreateTexture(nil, "OVERLAY")
	self.Debuffs.Magnify.border:SetTexture(cfg.BTNTEXTURE)
	self.Debuffs.Magnify.border:SetPoint("TOPLEFT", self.Debuffs.Magnify.icon, -5, 5)
	self.Debuffs.Magnify.border:SetPoint("BOTTOMRIGHT", self.Debuffs.Magnify.icon, 5, -5)
end
ns.AddDebuffs = AddDebuffs