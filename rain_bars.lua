--[[================================================================
	DESCRIPTION:
	Contrains functions for adding bars for the default oUF elements
	================================================================--]]

local _, ns = ...
local cfg = ns.config
local PutFontString = ns.PutFontString

local numRunes = 6 -- MAX_RUNES does not function any more
local numHoly = MAX_HOLY_POWER
local numShards = SHARD_BAR_NUM_SHARDS
local numCPoints = MAX_COMBO_POINTS
local playerClass = cfg.playerClass

local function AddAltPowerBar(self)
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
		if unit == "vehicle" or unit == "pet" then unit = "player" end
		-- XXX
		local powerName = select(10, UnitAlternatePowerInfo(unit))
		local powerTooltip = select(11, UnitAlternatePowerInfo(unit))
		
		if powerName then
			GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
			GameTooltip:AddLine(powerName)
			if powerTooltip and powerTooltip ~= "" then
				GameTooltip:AddLine("\n"..powerTooltip, nil, nil, nil, true)
			end
			GameTooltip:Show()
		end
	end
	
	self.AltPowerBar:EnableMouse()
	self.AltPowerBar:HookScript("OnLeave", GameTooltip_Hide)
	self.AltPowerBar:HookScript("OnEnter", self.AltPowerBar.Tooltip)
	
	self.AltPowerBar.PostUpdate = ns.PostUpdateAltPower
end
ns.AddAltPowerBar = AddAltPowerBar

local function AddCastbar(self, unit)
	self.Castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", (unit == "player" or unit == "target") and self.Portrait or self.Power)
	self.Castbar:SetStatusBarTexture(ns.media.TEXTURE)
	self.Castbar:GetStatusBarTexture():SetHorizTile(false)
	self.Castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	self.Castbar:SetAlpha(0.75)
	
	if (unit == "player" or unit == "target") then
		self.Castbar:SetAllPoints(self.Overlay)
		
		self.Castbar.Time = PutFontString(self.Overlay, ns.media.FONT2, 12, nil, "RIGHT")
		self.Castbar.Time:SetPoint("RIGHT", -3.5, 3)
		self.Castbar.Time:SetTextColor(0.84, 0.75, 0.65)
		
		self.Castbar.CustomTimeText = ns.CustomCastTimeText
		self.Castbar.CustomDelayText = ns.CustomCastDelayText
		
		self.Castbar.Text = PutFontString(self.Overlay, ns.media.FONT2, 12, nil, "LEFT")
		self.Castbar.Text:SetPoint("LEFT", 3.5, 3)
		self.Castbar.Text:SetPoint("RIGHT", self.Castbar.Time, "LEFT", -3.5, 0)
		self.Castbar.Text:SetTextColor(0.84, 0.75, 0.65)
		
		self.Castbar:HookScript("OnShow", function() self.Castbar.Text:Show(); self.Castbar.Time:Show() end)
		self.Castbar:HookScript("OnHide", function() self.Castbar.Text:Hide(); self.Castbar.Time:Hide() end)
		
	else
		self.Castbar:SetAllPoints(self.Power)
	end
	
	if (unit == "player") then
		self.Castbar.SafeZone = self.Castbar:CreateTexture(nil, "ARTWORK")
		self.Castbar.SafeZone:SetTexture(ns.media.TEXTURE)
		self.Castbar.SafeZone:SetVertexColor(0.69, 0.31, 0.31, 0.75)
	end
	
	if unit == "target" or unit:match("boss%d") or unit == "focus" then
		self.Castbar.Icon = self.Castbar:CreateTexture(nil, "ARTWORK")
		
		self.Castbar.IconOverlay = self.Castbar:CreateTexture(nil, "OVERLAY")
		self.Castbar.IconOverlay:SetTexture(ns.media.BTNTEXTURE)
		self.Castbar.IconOverlay:SetVertexColor(0.84, 0.75, 0.65)
		
		if unit == "target" then
			self.Castbar.Icon:SetPoint("RIGHT", self.Castbar, "LEFT", -15, 0)
			self.Castbar.Icon:SetSize(32, 32)
			self.Castbar.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, -5, 5)
			self.Castbar.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, 5, -5)
		else
			self.Castbar.Icon:SetSize(22, 22)
			self.Castbar.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, -3, 3)
			self.Castbar.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, 3, -3)
			if unit == "focus" then
				self.Castbar.Icon:SetPoint("BOTTOMLEFT", self, "BOTTOMRIGHT", 7.5, 0)
			else
				self.Castbar.Icon:SetPoint("BOTTOMRIGHT", self, "BOTTOMLEFT", -7.5, 0)
			end
		end
		self.Castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		
		self.Castbar.PostCastStart = ns.PostCastStart
		self.Castbar.PostChannelStart = ns.PostChannelStart
		self.Castbar.PostCastInterruptible = ns.PostCastInterruptible
		self.Castbar.PostCastNotInterruptible = ns.PostCastNotInterruptible
	end
