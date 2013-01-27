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

local CustomCastDelayText = function(Castbar, duration)
	Castbar.Time:SetText(("%.1f |cffaf5050%s %.1f|r"):format(Castbar.channeling and duration or Castbar.max - duration, Castbar.channeling and "- " or "+", Castbar.delay))
end

local CustomPlayerFilter = function(Auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	if (aura.isDebuff) then
		return true
	else
		if (duration <= 300 and duration > 0) then
			return true
		end
	end
end

local CustomFilter = function(Auras, unit, aura, name, rank, texture, count, dtype, duration, timeLeft, caster, canStealOrPurge, shouldConsolidate, spellID, canApplyAura, isBossDebuff)
	if (caster == "pet") then
		aura.isPlayer = true
	end

	if (not UnitIsFriend("player", unit)) then
		if (aura.isDebuff) then
			if(aura.isPlayer or ns.DebuffIDs[spellID]) then
				return true
			end
		else
			return true
		end
	else
		if (aura.isDebuff) then
			return true
		else
			return (Auras.onlyShowPlayer and aura.isPlayer) or (not Auras.onlyShowPlayer and name)
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
		if (a:IsShown() and b:IsShown()) then
			return a.timeLeft > b.timeLeft
		elseif (a:IsShown()) then
			return true
		end
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

--[[ END OF HELPER FUNCTIONS ]]--

--[[ PRE AND POST FUNCTIONS ]]--

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
-- TODO: not used?
local PostUpdateClassBar = function(classBar, unit)
	if (UnitHasVehicleUI("player")) then
		classBar:Hide()
	else
		classBar:Show()
	end
end

local PostUpdateClassPowerIcons = function(element, power, maxPower, maxPowerChanged)
	if (not maxPowerChanged) then return end

	local self = element.__owner
	local width = element.width
	local height = element.height
	local spacing = element.spacing

	for i = 1, maxPower do
		element[i]:SetSize((width - maxPower * spacing - spacing) / maxPower, height)
		element[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * element[i]:GetWidth() + i * spacing, 1)
	end
end

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
--[[ END OF PRE AND POST FUNCTIONS ]]--

--[[ LAYOUT FUNCTIONS ]]--
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

local AddAltPowerBar = function(self)
	self.AltPowerBar = CreateFrame("StatusBar", "oUF_Rain_AltPowerBar", self)
	self.AltPowerBar:SetHeight(3)
	self.AltPowerBar:SetPoint("TOPLEFT", "oUF_Rain_Player_Overlay", 0, 0)
	self.AltPowerBar:SetPoint("TOPRIGHT", "oUF_Rain_Player_Overlay", 0, 0)
	self.AltPowerBar:SetToplevel(true)
	self.AltPowerBar:SetStatusBarTexture(ns.media.TEXTURE)
	self.AltPowerBar:SetStatusBarColor(0, 0.5, 1)
	self.AltPowerBar:SetBackdrop(ns.media.BACKDROP)
	self.AltPowerBar:SetBackdropColor(0, 0, 0, 0)

	self.AltPowerBar.Text = PutFontString(self.AltPowerBar, ns.media.FONT2, 8, nil, "CENTER")
	self.AltPowerBar.Text:SetPoint("CENTER", self.AltPowerBar, 0, 0)
	self:Tag(self.AltPowerBar.Text, "[rain:altpower]")

	self.AltPowerBar.OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
		self:UpdateTooltip()
	end

	self.AltPowerBar:EnableMouse()
	self.AltPowerBar:SetScript("OnEnter", self.AltPowerBar.OnEnter)
end
ns.AddAltPowerBar = AddAltPowerBar

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

		if (unit == "player") then
			self.Buffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -9, 1)
			self.Buffs.initialAnchor = "TOPRIGHT"
			self.Buffs["growth-x"] = "LEFT"
			self.Buffs.CustomFilter = CustomPlayerFilter
		else
			self.Buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 9, 1)
			self.Buffs.initialAnchor = "TOPLEFT"
			self.Buffs["growth-x"] = "RIGHT"
			self.Buffs.CustomFilter = CustomFilter
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

