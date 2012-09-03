--[[========================================================================
	DESCRIPTION:
	Contrains the pre and post update and some helper functions for oUF_Rain
	========================================================================--]]

local _, ns = ...
local playerClass = ns.playerClass
local UnitIsFriend = UnitIsFriend

local prioTable = {}
--[[
if (ns.cfg.buffTable[playerClass]) then
	for k, v in pairs(ns.cfg.buffTable[playerClass]) do
		prioTable[k] = v
	end
end

if (ns.cfg.debuffTable[playerClass]) then
	for k, v in pairs(ns.cfg.debuffTable[playerClass]) do
		prioTable[k] = v
	end
end
--]]
--[[ HELPER FUNCTIONS ]]--

local SiValue = function(val)
	if (val >= 1e6) then
		return ("%.1fm"):format(val / 1e6)--:gsub('%.', 'm')
	elseif (val >= 1e4) then
		return ("%.1fk"):format(val / 1e3)--:gsub('%.', 'k')
	else
		return val
	end
end
ns.SiValue = SiValue

local ShortenName = function(name, shortenTo)
	if (not name) then return end
	if (not shortenTo) then
		shortenTo = 12
	end
	name = (string.len(name) > shortenTo) and string.gsub(name, "%s?(.[\128-\191]*)%S+%s", "%1. ") or name
	
	local bytes = string.len(name)
	if (bytes <= shortenTo) then
		return name
	else
		local length, currentIndex = 0, 1

		while (currentIndex <= bytes) do
			length = length + 1
			local char = string.byte(name, currentIndex)
			if (char > 240) then
				currentIndex = currentIndex + 4
			elseif (char > 225) then
				currentIndex = currentIndex + 3
			elseif (char > 192) then
				currentIndex = currentIndex + 2
			else
				currentIndex = currentIndex + 1
			end

			if (length == shortenTo) then
				break
			end
		end

		if (length == shortenTo and currentIndex <= bytes) then
			return string.sub(name, 1, currentIndex - 1) .. "..."
		else
			return name
		end
	end
end
ns.ShortenName = ShortenName

local RGBtoHEX = function(r, g, b)
	return string.format("|cff%02x%02x%02x", r * 255, g * 255, b * 255)
end
ns.RGBtoHEX = RGBtoHEX

local FormatTime = function(seconds)
	local day, hour, minute = 86400, 3600, 60
	if (seconds >= day) then
		return format("%dd", floor(seconds/day + 0.5)), seconds % day
	elseif (seconds >= hour) then
		return format("%dh", floor(seconds/hour + 0.5)), seconds % hour
	elseif (seconds >= minute) then
		if (seconds <= minute * 5) then
			return format("%d:%02d", floor(seconds/60), seconds % minute), seconds - floor(seconds)
		end
		return format("%dm", floor(seconds/minute + 0.5)), seconds % minute
	elseif (seconds >= minute / 12) then
		return floor(seconds + 0.5), (seconds * 100 - floor(seconds * 100)) / 100
	end
	return format("%.1f", seconds), (seconds * 100 - floor(seconds * 100)) / 100
end

local PutFontString = function(parent, fontName, fontHeight, fontStyle, justifyH)
	local fontString = parent:CreateFontString(nil, "OVERLAY")
	fontString:SetFont(fontName, fontHeight, fontStyle)
	fontString:SetJustifyH(justifyH or "LEFT")
	fontString:SetShadowColor(0, 0, 0)
	fontString:SetShadowOffset(0.75, -0.75)
	
	return fontString
end
ns.PutFontString = PutFontString

local CustomCastTimeText = function(Castbar, duration)
	Castbar.Time:SetText(("%.1f / %.2f"):format(Castbar.channeling and duration or Castbar.max - duration, Castbar.max))
end
ns.CustomCastTimeText = CustomCastTimeText

