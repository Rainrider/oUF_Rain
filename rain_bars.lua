-- TODO: eclipse bar
-- TODO: vengeance bar??

local _, ns = ...
local cfg = ns.config
local PutFontString = ns.PutFontString

local numRunes = 6 -- MAX_RUNES does not function any more
local numHoly = MAX_HOLY_POWER
local numShards = SHARD_BAR_NUM_SHARDS
local numTotems = MAX_TOTEMS
local numCPoints = MAX_COMBO_POINTS

local runeloadcolors = {
	[1] = {0.69, 0.31, 0.31},
	[2] = {0.69, 0.31, 0.31},
	[3] = {0.33, 0.59, 0.33},
	[4] = {0.33, 0.59, 0.33},
	[5] = {0.31, 0.45, 0.63},
	[6] = {0.31, 0.45, 0.63},
}

local combocolors = {
	[1] = {1, 0.68, 0.35},
	[2] = {254/255, 154/255, 46/255},
	[3] = {1, 128/255, 0},
	[4] = {223/255, 116/255, 1/255},
	[5] = {180/255, 95/255, 4/255},
}

local function AddPortrait(self, unit)
	self.Portrait = CreateFrame("PlayerModel", self:GetName().."_Portrait", self)
	self.Portrait:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 7.5, 10)
	self.Portrait:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -7.5, -7.5)
	self.Portrait:SetFrameLevel(self:GetFrameLevel() + 3)
	self.Portrait:SetBackdrop(cfg.BACKDROP)
	self.Portrait:SetBackdropColor(0, 0, 0, 1)
end
ns.AddPortrait = AddPortrait

local function AddOverlay(self, unit)
	self.Overlay = CreateFrame("StatusBar", self:GetName().."_Overlay", self)
	self.Overlay:SetParent(self.Portrait)
	self.Overlay:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
	self.Overlay:SetAllPoints()
	self.Overlay:SetStatusBarTexture(cfg.OVERLAY)
	self.Overlay:SetStatusBarColor(0.1, 0.1, 0.1, 0.75)
end
ns.AddOverlay = AddOverlay

local function AddCastbar(self, unit)
	self.Castbar = CreateFrame("StatusBar", self:GetName().."_Castbar", (unit == "player" or unit == "target") and self.Portrait or self.Power)
	self.Castbar:SetStatusBarTexture(cfg.TEXTURE)
	self.Castbar:GetStatusBarTexture():SetHorizTile(false)
	self.Castbar:SetStatusBarColor(0.55, 0.57, 0.61)
	self.Castbar:SetAlpha(0.75)
	
	if (unit == "player" or unit == "target") then
		self.Castbar:SetAllPoints(self.Overlay)
		
		self.Castbar.Time = PutFontString(self.Overlay, cfg.FONT2, 12, nil, "RIGHT")
		self.Castbar.Time:SetPoint("RIGHT", -3.5, 3)
		self.Castbar.Time:SetTextColor(0.84, 0.75, 0.65)
		
		self.Castbar.Text = PutFontString(self.Overlay, cfg.FONT2, 12, nil, "LEFT")
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
		self.Castbar.SafeZone:SetTexture(cfg.TEXTURE)
		self.Castbar.SafeZone:SetVertexColor(0.69, 0.31, 0.31, 0.75)
	end
	
	if (unit == "target") then
		self.Castbar.Icon = self.Castbar:CreateTexture(nil, "ARTWORK")
		self.Castbar.Icon:SetPoint("RIGHT", self.Castbar, "LEFT", -15, 0)
		self.Castbar.Icon:SetSize(32, 32)
		self.Castbar.Icon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
		--[[
		self.IconOverlay = self.Castbar:CreateTexture(nil, "OVERLAY")
		self.IconOverlay:SetPoint("TOPLEFT", self.Castbar.Icon, -2, 2)
		self.IconOverlay:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, 2, -2)
		self.IconOverlay:SetTexture(cfg.BTNTEXTURE)
		self.IconOverlay:SetVertexColor(0.84, 0.75, 0.65)
		--]]
		self.IconBackdrop = CreateFrame("Frame", nil, self.Castbar)
		self.IconBackdrop:SetPoint("TOPLEFT", self.Castbar.Icon, -3, 3)
		self.IconBackdrop:SetPoint("BOTTOMRIGHT", self.Castbar.Icon, 3, -3)
		self.IconBackdrop:SetBackdrop(cfg.BACKDROP2)
		self.IconBackdrop:SetBackdropColor(0, 0, 0, 0)
		self.IconBackdrop:SetBackdropBorderColor(0, 0, 0)
	end
end
ns.AddCastbar = AddCastbar

