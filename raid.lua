local _, ns = ...

local RaidStyle = function(self, unit)

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
	health.colorSmooth = nil
	-- health.colorReaction = true -- TODO: coloring for mind-controlled units (need further events too)
	health.frequentUpdates = nil
	health:SetBackdrop(ns.media.BACKDROP)
	health:SetBackdropColor(0, 0, 0)

	health.UpdateColor = ns.UpdateHealthColor

	local hpBG = health:CreateTexture(nil, "BORDER")
	hpBG:SetAllPoints()
	hpBG:SetTexture(ns.media.TEXTURE)
	hpBG:SetVertexColor(0.84, 0.75, 0.65)
	health.background = hpBG

	local hpValue = ns.GenerateFontString(health, ns.media.FONT2, 9, nil, "RIGHT")
	hpValue:SetPoint("BOTTOMRIGHT", -2, 2)

	if (ns.cfg.raidHealth > 0) then
		if (ns.cfg.raidHealth == 1) then
			self:Tag(hpValue, "[rain:raidmissinghp]") -- TODO: coloring
		elseif (ns.cfg.raidHealth == 2) then
			self:Tag(hpValue, "[rain:raidpercenthp]")
		end
	else
		self:Tag(hpValue, "[rain:status]")
	end
	health.value = hpValue

	self.Health = health

	local power = CreateFrame("StatusBar", self:GetName().."_Power", self)
	power:SetSize(64, 5)
	power:SetPoint("BOTTOMLEFT")
	power:SetStatusBarTexture(ns.media.TEXTURE)
	power.colorClass = true
	power:SetBackdrop(ns.media.BACKDROP)
	power:SetBackdropColor(0, 0, 0)

	local pbBG = power:CreateTexture(nil, "BORDER")
	pbBG:SetAllPoints()
	pbBG:SetTexture(ns.media.TEXTURE)
	pbBG.multiplier = 0.5
	power.bg = pbBG

	self.Power = power

	local name = ns.GenerateFontString(health, ns.media.FONT2, 9, nil, "LEFT")
	name:SetPoint("TOPLEFT", 2, -2)
	self:Tag(name, "[rain:role][rain:name]")

	--[[ ICONS ]]--
	ns.AddAssistantIcon(self)
	ns.AddLeaderIcon(self)
	ns.AddMasterLooterIcon(self)
	ns.AddPhaseIcon(self)
	ns.AddRaidTargetIcon(self)
	ns.AddRaidRoleIcon(self)
	ns.AddReadyCheckIcon(self)
	ns.AddResurrectIcon(self)

	--[[ ELEMENTS ]]--
	ns.AddAuras(self, unit)
	ns.AddDispelHighlight(self, unit)
	ns.AddHealthPrediction(self, unit)
	ns.AddRangeCheck(self)
	ns.AddThreatHighlight(self)

	self:RegisterEvent("PLAYER_TARGET_CHANGED", function(self)
		if (UnitIsUnit(self.unit, "target")) then
			self.FrameBackdrop:SetBackdropBorderColor(1, 1, 0)
		else
			self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
		end
	end)

end
ns.RaidStyle = RaidStyle