local AddCastbar = function(self, unit)
	self.Castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", (unit == "player" or unit == "target") and self.Portrait or self.Power)
	self.Castbar:SetStatusBarTexture(ns.media.TEXTURE)
	self.Castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	self.Castbar:SetAlpha(0.75)

	if (unit == "player" or unit == "target") then
		self.Castbar:SetAllPoints(self.Overlay)

		self.Castbar.Time = PutFontString(self.Castbar, ns.media.FONT2, 12, nil, "RIGHT")
		self.Castbar.Time:SetPoint("RIGHT", -3.5, 3)
		self.Castbar.Time:SetTextColor(0.84, 0.75, 0.65)

		self.Castbar.CustomTimeText = CustomCastTimeText
		self.Castbar.CustomDelayText = CustomCastDelayText

		self.Castbar.Text = PutFontString(self.Castbar, ns.media.FONT2, 12, nil, "LEFT")
		self.Castbar.Text:SetPoint("LEFT", 3.5, 3)
		self.Castbar.Text:SetPoint("RIGHT", self.Castbar.Time, "LEFT", -3.5, 0)
		self.Castbar.Text:SetTextColor(0.84, 0.75, 0.65)
	else
		self.Castbar:SetAllPoints(self.Power)
	end

	if (unit == "player") then
		self.Castbar.SafeZone = self.Castbar:CreateTexture(nil, "ARTWORK")
		self.Castbar.SafeZone:SetTexture(ns.media.TEXTURE)
		self.Castbar.SafeZone:SetVertexColor(0.69, 0.31, 0.31, 0.75)
	end

	if (unit == "target" or unit:match("^boss%d$") or unit == "focus") then
		self.Castbar.Icon = self.Castbar:CreateTexture(nil, "ARTWORK")

		self.Castbar.IconOverlay = self.Castbar:CreateTexture(nil, "OVERLAY")
		self.Castbar.IconOverlay:SetTexture(ns.media.BTNTEXTURE)
		self.Castbar.IconOverlay:SetVertexColor(0.84, 0.75, 0.65)

		if (unit == "target") then
			self.Castbar.Icon:SetPoint("RIGHT", self.Castbar, "LEFT", -15, 0)
			self.Castbar.Icon:SetSize(32, 32)
			self.Castbar.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, -5, 5)
			self.Castbar.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, 5, -5)
		else
			self.Castbar.Icon:SetSize(22, 22)
			self.Castbar.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, -3, 3)
			self.Castbar.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, 3, -3)
			if (unit == "focus") then
				self.Castbar.Icon:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 7.5, 0)
			else
				self.Castbar.Icon:SetPoint("LEFT", self, "RIGHT", 7.5, 0)
			end
		end
		self.Castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		self.Castbar.PostCastStart = PostUpdateCast
		self.Castbar.PostChannelStart = PostUpdateCast
		self.Castbar.PostCastInterruptible = PostUpdateCast
		self.Castbar.PostCastNotInterruptible = PostUpdateCast
	end
end
ns.AddCastbar = AddCastbar

local AddClassPowerIcons = function(self, width, height, spacing)
	self.ClassIcons = {}

	self.ClassIcons.width  = width
	self.ClassIcons.height = height
	self.ClassIcons.spacing = spacing

	local maxPower = 5

	for i = 1, maxPower do
		self.ClassIcons[i] = self.Overlay:CreateTexture("oUF_Rain_ComboPoint_"..i, "OVERLAY")
		self.ClassIcons[i]:SetTexture(ns.media.TEXTURE)
	end

	self.ClassIcons.PostUpdate = PostUpdateClassPowerIcons
end
ns.AddClassPowerIcons = AddClassPowerIcons

local AddCombatFeedbackText = function(self)
	if (not IsAddOnLoaded("oUF_CombatFeedback")) then return end

	self.CombatFeedbackText = PutFontString(self.Overlay, ns.media.FONT, 14, "OUTLINE", "LEFT")
	self.CombatFeedbackText:SetPoint("CENTER", 0, 5)
	self.CombatFeedbackText.colors = ns.combatFeedbackColors
end
ns.AddCombatFeedbackText = AddCombatFeedbackText

