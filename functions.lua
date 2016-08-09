local _, ns = ...

local Debug = ns.Debug

local format = format

local playerClass = ns.playerClass
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsFriend = UnitIsFriend
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsTapDenied = UnitIsTapDenied

local ColorGradient = oUF.ColorGradient

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
		return format("%.1fm", val / 1e6)
	elseif (val >= 1e4) then
		return format("%.1fk", val / 1e3)
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
	name = (strlenutf8(name) > shortenTo) and string.gsub(name, "(%S[\128-\191]*)%S+%s", "%1. ") or name

	local bytes = strlen(name)
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

local FormatTime = function(seconds)
	local day, hour, minute = 86400, 3600, 60
	if (seconds >= day) then
		return format("|cffD6BFA5%dd|r", floor(seconds/day + 0.5))
	elseif (seconds >= hour) then
		return format("|cffD6BFA5%dh|r", floor(seconds/hour + 0.5))
	elseif (seconds >= minute) then
		if (seconds <= minute * 5) then
			return format("|cffD6BFA5%d:%02d|r", floor(seconds/minute), seconds % minute)
		end
		return format("|cffD6BFA5%dm|r", floor(seconds/minute + 0.5))
	else
		local secs = floor(seconds + 0.5)
		return format("|cffD6BFA5%d|r", secs)
	end
end

local PutFontString = function(parent, fontName, fontHeight, fontStyle, justifyH)
	local fontString = parent:CreateFontString(nil, "OVERLAY")
	fontString:SetFont(fontName, fontHeight, fontStyle)
	fontString:SetJustifyH(justifyH or "LEFT")
	fontString:SetShadowColor(0, 0, 0)
	fontString:SetShadowOffset(0.75, -0.75)
	fontString:SetWordWrap(false)

	return fontString
end
ns.PutFontString = PutFontString

local CustomCastTimeText = function(Castbar, duration)
	Castbar.Time:SetText(format("%.1f / %.2f", Castbar.channeling and duration or Castbar.max - duration, Castbar.max))
end

local CustomCastDelayText = function(Castbar, duration)
	Castbar.Time:SetText(format("%.1f |cffaf5050%s %.1f|r", Castbar.channeling and duration or Castbar.max - duration, Castbar.channeling and "- " or "+", Castbar.delay))
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
		if (aura.elapsed >= 0.5) then
			if (not aura.first) then
				aura.timeLeft = aura.timeLeft - aura.elapsed
			else
				aura.timeLeft = aura.timeLeft - GetTime()
				aura.first = false
			end
			if (aura.timeLeft > 0) then
				local time = FormatTime(aura.timeLeft)
					aura.remaining:SetText(time)
			else
				aura.remaining:Hide()
				aura:SetScript("OnUpdate", nil)
			end
			aura.elapsed = 0
		end
	end
end

local SortAuras = function(a, b)
	if (a:IsShown() and b:IsShown()) then
		if (a.isDebuff == b.isDebuff) then
			return a.timeLeft > b.timeLeft
		elseif (not a.isDebuff) then
			return b.isDebuff
		end
	elseif (a:IsShown()) then
		return true
	end
end

local UpdateAuraTooltip = function(button)
	GameTooltip:SetUnitAura(button:GetParent().__owner.unit, button:GetID(), button.filter)
end

local AuraOnEnter = function(button)
	if(not button:IsVisible()) then return end

	GameTooltip:SetOwner(button, "ANCHOR_BOTTOMRIGHT")
	button:UpdateTooltip()
end

local AuraOnLeave = function(button)
	GameTooltip:Hide()
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

local SPEC_MONK_BREWMASTER = SPEC_MONK_BREWMASTER
local STAGGER_YELLOW_TRANSITION = STAGGER_YELLOW_TRANSITION
local STAGGER_RED_TRANSITION = STAGGER_RED_TRANSITION
local UnitStagger = UnitStagger

--[[
	 This differs from blizzard's implementation in that it uses the player's current health instead of max health
	 This is to make the display more meaningful when playing solo
--]]

local UpdateMonkStagger = function(Power, unit)
	if (Power.disconnected or UnitIsDeadOrGhost(unit)) then
		return Power:SetValue(0)
	end

	if (ns.playerSpec ~= SPEC_MONK_BREWMASTER) then return end

	local staggerPercent = UnitStagger(unit) / UnitHealthMax(unit)
	local color

	if (staggerPercent >= STAGGER_RED_TRANSITION) then
		color = Power.__owner.colors.power["STAGGER"][3]
	elseif (staggerPercent >= STAGGER_YELLOW_TRANSITION) then
		color = Power.__owner.colors.power["STAGGER"][2]
	else
		color = Power.__owner.colors.power["STAGGER"][1]
	end

	local r, g, b = color[1], color[2], color[3]
	Power:SetStatusBarColor(r, g, b)
	Power.bg:SetVertexColor(r * 0.5, g * 0.5, b * 0.5)