local CustomCastDelayText = function(Castbar, duration)
	Castbar.Time:SetText(("%.1f |cffaf5050%s %.1f|r"):format(Castbar.channeling and duration or Castbar.max - duration, Castbar.channeling and "- " or "+", Castbar.delay))
end
ns.CustomCastDelayText = CustomCastDelayText

local CustomPlayerFilter = function()
	return true
end

local CustomFilter = function(Auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	if (caster == "pet") then
		aura.isPlayer = true
	end

	if (not UnitIsFriend("player", unit)) then
		if (aura.isDebuff) then
			--if(aura.isPlayer or ns.debuffIDs[spellID]) then
			if(aura.isPlayer) then
				return true
			end
		else
			return true
		end
	else
		if (aura.isDebuff) then
			return true
		else
			return (Auras.onlyShowPlayer and Auras.isPlayer) or (not Auras.onlyShowPlayer and name)
		end
	end
end

local CustomPartyFilter = function(Auras, unit, aura, name, _, _, _, _, _, _, caster)
	if (prioTable[name]) then
		if ((prioTable[name] == 1 and caster == "player") or prioTable[name] == 2) then
			return true
		end
	end
end

local CreateAuraTimer = function(aura, elapsed)
	if (aura.timeLeft) then
		aura.elapsed = (aura.elapsed or 0) + elapsed
		if (aura.elapsed >= 0.1) then
			if (not aura.first) then
				aura.timeLeft = aura.timeLeft - aura.elapsed
			else
				aura.timeLeft = aura.timeLeft - GetTime()
				aura.first = false
			end
			if (aura.timeLeft > 0) then
				local time = FormatTime(aura.timeLeft)
					aura.remaining:SetText(time)
				if (aura.timeLeft < 5) then
					aura.remaining:SetTextColor(0.69, 0.31, 0.31)
				else
					aura.remaining:SetTextColor(0.84, 0.75, 0.65)
				end
			else
				aura.remaining:Hide()
				aura:SetScript("OnUpdate", nil)
			end
			aura.elapsed = 0
		end
	end
end

local SortAuras = function(a, b)
	if (a and b and a.timeLeft and b.timeLeft) then
		return a.timeLeft > b.timeLeft
	end
end

local UpdateAuraTooltip = function(button)
	GameTooltip:SetUnitAura(button:GetParent().__owner.unit, button:GetID(), button.filter)
end

local AuraOnEnter = function(button)
	if(not button:IsVisible()) then return end

	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
	button:UpdateTooltip()

	local r, g, b = button.overlay:GetVertexColor()
	local iconW, iconH = button:GetSize()
	local magnify = button:GetParent().Magnify
	
	magnify:SetSize(iconW * 2, iconH * 2)
	magnify:SetPoint("CENTER", button, "CENTER")
	
	magnify.icon:SetSize(iconW * 2, iconH * 2)
	magnify.icon:SetTexture(button.icon:GetTexture())
	magnify.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	magnify.border:SetVertexColor(r, g, b)

	magnify:Show()
	
	button:GetParent().Magnify = magnify
end

local AuraOnLeave = function(button)
	GameTooltip:Hide()
	button:GetParent().Magnify:Hide()
end

--[[PRE AND POST FUNCTIONS]]--

local PostUpdateCast = function(castbar, unit, name)
	if (castbar.interrupt and UnitCanAttack("player", unit)) then
		castbar:SetStatusBarColor(0.69, 0.31, 0.31)
		castbar.IconOverlay:SetVertexColor(0.69, 0.31, 0.31)
	elseif (ns.interruptSpellNames[name]) then
		castbar:SetStatusBarColor(0, 0, 1)
		castbar.IconOverlay:SetVertexColor(0, 0, 1)
	else
		castbar:SetStatusBarColor(0.55, 0.57, 0.61)
		castbar.IconOverlay:SetVertexColor(0.4, 0.4, 0.4)
	end
end
ns.PostUpdateCast = PostUpdateCast

local PostUpdateHealth = function(health, unit, cur, max)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		local _, class = UnitClass(unit)
		local color = UnitIsPlayer(unit) and ns.colors.class[class] or {0.84, 0.75, 0.65}

		health:SetValue(0)
		health.bg:SetVertexColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5)
		health.value:SetTextColor(0.75, 0.75, 0.75)
	elseif (UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit)) then
		health:SetStatusBarColor(unpack(ns.colors.tapped))
		health.bg:SetVertexColor(0.15, 0.15, 0,15)
	else
		local r, g, b
		r, g, b = oUF.ColorGradient(cur, max, 0.69, 0.31, 0.31, 0.71, 0.43, 0.27, 0.17, 0.17, 0.24)

		health:SetStatusBarColor(r, g, b)
		health.bg:SetVertexColor(0.15, 0.15, 0.15)
		
		r, g, b = oUF.ColorGradient(cur, max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)
		if (cur ~= max) then
			health.value:SetTextColor(r, g, b)
		else
			health.value:SetTextColor(r, g, b)
		end
	end
