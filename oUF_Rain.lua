local _, ns = ...

local cfg = ns.config
local SetFontString = ns.SetFontString

local playerClass = select(2, UnitClass("player"))

-- layout rules for specific unit frames (auras, combo points, totembar, runes, holy power, shards, druid mana ...)
local UnitSpecific = {
	player = function(self)
		ns.AddSwingBar(self, nil, nil)
		ns.AddReputationBar(self, nil, nil)
		ns.AddExperienceBar(self, nil, nil)
		
		if (playerClass == "DEATHKNIGHT") then
			ns.AddRuneBar(self, 230, 5)
		end
		if (playerClass == "PALADIN") then
			ns.AddHolyPowerBar(self, nil, 5)
		end
		if (playerClass == "WARLOCK") then
			ns.AddSoulshardsBar(self, 230, 5)
		end
		if (playerClass == "SHAMAN") then
			ns.AddTotemBar(self, nil, 5)
		end
		if (playerClass == "DRUID") then
			ns.AddEclipseBar(self, 230, 7)
		end
	end,
	
	target = function(self)
		self.Info = SetFontString(self.Health, cfg.FONT2, 12, nil, "LEFT")
		self.Info:SetPoint("TOP", self.Health, 0, -5)
		self:Tag(self.Info, "[rain:color][name]|r [difficulty][level] [shortclassification]|r")
		
		ns.AddComboPointsBar(self, nil, 5)
	end,
	
	pet = function(self)
		--ns.AddHealPredictionBar(self, 110, true)
		ns.AddExperienceBar(self, nil, nil)
		
		self.PetName = SetFontString(self.Health, cfg.FONT2, 9, nil, "LEFT")
		self.PetName:SetPoint("TOPLEFT", 2, -2)
		self.PetName:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		self:Tag(self.PetName, "[rain:petcolor][name]|r")
	end,
}

-- shared rules between more than one unit
-- pet, focus, tot and focustarget would be basicaly the same
local function Shared(self, unit)

	self.colors = ns.colors

	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	self.FrameBackdrop = CreateFrame("Frame", nil, self)
	self.FrameBackdrop:SetFrameLevel(self:GetFrameLevel() - 1)
	self.FrameBackdrop:SetPoint("TOPLEFT", self, -5, 5)
	self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, 5, -5)
	self.FrameBackdrop:SetBackdrop(cfg.BACKDROP2)
	self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	
	self.Health = CreateFrame("StatusBar", self:GetName().."_Health", self)
	self.Health:SetStatusBarTexture(cfg.TEXTURE)
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorHappiness = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = true
	self.Health:SetBackdrop(cfg.BACKDROP)
	self.Health:SetBackdropColor(0, 0, 0)
	
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints()
	self.Health.bg:SetTexture(cfg.TEXTURE)
	self.Health.bg.multiplier = 0.5
	
	self.Health.PostUpdate = ns.PostUpdateHealth
	
	self.Health.value = SetFontString(self.Health, cfg.FONT2, (unit == "player" or unit == "target") and 12 or 9, nil, "RIGHT")
	self.Health.value:SetPoint("TOPRIGHT", self.Health, -3.5, -3.5)
	self.Health.value.frequentUpdates = 1/4
	self:Tag(self.Health.value, "[dead][offline][rain:health]")
	
	self.Power = CreateFrame("StatusBar", self:GetName().."_Power", self)
	self.Power:SetStatusBarTexture(cfg.TEXTURE)
	self.Power:SetBackdrop(cfg.BACKDROP)
	self.Power:SetBackdropColor(0, 0, 0)
	
	self.Power.colorTapping = true
	self.Power.colorPower =  true and unit == "player" or unit == "pet"
	self.Power.colorClass = true
	self.Power.colorReaction = true
	self.Power.frequentUpdates = true
	
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints()
	self.Power.bg:SetTexture(cfg.TEXTURE)
	self.Power.bg.multiplier = 0.5
	
	self.Power.PreUpdate = ns.PreUpdatePower
	self.Power.PostUpdate = ns.PostUpdatePower
	
	
	if(unit == "player" or unit == "target") then
		-- set frame size
		self:SetSize(230, 50)
	
		self.Health:SetSize(230, 30)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Power:SetSize(230, 15)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Power.value = SetFontString(self.Health, cfg.FONT2, 12, nil, "LEFT")
		self.Power.value:SetPoint("TOPLEFT", self.Health, 3.5, -3.5)
		self.Power.value.frequentUpdates = 1/4
		self:Tag(self.Power.value, "[rain:perpp][rain:power]")
		
		ns.AddPortrait(self, unit)
		ns.AddOverlay(self, unit)
		ns.AddCastbar(self, unit)
		ns.AddCombatFeedbackText(self)
		ns.AddHealPredictionBar(self, unit)
		
		self.Status = SetFontString(self.Portrait, cfg.FONT2, 18, "OUTLINE", "RIGHT")
		self.Status:SetPoint("RIGHT", -3.5, 2)
		self.Status:SetTextColor(0.69, 0.31, 0.31, 0.6)
		self:Tag(self.Status, "[pvp]")
	end
	
	if(unit == "pet" or unit == "focus" or unit:find("target") and unit ~= "target") then
		self:SetSize(110, 22)
		
		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value:SetPoint("TOPRIGHT", -2, -2)
		
		self.Power:SetSize(110, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		if unit ~= "pet" then
			self.Name = SetFontString(self.Health, cfg.FONT2, 9, nil, "LEFT")
			self.Name:SetPoint("TOPLEFT", 2, -2)
			self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
			self:Tag(self.Name, "[rain:color][name]|r")
		end
		
		ns.AddCastbar(self, unit)
	end
	
	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end

end

oUF:RegisterStyle("Rain", Shared)
oUF:Factory(function(self)
	self:SetActiveStyle("Rain")
	self:Spawn("player", "oUF_Rain_Player"):SetPoint("CENTER", -300, -250)
	self:Spawn("pet", "oUF_Rain_Pet"):SetPoint("BOTTOMLEFT", oUF_Rain_Player, "TOPLEFT", 0, 10)
	self:Spawn("focus", "oUF_Rain_Focus"):SetPoint("BOTTOMRIGHT", oUF_Rain_Player, "TOPRIGHT", 0, 10)
	self:Spawn("target", "oUF_Rain_Target"):SetPoint("CENTER", 300, -250)
	self:Spawn("targettarget", "oUF_Rain_TargetTarget"):SetPoint("BOTTOMRIGHT", oUF_Rain_Target, "TOPRIGHT", 0, 10)
	self:Spawn("focustarget", "oUF_Rain_FocusTarget"):SetPoint("BOTTOMLEFT", oUF_Rain_Target, "TOPLEFT", 0 , 10)
end)