end
ns.UpdateMonkStagger = UpdateMonkStagger

local PostUpdatePower = function(Power, unit, cur, max)
	if (Power.disconnected or UnitIsDeadOrGhost(unit)) then
		Power:SetValue(0)
	end

	if (unit == "target") then
		local self = Power.__owner
		local info = self.Info
		if (info) then
			info:ClearAllPoints()
			if (Power.value:GetText()) then
				info:SetPoint("LEFT", Power.value, "RIGHT", 5, 0)
				info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
				info:SetJustifyH("CENTER")
			else
				info:SetPoint("TOPLEFT", 3.5, -3.5)
				info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
				info:SetJustifyH("LEFT")
			end
		end
	end
end
ns.PostUpdatePower = PostUpdatePower

local CreateAuraIcon = function(Auras, index)
	local unit = string.match(Auras.__owner.unit, "([a-z]+)%d*")
	Auras.createdIcons = Auras.createdIcons + 1 -- need to do this

	local button = CreateFrame("Button", nil, Auras)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	button.icon = icon

	local count = PutFontString(button, ns.media.FONT, 9, "OUTLINE", "RIGHT")
	count:SetPoint("BOTTOMRIGHT", 2.5, 0)
	count:SetTextColor(0.84, 0.75, 0.65)
	button.count = count
	-- aura border
	local overlay = button:CreateTexture(nil, "OVERLAY")
	overlay:SetTexture(ns.media.BTNTEXTURE)
	overlay:SetPoint("TOPLEFT", -4.5, 4.5)
	overlay:SetPoint("BOTTOMRIGHT", 4.5, -4.5)
	overlay:SetTexCoord(0, 1, 0, 1)
	button.overlay = overlay

	local stealable = button:CreateTexture(nil, "OVERLAY", nil, 1)
	stealable:SetTexture(ns.media.STEALABLETEX)
	stealable:SetPoint("TOPLEFT", -4.5, 4.5)
	stealable:SetPoint("BOTTOMRIGHT", 4.5, -4.5)
	stealable:SetTexCoord(0, 1, 0, 1)
	stealable:SetBlendMode("DISABLE")
	stealable:SetVertexColor(unpack(oUF.colors.class[playerClass]))
	button.stealable = stealable
	-- timer text
	if (unit ~= "raid") then
		local remaining = PutFontString(button, ns.media.FONT, 9, "OUTLINE", "LEFT")
		remaining:SetPoint("TOPLEFT", -0.5, 0)
		button.remaining = remaining
	end

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

	if (unit ~= "player" and not aura.isPlayer) then
		local friend = UnitIsFriend("player", unit)
		if ((not friend and aura.isDebuff)
				or (friend and not aura.isDebuff)) then
			aura.icon:SetDesaturated(true)
			aura.overlay:SetVertexColor(0.5, 0.5, 0.5)
		end
	elseif (unit ~= "player" and aura.isPlayer) then
		aura.icon:SetDesaturated(false)
	end

	if (aura.remaining) then
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
end

local PostUpdateGapIcon = function(Auras, unit, aura, index)
	aura.remaining:Hide()
	aura:SetScript("OnUpdate", nil)
	aura.timeLeft = aura.isDebuff and math.huge or -5
end

local totemPriorities = playerClass == "SHAMAN" and SHAMAN_TOTEM_PRIORITIES or STANDARD_TOTEM_PRIORITIES

local UpdateTotem = function(self, event, slot)
	local total = 0
	local totem = self.Totems[totemPriorities[slot] or 5]
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

	local height = element.height
	local spacing = element.spacing

	local width = (element.width - maxPower * spacing - spacing ) / maxPower -- factoring causes rounding issues?
	spacing = width + spacing

	for i = 1, maxPower do
		element[i]:SetSize(width, height)
		element[i]:SetPoint("BOTTOMLEFT", (i - 1) * spacing + 1, 1)
	end
end