end
ns.PostUpdateHealth = PostUpdateHealth

local PostUpdatePower = function(Power, unit, cur, max)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
		Power:SetValue(0)
	end
	
	if (unit == "target") then
		local self = Power.__owner
		if (self.Info) then
			self.Info:ClearAllPoints()
			if (Power.value:GetText()) then
				self.Info:SetPoint("LEFT", self.Power.value, "RIGHT", 5, 0)
				self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
				self.Info:SetJustifyH("CENTER")
			else
				self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
				self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
				self.Info:SetJustifyH("LEFT")
			end
		end
	end
end
ns.PostUpdatePower = PostUpdatePower

local CreateAuraIcon = function(Auras, index)
	Auras.createdIcons = Auras.createdIcons + 1 -- need to do this

	local button = CreateFrame("Button", nil, Auras)

	button.icon = button:CreateTexture(nil, "BORDER")
	button.icon:SetAllPoints(button)
	button.icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

	button.count = PutFontString(button, ns.media.FONT, 8, "OUTLINE", "RIGHT")
	button.count:SetPoint("BOTTOMRIGHT", 1, 1.5)
	button.count:SetTextColor(0.84, 0.75, 0.65)
	-- aura border
	button.overlay = button:CreateTexture(nil, "OVERLAY")
	button.overlay:SetTexture(ns.media.BTNTEXTURE)
	button.overlay:SetPoint("TOPLEFT", -4.5, 4.5)
	button.overlay:SetPoint("BOTTOMRIGHT", 4.5, -4.5)
	button.overlay:SetTexCoord(0, 1, 0, 1)

	button.stealable = button:CreateTexture(nil, "OVERLAY", nil, 1)
	button.stealable:SetTexture(ns.media.STEALABLETEX)
	button.stealable:SetPoint("TOPLEFT", -4.5, 4.5)
	button.stealable:SetPoint("BOTTOMRIGHT", 4.5, -4.5)
	button.stealable:SetTexCoord(0, 1, 0, 1)
	button.stealable:SetBlendMode("DISABLE")
	button.stealable:SetVertexColor(unpack(oUF.colors.class[playerClass]))
	-- timer text
	button.remaining = PutFontString(button, ns.media.FONT, 8, "OUTLINE", "LEFT")
	button.remaining:SetPoint("TOP", 0, 1)

	button.UpdateTooltip = UpdateAuraTooltip
	button:SetScript("OnEnter", AuraOnEnter)
	button:SetScript("OnLeave", AuraOnLeave)

	table.insert(Auras, button)

	return button
end

local PreSetPosition = function(Auras)
	table.sort(Auras, SortAuras)
	return 1, Auras.createdIcons
end

