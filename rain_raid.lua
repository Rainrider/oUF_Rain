local _, ns = ...
local cfg = ns.config

local raidStyle = function(self, unit)
	
	self.menu = ns.menu
	self.colors = ns.colors
	
	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	self:SetSize(64, 30)
	
	self.FrameBackdrop = CreateFrame("Frame", nil, self)
	self.FrameBackdrop:SetFrameLevel(self:GetFrameLevel() - 1)
	self.FrameBackdrop:SetPoint("TOPLEFT", self, -5, 5)
	self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, 5, -5)
	self.FrameBackdrop:SetBackdrop(ns.media.BACKDROP2)
	self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	
	self.Health = CreateFrame("StatusBar", self:GetName().."_Health", self)
	self.Health:SetSize(64, 25)
	self.Health:SetPoint("TOPLEFT")
	self.Health:SetStatusBarTexture(ns.media.TEXTURE)
	self.Health.colorDisconnected = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = true
	self.Health:SetBackdrop(ns.media.BACKDROP)
	self.Health:SetBackdropColor(0, 0, 0)
	
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints()
	self.Health.bg:SetTexture(ns.media.TEXTURE)
	self.Health.bg.multiplier = 0.5 -- TODO: solid color for health background
	
	self.Health.value = ns.PutFontString(self.Health, ns.media.FONT2, 9, nil, "RIGHT")
	self.Health.value:SetPoint("RIGHT", -2, 0)
	--self.Health.value.frequentUpdates = true
	if (cfg.raidHealth > 0) then
		if (cfg.raidHealth == 1) then
			self:Tag(self.Health.value, "[dead][offline][rain:raidhp]") -- TODO: coloring
		elseif (cfg.raidHealth == 2) then
			self:Tag(self.Health.value, "[dead][offline][perhp<%]")
		end
	end
	
	self.Power = CreateFrame("StatusBar", self:GetName().."_Power", self)
	self.Power:SetSize(64, 5)
	self.Power:SetPoint("BOTTOMLEFT")
	self.Power:SetStatusBarTexture(ns.media.TEXTURE)
	self.Power.colorPower = true
	self.Power:SetBackdrop(ns.media.BACKDROP)
	self.Power:SetBackdropColor(0, 0, 0)
	
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints()
	self.Power.bg:SetTexture(ns.media.TEXTURE)
	self.Power.bg.multiplier = 0.5
	
	--[[ ICONS ]]--
	ns.AddAssistantIcon(self, unit)
	ns.AddLeaderIcon(self, unit)
	ns.AddMasterLooterIcon(self, unit)
	ns.AddPhaseIcon(self, unit)
	ns.AddRaidIcon(self, unit) -- TODO: placement for raid frames
	ns.AddReadyCheckIcon(self, unit)
	
	--[[ BARS ]]--
	ns.AddHealPredictionBar(self, unit)
	
	self.Name = ns.PutFontString(self.Health, ns.media.FONT2, 9, nil, "LEFT")
	self.Name:SetPoint("LEFT", 2, 0)
	self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
	self:Tag(self.Name, "[rain:role][rain:name]") --TODO: option to display role
	
	--[[ MODULES ]]--
	ns.AddDebuffHighlight(self, unit) -- TODO: check appearance
	ns.AddRangeCheck(self)
	-- TODO: add aggro highlight
	-- TODO: add highlight on targeted
	-- TODO: add mouseover highlight ??
end
ns.raidStyle = raidStyle