local UpdateHealth = function(self, event, unit)
	if (self.unit ~= unit) then return end

	local health = self.Health

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local disconnected = not UnitIsConnected(unit)

	health:SetMinMaxValues(0, max)
	health:SetValue(cur)
	health.disconnected = disconnected

	local r, g, b, t
	if (disconnected and health.colorDisconnected or UnitIsDeadOrGhost(unit)) then
		health:SetValue(max)
		t = self.colors.disconnected
	elseif (health.colorTapping and not UnitPlayerControlled(unit) and
		UnitIsTapDenied(unit)) then
		t = self.colors.tapped
	elseif (health.colorSmooth) then
		r, g, b = ColorGradient(cur, max, unpack(self.colors.smooth))
	else
		r, g, b = 0.17, 0.17, 0.24
	end

	if (t) then
		r, g, b = t[1], t[2], t[3]
	end

	if (b) then
		health:SetStatusBarColor(r, g, b)
	end
end
ns.UpdateHealth = UpdateHealth

local UpdateThreat = function(self, event, unit)
	if (self.unit ~= unit) then return end

	local status = UnitThreatSituation(unit)

	if (status and status > 1) then
		local r, g, b = GetThreatStatusColor(status)
		self.FrameBackdrop:SetBackdropColor(r, g, b, 1)
	else
		self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	end
end

local PostUpdateRune = function(_, rune, _, _, _, runeReady)
	if (runeReady) then
		UIFrameFlash(rune, 0.5, 0.5, 1, true)
		rune.fullAlpha = true
	elseif (rune.fullAlpha) then
		UIFrameFlashStop(rune)
		rune:SetAlpha(0.5)
		rune.fullAlpha = nil
	end
end

local PostUpdateHealPrediction = function(element, unit, overAbsorb, overHealAbsorb)
	local health = element.__owner.Health
	local maxHealth = UnitHealthMax(unit)
	local myBar = element.myBar
	local absorbBar = element.absorbBar
	local healAbsorbBar = element.healAbsorbBar
	local myCurrentHealAbsorb = UnitGetTotalHealAbsorbs(unit) or 0
	local myCurrentHealAbsorbPercent = myCurrentHealAbsorb / maxHealth

	if (absorbBar:GetValue() > 0) then
		absorbBar:ClearAllPoints()
		absorbBar:SetPoint("TOP")
		absorbBar:SetPoint("BOTTOM")

		if (healAbsorbBar:GetValue() > 0) then
			absorbBar:SetPoint("LEFT", healAbsorbBar:GetStatusBarTexture(), "RIGHT", 0, 0)
		else
			absorbBar:SetPoint("LEFT", element.otherBar:GetStatusBarTexture(), "RIGHT", 0, 0)
		end
	end

	if (overHealAbsorb) then
		element.overHealAbsorbGlow:Show()
		myBar:Hide()
	else
		element.overHealAbsorbGlow:Hide()
		myBar:ClearAllPoints()
		myBar:SetPoint("TOP")
		myBar:SetPoint("BOTTOM")
		myBar:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT", -(health:GetWidth() * myCurrentHealAbsorbPercent), 0)
		myBar:Show()
	end

	if (overAbsorb) then
		element.overAbsorbGlow:Show()
	else
		element.overAbsorbGlow:Hide()
	end
end

local PostUpdateArtifactPower = function(element, event, isShown)
	if (not isShown) then return end

	element.text:SetFormattedText("%d / %d", element.totalPower, element.powerForNextTrait - element.power)
end
--[[ END OF PRE AND POST FUNCTIONS ]]--

--[[ LAYOUT FUNCTIONS ]]--
local AddAuras = function(self, unit)
	local auras = CreateFrame("Frame", self:GetName().."_Auras", unit ~= "raid" and self or self.Health)

	auras.numBuffs = 3
	auras.numDebuffs = 3
	auras.gap = true
	auras.spacing = 6
	auras.size = (230 - 7 * auras.spacing) / 8
	auras:SetSize(7 * (auras.size + auras.spacing), auras.size + auras.spacing)
	auras.disableCooldown = true
	auras.showType = true
	auras.CreateIcon = CreateAuraIcon
	auras.PreSetPosition = PreSetPosition
	auras.PostUpdateIcon = PostUpdateIcon
	auras.PostUpdateGapIcon = PostUpdateGapIcon

	if (unit == "party") then
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
	elseif (unit == "pet") then
		auras:SetPoint("RIGHT", self, "LEFT", -9, 0)
		auras.initialAnchor = "RIGHT"
		auras["growth-x"] = "LEFT"
		auras["growth-y"] = "UP"
	elseif (unit == "raid") then
		auras.numBuffs = 2
		auras.numDebuffs = 2
		auras.gap = nil
		auras.spacing = 1
		auras.size = 12
		auras:SetSize(4 * (auras.size + auras.spacing), auras.size + auras.spacing)
		auras.showType = nil -- so that oUF hides the border
		auras.PreSetPosition = nil
		auras.PostUpdateGapIcon = nil
		auras:SetPoint("BOTTOMLEFT", self.Power, "TOPLEFT", 0, 0)
	end

	auras.CustomFilter = ns.CustomFilter[unit]

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

	altPowerBar:EnableMouse(true)
	altPowerBar:SetScript("OnEnter", altPowerBar.OnEnter)

	self.AltPowerBar = altPowerBar