end
ns.AddCastbar = AddCastbar

local function AddComboPointsBar(self, width, height)
	self.CPoints = {}
	
	for i = 1, numCPoints do
		self.CPoints[i] = CreateFrame("StatusBar", "oUF_Rain_CPoint_"..i, self)
		self.CPoints[i]:SetSize((215 - numCPoints - 1) / numCPoints, height) -- frame width=230 ; Overlay width=215 ; 5 cp + 6 * 1 px = 215 => 1cp = 209/5
		self.CPoints[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numCPoints) + 1, 1)
		self.CPoints[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.CPoints[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.CPoints[i]:GetStatusBarTexture():SetHorizTile(false)
		self.CPoints[i]:SetStatusBarColor(unpack(ns.colors.cpoints[i]))
		self.CPoints[i]:SetBackdrop(ns.media.BACKDROP)
		self.CPoints[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddComboPointsBar = AddComboPointsBar

local function AddEclipseBar(self, width, height)
	local eclipseBar = CreateFrame("Frame", "oUF_Rain_EclipseBar", self)
	eclipseBar:SetHeight(5)
	eclipseBar:SetPoint("BOTTOMLEFT", self.Overlay, 1, 1)
	eclipseBar:SetPoint("BOTTOMRIGHT", self.Overlay, -1, 1)
	eclipseBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	eclipseBar:SetBackdrop(ns.media.BACKDROP)
	eclipseBar:SetBackdropColor(0, 0, 0)
	
	local lunarBar = CreateFrame("StatusBar", "oUF_Rain_LunarBar", eclipseBar)
	lunarBar:SetAllPoints(eclipseBar)
	lunarBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	lunarBar:SetStatusBarTexture(ns.media.TEXTURE)
	lunarBar:GetStatusBarTexture():SetHorizTile(false)
	lunarBar:SetStatusBarColor(0.34, 0.1, 0.86)
	eclipseBar.LunarBar = lunarBar

	local solarBar = CreateFrame("StatusBar", "oUF_Rain_SolarBar", eclipseBar)
	solarBar:SetHeight(5)
	solarBar:SetWidth(213)
	solarBar:SetPoint("LEFT", lunarBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	--solarBar:SetPoint("RIGHT", eclipseBar, "RIGHT", 0, 0)
	solarBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	solarBar:SetStatusBarTexture(ns.media.TEXTURE)
	solarBar:GetStatusBarTexture():SetHorizTile(false)
	solarBar:SetStatusBarColor(0.95, 0.73, 0.15)
	eclipseBar.SolarBar = solarBar
	
	local eclipseBarText = PutFontString(solarBar, ns.media.FONT2, 10, "OUTLINE", "CENTER")
	eclipseBarText:SetPoint("CENTER", eclipseBar, 0, 0)
	self:Tag(eclipseBarText, "[pereclipse]%")
	
	self.EclipseBar = eclipseBar
end
ns.AddEclipseBar = AddEclipseBar

local function AddHealPredictionBar(self, unit)
	local mhpb = CreateFrame("StatusBar", self:GetName().."PlayersHealBar", self.Health)
	mhpb:SetPoint("TOPLEFT", self.Health:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	mhpb:SetPoint("BOTTOMLEFT", self.Health:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	mhpb:SetWidth((unit == "player" or unit == "target") and 230 or 110)
	mhpb:SetStatusBarTexture(ns.media.TEXTURE)
	mhpb:SetStatusBarColor(0.5, 0.5, 0, 0.25)

	local ohpb = CreateFrame("StatusBar", self:GetName().."OthersHealBar", self.Health)
	ohpb:SetPoint("TOPLEFT", mhpb:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	ohpb:SetPoint("BOTTOMLEFT", mhpb:GetStatusBarTexture(), "BOTTOMRIGHT", 0, 0)
	ohpb:SetWidth((unit == "player" or unit == "target") and 230 or 110)
	ohpb:SetStatusBarTexture(ns.media.TEXTURE)
	ohpb:SetStatusBarColor(0, 1, 0, 0.25)

	self.HealPrediction = {
		myBar = mhpb,
		otherBar = ohpb,
		maxOverflow = unit == "target" and 1.25 or 1,
	}
end
ns.AddHealPredictionBar = AddHealPredictionBar

local function AddHolyPowerBar(self, width, height)
	self.HolyPower = {}

	for i = 1, numHoly do
		self.HolyPower[i] = CreateFrame("StatusBar", "oUF_Rain_HolyPower"..i, self)
		self.HolyPower[i]:SetSize((215 - numHoly - 1) / numHoly, height)
		self.HolyPower[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numHoly) + 1, 1)
		self.HolyPower[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.HolyPower[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.HolyPower[i]:GetStatusBarTexture():SetHorizTile(false)
		--self.HolyPower[i]:SetStatusBarColor(0.95, 0.9, 0.6) -- TODO: oUF_colors.power.HOLY_POWER
		self.HolyPower[i]:SetStatusBarColor(unpack(ns.colors.power["HOLY_POWER"]))
		self.HolyPower[i]:SetBackdrop(ns.media.BACKDROP)
		self.HolyPower[i]:SetBackdropColor(0, 0, 0)
	end
	
	self.HolyPower.PostUpdate = ns.PostUpdateClassBar
end
ns.AddHolyPowerBar = AddHolyPowerBar

local function AddOverlay(self, unit)
	self.Overlay = CreateFrame("StatusBar", self:GetName().."_Overlay", self.Portrait)
	self.Overlay:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
	self.Overlay:SetPoint("TOPLEFT", self.Portrait, 0, 0)
	self.Overlay:SetPoint("BOTTOMRIGHT", self.Portrait, 0, -1)
	self.Overlay:SetStatusBarTexture(ns.media.OVERLAY)
	self.Overlay:SetStatusBarColor(0.1, 0.1, 0.1, 0.75)
end
ns.AddOverlay = AddOverlay

local function AddPortrait(self, unit)
	self.Portrait = CreateFrame("PlayerModel", self:GetName().."_Portrait", self)
	self.Portrait:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 7.5, 10)
	self.Portrait:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -7.5, -7.5)
	self.Portrait:SetFrameLevel(self:GetFrameLevel() + 3)
	self.Portrait:SetBackdrop(ns.media.BACKDROP)
	self.Portrait:SetBackdropColor(0, 0, 0, 1)
end
ns.AddPortrait = AddPortrait

local function AddRuneBar(self, width, height)
	self.Runes = CreateFrame("Frame", "oUF_Rain_Runebar", self)
	self.Runes:SetPoint("BOTTOMLEFT", self.Overlay, 1, 1)
	self.Runes:SetPoint("BOTTOMRIGHT", self.Overlay, -1, 1)
	self.Runes:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	self.Runes:SetBackdrop(ns.media.BACKDROP)
	self.Runes:SetBackdropColor(0, 0, 0)

	for i = 1, numRunes do
		self.Runes[i] = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self.Runes)
		self.Runes[i]:SetSize((215 - numRunes - 1) / numRunes, height)
		self.Runes[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numRunes) + 1, 1)
		self.Runes[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.Runes[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.Runes[i]:GetStatusBarTexture():SetHorizTile(false)
		self.Runes[i]:SetBackdrop(ns.media.BACKDROP)
		self.Runes[i]:SetBackdropColor(0, 0, 0)
	end
	
	self.Runes:RegisterEvent("UNIT_ENTERED_VEHICLE", ns.PostUpdateClassBar)
	self.Runes:RegisterEvent("UNIT_EXITED_VEHICLE", ns.PostUpdateClassBar)
end
ns.AddRuneBar = AddRuneBar

local function AddSoulShardsBar(self, width, height)
	self.SoulShards = {}

	for i = 1, numShards do
		self.SoulShards[i] = CreateFrame("StatusBar", "oUF_Rain_SoulShard"..i, self)
		self.SoulShards[i]:SetSize((215 - numShards - 1) / numShards, height)
		self.SoulShards[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numShards) + 1, 1)
		self.SoulShards[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.SoulShards[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.SoulShards[i]:GetStatusBarTexture():SetHorizTile(false)
		self.SoulShards[i]:SetStatusBarColor(unpack(ns.colors.power["SOUL_SHARDS"]))
		self.SoulShards[i]:SetBackdrop(ns.media.BACKDROP)
		self.SoulShards[i]:SetBackdropColor(0, 0, 0)
	end
	
	self.SoulShards.PostUpdate = ns.PostUpdateClassBar
end
ns.AddSoulshardsBar = AddSoulShardsBar

local function AddTotems(self, width, height)
	self.Totems = {}
	local numTotems = MAX_TOTEMS
	
	for i = 1, numTotems do
		self.Totems[i] = CreateFrame("StatusBar", "oUF_Rain_Totem"..i, self)
		self.Totems[i]:SetStatusBarTexture(ns.media.TEXTURE)
		self.Totems[i]:SetMinMaxValues(0, 1)
		
		if playerClass == "SHAMAN" then
			self.Totems[i]:SetSize((215 - numTotems - 1) / numTotems, height)
			self.Totems[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numTotems) + 1, 1)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.totems[i]))
		elseif playerClass == "DRUID" then -- Druid's mushrooms
			self.Totems[i]:SetSize(width, height)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
				if i == 1 then
					self.Totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
				elseif i == 2 then
					self.Totems[i]:SetPoint("RIGHT", self.Totems[1], "LEFT", -1, 0)
				else
					self.Totems[i]:SetPoint("LEFT", self.Totems[1], "RIGHT", 1, 0)
				end
		elseif playerClass == "DEATHKNIGHT" then -- Death knight's ghoul
			self.Totems[i]:SetSize(width, height)
			self.Totems[i]:SetStatusBarColor(unpack(ns.colors.class[playerClass]))
			self.Totems[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
		end
		
		self.Totems[i]:SetBackdrop(ns.media.BACKDROP)
		self.Totems[i]:SetBackdropColor(0, 0, 0)
		self.Totems[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		
		self.Totems[i].Destroy = CreateFrame("Button", nil, self.Totems[i])
		self.Totems[i].Destroy:SetAllPoints()
		self.Totems[i].Destroy:RegisterForClicks("RightButtonUp")
		self.Totems[i].Destroy:SetScript("OnClick", function()
			if IsShiftKeyDown() then
				DestroyTotem(i)
			end
		end)
		
		self.Totems[i].Destroy:EnableMouse()
		self.Totems[i].Destroy:SetScript("OnEnter", function(self)
			GameTooltip:SetOwner(self, "ANCHOR_BOTTOMRIGHT")
			local totem = self:GetParent()
			GameTooltip:SetTotem(totem:GetID())
			GameTooltip:AddLine("|cffff0000"..GLYPH_SLOT_REMOVE_TOOLTIP.."|r") -- <Shift Right Click to Remove>
			GameTooltip:Show()
		end)
		self.Totems[i].Destroy:SetScript("OnLeave", function()
			GameTooltip:Hide()
		end)
	end
	
	self.Totems.PostUpdate = ns.PostUpdateTotems
end
ns.AddTotems = AddTotems

--[[
	NOTES: Just an example for icons with cooldowns
local function AddTotems(self, width, height)
	Totems = {}

	for i = 1, MAX_TOTEMS do
		Totems[i] = CreateFrame("Botton", "Totem"..i, self)
		Totems[i]:SetSize(40, 40)
		Totems[i]:SetPoint(anchor whereever you want)

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
--]]