local function AddRuneBar(self, width, height)
	self.Runes = CreateFrame("Frame", "oUF_Rain_Runebar", self)
	self.Runes:SetPoint("BOTTOMLEFT", self.Overlay, 1, 1)
	self.Runes:SetPoint("BOTTOMRIGHT", self.Overlay, -1, 1)
	self.Runes:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	self.Runes:SetBackdrop(cfg.BACKDROP)
	self.Runes:SetBackdropColor(0, 0, 0)

	for i = 1, numRunes do
		self.Runes[i] = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self)
		self.Runes[i]:SetSize((215 - numRunes - 1) / numRunes, height)
		self.Runes[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numRunes) + 1, 1)
		self.Runes[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.Runes[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.Runes[i]:GetStatusBarTexture():SetHorizTile(false)
		self.Runes[i]:SetStatusBarColor(unpack(runeloadcolors[i]))
		self.Runes[i]:SetBackdrop(cfg.BACKDROP)
		self.Runes[i]:SetBackdropColor(0, 0, 0)
		--[[
		self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
		self.Runes[i].bg:SetAllPoints()
		self.Runes[i].bg:SetTexture(cfg.TEXTURE)
		self.Runes[i].bg:SetVertexColor(0.15, 0.15, 0.15)--]]
	end
end
ns.AddRuneBar = AddRuneBar

local function AddSoulShardsBar(self, width, height)
	self.SoulShards = {}
	
	for i = 1, numShards do
		self.SoulShards[i] = CreateFrame("StatusBar", "oUF_Rain_SoulShard"..i, self)
		self.SoulShards[i]:SetSize((215 - numShards - 1) / numShards, height)
		self.SoulShards[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numShards) + 1, 1)
		self.SoulShards[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.SoulShards[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.SoulShards[i]:GetStatusBarTexture():SetHorizTile(false)
		self.SoulShards[i]:SetStatusBarColor(0.50, 0.32, 0.55) -- TODO: oUF.colors.power.SOUL_SHARDS
		self.SoulShards[i]:SetBackdrop(cfg.BACKDROP)
		self.SoulShards[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddSoulshardsBar = AddSoulShardsBar

local function AddHolyPowerBar(self, width, height)
	self.HolyPower = {}

	for i = 1, numHoly do
		self.HolyPower[i] = CreateFrame("StatusBar", "oUF_Rain_HolyPower"..i, self)
		self.HolyPower[i]:SetSize((215 - numHoly - 1) / numHoly, height)
		self.HolyPower[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numHoly) + 1, 1)
		self.HolyPower[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.HolyPower[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.HolyPower[i]:GetStatusBarTexture():SetHorizTile(false)
		self.HolyPower[i]:SetStatusBarColor(0.95, 0.9, 0.6) -- TODO: oUF_colors.power.HOLY_POWER
		self.HolyPower[i]:SetBackdrop(cfg.BACKDROP)
		self.HolyPower[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddHolyPowerBar = AddHolyPowerBar

local function AddTotemBar(self, width, height)
	if (not IsAddOnLoaded("oUF_TotemBar")) then return end

	self.TotemBar = {}
	self.TotemBar.Destroy = true
	
	for i = 1, numTotems do
		self.TotemBar[i] = CreateFrame("StatusBar", "oUF_Rain_TotemBar"..i, self)
		self.TotemBar[i]:SetSize((215 - numTotems - 1) / numTotems, height)
		self.TotemBar[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numTotems) + 1, 1)
		self.TotemBar[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.TotemBar[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.TotemBar[i]:GetStatusBarTexture():SetHorizTile(false)
		self.TotemBar[i]:SetMinMaxValues(0, 1)
		self.TotemBar[i]:SetBackdrop(cfg.BACKDROP)
		self.TotemBar[i]:SetBackdropColor(0, 0, 0)

		self.TotemBar[i].bg = self.TotemBar[i]:CreateTexture(nil, "BORDER")
		self.TotemBar[i].bg:SetAllPoints()
		self.TotemBar[i].bg:SetTexture(cfg.TEXTURE)
		self.TotemBar[i].bg:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddTotemBar = AddTotemBar

local function AddComboPointsBar(self, width, height)
	self.CPoints = {}
	
	for i = 1, numCPoints do
		self.CPoints[i] = CreateFrame("StatusBar", "oUF_Rain_CPoint_"..i, self)
		self.CPoints[i]:SetSize((215 - numCPoints - 1) / numCPoints, height) -- frame width=230 ; Overlay width=215 ; 5 cp + 6 * 1 px = 215 => 1cp = 209/5
		self.CPoints[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numCPoints) + 1, 1)
		self.CPoints[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
		self.CPoints[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.CPoints[i]:GetStatusBarTexture():SetHorizTile(false)
		self.CPoints[i]:SetStatusBarColor(unpack(combocolors[i]))
		self.CPoints[i]:SetBackdrop(cfg.BACKDROP)
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
	eclipseBar:SetBackdrop(cfg.BACKDROP)
	eclipseBar:SetBackdropColor(0, 0, 0)
	
	local lunarBar = CreateFrame("StatusBar", "oUF_Rain_LunarBar", eclipseBar)
	lunarBar:SetAllPoints(eclipseBar)
	lunarBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	lunarBar:SetStatusBarTexture(cfg.TEXTURE)
	lunarBar:GetStatusBarTexture():SetHorizTile(false)
	lunarBar:SetStatusBarColor(0.34, 0.1, 0.86)
	eclipseBar.LunarBar = lunarBar

	local solarBar = CreateFrame("StatusBar", "oUF_Rain_SolarBar", eclipseBar)
	solarBar:SetHeight(5)
	solarBar:SetWidth(213)
	solarBar:SetPoint("LEFT", lunarBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	--solarBar:SetPoint("RIGHT", eclipseBar, "RIGHT", 0, 0)
	solarBar:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
	solarBar:SetStatusBarTexture(cfg.TEXTURE)
	solarBar:GetStatusBarTexture():SetHorizTile(false)
	solarBar:SetStatusBarColor(0.95, 0.73, 0.15)
	eclipseBar.SolarBar = solarBar
	
	local eclipseBarText = solarBar:CreateFontString(nil, "OVERLAY")
	eclipseBarText:SetPoint("CENTER", eclipseBar, "CENTER", 0, 0)
	eclipseBarText:SetFont(cfg.FONT2, 10, "OUTLINE")
	self:Tag(eclipseBarText, "[pereclipse]%")
	
	self.EclipseBar = eclipseBar
end
ns.AddEclipseBar = AddEclipseBar