end
ns.AddAltPowerBar = AddAltPowerBar

local AddArtifactPowerBar = function(self)
	local artifactPower = CreateFrame("StatusBar", "oUF_Rain_ArtifactPowerBar", self)
	artifactPower:SetHeight(5)
	artifactPower:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 2.5)
	artifactPower:SetPoint("BOTTOMRIGHT", self.Health, "TOP", -2, 2.5)
	artifactPower:SetStatusBarTexture(ns.media.TEXTURE)
	artifactPower:SetStatusBarColor(.901, .8, .601)
	artifactPower:SetBackdrop(ns.media.BACKDROP)
	artifactPower:SetBackdropColor(0, 0, 0)
	artifactPower:EnableMouse(true)
	artifactPower:Hide()

	artifactPower.onAlpha = 1
	artifactPower.offAlpha = 0

	local text = PutFontString(artifactPower, ns.media.FONT2, 9, nil, "CENTER")
	text:SetPoint("CENTER")
	artifactPower.text = text

	artifactPower.PostUpdate = PostUpdateArtifactPower

	self.ArtifactPower = artifactPower
end
ns.AddArtifactPowerBar = AddArtifactPowerBar

local AddBuffs = function(self, unit)
	local buffs = CreateFrame("Frame", self:GetName().."_Buffs", self)
	buffs.spacing = 6
	buffs.size = unit == "player" and 38.4 or (230 - 7 * buffs.spacing) / 8
	buffs.disableCooldown = true
	buffs.showType = true
	buffs.onlyShowPlayer = ns.cfg.onlyShowPlayerBuffs
	buffs.showStealableBuffs = true
	buffs.CreateIcon = CreateAuraIcon
	buffs.PreSetPosition = unit ~= "player" and PreSetPosition
	buffs.PostUpdateIcon = PostUpdateIcon

	if (unit == "player" or unit == "target") then
		buffs["growth-y"] = "DOWN"

		if (unit == "player") then
			buffs:SetSize(6 * (buffs.size + buffs.spacing), 6 * (buffs.size + buffs.spacing))
			buffs:SetPoint("TOPRIGHT", self, "TOPLEFT", -9, 1)
			buffs.initialAnchor = "TOPRIGHT"
			buffs["growth-x"] = "LEFT"
		else
			buffs:SetSize(8 * (buffs.size + buffs.spacing), 4 * (buffs.size + buffs.spacing))
			buffs:SetPoint("TOPLEFT", self, "TOPRIGHT", 9, 1)
			buffs.initialAnchor = "TOPLEFT"
			buffs["growth-x"] = "RIGHT"
		end

		buffs.CustomFilter = ns.CustomFilter[unit]
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
		buffs.onlyShowPlayer = nil
	end

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

		local castTime = PutFontString(castbar, ns.media.FONT2, 12, nil, "RIGHT")
		castTime:SetPoint("RIGHT", -3.5, 3)
		castTime:SetTextColor(0.84, 0.75, 0.65)
		castbar.Time = castTime

		castbar.CustomTimeText = CustomCastTimeText
		castbar.CustomDelayText = CustomCastDelayText

		local text = PutFontString(castbar, ns.media.FONT2, 12, nil, "LEFT")
		text:SetPoint("LEFT", 3.5, 3)
		text:SetPoint("RIGHT", castbar.Time, "LEFT", -3.5, 0)
		text:SetTextColor(0.84, 0.75, 0.65)
		castbar.Text = text
	else
		castbar:SetAllPoints(self.Power)
	end

	if (unit == "player") then
		local safeZone = castbar:CreateTexture(nil, "ARTWORK")
		safeZone:SetTexture(ns.media.TEXTURE)
		safeZone:SetVertexColor(0.69, 0.31, 0.31, 0.75)
		castbar.SafeZone = safeZone
	end

	if (unit == "target" or unit:match("^boss%d$") or unit == "focus") then
		local icon = castbar:CreateTexture(nil, "ARTWORK")
		icon:SetSize(30, 30)
		icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)

		if (unit == "target") then
			icon:SetPoint("RIGHT", castbar, "LEFT", -15, 0)
		else
			icon:SetPoint("LEFT", self, "RIGHT", 7.5, 0)
		end

		local iconOverlay = castbar:CreateTexture(nil, "OVERLAY")
		iconOverlay:SetTexture(ns.media.BTNTEXTURE)
		iconOverlay:SetVertexColor(0.84, 0.75, 0.65)
		iconOverlay:SetPoint("TOPLEFT", icon, -5, 5)
		iconOverlay:SetPoint("BOTTOMRIGHT", icon, 5, -5)

		castbar.Icon = icon
		castbar.IconOverlay = iconOverlay
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

	classIcons.width = width
	classIcons.height = height
	classIcons.spacing = spacing

	local maxPower = 6

	for i = 1, maxPower do
		classIcons[i] = self.Overlay:CreateTexture("oUF_Rain_ClassIcon_"..i, "OVERLAY")
		classIcons[i]:SetTexture(ns.media.TEXTURE)
	end

	classIcons.PostUpdate = PostUpdateClassPowerIcons

	self.ClassIcons = classIcons
