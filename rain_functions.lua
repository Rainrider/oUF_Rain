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

	local auras = CreateFrame("Frame", self:GetName().."_Auras", self)
	if (ns.cfg.horizParty) then
		auras:SetPoint("BOTTOMLEFT", self, "TOPLEFT", 0, 9)
		auras.initialAnchor = "LEFT"
		auras["growth-x"] = "RIGHT"
		auras["growth-y"] = "UP"
	else
		auras:SetPoint("RIGHT", self, "LEFT", -9, 0)
		auras.initialAnchor = "RIGHT"
		auras["growth-x"] = "LEFT"
		auras["growth-y"] = "DOWN"
	end
	auras.numBuffs = 3
	auras.numDebuffs = 3
	auras.spacing = 6
	auras.size = (230 - 9 * auras.spacing) / 10
	auras:SetSize(12 * (auras.size + auras.spacing), auras.size + auras.spacing)
	auras.disableCooldown = true
	auras.showType = true
	auras.onlyShowPlayer = false
	auras.CreateIcon = CreateAuraIcon
	auras.PreSetPosition = PreSetPosition
	auras.PostUpdateIcon = PostUpdateIcon
	auras.CustomFilter = CustomPartyFilter

	auras.Magnify = CreateFrame("Frame", nil, self)
	auras.Magnify:SetFrameLevel(auras:GetFrameLevel() + 2)

	auras.Magnify.icon = auras.Magnify:CreateTexture(nil, "ARTWORK")
	auras.Magnify.icon:SetPoint("CENTER")

	auras.Magnify.border = auras.Magnify:CreateTexture(nil, "OVERLAY")
	auras.Magnify.border:SetTexture(ns.media.BTNTEXTURE)
	auras.Magnify.border:SetPoint("TOPLEFT", auras.Magnify.icon, -5, 5)
	auras.Magnify.border:SetPoint("BOTTOMRIGHT", auras.Magnify.icon, 5, -5)

	self.Auras = auras
end
ns.AddAuras = AddAuras

local AddAltPowerBar = function(self)
	local altPowerBar = CreateFrame("StatusBar", "oUF_Rain_AltPowerBar", self)
	altPowerBar:SetHeight(3)
	altPowerBar:SetPoint("TOPLEFT", "oUF_Rain_Player_Overlay", 0, 0)
	altPowerBar:SetPoint("TOPRIGHT", "oUF_Rain_Player_Overlay", 0, 0)
	altPowerBar:SetToplevel(true)
	altPowerBar:SetStatusBarTexture(ns.media.TEXTURE)
	altPowerBar:SetStatusBarColor(0, 0.5, 1)
	altPowerBar:SetBackdrop(ns.media.BACKDROP)
	altPowerBar:SetBackdropColor(0, 0, 0, 0)

	altPowerBar.Text = PutFontString(altPowerBar, ns.media.FONT2, 8, nil, "CENTER")
	altPowerBar.Text:SetPoint("CENTER", altPowerBar, 0, 0)
	self:Tag(altPowerBar.Text, "[rain:altpower]")

	altPowerBar.OnEnter = function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
		self:UpdateTooltip()
	end

	altPowerBar:EnableMouse()
	altPowerBar:SetScript("OnEnter", altPowerBar.OnEnter)

	self.AltPowerBar = altPowerBar
end
ns.AddAltPowerBar = AddAltPowerBar

