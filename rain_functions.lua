local _, ns = ...
local playerClass = ns.playerClass
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitIsFriend = UnitIsFriend
local UnitIsConnected = UnitIsConnected
local UnitIsDeadOrGhost = UnitIsDeadOrGhost
local UnitClass = UnitClass
local UnitIsPlayer = UnitIsPlayer
local UnitPlayerControlled = UnitPlayerControlled
local UnitIsTapped = UnitIsTapped
local UnitIsTappedByPlayer = UnitIsTappedByPlayer
local UnitIsTappedByAllThreatList = UnitIsTappedByAllThreatList

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

local PostUpdatePower = function(Power, unit, cur, max)
	if (not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit)) then
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
	Auras.createdIcons = Auras.createdIcons + 1 -- need to do this

	local button = CreateFrame("Button", nil, Auras)

	local icon = button:CreateTexture(nil, "BORDER")
	icon:SetAllPoints(button)
	icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	button.icon = icon

	local count = PutFontString(button, ns.media.FONT, 8, "OUTLINE", "RIGHT")
	count:SetPoint("BOTTOMRIGHT", 1, 1.5)
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
	local remaining = PutFontString(button, ns.media.FONT, 8, "OUTLINE", "LEFT")
	remaining:SetPoint("TOP", 0, 1)
	button.remaining = remaining

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

local PostUpdateGapIcon = function(Auras, unit, aura, index)
	aura.remaining:Hide()
	aura:SetScript("OnUpdate", nil)
	aura.timeLeft = aura.isDebuff and math.huge or -5
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

local UpdateHealth = function(self, event, unit)
	if (self.unit ~= unit) then return end

	local health = self.Health

	local cur, max = UnitHealth(unit), UnitHealthMax(unit)
	local disconnected = not UnitIsConnected(unit)

	health:SetMinMaxValues(0, max)
	health:SetValue(cur)
	health.disconnected = disconnected

	local r, g, b, t, faded
	if (health.colorDisconnected and disconnected or UnitIsDeadOrGhost(unit)) then
		health:SetValue(max)
		local _, class = UnitClass(unit)
		t = UnitIsPlayer(unit) and not unit:match("raid%d") and self.colors.class[class] or self.colors.disconnected
		faded = true
	elseif (health.colorTapping and not UnitPlayerControlled(unit) and
		UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) and
		not UnitIsTappedByAllThreatList(unit)) then
		t = self.colors.tapped
	elseif (health.colorSmooth) then
		r, g, b = ColorGradient(cur, max, unpack(self.colors.smooth))
	end

	if (t) then
		if (not faded) then
			r, g, b = t[1], t[2], t[3]
		else
			r, g, b = t[1] * 0.5, t[2] * 0.5, t[3] * 0.5
		end
	end

	if (b) then
		health:SetStatusBarColor(r, g, b)
	end
end
ns.UpdateHealth = UpdateHealth

local WarlockPowerPostUpdateVisibility = function(element, spec, power, maxPower)
	local self = element.__owner
	local width = element.width
	local height = element.height
	local spacing = element.spacing

	if (spec) then
		if (spec == 1 or spec == 3) then -- Affliction or Destruction
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

	if (spec ~= 3) then
		for i = 1, 4 do
			element[i]:SetBackdropColor(0, 0, 0)
		end
	end
end

local MAX_POWER_PER_EMBER = MAX_POWER_PER_EMBER
local WarlockPostUpdatePower = function(element, powerType, power, maxPower)
	if (powerType == "BURNING_EMBERS") then
		for i = 1, maxPower do
			if (i <= power / MAX_POWER_PER_EMBER) then
				element[i]:SetBackdropColor(1, 0.5, 0)
			else
				element[i]:SetBackdropColor(0, 0, 0)
			end
		end
	end
end
--[[ END OF PRE AND POST FUNCTIONS ]]--

--[[ LAYOUT FUNCTIONS ]]--
local AddAuras = function(self, unit)
	local auras = CreateFrame("Frame", self:GetName().."_Auras", self)

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
	end
	auras.numBuffs = 3
	auras.numDebuffs = 3
	auras.gap = true
	auras.spacing = 6
	auras.size = (230 - 7 * auras.spacing) / 8
	auras:SetSize(7 * (auras.size + auras.spacing), auras.size + auras.spacing)
	auras.disableCooldown = true
	auras.showType = true
	auras.onlyShowPlayer = false
	auras.CreateIcon = CreateAuraIcon
	auras.PreSetPosition = PreSetPosition
	auras.PostUpdateIcon = PostUpdateIcon
	auras.PostUpdateGapIcon = PostUpdateGapIcon
	auras.buffFilter = nil
	auras.debuffFilter = nil

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
		castbar.SaveZone = safeZone
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

local AddComboPointsBar = function(self, width, height, spacing)
	local comboPoints = {}
	local maxCPoints = MAX_COMBO_POINTS

	for i = 1, maxCPoints do
		local cPoint = self.Overlay:CreateTexture("oUF_Rain_ComboPoint_"..i, "OVERLAY")
		cPoint:SetSize((width - maxCPoints * spacing - spacing) / maxCPoints, height)
		cPoint:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * cPoint:GetWidth() + i * spacing, 1)
		cPoint:SetTexture(unpack(ns.colors.cpoints[i]))
		comboPoints[i] = cPoint
	end

	self.CPoints = comboPoints
end
ns.AddComboPointsBar = AddComboPointsBar