local PostUpdateIcon = function(Auras, unit, aura, index, offset)
	local _, _, _, _, _, duration, expirationTime, caster = UnitAura(unit, index, aura.filter)

	if (caster == "pet") then
		aura.isPlayer = true
	end

	if (not aura.isPlayer) then
		local friend = UnitIsFriend("player", unit)
		if ((not friend and aura.isDebuff)
				or (friend and not aura.isDebuff)) then
			aura.icon:SetDesaturated(true)
			aura.overlay:SetVertexColor(0.5, 0.5, 0.5)
		end
	end

	if (duration and duration > 0) then
		aura.remaining:Show()
		aura.timeLeft = expirationTime
		aura:SetScript("OnUpdate", CreateAuraTimer)
	else
		aura.remaining:Hide()
		aura.timeLeft = math.huge
		aura:SetScript("OnUpdate", nil)
	end

	aura.first = true
end

local totemPriorities = playerClass == "SHAMAN" and SHAMAN_TOTEM_PRIORITIES or STANDARD_TOTEM_PRIORITIES

local UpdateTotem = function(self, event, slot)
	local total = 0
	local totem = self.Totems[totemPriorities[slot]]
	local haveTotem, name, start, duration, icon = GetTotemInfo(slot)
	
	if (duration > 0) then
		totem:SetValue(1 - (GetTime() - start) / duration)
		totem:SetScript("OnUpdate", function(self, elapsed)
			total = total + elapsed
			if (total >= 0.9) then
				total = 0
				self:SetValue(1 - (GetTime() - start) / duration)
			end
		end)
		totem:Show()
	else
		totem:Hide()
	end
end
ns.UpdateTotem = UpdateTotem

local PostUpdateClassBar = function(classBar, unit)
	if (UnitHasVehicleUI("player")) then
		classBar:Hide()
	else
		classBar:Show()
	end
end
ns.PostUpdateClassBar = PostUpdateClassBar

-- temp fix for monks chi because the current implementation of HarmonyBar does not check for talent Ascension
local PostUpdateChi = function(element, chi, maxChi, maxChiChanged)
	if (not maxChiChanged) then return end

	local self = element.__owner
	local width = element.width
	local height = element.height
	local spacing = element.spacing

	for i = 1, maxChi do
		element[i]:SetSize((width - maxChi * spacing - spacing) / maxChi, height)
		element[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * element[i]:GetWidth() + i * spacing, 1)
	end
end
ns.PostUpdateChi = PostUpdateChi

local WarlockPowerPostUpdateVisibility = function(element, spec, power, maxPower)
	local self = element.__owner
	local width = element.width
	local height = element.height
	local spacing = element.spacing

	if spec then
		if spec == 1 or spec == 3 then -- Affliction or Destruction
			for i = 1, maxPower do
				element[i]:SetSize((width - maxPower * spacing - spacing) / maxPower, height)
				element[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * element[i]:GetWidth() + i * spacing, 1)
			end
		else -- Demonology
			element[1]:SetSize(width - 2 * spacing, height)
			element[1]:SetPoint("BOTTOMLEFT", self.Overlay, spacing, 1)
			--element[1]:SetPoint("BOTTOMRIGHT", self.Overlay, -spacing, 1) -- we have to use SetSize lol?
		end
	end
end
ns.WarlockPowerPostUpdateVisibility = WarlockPowerPostUpdateVisibility
--[[END OF PRE AND POST FUNCTIONS]]--