end
ns.AddClassPowerIcons = AddClassPowerIcons

local AddComboPointsBar = function(self, width, height, spacing)
	local comboPoints = {}
	local maxCPoints = MAX_COMBO_POINTS

	width = (width - maxCPoints * spacing - spacing) / maxCPoints -- factoring causes rounding issues?
	spacing = width + spacing

	for i = 1, maxCPoints do
		local cPoint = self.Overlay:CreateTexture("oUF_Rain_ComboPoint_"..i, "OVERLAY")
		cPoint:SetSize(width, height)
		cPoint:SetPoint("BOTTOMLEFT", (i - 1) * spacing + 1, 1)
		local color = ns.colors.power.COMBO_POINTS
		cPoint:SetColorTexture(color[1], color[2], color[3])
		comboPoints[i] = cPoint
	end

	self.CPoints = comboPoints
end
ns.AddComboPointsBar = AddComboPointsBar

local AddDispelHighlight = function(self, unit)
	local dispelHighlight = {}

	local texture = self.Health:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints()
	texture:SetTexture(ns.media.HIGHLIGHTTEXTURE)
	texture:SetBlendMode("ADD")
	texture:SetVertexColor(0, 0, 0, 0)
--[[
	local icon, iconOverlay
	if (unit == "player" or unit == "target") then
		icon = self.Overlay:CreateTexture(nil, "OVERLAY")
		icon:SetSize(18, 18)

		iconOverlay = self.Overlay:CreateTexture(nil, "OVERLAY", nil, 1)
		iconOverlay:SetPoint("TOPLEFT", icon, -3.5, 3.5)
		iconOverlay:SetPoint("BOTTOMRIGHT", icon, 3.5, -3.5)
	else
		icon = self.Health:CreateTexture(nil, "OVERLAY")
		icon:SetSize(16, 16)

		iconOverlay = self.Health:CreateTexture(nil, "OVERLAY", nil, 1)
		iconOverlay:SetPoint("TOPLEFT", icon, -1, 1)
		iconOverlay:SetPoint("BOTTOMRIGHT", icon, 1, -1)
	end
	icon:SetPoint("CENTER")
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	iconOverlay:SetTexture(ns.media.BTNTEXTURE)
	iconOverlay:SetVertexColor(0, 0, 0, 0)
--]]
	dispelHighlight.texture = texture
	dispelHighlight.icon = icon
	dispelHighlight.iconOverlay = iconOverlay

	self.DispelHighlight = dispelHighlight
end
ns.AddDispelHighlight = AddDispelHighlight

local AddDebuffs = function(self, unit)
	local debuffs = CreateFrame("Frame", self:GetName().."_Debuffs", self)
	debuffs.spacing = 6
	debuffs.size = (230 - 7 * debuffs.spacing) / 8
	debuffs.showType = true
	debuffs.disableCooldown = true
	debuffs.onlyShowPlayer = unit ~= "focus" and ns.cfg.onlyShowPlayerDebuffs
	debuffs.CreateIcon = CreateAuraIcon
	debuffs.PreSetPosition = unit ~= "player" and unit ~= "focus" and PreSetPosition
	debuffs.PostUpdateIcon = PostUpdateIcon

	if (unit == "player" or unit == "target") then
		debuffs:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -7.5)
		debuffs:SetPoint("TOPRIGHT", self, "BOTTOMRIGHT", 0, -7.5)
		debuffs:SetHeight(5 * (debuffs.size + debuffs.spacing))

		debuffs.initialAnchor = "TOPLEFT"
		debuffs["growth-x"] = "RIGHT"
		debuffs["growth-y"] = "DOWN"
	end

	if (unit == "focus") then
		debuffs:SetPoint("BOTTOMRIGHT", self, "TOPRIGHT", 0, 7.5)
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

	debuffs.CustomFilter = ns.CustomFilter[unit]

	self.Debuffs = debuffs