local AddBuffs = function(self, unit)
	local buffs = CreateFrame("Frame", self:GetName().."_Buffs", self)
	buffs.spacing = 6
	buffs.size = (230 - 7 * buffs.spacing) / 8
	buffs.disableCooldown = true
	buffs.showType = true
	buffs.onlyShowPlayer = ns.cfg.onlyShowPlayerBuffs
	buffs.showStealableBuffs = true
	buffs.CreateIcon = CreateAuraIcon
	buffs.PreSetPosition = PreSetPosition
	buffs.PostUpdateIcon = PostUpdateIcon

	if (unit == "player" or unit == "target") then
		buffs:SetSize(8 * (buffs.size + buffs.spacing), 4 * (buffs.size + buffs.spacing))
		buffs["growth-y"] = "DOWN"

		if (unit == "player") then
			buffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -9, 1)
			buffs.initialAnchor = "TOPRIGHT"
			buffs["growth-x"] = "LEFT"
			buffs.CustomFilter = CustomPlayerFilter
		else
			buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 9, 1)
			buffs.initialAnchor = "TOPLEFT"
			buffs["growth-x"] = "RIGHT"
			buffs.CustomFilter = CustomFilter
		end
	end

	if (unit == "pet") then
		buffs:SetPoint("RIGHT", self.Debuffs, "LEFT", -5, 0)
		buffs.num = 6
		buffs:SetSize(buffs.num * (buffs.size + buffs.spacing), buffs.size + buffs.spacing)
		buffs.initialAnchor = "RIGHT"
		buffs["growth-x"] = "LEFT"
	end

	if (unit:match("^boss%d$")) then
		buffs:SetPoint("RIGHT", self, "LEFT", -15, 0)
		buffs.num = 6
		buffs:SetSize(buffs.num * (buffs.size + buffs.spacing), buffs.size + buffs.spacing)
		buffs.initialAnchor = "RIGHT"
		buffs["growth-x"] = "LEFT"
	end

	buffs.Magnify = CreateFrame("Frame", nil, self)
	buffs.Magnify:SetFrameLevel(buffs:GetFrameLevel() + 2)

	buffs.Magnify.icon = buffs.Magnify:CreateTexture(nil, "ARTWORK")
	buffs.Magnify.icon:SetPoint("CENTER")

	buffs.Magnify.border = buffs.Magnify:CreateTexture(nil, "OVERLAY")
	buffs.Magnify.border:SetTexture(ns.media.BTNTEXTURE)
	buffs.Magnify.border:SetPoint("TOPLEFT", buffs.Magnify.icon, -5, 5)
	buffs.Magnify.border:SetPoint("BOTTOMRIGHT", buffs.Magnify.icon, 5, -5)

	self.Buffs = buffs
end
ns.AddBuffs = AddBuffs

local AddCastbar = function(self, unit)
	local castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", (unit == "player" or unit == "target") and self.Portrait or self.Power)
	castbar:SetStatusBarTexture(ns.media.TEXTURE)
	castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	castbar:SetAlpha(0.75)

	if (unit == "player" or unit == "target") then
		castbar:SetAllPoints(self.Overlay)

		castbar.Time = PutFontString(castbar, ns.media.FONT2, 12, nil, "RIGHT")
		castbar.Time:SetPoint("RIGHT", -3.5, 3)
		castbar.Time:SetTextColor(0.84, 0.75, 0.65)

		castbar.CustomTimeText = CustomCastTimeText
		castbar.CustomDelayText = CustomCastDelayText

		castbar.Text = PutFontString(castbar, ns.media.FONT2, 12, nil, "LEFT")
		castbar.Text:SetPoint("LEFT", 3.5, 3)
		castbar.Text:SetPoint("RIGHT", castbar.Time, "LEFT", -3.5, 0)
		castbar.Text:SetTextColor(0.84, 0.75, 0.65)
	else
		castbar:SetAllPoints(self.Power)
	end

	if (unit == "player") then
		castbar.SafeZone = castbar:CreateTexture(nil, "ARTWORK")
		castbar.SafeZone:SetTexture(ns.media.TEXTURE)
		castbar.SafeZone:SetVertexColor(0.69, 0.31, 0.31, 0.75)
	end

	if (unit == "target" or unit:match("^boss%d$") or unit == "focus") then
		castbar.Icon = castbar:CreateTexture(nil, "ARTWORK")

		castbar.IconOverlay = castbar:CreateTexture(nil, "OVERLAY")
		castbar.IconOverlay:SetTexture(ns.media.BTNTEXTURE)
		castbar.IconOverlay:SetVertexColor(0.84, 0.75, 0.65)

		if (unit == "target") then
			castbar.Icon:SetPoint("RIGHT", castbar, "LEFT", -15, 0)
			castbar.Icon:SetSize(32, 32)
			castbar.IconOverlay:SetPoint("TOPLEFT", castbar.Icon, -5, 5)
			castbar.IconOverlay:SetPoint("BOTTOMRIGHT", castbar.Icon, 5, -5)
		else
			castbar.Icon:SetSize(22, 22)
			castbar.IconOverlay:SetPoint("TOPLEFT", castbar.Icon, -3, 3)
			castbar.IconOverlay:SetPoint("BOTTOMRIGHT", castbar.Icon, 3, -3)
			if (unit == "focus") then
				castbar.Icon:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 7.5, 0)
			else
				castbar.Icon:SetPoint("LEFT", self, "RIGHT", 7.5, 0)
			end
		end
		castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		castbar.PostCastStart = PostUpdateCast
		castbar.PostChannelStart = PostUpdateCast
		castbar.PostCastInterruptible = PostUpdateCast
		castbar.PostCastNotInterruptible = PostUpdateCast
	end

	self.Castbar = castbar