local AddAuras = function(self, unit)
	if (not next(prioTable)) then return end

	self.Auras = CreateFrame("Frame", self:GetName().."_Auras", self)
	if (ns.cfg.horizParty) then
		self.Auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 9)
		self.Auras.initialAnchor = "LEFT"
		self.Auras["growth-x"] = "RIGHT"
		self.Auras["growth-y"] = "UP"
	else
		self.Auras:SetPoint("RIGHT", self, "LEFT", -9, 0)
		self.Auras.initialAnchor = "RIGHT"
		self.Auras["growth-x"] = "LEFT"
		self.Auras["growth-y"] = "DOWN"
	end
	self.Auras.numBuffs = 3
	self.Auras.numDebuffs = 3
	self.Auras.spacing = 6
	self.Auras.size = (230 - 9 * self.Auras.spacing) / 10
	self.Auras:SetSize(12 * (self.Auras.size + self.Auras.spacing), self.Auras.size + self.Auras.spacing)
	self.Auras.disableCooldown = true
	self.Auras.showType = true
	self.Auras.onlyShowPlayer = false
	self.Auras.CreateIcon = CreateAuraIcon
	self.Auras.PreSetPosition = PreSetPosition
	self.Auras.PostUpdateIcon = PostUpdateIcon
	self.Auras.CustomFilter = CustomPartyFilter

	self.Auras.Magnify = CreateFrame("Frame", nil, self)
	self.Auras.Magnify:SetFrameLevel(self.Auras:GetFrameLevel() + 2)

	self.Auras.Magnify.icon = self.Auras.Magnify:CreateTexture(nil, "ARTWORK")
	self.Auras.Magnify.icon:SetPoint("CENTER")

	self.Auras.Magnify.border = self.Auras.Magnify:CreateTexture(nil, "OVERLAY")
	self.Auras.Magnify.border:SetTexture(ns.media.BTNTEXTURE)
	self.Auras.Magnify.border:SetPoint("TOPLEFT", self.Auras.Magnify.icon, -5, 5)
	self.Auras.Magnify.border:SetPoint("BOTTOMRIGHT", self.Auras.Magnify.icon, 5, -5)
end
ns.AddAuras = AddAuras

local AddBuffs = function(self, unit)
	self.Buffs = CreateFrame("Frame", self:GetName().."_Buffs", self)
	self.Buffs.spacing = 6
	self.Buffs.size = (230 - 7 * self.Buffs.spacing) / 8
	self.Buffs.disableCooldown = true
	self.Buffs.showType = true
	self.Buffs.onlyShowPlayer = ns.cfg.onlyShowPlayerBuffs
	self.Buffs.showStealableBuffs = true
	self.Buffs.CreateIcon = CreateAuraIcon
	self.Buffs.PreSetPosition = PreSetPosition
	self.Buffs.PostUpdateIcon = PostUpdateIcon
	
	if (unit == "player" or unit == "target") then
		self.Buffs:SetSize(8 * (self.Buffs.size + self.Buffs.spacing), 4 * (self.Buffs.size + self.Buffs.spacing))
		self.Buffs["growth-y"] = "DOWN"
		self.Buffs.CustomFilter = CustomFilter
		
		if (unit == "player") then
			self.Buffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -9, 1)
			self.Buffs.initialAnchor = "TOPRIGHT"
			self.Buffs["growth-x"] = "LEFT"
		else
			self.Buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 9, 1)
			self.Buffs.initialAnchor = "TOPLEFT"
			self.Buffs["growth-x"] = "RIGHT"
		end
	end
	
	if (unit == "pet") then
		self.Buffs:SetPoint("RIGHT", self.Debuffs, "LEFT", -5, 0)
		self.Buffs.num = 6
		self.Buffs:SetSize(self.Buffs.num * (self.Buffs.size + self.Buffs.spacing), self.Buffs.size + self.Buffs.spacing)
		self.Buffs.initialAnchor = "RIGHT"
		self.Buffs["growth-x"] = "LEFT"
	end
	
	if (unit:match("^boss%d$")) then
		self.Buffs:SetPoint("RIGHT", self, "LEFT", -15, 0)
		self.Buffs.num = 6
		self.Buffs:SetSize(self.Buffs.num * (self.Buffs.size + self.Buffs.spacing), self.Buffs.size + self.Buffs.spacing)
		self.Buffs.initialAnchor = "RIGHT"
		self.Buffs["growth-x"] = "LEFT"
	end
	
	self.Buffs.Magnify = CreateFrame("Frame", nil, self)
	self.Buffs.Magnify:SetFrameLevel(self.Buffs:GetFrameLevel() + 2)
	
	self.Buffs.Magnify.icon = self.Buffs.Magnify:CreateTexture(nil, "ARTWORK")
	self.Buffs.Magnify.icon:SetPoint("CENTER")
	
	self.Buffs.Magnify.border = self.Buffs.Magnify:CreateTexture(nil, "OVERLAY")
	self.Buffs.Magnify.border:SetTexture(ns.media.BTNTEXTURE)
	self.Buffs.Magnify.border:SetPoint("TOPLEFT", self.Buffs.Magnify.icon, -5, 5)
	self.Buffs.Magnify.border:SetPoint("BOTTOMRIGHT", self.Buffs.Magnify.icon, 5, -5)
