-- TODO: eclipse bar
-- TODO: vengeance bar??

local _, ns = ...
local cfg = ns.config

local numRunes = MAX_RUNES
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

local function AddRuneBar(self, width, height)
	self.Runes = CreateFrame("Frame", nil, self)
	self.Runes:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
	self.Runes:SetSize(width, height)
	self.Runes:SetBackdrop(cfg.BACKDROP)
	self.Runes:SetBackdropColor(0.25, 0.25, 0.25)

	for i = 1, numRunes do
		self.Runes[i] = CreateFrame("StatusBar", "oUF_Rain_Runes"..i, self)
		self.Runes[i]:SetSize(((width - numRunes + 1) / numRunes), height)
		if (i > 1) then
			self.Runes[i]:SetPoint("LEFT", self.Runes[i-1], "RIGHT", 1, 0)
		else
			self.Runes[i]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
		end
		self.Runes[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.Runes[i]:GetStatusBarTexture():SetHorizTile(false)
		self.Runes[i]:SetStatusBarColor(unpack(runeloadcolors[i])) -- TODO:

		self.Runes[i].bd = self.Runes[i]:CreateTexture(nil, "BORDER")
		self.Runes[i].bd:SetAllPoints()
		self.Runes[i].bd:SetTexture(cfg.TEXTURE)
		self.Runes[i].bd:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddRuneBar = AddRuneBar

local function AddSoulShardsBar(self, width, height)
	self.SoulShards = CreateFrame("Frame", nil, self)
	self.SoulShards:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
	self.SoulShards:SetSize(width, height)
	self.SoulShards:SetBackdrop(cfg.BACKDORP)
	self.SoulShards:SetBackdropColor(0.25, 0.25, 0.25)

	for i = 1, numShards do
		self.SoulShards[i] = CreateFrame("StatusBar", "oUF_Rain_SoulShards"..i, self)
		self.SoulShards[i]:SetSize(((width - numShards + 1) / numShards), height)
		if (i > 1) then
			self.SoulShards[i]:SetPoint("LEFT", self.SoulShards[i-1], "RIGHT", 1, 0)
		else
			self.SoulShards[i]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
		end
		self.SoulShards[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.SoulShards[i]:GetStatusBarTexture():SetHorizTile(false)
		self.SoulShards[i]:SetStatusBarColor(0.50, 0.32, 0.55) -- TODO: oUF.colors.power.SOUL_SHARDS

		self.SoulShards[i].bd = self.SoulShards[i]:CreateTexture(nil, "BORDER")
		self.SoulShards[i].bd:SetAllPoints()
		self.SoulShards[i].bd:SetTexture(cfg.TEXTURE)
		self.SoulShards[i].bd:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddSoulshardsBar = AddSoulShardsBar

local function AddHolyPowerBar(self, width, height)
	self.HolyPower = CreateFrame("Frame", nil, self)
	self.HolyPower:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
	self.HolyPower:SetSize(width, height)
	self.HolyPower:SetBackdrop(cfg.BACKDROP)
	self.HolyPower:SetBackdropColor(0.25, 0.25, 0.25)

	for i = 1, numHoly do
		self.HolyPower[i] = CreateFrame("StatusBar", "oUF_Rain_HolyPower"..i, self)
		self.HolyPower[i]:SetSize(((width - numHoly + 1) / numHoly), height)
		if (i > 1) then
			self.HolyPower[i]:SetPoint("LEFT", self.HolyPower[i-1], "RIGHT", 1, 0)
		else
			self.HolyPower[i]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
		end
		self.HolyPower[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.HolyPower[i]:GetStatusBarTexture():SetHorizTile(false)
		self.HolyPower[i]:SetStatusBarColor(0.95, 0.9, 0.6) -- TODO: oUF_colors.power.HOLY_POWER
		
		self.HolyPower[i].bd = self.HolyPower[i]:CreateTexture(nil, "BORDER")
		self.HolyPower[i].bd:SetAllPoints()
		self.HolyPower[i].bd:SetTexture(cfg.TEXTURE)
		self.HolyPower[i].bd:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddHolyPowerBar = AddHolyPowerBar

local function AddTotemBar(self, width, height)
	self.TotemBar = {}
	self.TotemBar.Destroy = true
	for i = 1, numTotems do
		self.TotemBar[i] = CreateFrame("StatusBar", "oUF_Rain_TotemBar"..i, self)
		self.TotemBar[i]:SetSize(((width - numTotems + 1) / numTotems), height)
		if (i > 1) then
			self.TotemBar[i]:SetPoint("TOPLEFT", self.TotemBar[i-1], "TOPRIGHT", 1, 0)
		else
			self.TotemBar[i]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
		end
		self.TotemBar[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.TotemBar[i]:GetStatusBarTexture():SetHorizTile(false)
		self.TotemBar[i]:SetMinMaxValues(0, 1)
		self.TotemBar[i]:SetBackdrop(cfg.BACKDROP)
		self.TotemBar[i]:SetBackdropColor(0.25, 0.25, 0.25)

		self.TotemBar[i].bg = self.TotemBar[i]:CreateTexture(nil, "BORDER")
		self.TotemBar[i].bg:SetAllPoints()
		self.TotemBar[i].bg:SetTexture(cfg.BACKDROP)
		self.TotemBar[i].bg:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddTotemBar = AddTotemBar

local function AddComboPointsBar(self, width, height)
	self.CPoints = CreateFrame("Frame", nil, self)
	self.CPoints:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
	self.CPoints:SetSize(width, height)
	self.CPoints:SetBackdrop(cfg.BACKDROP)
	self.CPoints:SetBackdropColor(0.25, 0.25, 0.25)

	for i = 1, numCPoints do
		self.CPoints[i] = CreateFrame("StatusBar", "oUF_Rain_CPoints"..i, self)
		self.CPoints[i]:SetSize(((width - numCPoints + 1) / numCPoints), height)
		if (i > 1) then
			self.CPoints[i]:SetPoint("LEFT", self.CPoints[i-1], "RIGHT", 1, 0)
		else
			self.CPoints[i]:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
		end
		self.CPoints[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.CPoints[i]:GetStatusBarTexture():SetHorizTile(false)
		self.CPoints[i]:SetStatusBarColor(unpack(combocolors[i]))

		self.CPoints[i].bd = self.CPoints[i]:CreateTexture(nil, "BORDER")
		self.CPoints[i].bd:SetAllPoints()
		self.CPoints[i].bd:SetTexture(cfg.TEXTURE)
		self.CPoints[i].bd:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddComboPointsBar = AddComboPointsBar

local function AddEclipseBar(self, width, height)
	local eclipseBar = CreateFrame("Frame", nil, self)
	eclipseBar:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -1)
	eclipseBar:SetSize(width, height)
	eclipseBar:SetBackdrop(cfg.BACKDROP)
	eclipseBar:SetBackdropColor(0.25, 0.25, 0.25)
	
	local lunarBar = CreateFrame("StatusBar", "oUF_Rain_LunarBar", eclipseBar)
	lunarBar:SetPoint("LEFT", eclipseBar, "LEFT", 0, 0)
	lunarBar:SetSize(width , height)
	lunarBar:SetStatusBarTexture(cfg.TEXTURE)
	lunarBar:GetStatusBarTexture():SetHorizTile(false)
	lunarBar:SetStatusBarColor(0.34, 0.1, 0.86)
	eclipseBar.LunarBar = lunarBar

	local solarBar = CreateFrame("StatusBar", "oUF_Rain_SolarBar", eclipseBar)
	solarBar:SetPoint("LEFT", lunarBar:GetStatusBarTexture(), "RIGHT", 0, 0)
	solarBar:SetSize(width , height)
	solarBar:SetStatusBarTexture(cfg.TEXTURE)
	solarBar:GetStatusBarTexture():SetHorizTile(false)
	solarBar:SetStatusBarColor(0.95, 0.73, 0.15)
	eclipseBar.SolarBar = solarBar
	
	local eclipseBarText = solarBar:CreateFontString(nil, "OVERLAY")
	eclipseBarText:SetPoint("CENTER", eclipseBar, "CENTER", 0, 0)
	eclipseBarText:SetFont(cfg.FONT, 10, "OUTLINE")
	self:Tag(eclipseBarText, "[pereclipse]%")
	
	self.EclipseBar = eclipseBar
end
ns.AddEclipseBar = AddEclipseBar