end
ns.AddCastbar = AddCastbar

local AddClassPowerIcons = function(self, width, height, spacing)
	local classIcons = {}

	classIcons.width  = width
	classIcons.height = height
	classIcons.spacing = spacing

	local maxPower = 5

	for i = 1, maxPower do
		classIcons[i] = self.Overlay:CreateTexture("oUF_Rain_ComboPoint_"..i, "OVERLAY")
		classIcons[i]:SetTexture(ns.media.TEXTURE)
	end

	classIcons.PostUpdate = PostUpdateClassPowerIcons

	self.ClassIcons = classIcons
end
ns.AddClassPowerIcons = AddClassPowerIcons

local AddCombatFeedbackText = function(self)
	if (not IsAddOnLoaded("oUF_CombatFeedback")) then return end

	local combatFeedbackText = PutFontString(self.Overlay, ns.media.FONT, 14, "OUTLINE", "LEFT")
	combatFeedbackText:SetPoint("CENTER", 0, 5)
	combatFeedbackText.colors = ns.combatFeedbackColors

	self.CombatFeedbackText = combatFeedbackText
end
ns.AddCombatFeedbackText = AddCombatFeedbackText

local AddComboPointsBar = function(self, width, height, spacing)
	local comboPoints = {}
	local maxCPoints = MAX_COMBO_POINTS

	for i = 1, maxCPoints do
		comboPoints[i] = self.Overlay:CreateTexture("oUF_Rain_ComboPoint_"..i, "OVERLAY")
		comboPoints[i]:SetSize((width - maxCPoints * spacing - spacing) / maxCPoints, height)
		comboPoints[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * comboPoints[i]:GetWidth() + i * spacing, 1)
		comboPoints[i]:SetTexture(unpack(ns.colors.cpoints[i]))
	end

	self.CPoints = comboPoints