end
ns.AddDebuffs = AddDebuffs

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

	experience:EnableMouse(true)
	experience:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
	experience:SetScript("OnLeave", function(self) self:SetAlpha(0) end)

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
		GameTooltip:AddLine(format("XP: %s / %s (%d%% - %.1f bars)", BreakUpLargeNumbers(curXP), BreakUpLargeNumbers(maxXP), curXP/maxXP * 100 + 0.5, bars * curXP / maxXP))
		GameTooltip:AddLine(format("Remaining: %s (%d%% - %.1f bars)", BreakUpLargeNumbers(maxXP - curXP), (maxXP - curXP) / maxXP * 100 + 0.5, bars * (maxXP - curXP) / maxXP))
		if (rested and rested > 0) then
			GameTooltip:AddLine(format("|cff0090ffRested: +%s (%d%%)", BreakUpLargeNumbers(rested), rested / maxXP * 100 + 0.5))
		end
		GameTooltip:Show()
	end

	experience:HookScript("OnLeave", GameTooltip_Hide)
	experience:HookScript("OnEnter", experience.Tooltip)

	self.Experience = experience
end
ns.AddExperienceBar = AddExperienceBar

local AddHealPredictionBar = function(self, unit)
	local health = self.Health
	local width = 110 -- party, focus, pet
	if (unit == "player" or unit == "target") then
		width = 230
	elseif (unit == "raid") then
		width = 64
	end

	local hab = CreateFrame("StatusBar", nil, health)
	hab:SetStatusBarTexture(ns.media.TEXTURE)
	hab:SetStatusBarColor(0.75, 0.75, 0, 0.5)
	hab:SetPoint("TOP")
	hab:SetPoint("BOTTOM")
	hab:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT", -230, 0)
	hab:SetWidth(width)
	hab:SetReverseFill(true)

	local mhpb = CreateFrame("StatusBar", nil, health)
	mhpb:SetStatusBarTexture(ns.media.TEXTURE)
	mhpb:SetStatusBarColor(0, 0.5, 0.5, 0.5)
	mhpb:SetPoint("TOP")
	mhpb:SetPoint("BOTTOM")
	mhpb:SetPoint("LEFT", health:GetStatusBarTexture(), "RIGHT")
	mhpb:SetWidth(width)

	local ohpb = CreateFrame("StatusBar", nil, health)
	ohpb:SetStatusBarTexture(ns.media.TEXTURE)
	ohpb:SetStatusBarColor(0, 1, 0, 0.5)
	ohpb:SetPoint("TOP")
	ohpb:SetPoint("BOTTOM")
	ohpb:SetPoint("LEFT", mhpb:GetStatusBarTexture(), "RIGHT")
	ohpb:SetWidth(width)

	local absorb = CreateFrame("StatusBar", nil, health)
	absorb:SetStatusBarTexture(ns.media.TEXTURE)
	absorb:SetStatusBarColor(1, 1, 1, 0.5)
	absorb:SetPoint("TOP")
	absorb:SetPoint("BOTTOM")
	absorb:SetPoint("LEFT", ohpb:GetStatusBarTexture(), "RIGHT")
	absorb:SetWidth(width)

	local overAbsorb = health:CreateTexture(nil, "OVERLAY")
	overAbsorb:SetSize(16, 0)
	overAbsorb:SetTexture([[Interface\RaidFrame\Shield-Overshield]])
	overAbsorb:SetBlendMode("ADD")
	overAbsorb:SetPoint("TOP")
	overAbsorb:SetPoint("BOTTOM")
	overAbsorb:SetPoint("LEFT", health, "RIGHT", -7, 0)
	overAbsorb:Hide()

	local overHealAbsorb = health:CreateTexture(nil, "OVERLAY")
	overHealAbsorb:SetSize(16, 0)
	overHealAbsorb:SetTexture([[Interface\RaidFrame\Absorb-Overabsorb]])
	overHealAbsorb:SetBlendMode("ADD")
	overHealAbsorb:SetPoint("TOP")
	overHealAbsorb:SetPoint("BOTTOM")
	overHealAbsorb:SetPoint("RIGHT", health, "LEFT", 7, 0)
	overHealAbsorb:Hide()

	self.HealPrediction = {
		healAbsorbBar = hab,
		myBar = mhpb,
		otherBar = ohpb,
		absorbBar = absorb,
		overAbsorbGlow = overAbsorb,
		overHealAbsorbGlow = overHealAbsorb,
		maxOverflow = unit == "target" and 1.25 or 1,
		frequentUpdates = health.frequentUpdates,
		PostUpdate = PostUpdateHealPrediction
	}