local AddComboPointsBar = function(self, width, height, spacing)
	self.CPoints = {}
	local maxCPoints = MAX_COMBO_POINTS

	for i = 1, maxCPoints do
		self.CPoints[i] = self.Overlay:CreateTexture("oUF_Rain_ComboPoint_"..i, "OVERLAY")
		self.CPoints[i]:SetSize((width - maxCPoints * spacing - spacing) / maxCPoints, height)
		self.CPoints[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * self.CPoints[i]:GetWidth() + i * spacing, 1)
		self.CPoints[i]:SetTexture(unpack(ns.colors.cpoints[i]))
	end
end
ns.AddComboPointsBar = AddComboPointsBar

local AddDebuffHighlight = function(self, unit)
	self.DebuffHighlight = CreateFrame("Frame", self:GetName().."_DebuffHighlight", self.Health)
	self.DebuffHighlight:SetAllPoints()
	self.DebuffHighlight:SetFrameLevel(self.DebuffHighlight:GetParent():GetFrameLevel() + 1)

	self.DebuffHighlightFilter = ns.cfg.dispelTypeFilter

	self.DebuffHighlightTexture = self.DebuffHighlight:CreateTexture(nil, "OVERLAY")
	self.DebuffHighlightTexture:SetAllPoints()
	self.DebuffHighlightTexture:SetTexture(ns.media.HIGHLIGHTTEXTURE)
	self.DebuffHighlightTexture:SetBlendMode("ADD")
	self.DebuffHighlightTexture:SetVertexColor(0, 0, 0, 0)

	if (unit == "player" or unit == "target") then
		self.DebuffHighlightIcon = self.Overlay:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIcon:SetSize(18, 18)

		self.DebuffHighlightIconOverlay = self.Overlay:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIconOverlay:SetPoint("TOPLEFT", self.DebuffHighlightIcon, -3.5, 3.5)
		self.DebuffHighlightIconOverlay:SetPoint("BOTTOMRIGHT", self.DebuffHighlightIcon, 3.5, -3.5)
	else
		self.DebuffHighlightIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIcon:SetSize(16, 16)

		self.DebuffHighlightIconOverlay = self.DebuffHighlight:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIconOverlay:SetPoint("TOPLEFT", self.DebuffHighlightIcon, -1, 1)
		self.DebuffHighlightIconOverlay:SetPoint("BOTTOMRIGHT", self.DebuffHighlightIcon, 1, -1)
	end
	self.DebuffHighlightIcon:SetPoint("CENTER")
	self.DebuffHighlightIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	self.DebuffHighlightIconOverlay:SetTexture(ns.media.BTNTEXTURE)
	self.DebuffHighlightIconOverlay:SetVertexColor(0, 0, 0, 0)
end
ns.AddDebuffHighlight = AddDebuffHighlight

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

		if (unit == "player") then
			self.Debuffs.CustomFilter = CustomPlayerFilter
		else
			self.Debuffs.CustomFilter = CustomFilter
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