end
ns.AddComboPointsBar = AddComboPointsBar
-- TODO: this looks awfully
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
	local debuffs = CreateFrame("Frame", self:GetName().."_Debuffs", self)
	debuffs.spacing = 6
	debuffs.size = (230 - 7 * debuffs.spacing) / 8
	debuffs.showType = true
	debuffs.disableCooldown = true
	debuffs.onlyShowPlayer = ns.cfg.onlyShowPlayerDebuffs
	debuffs.CreateIcon = CreateAuraIcon
	debuffs.PreSetPosition = PreSetPosition
	debuffs.PostUpdateIcon = PostUpdateIcon

	if (unit == "player" or unit == "target") then
		debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -7.5)
		debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -7.5)
		debuffs:SetHeight(5 * (debuffs.size + debuffs.spacing))

		debuffs.initialAnchor = "TOPLEFT"
		debuffs["growth-x"] = "RIGHT"
		debuffs["growth-y"] = "DOWN"

		if (unit == "player") then
			debuffs.CustomFilter = CustomPlayerFilter
		else
			debuffs.CustomFilter = CustomFilter
		end
	end

	if (unit == "pet") then
		debuffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -15, 0)
		debuffs.num = 6
		debuffs:SetSize(debuffs.num * (debuffs.size + debuffs.spacing), debuffs.size + debuffs.spacing)

		debuffs.initialAnchor = "RIGHT"
		debuffs["growth-x"] = "LEFT"
	end

	if (unit == "targettarget") then
		debuffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 15, 0)
		debuffs.num = 6
		debuffs:SetSize(debuffs.num * debuffs.size + (debuffs.num - 1) * debuffs.spacing, debuffs.size)

		debuffs.initialAnchor = "LEFT"
		debuffs["growth-x"] = "RIGHT"
	end

	debuffs.Magnify = CreateFrame("Frame", nil, self)
	debuffs.Magnify:SetFrameLevel(debuffs:GetFrameLevel() + 2)

	debuffs.Magnify.icon = debuffs.Magnify:CreateTexture(nil, "ARTWORK")
	debuffs.Magnify.icon:SetPoint("CENTER")

	debuffs.Magnify.border = debuffs.Magnify:CreateTexture(nil, "OVERLAY")
	debuffs.Magnify.border:SetTexture(ns.media.BTNTEXTURE)
	debuffs.Magnify.border:SetPoint("TOPLEFT", debuffs.Magnify.icon, -5, 5)
	debuffs.Magnify.border:SetPoint("BOTTOMRIGHT", debuffs.Magnify.icon, 5, -5)

	self.Debuffs = debuffs
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
	local experience = CreateFrame("StatusBar", "oUF_Rain_Experience", self)
	experience:SetHeight(5)
	experience:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 2.5)
	experience:SetPoint("BOTTOMRIGHT", self.Health, "TOP", -2, 2.5)
	experience:SetStatusBarTexture(ns.media.TEXTURE)
	experience:SetStatusBarColor(0.67, 0.51, 1)
	experience:SetBackdrop(ns.media.BACKDROP)
	experience:SetBackdropColor(0, 0, 0)
	experience:SetAlpha(0)

	experience:EnableMouse()
	experience:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
	experience:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

	local rested = CreateFrame("StatusBar", "oUF_Rain_Experience_Rested", experience)
	rested:SetPoint("TOPLEFT", experience:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	rested:SetPoint("BOTTOMRIGHT", experience, 0, 0)
	rested:SetStatusBarTexture(ns.media.TEXTURE)
	rested:SetStatusBarColor(0, 0.56, 1)
	rested:SetBackdrop(ns.media.BACKDROP)
	rested:SetBackdropColor(0, 0, 0)
	experience.Rested = rested

	experience.Tooltip = function(self)
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

	experience:HookScript("OnLeave", GameTooltip_Hide)
	experience:HookScript("OnEnter", experience.Tooltip)

	self.Experience = experience
end
ns.AddExperienceBar = AddExperienceBar

local AddFocusHelper = function(self)
	local focusSpark = self.Power:CreateTexture(nil, "OVERLAY")
	focusSpark:SetWidth(10)
	focusSpark:SetHeight(self.Power:GetHeight() * 1.85)

	focusSpark.bmSpell = ns.cfg.bmSpell -- Kill Command
	focusSpark.mmSpell = ns.cfg.mmSpell -- Chimera Shot
	focusSpark.svSpell = ns.cfg.svSpell -- Explosive Shot

	local focusGain = self.Power:CreateTexture(nil, "OVERLAY")
	focusGain:SetHeight(self.Power:GetHeight())
	focusGain:SetTexture(ns.media.TEXTURE)
	focusGain:SetVertexColor(0, 1, 0, 0.3)

	self.FocusSpark = focusSpark
	self.FocusGain = focusGain
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
	local overlay = CreateFrame("Frame", self:GetName().."_Overlay", self.Portrait)
	overlay:SetPoint("TOPLEFT", self.Portrait, 0, 1)
	overlay:SetPoint("BOTTOMRIGHT", self.Portrait, 0, -1)

	if (unit == "player") then
		local threat = overlay:CreateTexture(nil, "BORDER")
		threat:SetAllPoints()
		threat:SetTexture(ns.media.OVERLAY)
		threat:SetVertexColor(0.1, 0.1, 0.1, 0.75)
		self.Threat = threat
	else
		local ccWarn = overlay:CreateTexture(nil, "BORDER")
		ccWarn:SetAllPoints()
		ccWarn:SetTexture(ns.media.OVERLAY)
		ccWarn:SetVertexColor(0.1, 0.1, 0.1, 0.75)
		self.CCWarn = ccWarn
	end

	self.Overlay = overlay
end
ns.AddOverlay = AddOverlay

local AddPortrait = function(self, unit)
	local portrait = CreateFrame("PlayerModel", self:GetName().."_Portrait", self)
	portrait:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 7.5, 10)
	portrait:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -7.5, -7.5)
	portrait:SetFrameLevel(self:GetFrameLevel() + 3)
	portrait:SetBackdrop(ns.media.BACKDROP)
	portrait:SetBackdropColor(0, 0, 0, 1)

	self.Portrait = portrait
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

	local reputation = CreateFrame("StatusBar", "oUF_Rain_Reputation", self)
	reputation:SetHeight(5)
	reputation:SetPoint("TOPLEFT", self.Health, "TOP", 2, 7.5)
	reputation:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", 0, 7.5)
	reputation:SetStatusBarTexture(ns.media.TEXTURE)
	reputation:SetBackdrop(ns.media.BACKDROP)
	reputation:SetBackdropColor(0, 0, 0)
	reputation:SetAlpha(0)

	reputation:EnableMouse()
	reputation:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
	reputation:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

	local bg = reputation:CreateTexture(nil, "BORDER")
	bg:SetAllPoints(reputation)
	bg:SetTexture(ns.media.TEXTURE)
	bg:SetVertexColor(0.15, 0.15, 0.15)
	reputation.bg = bg

	reputation.colorStanding = true

	reputation.Tooltip = function(self)
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

	reputation:HookScript("OnLeave", GameTooltip_Hide)
	reputation:HookScript("OnEnter", reputation.Tooltip)

	self.Reputation = reputation