end
ns.AddHealPredictionBar = AddHealPredictionBar

local AddOverlay = function(self, unit)
	local overlay = CreateFrame("Frame", self:GetName().."_Overlay", self.Portrait)
	overlay:SetPoint("TOPLEFT", self.Portrait, 0, 1)
	overlay:SetPoint("BOTTOMRIGHT", self.Portrait, 0, -1)

	local tex = overlay:CreateTexture(nil, "BORDER")
	tex:SetAllPoints()
	tex:SetTexture(ns.media.OVERLAY)
	tex:SetVertexColor(0.1, 0.1, 0.1, 0.75)

	if (unit == "target") then
		self.CCWarn = tex
	end

	self.Overlay = overlay
end
ns.AddOverlay = AddOverlay

local AddPortrait = function(self)
	local portrait = CreateFrame("PlayerModel", self:GetName().."_Portrait", self)
	portrait:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 7.5, 10)
	portrait:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -7.5, -7.5)
	portrait:SetFrameLevel(self:GetFrameLevel() + 3)
	portrait:SetBackdrop(ns.media.BACKDROP)
	portrait:SetBackdropColor(0, 0, 0, 1)

	self.Portrait = portrait
end
ns.AddPortrait = AddPortrait

local AddPowerPredictionBar = function(self)
	local mainBar = CreateFrame("StatusBar", nil, self.Power)
	mainBar:SetStatusBarTexture(ns.media.TEXTURE)
	mainBar:SetStatusBarColor(0, 0, 1, 0.5)
	mainBar:SetReverseFill(true)
	mainBar:SetPoint("TOP")
	mainBar:SetPoint("BOTTOM")
	mainBar:SetPoint("RIGHT", self.Power:GetStatusBarTexture())
	mainBar:SetWidth(230)

	self.PowerPrediction = {
		mainBar = mainBar,
	}
end
ns.AddPowerPredictionBar = AddPowerPredictionBar

local AddRangeCheck = function(self)
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

	reputation:EnableMouse(true)
	reputation:SetScript("OnEnter", function(self) self:SetAlpha(1) end)
	reputation:SetScript("OnLeave", function(self) self:SetAlpha(0) end)

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
			GameTooltip:AddLine(format("%s (%s)", name, GetText("FACTION_STANDING_LABEL"..standing, UnitSex("player"))))
			GameTooltip:AddLine(format("%d / %d (%d%%)", value - min, max - min, (value - min) / (max - min) * 100 + 0.5))
		else
			local currentValue = friendRep - friendThreshold
			local maxCurrentValue = (nextFriendThreshold or friendMaxRep) - friendThreshold
			GameTooltip:AddLine(format("%s (%s)", name, friendTextLevel))
			GameTooltip:AddLine(format("%d / %d (%d%%)", currentValue, maxCurrentValue, currentValue / maxCurrentValue * 100 + 0.5))
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
	local color = ns.colors.power.RUNES
	local r, g, b = color[1], color[2], color[3]

	width = (width - maxRunes * spacing - spacing) / maxRunes -- factoring causes rounding issues?
	spacing = width + spacing

	for i = 1, maxRunes do
		local rune = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self.Overlay)
		rune:SetSize(width, height)
		rune:SetPoint("BOTTOMLEFT", (i - 1) * spacing + 1, 1)
		rune:SetStatusBarTexture(ns.media.TEXTURE)
		rune:SetStatusBarColor(r, g, b)
		rune:SetBackdrop(ns.media.BACKDROP)
		rune:SetBackdropColor(0, 0, 0)

		local bg = rune:CreateTexture(nil, "BORDER")
		bg:SetTexture(ns.media.TEXTURE)
		bg:SetAllPoints()
		bg:SetVertexColor(r * 0.5, g * 0.5, b * 0.5)
		runes[i] = rune
	end

	runes.PostUpdateRune = PostUpdateRune
	self.Runes = runes
end
ns.AddRuneBar = AddRuneBar

local AddThreatHighlight = function(self)
	local threat = self:CreateTexture(nil) -- oUF requires that IsObjectType can be called with this
	threat:SetColorTexture(1, 1, 1, 0) -- so that oUF does not try to replace it
	threat.Override = UpdateThreat
	self.Threat = threat
end
ns.AddThreatHighlight = AddThreatHighlight