local AddEclipseBar = function(self, width, height)
	local eclipseBar = CreateFrame("Frame", "oUF_Rain_EclipseBar", self.Overlay)
	eclipseBar:SetHeight(5)
	eclipseBar:SetPoint("BOTTOMLEFT", self.Overlay, 1, 1)
	eclipseBar:SetPoint("BOTTOMRIGHT", self.Overlay, -1, 1)
	eclipseBar:SetBackdrop(ns.media.BACKDROP)
	eclipseBar:SetBackdropColor(0, 0, 0)

	local lunarBar = CreateFrame("StatusBar", "oUF_Rain_LunarBar", eclipseBar)
	lunarBar:SetAllPoints(eclipseBar)
	lunarBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	lunarBar:SetStatusBarTexture(ns.media.TEXTURE)
	lunarBar:SetStatusBarColor(0.34, 0.1, 0.86)
	eclipseBar.LunarBar = lunarBar

	local solarBar = CreateFrame("StatusBar", "oUF_Rain_SolarBar", eclipseBar)
	solarBar:SetHeight(5)
	solarBar:SetWidth(213)
	solarBar:SetPoint("LEFT", lunarBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	solarBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	solarBar:SetStatusBarTexture(ns.media.TEXTURE)
	solarBar:SetStatusBarColor(0.95, 0.73, 0.15)
	eclipseBar.SolarBar = solarBar

	local eclipseBarText = PutFontString(solarBar, ns.media.FONT2, 10, "OUTLINE", "CENTER")
	eclipseBarText:SetPoint("CENTER", eclipseBar, 0, 0)
	self:Tag(eclipseBarText, "[pereclipse]%")

	self.EclipseBar = eclipseBar
end
ns.AddEclipseBar = AddEclipseBar

local AddExperienceBar = function(self)
	self.Experience = CreateFrame("StatusBar", "oUF_Rain_Experience", self)
	self.Experience:SetHeight(5)
	self.Experience:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 2.5)
	self.Experience:SetPoint("BOTTOMRIGHT", self.Health, "TOP", -2, 2.5)
	self.Experience:SetStatusBarTexture(ns.media.TEXTURE)
	self.Experience:SetStatusBarColor(0.67, 0.51, 1)
	self.Experience:SetBackdrop(ns.media.BACKDROP)
	self.Experience:SetBackdropColor(0, 0, 0)
	self.Experience:SetAlpha(0)

	self.Experience:EnableMouse()
	self.Experience:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
	self.Experience:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

	self.Experience.Rested = CreateFrame("StatusBar", "oUF_Rain_Experience_Rested", self.Experience)
	self.Experience.Rested:SetPoint("TOPLEFT", self.Experience:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Experience.Rested:SetPoint("BOTTOMRIGHT", self.Experience, 0, 0)
	self.Experience.Rested:SetStatusBarTexture(ns.media.TEXTURE)
	self.Experience.Rested:SetStatusBarColor(0, 0.56, 1)
	self.Experience.Rested:SetBackdrop(ns.media.BACKDROP)
	self.Experience.Rested:SetBackdropColor(0, 0, 0)

	self.Experience.Tooltip = function(self)
		local curXP, maxXP = UnitXP("player"), UnitXPMax("player")
		local bars = 20
		local rested = GetXPExhaustion()
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
		GameTooltip:AddLine(string.format("XP: %d / %d (%d%% - %.1f bars)", curXP, maxXP, curXP/maxXP * 100 + 0.5, bars * curXP / maxXP))
		GameTooltip:AddLine(string.format("Remaining: %d (%d%% - %.1f bars)", maxXP - curXP, (maxXP - curXP) / maxXP * 100 + 0.5, bars * (maxXP - curXP) / maxXP))
		if (rested and rested > 0) then
			GameTooltip:AddLine(string.format("|cff0090ffRested: +%d (%d%%)", rested, rested / maxXP * 100 + 0.5))
		end
		GameTooltip:Show()
	end

	self.Experience:HookScript("OnLeave", GameTooltip_Hide)
	self.Experience:HookScript("OnEnter", self.Experience.Tooltip)
end
ns.AddExperienceBar = AddExperienceBar

local AddFocusHelper = function(self)
	self.FocusSpark = self.Power:CreateTexture(nil, "OVERLAY")
	self.FocusSpark:SetWidth(10)
	self.FocusSpark:SetHeight(self.Power:GetHeight() * 1.85)

	self.FocusSpark.bmSpell = ns.cfg.bmSpell -- Kill Command
	self.FocusSpark.mmSpell = ns.cfg.mmSpell -- Chimera Shot
	self.FocusSpark.svSpell = ns.cfg.svSpell -- Explosive Shot

	self.FocusGain = self.Power:CreateTexture(nil, "OVERLAY")
	self.FocusGain:SetHeight(self.Power:GetHeight())
	self.FocusGain:SetTexture(ns.media.TEXTURE)
	self.FocusGain:SetVertexColor(0, 1, 0, 0.3)
end
ns.AddFocusHelper = AddFocusHelper

local AddHealPredictionBar = function(self, unit)
	local mhpb = CreateFrame("StatusBar", self:GetName().."PlayersHealBar", self.Health)
	mhpb:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	mhpb:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	mhpb:SetWidth((unit == "player" or unit == "target") and 230 or 110)
	mhpb:SetStatusBarTexture(ns.media.TEXTURE)
	mhpb:SetStatusBarColor(0, 0.5, 0.5, 0.5)

	local ohpb = CreateFrame("StatusBar", self:GetName().."OthersHealBar", self.Health)
	ohpb:SetPoint("TOPLEFT", mhpb:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	ohpb:SetPoint("BOTTOMLEFT", mhpb:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	ohpb:SetWidth((unit == "player" or unit == "target") and 230 or 110)
	ohpb:SetStatusBarTexture(ns.media.TEXTURE)
	ohpb:SetStatusBarColor(0, 1, 0, 0.5)

	self.HealPrediction = {
		myBar = mhpb,
		otherBar = ohpb,
		maxOverflow = unit == "target" and 1.25 or 1,
	}
end
ns.AddHealPredictionBar = AddHealPredictionBar

local AddOverlay = function(self, unit)
	self.Overlay = CreateFrame("Frame", self:GetName().."_Overlay", self.Portrait)
	self.Overlay:SetPoint("TOPLEFT", self.Portrait, 0, 1)
	self.Overlay:SetPoint("BOTTOMRIGHT", self.Portrait, 0, -1)

	if (unit == "player") then
		self.Threat = self.Overlay:CreateTexture(nil, "BORDER")
		self.Threat:SetAllPoints()
		self.Threat:SetTexture(ns.media.OVERLAY)
		self.Threat:SetVertexColor(0.1, 0.1, 0.1, 0.75)
	else
		self.CCWarn = self.Overlay:CreateTexture(nil, "BORDER")
		self.CCWarn:SetAllPoints()
		self.CCWarn:SetTexture(ns.media.OVERLAY)
		self.CCWarn:SetVertexColor(0.1, 0.1, 0.1, 0.75)
	end
end
ns.AddOverlay = AddOverlay

local AddPortrait = function(self, unit)
	self.Portrait = CreateFrame("PlayerModel", self:GetName().."_Portrait", self)
	self.Portrait:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 7.5, 10)
	self.Portrait:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -7.5, -7.5)
	self.Portrait:SetFrameLevel(self:GetFrameLevel() + 3)
	self.Portrait:SetBackdrop(ns.media.BACKDROP)
	self.Portrait:SetBackdropColor(0, 0, 0, 1)
end
ns.AddPortrait = AddPortrait

local AddRangeCheck = function(self, unit)
	self.Range = {
		insideAlpha = 1,
		outsideAlpha = 0.5,
	}
end
ns.AddRangeCheck = AddRangeCheck

local AddReputationBar = function(self)
	if (not IsAddOnLoaded("oUF_Reputation")) then return end

	self.Reputation = CreateFrame("StatusBar", "oUF_Rain_Reputation", self)
	self.Reputation:SetHeight(5)
	self.Reputation:SetPoint("TOPLEFT", self.Health, "TOP", 2, 7.5)
	self.Reputation:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", 0, 7.5)
	self.Reputation:SetStatusBarTexture(ns.media.TEXTURE)
	self.Reputation:SetBackdrop(ns.media.BACKDROP)
	self.Reputation:SetBackdropColor(0, 0, 0)
	self.Reputation:SetAlpha(0)

	self.Reputation:EnableMouse()
	self.Reputation:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
	self.Reputation:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

	self.Reputation.bg = self.Reputation:CreateTexture(nil, "BORDER")
	self.Reputation.bg:SetAllPoints(self.Reputation)
	self.Reputation.bg:SetTexture(ns.media.TEXTURE)
	self.Reputation.bg:SetVertexColor(0.15, 0.15, 0.15)

	self.Reputation.colorStanding = true

	self.Reputation.Tooltip = function(self)
		local name, standing, min, max, value, id = GetWatchedFactionInfo()
		local _, friendRep, friendMaxRep, _, _, _, friendTextLevel, friendThreshold, nextFriendThreshold = GetFriendshipReputation(id)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
		if (not friendRep) then
			GameTooltip:AddLine(string.format("%s (%s)", name, _G["FACTION_STANDING_LABEL"..standing], UnitSex("player")))
			GameTooltip:AddLine(string.format("%d / %d (%d%%)", value - min, max - min, (value - min) / (max - min) * 100 + 0.5))
		else
			local currentValue = friendRep - friendThreshold
			local maxCurrentValue = math.min(friendMaxRep - friendThreshold, 8400)
			local currentRank, maxRank = GetFriendshipReputationRanks(id)
			GameTooltip:AddLine(string.format("%s (%d / %d - %s)", name, currentRank, maxRank, friendTextLevel))
			GameTooltip:AddLine(string.format("%d / %d (%d%%)", currentValue, maxCurrentValue, currentValue / maxCurrentValue * 100 + 0.5))
		end
		GameTooltip:Show()
	end

	self.Reputation:HookScript("OnLeave", GameTooltip_Hide)
	self.Reputation:HookScript("OnEnter", self.Reputation.Tooltip)
end
ns.AddReputationBar = AddReputationBar

local AddRuneBar = function(self, width, height, spacing)
	self.Runes = {}
	local maxRunes = 6

	for i = 1, maxRunes do
		self.Runes[i] = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self.Overlay)
		self.Runes[i]:SetSize((width - maxRunes * spacing - spacing) / maxRunes, height)
		self.Runes[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * self.Runes[i]:GetWidth() + i * spacing, 1)
		self.Runes[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.Runes[i]:SetBackdrop(ns.media.BACKDROP)
		self.Runes[i]:SetBackdropColor(0, 0, 0)

		self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
		self.Runes[i].bg:SetTexture(ns.media.TEXTURE)
		self.Runes[i].bg:SetAllPoints()
		self.Runes[i].bg.multiplier = 0.5
	end
end
ns.AddRuneBar = AddRuneBar

local AddSwingBar = function(self)
	if (not IsAddOnLoaded("oUF_Swing")) then return end

	self.Swing = CreateFrame("Frame", self:GetName().."_Swing", self)
	self.Swing:SetHeight(3)
	self.Swing:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 7)
	self.Swing:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 7)
	self.Swing.texture = ns.media.TEXTURE
	self.Swing.color = {0.55, 0.57, 0.61, 1}
	self.Swing.textureBG = ns.media.TEXTURE
	self.Swing.colorBG = {0, 0, 0, 0.6}

	self.Swing.hideOoc = true