end
ns.AddReputationBar = AddReputationBar

local AddRuneBar = function(self, width, height, spacing)
	local runes = {}
	local maxRunes = 6

	for i = 1, maxRunes do
		runes[i] = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self.Overlay)
		runes[i]:SetSize((width - maxRunes * spacing - spacing) / maxRunes, height)
		runes[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * runes[i]:GetWidth() + i * spacing, 1)
		runes[i]:SetStatusBarTexture(ns.media.TEXTURE)
		runes[i]:SetBackdrop(ns.media.BACKDROP)
		runes[i]:SetBackdropColor(0, 0, 0)

		local bg = runes[i]:CreateTexture(nil, "BORDER")
		bg:SetTexture(ns.media.TEXTURE)
		bg:SetAllPoints()
		bg.multiplier = 0.5
		runes[i].bg = bg
	end

	self.Runes = runes
end
ns.AddRuneBar = AddRuneBar

local AddSwingBar = function(self)
	if (not IsAddOnLoaded("oUF_Swing")) then return end

	local swing = CreateFrame("Frame", self:GetName().."_Swing", self)
	swing:SetHeight(3)
	swing:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 7)
	swing:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 7)
	swing.texture = ns.media.TEXTURE
	swing.color = {0.55, 0.57, 0.61, 1}
	swing.textureBG = ns.media.TEXTURE
	swing.colorBG = {0, 0, 0, 0.6}

	swing.hideOoc = true

	self.Swing = swing
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
	local totems = {}
	local maxTotems = MAX_TOTEMS

	for i = 1, maxTotems do
		totems[i] = CreateFrame("StatusBar", "oUF_Rain_Totem"..i, self.Overlay)
		totems[i]:SetStatusBarTexture(ns.media.TEXTURE)
		totems[i]:SetMinMaxValues(0, 1)

		if (playerClass == "SHAMAN") then
			totems[i]:SetSize((215 - maxTotems - 1) / maxTotems, height)
			totems[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / maxTotems) + 1, 0)
			totems[i]:SetStatusBarColor(unpack(ns.colors.totems[SHAMAN_TOTEM_PRIORITIES[i]]))
		elseif (playerClass == "DRUID") then -- Druid's mushrooms
			totems[i]:SetSize(width, height)
			totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
				if (i == 1) then
					totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
				elseif (i == 2) then
					totems[i]:SetPoint("RIGHT", totems[1], "LEFT", -1, 0)
				else
					totems[i]:SetPoint("LEFT", totems[1], "RIGHT", 1, 0)
				end
		elseif (playerClass == "DEATHKNIGHT") then -- Death knight's ghoul
			totems[i]:SetSize(width, height)
			totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
			totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
		end

		totems[i]:SetBackdrop(ns.media.BACKDROP)
		totems[i]:SetBackdropColor(0, 0, 0)

		totems[i]:EnableMouse()
--[[
		totems[i]:SetScript("OnMouseUp", function(self, button)
			if (button == "RightButton") then
				DestroyTotem(self:GetID())
			end
		end)
--]]
		totems[i].UpdateTooltip = function(self)
			GameTooltip:SetTotem(self:GetID())
			--GameTooltip:AddLine(GLYPH_SLOT_REMOVE_TOOLTIP, 1, 0, 0)
			GameTooltip:Show()
		end
	end

	totems.Override = UpdateTotem

	self.Totems = totems
end
ns.AddTotems = AddTotems

local AddWarlockPowerBar = function(self, width, height, spacing)
	local warlockPowerBar = {}
	warlockPowerBar.width = width
	warlockPowerBar.height = height
	warlockPowerBar.spacing = spacing

	for i = 1, 4 do
		warlockPowerBar[i] = CreateFrame("StatusBar", "oUF_Rain_WarlockPowerBar"..i, self.Overlay)
		warlockPowerBar[i]:SetSize((width - 4 * spacing - spacing) / 4, height)
		warlockPowerBar[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * warlockPowerBar[i]:GetWidth() + i * spacing, 1)
		warlockPowerBar[i]:SetStatusBarTexture(ns.media.TEXTURE)
		warlockPowerBar[i]:SetBackdrop(ns.media.BACKDROP)
		warlockPowerBar[i]:SetBackdropColor(0, 0, 0)

		local bg = warlockPowerBar[i]:CreateTexture(nil, "BORDER")
		bg:SetTexture(ns.media.TEXTURE)
		bg:SetAllPoints()
		bg.multiplier = 0.3
		warlockPowerBar.bg = bg
	end

	warlockPowerBar.PostUpdateVisibility = WarlockPowerPostUpdateVisibility

	self.WarlockPowerBar = warlockPowerBar