local AddTotems = function(self, width, height, spacing)
	local totems = {}
	local maxTotems = MAX_TOTEMS + 1

	width = (width - maxTotems * spacing - spacing) / maxTotems -- factoring causes rounding issues?
	spacing = width + spacing

	for i = 1, maxTotems do
		local totem = CreateFrame("StatusBar", "oUF_Rain_Totem"..i, self.Overlay)
		totem:SetStatusBarTexture(ns.media.TEXTURE)
		totem:SetSize(width, height)
		totem:SetMinMaxValues(0, 1)
		local color

		if (playerClass == "SHAMAN") then
			totem:SetPoint("BOTTOMLEFT", (i - 1) * spacing + 1, 1)
			color = ns.colors.totems[SHAMAN_TOTEM_PRIORITIES[i]] or {1, 0, 0}
		elseif (playerClass == "DRUID") then -- Druid's mushrooms
			if (i == 1) then
				totem:SetPoint("TOP", 0, height / 2)
			elseif (i == 2) then
				totem:SetPoint("RIGHT", totems[1], "LEFT", -(spacing - width), 0)
			else
				totem:SetPoint("LEFT", totems[1], "RIGHT", spacing - width, 0)
			end
			color = ns.colors.class[playerClass]
		else
			-- Death knight: Ghoul
			-- Mage
			-- Monk: Statues
			-- Paladin: Consecration
			-- Warlock
			-- Warrior: Banners
			totem:SetPoint("TOP", 0, height / 2)
			color = ns.colors.class[playerClass]
		end

		totem:SetStatusBarColor(color[1], color[2], color[3])
		totem:SetBackdrop(ns.media.BACKDROP)
		totem:SetBackdropColor(0, 0, 0)

		local bg = totem:CreateTexture(nil, "BORDER")
		bg:SetAllPoints()
		bg:SetColorTexture(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5)

		totem:EnableMouse(true)
		totem.UpdateTooltip = function(self)
			GameTooltip:SetTotem(self:GetID())
			GameTooltip:Show()
		end

		totems[i] = totem
	end

	totems.Override = UpdateTotem

	self.Totems = totems
end
ns.AddTotems = AddTotems

--[[ ICONS ]]--

local AddAssistantIcon = function(self)
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

local AddLeaderIcon = function(self)
	local leader = self.Health:CreateTexture(nil, "OVERLAY")
	leader:SetSize(16, 16)
	leader:SetPoint("TOPLEFT", -8.5, 8.5)
	self.Leader = leader
end
ns.AddLeaderIcon = AddLeaderIcon

local AddMasterLooterIcon = function(self)
	local masterLooter = self.Health:CreateTexture(nil, "OVERLAY")
	masterLooter:SetSize(16, 16)
	masterLooter:SetPoint("TOPRIGHT", 8.5, 8.5)
	self.MasterLooter = masterLooter
end
ns.AddMasterLooterIcon = AddMasterLooterIcon

local AddPhaseIcon = function(self)
	local phaseIcon = self.Health:CreateTexture(nil, "OVERLAY")
	phaseIcon:SetSize(16, 16)
	phaseIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
	self.PhaseIcon = phaseIcon
end
ns.AddPhaseIcon = AddPhaseIcon

local AddQuestIcon = function(self)
	local questIcon = self.Health:CreateTexture(nil, "OVERLAY")
	questIcon:SetSize(16, 16)
	questIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
	self.QuestIcon = questIcon
end
ns.AddQuestIcon = AddQuestIcon

local AddRaidIcon = function(self)
	raidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	raidIcon:SetTexture(ns.media.RAIDICONS)
	raidIcon:SetSize(18, 18)
	raidIcon:SetPoint("CENTER", self.Health, "TOP", 0, 0)
	self.RaidIcon = raidIcon
end
ns.AddRaidIcon = AddRaidIcon

local AddRaidRoleIcon = function(self)
	local raidRole = self:CreateTexture(nil, "OVERLAY")
	raidRole:SetSize(16, 16)
	raidRole:SetPoint("BOTTOMRIGHT", -8.5, 8.5)
	self.RaidRole = raidRole
end
ns.AddRaidRoleIcon = AddRaidRoleIcon

-- oUF checks ready status only for raid and party
local AddReadyCheckIcon = function(self)
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

local AddResurrectIcon = function(self)
	local resurrectIcon = self.Health:CreateTexture(nil, "OVERLAY")
	resurrectIcon:SetSize(16, 16)
	resurrectIcon:SetPoint("CENTER")
	self.ResurrectIcon = resurrectIcon
end
ns.AddResurrectIcon = AddResurrectIcon