end
ns.AddSwingBar = AddSwingBar

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

local AddTotems = function(self, width, height)
	self.Totems = {}
	local maxTotems = MAX_TOTEMS

	for i = 1, maxTotems do
		self.Totems[i] = CreateFrame("StatusBar", "oUF_Rain_Totem"..i, self.Overlay)
		self.Totems[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.Totems[i]:SetMinMaxValues(0, 1)

		if (playerClass == "SHAMAN") then
			self.Totems[i]:SetSize((215 - maxTotems - 1) / maxTotems, height)
			self.Totems[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / maxTotems) + 1, 0)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.totems[SHAMAN_TOTEM_PRIORITIES[i]]))
		elseif (playerClass == "DRUID") then -- Druid's mushrooms
			self.Totems[i]:SetSize(width, height)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
				if (i == 1) then
					self.Totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
				elseif (i == 2) then
					self.Totems[i]:SetPoint("RIGHT", self.Totems[1], "LEFT", -1, 0)
				else
					self.Totems[i]:SetPoint("LEFT", self.Totems[1], "RIGHT", 1, 0)
				end
		elseif (playerClass == "DEATHKNIGHT") then -- Death knight's ghoul
			self.Totems[i]:SetSize(width, height)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
			self.Totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
		end

		self.Totems[i]:SetBackdrop(ns.media.BACKDROP)
		self.Totems[i]:SetBackdropColor(0, 0, 0)

		self.Totems[i]:EnableMouse()

		self.Totems[i]:SetScript("OnMouseUp", function(self, button)
			if (button == "RightButton") then
				DestroyTotem(self:GetID())
			end
		end)

		self.Totems[i].UpdateTooltip = function(self)
			GameTooltip:SetTotem(self:GetID())
			GameTooltip:AddLine(GLYPH_SLOT_REMOVE_TOOLTIP, 1, 0, 0)
			GameTooltip:Show()
		end
	end

	self.Totems.Override = UpdateTotem
