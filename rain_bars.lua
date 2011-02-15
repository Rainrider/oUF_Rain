-- TODO: eclipse bar
-- TODO: vengeance bar??

local _, ns = ...
local cfg = ns.config

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

local function AddRuneBar(self, width, height)
	self.Runes = CreateFrame("Frame", self:GetName().."_RunesBar", self)
	self.Runes:SetPoint("BOTTOMLEFT", self.Portrait, 1, 1)
	self.Runes:SetPoint("BOTTOMRIGHT", self.Portrait, -1, 1)
	self.Runes:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
	self.Runes:SetBackdrop(cfg.BACKDROP)
	self.Runes:SetBackdropColor(0, 0, 0)

	for i = 1, numRunes do
		self.Runes[i] = CreateFrame("StatusBar", "oUF_Rain_Rune"..i, self)
		self.Runes[i]:SetSize((215 - numRunes - 1) / numRunes, height)
		self.Runes[i]:SetPoint("BOTTOMLEFT", self.Portrait, (i - 1) * (214 / numRunes) + 1, 1)
		self.Runes[i]:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
		self.Runes[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.Runes[i]:GetStatusBarTexture():SetHorizTile(false)
		self.Runes[i]:SetStatusBarColor(unpack(runeloadcolors[i]))
		self.Runes[i]:SetBackdrop(cfg.BACKDROP)
		self.Runes[i]:SetBackdropColor(0, 0, 0)
		--[[
		self.Runes[i].bg = self.Runes[i]:CreateTexture(nil, "BORDER")
		self.Runes[i].bg:SetAllPoints()
		self.Runes[i].bg:SetTexture(normtex)
		self.Runes[i].bg:SetVertexColor(0.15, 0.15, 0.15)--]]
	end
end
ns.AddRuneBar = AddRuneBar

local function AddSoulShardsBar(self, width, height)
	self.SoulShards = {}
	
	for i = 1, numShards do
		self.SoulShards[i] = CreateFrame("StatusBar", "oUF_Rain_SoulShards"..i, self)
		self.SoulShards[i]:SetSize((215 - numShards - 1) / numShards, height)
		self.SoulShards[i]:SetPoint("BOTTOMLEFT", self.Portrait, (i - 1) * (214 / numShards) + 1, 1)
		self.SoulShards[i]:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
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
		self.HolyPower[i]:SetPoint("BOTTOMLEFT", self.Portrait, (i - 1) * (214 / numHoly) + 1, 1)
		self.HolyPower[i]:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
		self.HolyPower[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.HolyPower[i]:GetStatusBarTexture():SetHorizTile(false)
		self.HolyPower[i]:SetStatusBarColor(0.95, 0.9, 0.6) -- TODO: oUF_colors.power.HOLY_POWER
		self.HolyPower[i]:SetBackdrop(cfg.BACKDROP)
		self.HolyPower[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddHolyPowerBar = AddHolyPowerBar

local function AddTotemBar(self, width, height)
	self.TotemBar = {}
	self.TotemBar.Destroy = true
	
	for i = 1, numTotems do
		self.TotemBar[i] = CreateFrame("StatusBar", "oUF_Rain_TotemBar"..i, self)
		self.TotemBar[i]:SetSize((215 - numTotems - 1) / numTotems, height)
		self.TotemBar[i]:SetPoint("BOTTOMLEFT", self.Portrait, (i - 1) * (214 / numTotems) + 1, 1)
		self.TotemBar[i]:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
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
		self.CPoints[i] = CreateFrame("StatusBar", self:GetName().."CPoint_"..i, self)
		self.CPoints[i]:SetSize((215 - numCPoints - 1) / numCPoints, height) -- frame width=230 ; portrait width=215 ; 5 cp + 6 * 1 px = 215 => 1cp = 209/5
		self.CPoints[i]:SetPoint("BOTTOMLEFT", self.Portrait, (i - 1) * (214 / numCPoints) + 1, 1)
		self.CPoints[i]:SetFrameLevel(self.Portrait:GetFrameLevel() + 1)
		self.CPoints[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.CPoints[i]:GetStatusBarTexture():SetHorizTile(false)
		self.CPoints[i]:SetStatusBarColor(unpack(combocolors[i]))
		self.CPoints[i]:SetBackdrop(cfg.BACKDROP)
		self.CPoints[i]:SetBackdropColor(0, 0, 0)
	end
end
ns.AddComboPointsBar = AddComboPointsBar

local function AddEclipseBar(self, width, height)
	local eclipseBar = CreateFrame("Frame", self:GetName().."EclipseBar", self)
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

local function AddPortrait(self, width, height)
	self.Portrait = CreateFrame("PlayerModel", self:GetName().."Portrait", self)
	self.Portrait:SetPoint("TOPLEFT", self.Health, "BOTTOMLEFT", 7.5, 10)
	self.Portrait:SetPoint("BOTTOMRIGHT", self.Power, "TOPRIGHT", -7.5, -7.5)
	self.Portrait:SetFrameLevel(self:GetFrameLevel() + 3)
	self.Portrait:SetBackdrop(cfg.BACKDROP)
	self.Portrait:SetBackdropColor(0, 0, 0, 1)
end
ns.AddPortrait = AddPortrait