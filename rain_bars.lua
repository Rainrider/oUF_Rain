--[[================================================================
	DESCRIPTION:
	Contrains functions for adding bars for the default oUF elements
	================================================================--]]

local _, ns = ...
local cfg = ns.config
local PutFontString = ns.PutFontString
local playerClass = ns.playerClass

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
	
	self.AltPowerBar.Tooltip = function(self)
		local unit = self.__owner.unit
		-- XXX Temp fix for vehicle
		if (unit == "vehicle" or unit == "pet") then unit = "player" end
		-- XXX
		local powerName = select(10, UnitAlternatePowerInfo(unit))
		local powerTooltip = select(11, UnitAlternatePowerInfo(unit))
		
		if (powerName) then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
			GameTooltip:AddLine(powerName)
			if (powerTooltip and powerTooltip ~= "") then
				GameTooltip:AddLine("\n"..powerTooltip, nil, nil, nil, true)
			end
			GameTooltip:Show()
		end
	end
	
	self.AltPowerBar:EnableMouse()
	self.AltPowerBar:HookScript("OnLeave", GameTooltip_Hide)
	self.AltPowerBar:HookScript("OnEnter", self.AltPowerBar.Tooltip)
end
ns.AddAltPowerBar = AddAltPowerBar

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
		
		self.Castbar.CustomTimeText = ns.CustomCastTimeText
		self.Castbar.CustomDelayText = ns.CustomCastDelayText
		
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
		
		self.Castbar.PostCastStart = ns.PostUpdateCast
		self.Castbar.PostChannelStart = ns.PostUpdateCast
		self.Castbar.PostCastInterruptible = ns.PostUpdateCast
		self.Castbar.PostCastNotInterruptible = ns.PostUpdateCast
	end
end
ns.AddCastbar = AddCastbar

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

local AddHolyPowerBar = function(self, width, height)
	self.HolyPower = {}
	local maxHoly = UnitPowerMax("player", SPELL_POWER_HOLY_POWER)

	for i = 1, maxHoly do
		self.HolyPower[i] = CreateFrame("StatusBar", "oUF_Rain_HolyPower"..i, self.Overlay)
		self.HolyPower[i]:SetSize((215 - maxHoly - 1) / maxHoly, height)
		self.HolyPower[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / maxHoly) + 1, 1)
		self.HolyPower[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.HolyPower[i]:SetStatusBarColor(unpack(ns.colors.power["HOLY_POWER"]))
		self.HolyPower[i]:SetBackdrop(ns.media.BACKDROP)
		self.HolyPower[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddHolyPowerBar = AddHolyPowerBar

local AddOverlay = function(self, unit)
	self.Overlay = CreateFrame("StatusBar", self:GetName().."_Overlay", self.Portrait)
	self.Overlay:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
	self.Overlay:SetPoint("TOPLEFT", self.Portrait, 0, 0)
	self.Overlay:SetPoint("BOTTOMRIGHT", self.Portrait, 1, -1)
	self.Overlay:SetStatusBarTexture(ns.media.OVERLAY)
	self.Overlay:SetStatusBarColor(0.1, 0.1, 0.1, 0.75)
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

local AddShadowOrbsBar = function(self, width, height, spacing)
	self.ShadowOrbs = {}
	local maxOrbs = PRIEST_BAR_NUM_ORBS

	for i = 1, maxOrbs do
		self.ShadowOrbs[i] = self.Overlay:CreateTexture("oUF_Rain_ShadowOrb_"..i, "OVERLAY")
		self.ShadowOrbs[i]:SetSize((width - maxOrbs * spacing - spacing) / maxOrbs, height)
		self.ShadowOrbs[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * self.ShadowOrbs[i]:GetWidth() + i * spacing, 1)
		self.ShadowOrbs[i]:SetTexture(unpack(ns.colors.power["SOUL_SHARDS"]))
	end
end
ns.AddShadowOrbsBar = AddShadowOrbsBar

local AddSoulShardsBar = function(self, width, height)
	self.SoulShards = {}
	local maxShards = UnitPowerMax("player", SPELL_POWER_SOUL_SHARDS)

	for i = 1, maxShards do
		self.SoulShards[i] = CreateFrame("StatusBar", "oUF_Rain_SoulShard"..i, self.Overlay)
		self.SoulShards[i]:SetSize((215 - maxShards - 1) / maxShards, height)
		self.SoulShards[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / maxShards) + 1, 1)
		self.SoulShards[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.SoulShards[i]:SetStatusBarColor(unpack(ns.colors.power["SOUL_SHARDS"]))
		self.SoulShards[i]:SetBackdrop(ns.media.BACKDROP)
		self.SoulShards[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddSoulshardsBar = AddSoulShardsBar

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
		elseif (playerClass) == "DEATHKNIGHT" then -- Death knight's ghoul
			self.Totems[i]:SetSize(width, height)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
			self.Totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
		end

		self.Totems[i]:SetBackdrop(ns.media.BACKDROP)
		self.Totems[i]:SetBackdropColor(0, 0, 0)

		self.Totems[i].Destroy = CreateFrame("Button", nil, self.Totems[i])
		self.Totems[i].Destroy:SetAllPoints()
		self.Totems[i].Destroy:RegisterForClicks("RightButtonUp")
		self.Totems[i].Destroy:SetScript("OnClick", function()
			if (IsShiftKeyDown()) then
				DestroyTotem(self.Totems[i]:GetID())
			end
		end)

		self.Totems[i].Destroy:EnableMouse()
		self.Totems[i].Destroy:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			GameTooltip:SetTotem(self:GetParent():GetID())
			GameTooltip:AddLine("|cffff0000"..GLYPH_SLOT_REMOVE_TOOLTIP.."|r") -- <Shift Right Click to Remove>
			GameTooltip:Show()
		end)
		self.Totems[i].Destroy:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end

	self.Totems.Override = ns.UpdateTotem
end
ns.AddTotems = AddTotems
--[[
	NOTES: Just an example for icons with cooldowns --]]
--[[
local function AddTotems(self, width, height)
	local Totems = {}

	for i = 1, MAX_TOTEMS do
		Totems[i] = CreateFrame("Button", "Totem"..i, self)
		Totems[i]:SetSize(40, 40)
		Totems[i]:SetPoint("BOTTOMLEFT", self, "TOPLEFT", (i - 1) * 42, 10)

		Totems[i].Icon = Totems[i]:CreateTexture(nil, "OVERLAY")
		Totems[i].Icon:SetAllPoints()
		Totems[i].Cooldown = CreateFrame("Cooldown", nil, Totems[i])
		Totems[i].Cooldown:SetAllPoints()
		Totems[i].Cooldown:SetReverse(true)

		Totems[i]:EnableMouse() -- for tooltips
		Totems[i]:RegisterForClicks("RightButtonUp") -- Rightclick for destroy
	end

	self.Totems = Totems
end
ns.AddTotems = AddTotems
--]]