end
ns.AddTotems = AddTotems

local AddWarlockPowerBar = function(self, width, height, spacing)
	self.WarlockPowerBar = {}
	self.WarlockPowerBar.width = width
	self.WarlockPowerBar.height = height
	self.WarlockPowerBar.spacing = spacing

	for i = 1, 4 do
		self.WarlockPowerBar[i] = CreateFrame("StatusBar", "oUF_Rain_WarlockPowerBar"..i, self.Overlay)
		self.WarlockPowerBar[i]:SetSize((width - 4 * spacing - spacing) / 4, height)
		self.WarlockPowerBar[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * self.WarlockPowerBar[i]:GetWidth() + i * spacing, 1)
		self.WarlockPowerBar[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.WarlockPowerBar[i]:SetBackdrop(ns.media.BACKDROP)
		self.WarlockPowerBar[i]:SetBackdropColor(0, 0, 0)

		self.WarlockPowerBar[i].bg = self.WarlockPowerBar[i]:CreateTexture(nil, "BORDER")
		self.WarlockPowerBar[i].bg:SetTexture(ns.media.TEXTURE)
		self.WarlockPowerBar[i].bg:SetAllPoints()
		self.WarlockPowerBar[i].bg.multiplier = 0.3
	end

	self.WarlockPowerBar.PostUpdateVisibility = WarlockPowerPostUpdateVisibility
end
ns.AddWarlockPowerBar = AddWarlockPowerBar

--[[ ICONS ]]--

local AddAssistantIcon = function(self, unit)
	self.Assistant = self.Health:CreateTexture(nil, "OVERLAY")
	self.Assistant:SetSize(16, 16)
	self.Assistant:SetPoint("TOPLEFT", -8.5, 8.5)
end
ns.AddAssistantIcon = AddAssistantIcon

local AddCombatIcon = function(self)
	self.Combat = self.Health:CreateTexture(nil, "OVERLAY")
	self.Combat:SetSize(20, 20)
	self.Combat:SetPoint("TOP", 0, 1)
end
ns.AddCombatIcon = AddCombatIcon

local AddLeaderIcon = function(self, unit)
	self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
	self.Leader:SetSize(16, 16)
	self.Leader:SetPoint("TOPLEFT", -8.5, 8.5)
end
ns.AddLeaderIcon = AddLeaderIcon

local AddMasterLooterIcon = function(self, unit)
	self.MasterLooter = self.Health:CreateTexture(nil, "OVERLAY")
	self.MasterLooter:SetSize(16, 16)
	self.MasterLooter:SetPoint("TOPRIGHT", 8.5, 8.5)
end
ns.AddMasterLooterIcon = AddMasterLooterIcon

local AddPhaseIcon = function(self, unit)
	self.PhaseIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.PhaseIcon:SetSize(16, 16)
	self.PhaseIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
end
ns.AddPhaseIcon = AddPhaseIcon

local AddQuestIcon = function(self, unit)
	self.QuestIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.QuestIcon:SetSize(16, 16)
	self.QuestIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
end
ns.AddQuestIcon = AddQuestIcon

local AddRaidIcon = function(self, unit)
	self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.RaidIcon:SetTexture(ns.media.RAIDICONS)
	if (unit ~= "player" and unit ~= "target") then
		self.RaidIcon:SetSize(14, 14)
		self.RaidIcon:SetPoint("TOP", 0, 10)
	else
		self.RaidIcon:SetSize(18, 18)
		self.RaidIcon:SetPoint("TOP", 0, 10)
	end
end
ns.AddRaidIcon = AddRaidIcon

local AddRaidRoleIcon = function(self, unit)
	self.RaidRole = self:CreateTexture(nil, "OVERLAY")
	self.RaidRole:SetSize(16, 16)
	self.RaidRole:SetPoint("BOTTOMRIGHT", -8.5, 8.5)
end
ns.AddRaidRoleIcon = AddRaidRoleIcon

-- oUF checks ready status only for raid and party
local AddReadyCheckIcon = function(self, unit)
	self.ReadyCheck = self.Health:CreateTexture(nil, "OVERLAY")
	self.ReadyCheck:SetSize(16, 16)
	self.ReadyCheck:SetPoint("RIGHT", -5, 0)

	self.ReadyCheck.finishedTime = 10
	self.ReadyCheck.fadeTime = 3
end
ns.AddReadyCheckIcon = AddReadyCheckIcon

local AddRestingIcon = function(self)
	self.Resting = self.Power:CreateTexture(nil, "OVERLAY")
	self.Resting:SetSize(16, 16)
	self.Resting:SetPoint("BOTTOMLEFT", -8.5, -8.5)
end
ns.AddRestingIcon = AddRestingIcon

local AddResurrectIcon = function(self, unit)
	self.ResurrectIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.ResurrectIcon:SetSize(16, 16)
	self.ResurrectIcon:SetPoint("CENTER")
end
ns.AddResurrectIcon = AddResurrectIcon