local AddDebuffHighlight = function(self, unit)
	local debuffHighlight = {}

	local texture = self.Health:CreateTexture(nil, "OVERLAY")
	texture:SetAllPoints()
	texture:SetTexture(ns.media.HIGHLIGHTTEXTURE)
	texture:SetBlendMode("ADD")
	texture:SetVertexColor(0, 0, 0, 0)
	debuffHighlight.texture = texture

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

	debuffHighlight.icon = icon
	debuffHighlight.iconOverlay = iconOverlay
	debuffHighlight.filter = ns.cfg.dispelTypeFilter

	self.DebuffHighlight = debuffHighlight
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
		GameTooltip:AddLine(string.format("XP: %s / %s (%d%% - %.1f bars)", BreakUpLargeNumbers(curXP), BreakUpLargeNumbers(maxXP), curXP/maxXP * 100 + 0.5, bars * curXP / maxXP))
		GameTooltip:AddLine(string.format("Remaining: %s (%d%% - %.1f bars)", BreakUpLargeNumbers(maxXP - curXP), (maxXP - curXP) / maxXP * 100 + 0.5, bars * (maxXP - curXP) / maxXP))
		if (rested and rested > 0) then
			GameTooltip:AddLine(string.format("|cff0090ffRested: +%s (%d%%)", BreakUpLargeNumbers(rested), rested / maxXP * 100 + 0.5))
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

	local mhpb = health:CreateTexture(nil, "OVERLAY")
	mhpb:SetTexture(ns.media.TEXTURE)
	mhpb:SetVertexColor(0, 0.5, 0.5, 0.5)

	local ohpb = health:CreateTexture(nil, "OVERLAY")
	ohpb:SetTexture(ns.media.TEXTURE)
	ohpb:SetVertexColor(0, 1, 0, 0.5)

	local absorb = health:CreateTexture(nil, "OVERLAY")
	absorb:SetAlpha(0.5)

	local overAbsorb = health:CreateTexture(nil, "OVERLAY")

	self.RainHealPrediction = {
		myBar = mhpb,
		otherBar = ohpb,
		absorbBar = absorb,
		overAbsorbGlow = overAbsorb,
		maxOverflow = unit == "target" and 1.25 or 1,
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
		local rune = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self.Overlay)
		rune:SetSize((width - maxRunes * spacing - spacing) / maxRunes, height)
		rune:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * rune:GetWidth() + i * spacing, 1)
		rune:SetStatusBarTexture(ns.media.TEXTURE)
		rune:SetBackdrop(ns.media.BACKDROP)
		rune:SetBackdropColor(0, 0, 0)

		local bg = rune:CreateTexture(nil, "BORDER")
		bg:SetTexture(ns.media.TEXTURE)
		bg:SetAllPoints()
		bg.multiplier = 0.5
		rune.bg = bg
		runes[i] = rune
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

	if (status and status > 1) then
		local r, g, b = GetThreatStatusColor(status)
		self.FrameBackdrop:SetBackdropColor(r, g, b, 1)
	else
		self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	end
end
ns.AddThreatHighlight = AddThreatHighlight

local AddTotems = function(self, width, height)
	local totems = {}
	local maxTotems = MAX_TOTEMS

	for i = 1, maxTotems do
		local totem = CreateFrame("StatusBar", "oUF_Rain_Totem"..i, self.Overlay)
		totem:SetStatusBarTexture(ns.media.TEXTURE)
		totem:SetMinMaxValues(0, 1)

		if (playerClass == "SHAMAN") then
			totem:SetSize((215 - maxTotems - 1) / maxTotems, height)
			totem:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / maxTotems) + 1, 0)
			totem:SetStatusBarColor(unpack(ns.colors.totems[SHAMAN_TOTEM_PRIORITIES[i]]))
		elseif (playerClass == "DRUID") then -- Druid's mushrooms
			totem:SetSize(width, height)
			totem:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
				if (i == 1) then
					totem:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
				elseif (i == 2) then
					totem:SetPoint("RIGHT", totems[1], "LEFT", -1, 0)
				else
					totem:SetPoint("LEFT", totems[1], "RIGHT", 1, 0)
				end
		elseif (playerClass == "DEATHKNIGHT") then -- Death knight's ghoul
			totem:SetSize(width, height)
			totem:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
			totem:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
		end

		totem:SetBackdrop(ns.media.BACKDROP)
		totem:SetBackdropColor(0, 0, 0)

		totem:EnableMouse()
--[[
		totems[i]:SetScript("OnMouseUp", function(self, button)
			if (button == "RightButton") then
				DestroyTotem(self:GetID())
			end
		end)
--]]
		totem.UpdateTooltip = function(self)
			GameTooltip:SetTotem(self:GetID())
			--GameTooltip:AddLine(GLYPH_SLOT_REMOVE_TOOLTIP, 1, 0, 0)
			GameTooltip:Show()
		end

		totems[i] = totem
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
		local wpb = CreateFrame("StatusBar", "oUF_Rain_WarlockPowerBar"..i, self.Overlay)
		wpb:SetSize((width - 4 * spacing - spacing) / 4, height)
		wpb:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * wpb:GetWidth() + i * spacing, 1)
		wpb:SetStatusBarTexture(ns.media.TEXTURE)
		wpb:SetBackdrop(ns.media.BACKDROP)
		wpb:SetBackdropColor(0, 0, 0)

		local bg = wpb:CreateTexture(nil, "BORDER")
		bg:SetTexture(ns.media.TEXTURE)
		bg:SetAllPoints()
		bg.multiplier = 0.3
		wpb.bg = bg
		warlockPowerBar[i] = wpb
	end

	warlockPowerBar.PostUpdateVisibility = WarlockPowerPostUpdateVisibility
	warlockPowerBar.PostUpdate = WarlockPostUpdatePower

	self.WarlockPowerBar = warlockPowerBar
end
ns.AddWarlockPowerBar = AddWarlockPowerBar

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
