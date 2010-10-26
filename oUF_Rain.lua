local _, ns = ...

local cfg = ns.config

local playerClass = select(2, UnitClass("player"))

-- pre and post function go here

local function PostUpdatePower(Power, unit, min, max)
	Power.colorTapping = true
	Power.colorPower = UnitIsPlayer(unit) == 1 or UnitPlayerControlled(unit) == 1
	--self.Power.colorClass = true
	--self.Power.colorPower = true -- and UnitIsPlayer(unit)
	Power.colorReaction = true
	Power.frequentUpdates = true
end


-- layout rules for specific unit frames (auras, combo points, totembar, runes, holy power, shards, druid mana ...)
local UnitSpecific = {
	player = function(self)
		ns.AddHealPredictionBar(self, 230, true)
		ns.AddSwingBar(self, nil, nil)
		ns.AddReputationBar(self, nil, nil)
		ns.AddExperienceBar(self, nil, nil)
		
		if (playerClass == "DEATHKNIGHT") then
			ns.AddRuneBar(self, 230, 7)
		end
		if (playerClass == "PALADIN") then
			ns.AddHolyPowerBar(self, 230, 7)
		end
		if (playerClass == "WARLOCK") then
			ns.AddSoulshardsBar(self, 230, 7)
		end
		if (playerClass == "SHAMAN" and IsAddOnLoaded("oUF_TotemBar")) then
			ns.AddTotemBar(self, 230, 7)
		end
		if (playerClass == "DRUID") then
			ns.AddEclipseBar(self, 230, 7)
		end
	end,
	
	target = function(self)
		ns.AddHealPredictionBar(self, 230, true)
		ns.AddComboPointsBar(self, 230, 7)
	end,
	
	pet = function(self)
		ns.AddHealPredictionBar(self, 230, true)
		ns.AddExperienceBar(self, nil, nil)
	end,
}

-- shared rules between more than one unit
-- pet, focus, tot and focustarget would be basicaly the same
local function Shared(self, unit)

	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	self:SetBackdrop(cfg.BACKDROP)
	self:SetBackdropColor(0, 0, 0)
	
	-- health bar
	self.Health = CreateFrame("StatusBar", nil, self)
	self.Health:SetStatusBarTexture(cfg.TEXTURE)
	self.Health.colorTapping = true
	self.Health.colorDisconnected = true
	self.Health.colorHappiness = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = true
	
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints()
	self.Health.bg:SetTexture(cfg.TEXTURE)
	self.Health.bg.multiplier = 0.5
	
	local healthValue = self.Health:CreateFontString(nil, "OVERLAY")
	healthValue:SetPoint("RIGHT", self.Health, -2, 0)
	healthValue:SetFont(cfg.FONT, 12, "OUTLINE")
	healthValue:SetJustifyH("RIGHT")
	healthValue.frequentUpdates = 1/4
	self:Tag(healthValue, "[curhp] | [level]")
	
	
	self.Power = CreateFrame("StatusBar", nil, self)
	self.Power:SetStatusBarTexture(cfg.TEXTURE)
	
	
	self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
	self.Power.bg:SetAllPoints()
	self.Power.bg:SetTexture(cfg.TEXTURE)
	self.Power.bg.multiplier = 0.5
	
	self.Power.PostUpdate = PostUpdatePower
	
	if(unit == "player" or unit == "target") then
		-- set frame size
		self:SetSize(230, 40)
	
		self.Health:SetSize(230, 30)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Power:SetSize(230, 7)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1)
		
		
		
	end
	
	if(unit == "pet" or unit == "focus" or unit:find("target") and unit ~= "target") then
		self:SetSize(115, 20)
		
		self.Health:SetSize(115, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Power:SetSize(115, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		self.Power:SetPoint("TOP", self.Health, "BOTTOM", 0, -1)
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