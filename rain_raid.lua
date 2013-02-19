local _, ns = ...

local RaidStyle = function(self, unit)

	self.menu = ns.menu
	self.colors = ns.colors

	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	local frameBackdrop = CreateFrame("Frame", nil, self)
	frameBackdrop:SetFrameLevel(self:GetFrameLevel() - 1)
	frameBackdrop:SetPoint("TOPLEFT", self, -5, 5)
	frameBackdrop:SetPoint("BOTTOMRIGHT", self, 5, -5)
	frameBackdrop:SetBackdrop(ns.media.BACKDROP2)
	frameBackdrop:SetBackdropColor(0, 0, 0, 0)
	frameBackdrop:SetBackdropBorderColor(0, 0, 0)
	self.FrameBackdrop = frameBackdrop

	local health = CreateFrame("StatusBar", self:GetName().."_Health", self)
	health:SetSize(64, 25)
	health:SetPoint("TOPLEFT")
	health:SetStatusBarTexture(ns.media.TEXTURE)
	health.colorDisconnected = true
	health.colorClass = true
	health.colorReaction = true
	health.frequentUpdates = true
	health:SetBackdrop(ns.media.BACKDROP)
	health:SetBackdropColor(0, 0, 0)

	local hpBG = health:CreateTexture(nil, "BORDER")
	hpBG:SetAllPoints()
	hpBG:SetTexture(ns.media.TEXTURE)
	hpBG.multiplier = 0.5 -- TODO: solid color for health background
	health.bg = hpBG

	local hpValue = ns.PutFontString(health, ns.media.FONT2, 9, nil, "RIGHT")
	hpValue:SetPoint("RIGHT", -2, 0)

	if (ns.cfg.raidHealth > 0) then
		if (ns.cfg.raidHealth == 1) then
			self:Tag(hpValue, "[dead][offline][rain:raidhp]") -- TODO: coloring
		elseif (ns.cfg.raidHealth == 2) then
			self:Tag(hpValue, "[dead][offline][perhp<%]")
		end
	end
	health.value = hpValue

	self.Health = health

	local power = CreateFrame("StatusBar", self:GetName().."_Power", self)
	power:SetSize(64, 5)
	power:SetPoint("BOTTOMLEFT")
	power:SetStatusBarTexture(ns.media.TEXTURE)
	power.colorPower = true
	power:SetBackdrop(ns.media.BACKDROP)
	power:SetBackdropColor(0, 0, 0)

	local pbBG = power:CreateTexture(nil, "BORDER")
	pbBG:SetAllPoints()
	pbBG:SetTexture(ns.media.TEXTURE)
	pbBG.multiplier = 0.5
	power.bg = pbBG

	self.Power = power

	local name = ns.PutFontString(health, ns.media.FONT2, 9, nil, "LEFT")
	name:SetPoint("LEFT", 2, 0)
	name:SetPoint("RIGHT", health.value, "LEFT", -3, 0)
	self:Tag(name, "[rain:role]")
	self.Name = name

	--[[ ICONS ]]--
	ns.AddAssistantIcon(self)
	ns.AddLeaderIcon(self)
	ns.AddMasterLooterIcon(self)
	ns.AddPhaseIcon(self)
	ns.AddRaidIcon(self, unit) -- TODO: placement for raid frames
	ns.AddRaidRoleIcon(self)
	ns.AddReadyCheckIcon(self)
	ns.AddResurrectIcon(self)

	--[[ ELEMENTS ]]--
	ns.AddDebuffHighlight(self, unit) -- TODO: check appearance
	ns.AddHealPredictionBar(self, unit)
	ns.AddRangeCheck(self)

	self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", ns.AddThreatHighlight)
	self:RegisterEvent("PLAYER_TARGET_CHANGED", function(self)
		if (UnitIsUnit(self.unit, "target")) then
			self.FrameBackdrop:SetBackdropBorderColor(1, 1, 0)
		else
			self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
		end
	end)

end
ns.RaidStyle = RaidStyle