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
		print("customFilter |cffff0000casterClass:|r ", casterClass)
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
	if  not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		Power:SetValue(0)
	end
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

local function PostCreateAura(Auras, button)
	-- remove OmniCC and CooldownCount timers
	button.cd.noOCC = true
	button.cd.noCooldownCount = true
	
	button.count:SetPoint("BOTTOMRIGHT", 1, 1.5)
	button.count:SetFont(cfg.FONT, 8, "OUTLINE")
	button.count:SetTextColor(0.84, 0.75, 0.65)
	button.count:SetJustifyH("RIGHT")
	
	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	
	button.backdrop = CreateFrame("Frame", nil, button)
	button.backdrop:SetPoint("TOPLEFT", -5, 5)
	button.backdrop:SetPoint("BOTTOMRIGHT", 5, -5)
	button.backdrop:SetBackdrop(cfg.BORDERBACKDROP)
	button.backdrop:SetBackdropBorderColor(0, 0, 0)
	
	button.overlay:SetTexture(cfg.BTNTEXTURE)
	button.overlay:SetPoint("TOPLEFT", -3.5, 3.5)
	button.overlay:SetPoint("BOTTOMRIGHT", 3.5, -3.5)
	button.overlay:SetTexCoord(0, 1, 0, 1)
	--button.overlay.Hide = function(self) end -- TODO unneeded?
	
	button.remaining = PutFontString(button.backdrop, cfg.FONT, 8, "OUTLINE", "LEFT")
	button.remaining:SetPoint("TOP", 0, -2)
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
		print("PostUpdateIcon |cffff0000caster:|r ", unitCaster, "|cffff0000unit:|r ", unit)
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

--[[END OF PRE AND POST FUNCTIONS]]--

local function AddAuras(self, unit)
	self.Auras = CreateFrame("Frame", self:GetName().."_Auras", self)
	self.Auras:SetPoint("RIGHT", self, "LEFT", -9, 0)
	self.Auras.numBuffs = 6
	self.Auras.numDebuffs = 6
	self.Auras.spacing = 6
	self.Auras.size = ((230 - 9 * self.Auras.spacing) / 10)
	self.Auras:SetSize(12 * self.Auras.size + 11 * self.Auras.spacing, self.Auras.size)
	self.Auras.disableCooldown = true
	self.Auras.showType = true
	self.Auras.onlyShowPlayer = false
	self.Auras.PreSetPosition = PreSetPosition
	self.Auras.PostCreateIcon = PostCreateAura
	self.Auras.PostUpdateIcon = PostUpdateIcon
end
ns.AddAuras = AddAuras

local function AddBuffs(self, unit)
	self.Buffs = CreateFrame("Frame", self:GetName().."_Buffs", self)
	self.Buffs.spacing = 6
	self.Buffs.size = ((230 - 7 * self.Buffs.spacing) / 8)
	--self.Buffs.size = 22
	self.Buffs.disableCooldown = true
	self.Buffs.showType = true
	self.Buffs.onlyShowPlayer = false
	self.Buffs.PreSetPosition = PreSetPosition
	self.Buffs.PostCreateIcon = PostCreateAura
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
end
ns.AddBuffs = AddBuffs

local function AddDebuffs(self, unit)
	self.Debuffs = CreateFrame("Frame", self:GetName().."_Debuffs", self)
	self.Debuffs.spacing = 6
	self.Debuffs.size = (230 - 7 * self.Debuffs.spacing) / 8
	self.Debuffs.showType = true
	self.Debuffs.disableCooldown = true
	self.Debuffs.onlyShowPlayer = false
	self.Debuffs.PreSetPosition = PreSetPosition
	self.Debuffs.PostCreateIcon = PostCreateAura
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
end
ns.AddDebuffs = AddDebuffs