end
ns.AddWarlockPowerBar = AddWarlockPowerBar

--[[ ICONS ]]--

local AddAssistantIcon = function(self, unit)
	local assistant = self.Health:CreateTexture(nil, "OVERLAY")
	assistant:SetSize(16, 16)
	assistant:SetPoint("TOPLEFT", -8.5, 8.5)
	self.Assistant = assistant
end
ns.AddAssistantIcon = AddAssistantIcon

local AddCombatIcon = function(self)
	local combat = self.Health:CreateTexture(nil, "OVERLAY")
	combat:SetSize(20, 20)
	combat:SetPoint("TOP", 0, 1)
	self.Combat = combat
end
ns.AddCombatIcon = AddCombatIcon

local AddLeaderIcon = function(self, unit)
	local leader = self.Health:CreateTexture(nil, "OVERLAY")
	leader:SetSize(16, 16)
	leader:SetPoint("TOPLEFT", -8.5, 8.5)
	self.Leader = leader
end
ns.AddLeaderIcon = AddLeaderIcon

local AddMasterLooterIcon = function(self, unit)
	local masterLooter = self.Health:CreateTexture(nil, "OVERLAY")
	masterLooter:SetSize(16, 16)
	masterLooter:SetPoint("TOPRIGHT", 8.5, 8.5)
	self.MasterLooter = masterLooter
end
ns.AddMasterLooterIcon = AddMasterLooterIcon

local AddPhaseIcon = function(self, unit)
	local phaseIcon = self.Health:CreateTexture(nil, "OVERLAY")
	phaseIcon:SetSize(16, 16)
	phaseIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
	self.PhaseIcon = phaseIcon
end
ns.AddPhaseIcon = AddPhaseIcon

local AddQuestIcon = function(self, unit)
	local questIcon = self.Health:CreateTexture(nil, "OVERLAY")
	questIcon:SetSize(16, 16)
	questIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
	self.QuestIcon = questIcon
end
ns.AddQuestIcon = AddQuestIcon

local AddRaidIcon = function(self, unit)
	raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	raidIcon:SetTexture(ns.media.RAIDICONS)
	if (unit ~= "player" and unit ~= "target") then
		raidIcon:SetSize(14, 14)
		raidIcon:SetPoint("TOP", 0, 10)
	else
		raidIcon:SetSize(18, 18)
		raidIcon:SetPoint("TOP", 0, 10)
	end
	self.RaidIcon = raidIcon
end
ns.AddRaidIcon = AddRaidIcon

local AddRaidRoleIcon = function(self, unit)
	local raidRole = self:CreateTexture(nil, "OVERLAY")
	raidRole:SetSize(16, 16)
	raidRole:SetPoint("BOTTOMRIGHT", -8.5, 8.5)
	self.RaidRole = raidRole
end
ns.AddRaidRoleIcon = AddRaidRoleIcon

-- oUF checks ready status only for raid and party
local AddReadyCheckIcon = function(self, unit)
	local readyCheck = self.Health:CreateTexture(nil, "OVERLAY")
	readyCheck:SetSize(16, 16)
	readyCheck:SetPoint("RIGHT", -5, 0)

	readyCheck.finishedTime = 10
	readyCheck.fadeTime = 3

	self.ReadyCheck = readyCheck
end
ns.AddReadyCheckIcon = AddReadyCheckIcon

local AddRestingIcon = function(self)
	local resting = self.Power:CreateTexture(nil, "OVERLAY")
	resting:SetSize(16, 16)
	resting:SetPoint("BOTTOMLEFT", -8.5, -8.5)
	self.Resting = resting
end
ns.AddRestingIcon = AddRestingIcon

local AddResurrectIcon = function(self, unit)
	local resurrectIcon = self.Health:CreateTexture(nil, "OVERLAY")
	resurrectIcon:SetSize(16, 16)
	resurrectIcon:SetPoint("CENTER")
	self.ResurrectIcon = resurrectIcon
end
ns.AddResurrectIcon = AddResurrectIcon