end
ns.AddBuffs = AddBuffs

local AddDebuffs = function(self, unit)
	self.Debuffs = CreateFrame("Frame", self:GetName().."_Debuffs", self)
	self.Debuffs.spacing = 6
	self.Debuffs.size = (230 - 7 * self.Debuffs.spacing) / 8
	self.Debuffs.showType = true
	self.Debuffs.disableCooldown = true
	self.Debuffs.onlyShowPlayer = ns.cfg.onlyShowPlayerDebuffs
	self.Debuffs.CreateIcon = CreateAuraIcon
	self.Debuffs.PreSetPosition = PreSetPosition
	self.Debuffs.PostUpdateIcon = PostUpdateIcon
	
	if (unit == "player" or unit == "target") then
		self.Debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -7.5)
		self.Debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -7.5)
		self.Debuffs:SetHeight(5 * (self.Debuffs.size + self.Debuffs.spacing))
		
		self.Debuffs.initialAnchor = "TOPLEFT"
		self.Debuffs["growth-x"] = "RIGHT"
		self.Debuffs["growth-y"] = "DOWN"
		
		if (unit == "target") then
			self.Debuffs.CustomFilter = CustomFilter
		else
			self.Debuffs.CustomFilter = CustomPlayerFilter
		end
	end
	
	if (unit == "pet") then
		self.Debuffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -15, 0)
		self.Debuffs.num = 6
		self.Debuffs:SetSize(self.Debuffs.num * (self.Debuffs.size + self.Debuffs.spacing), self.Debuffs.size + self.Debuffs.spacing)
		
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
	self.Debuffs.Magnify:SetFrameLevel(self.Debuffs:GetFrameLevel() + 2)
	
	self.Debuffs.Magnify.icon = self.Debuffs.Magnify:CreateTexture(nil, "ARTWORK")
	self.Debuffs.Magnify.icon:SetPoint("CENTER")
	
	self.Debuffs.Magnify.border = self.Debuffs.Magnify:CreateTexture(nil, "OVERLAY")
	self.Debuffs.Magnify.border:SetTexture(ns.media.BTNTEXTURE)
	self.Debuffs.Magnify.border:SetPoint("TOPLEFT", self.Debuffs.Magnify.icon, -5, 5)
	self.Debuffs.Magnify.border:SetPoint("BOTTOMRIGHT", self.Debuffs.Magnify.icon, 5, -5)
end
ns.AddDebuffs = AddDebuffs

local AddRangeCheck = function(self, unit)
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}
end
ns.AddRangeCheck = AddRangeCheck

local AddThreatHighlight = function(self, event, unit)
	if (unit ~= self.unit) then return end

	local status = UnitThreatSituation(unit)
	if (status and status > 0) then
		local r, g, b = GetThreatStatusColor(status)
	
		self.FrameBackdrop:SetBackdropBorderColor(r, g, b)
	else
		self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	end
end
ns.AddThreatHighlight = AddThreatHighlight
