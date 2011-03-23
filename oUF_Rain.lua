local _, ns = ...

local cfg = ns.config
local PutFontString = ns.PutFontString

local playerClass = select(2, UnitClass("player"))

-- layout rules for specific unit frames (auras, combo points, totembar, runes, holy power, shards, druid mana ...)
local UnitSpecific = {
	player = function(self)
		ns.AddSwingBar(self)
		ns.AddReputationBar(self)
		ns.AddExperienceBar(self)
		ns.AddAltPowerBar(self)
		
		if (playerClass == "DEATHKNIGHT") then
			ns.AddRuneBar(self, 230, 5)
		elseif (playerClass == "PALADIN") then
			ns.AddHolyPowerBar(self, nil, 5)
		elseif (playerClass == "WARLOCK") then
			ns.AddSoulshardsBar(self, 230, 5)
		elseif (playerClass == "SHAMAN") then
			ns.AddTotemBar(self, nil, 5)
		elseif (playerClass == "DRUID") then
			ns.AddEclipseBar(self, 230, 7)
			ns.AddDruidMushrooms(self)
			--self:RegisterEvent("PLAYER_TOTEM_UPDATE", ns.AddDruidMushrooms(self))
		elseif (playerClass == "HUNTER") then
			ns.AddHunterFocusSpark(self)
		end
		
		ns.AddCombatIcon(self)
		ns.AddRestingIcon(self)
	end,
	
	target = function(self)
		self.Info = PutFontString(self.Health, cfg.FONT2, 12, nil, "LEFT")
		self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
		self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", 0, -5)
		self:Tag(self.Info, "[rain:name] [difficulty][level] [shortclassification]|r")
		
		ns.AddComboPointsBar(self, nil, 5)
		
		ns.AddQuestIcon(self, "target")
	end,
	
	pet = function(self)
		ns.AddHealPredictionBar(self, 110, false)
		ns.AddExperienceBar(self)
		ns.AddAltPowerBar(self) -- this is needed when the player is in vehicle. because the pet frame then holds the player unit
		
		ns.AddDebuffs(self, "pet")
		ns.AddBuffs(self, "pet")
	end,
}

-- shared rules between more than one unit
-- pet, focus, tot and focustarget would be basicaly the same
local function Shared(self, unit)

	self.menu = ns.menu
	self.colors = ns.colors

	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	local unitIsInParty = self:GetParent():GetName():match("oUF_Rain_Party")
	local unitIsPartyTarget = self:GetParent():GetName():match("oUF_Rain_PartyTargets")
	--local unitIsPartyPet = self:GetParent():GetName():match("oUF_Rain_PartyPets")
	local unitIsPartyPet = self:GetAttribute("unitsuffix") == "pet"
	local unitIsMT = self:GetParent():GetName():match("oUF_Rain_MT")
	local unitIsMTT = self:GetParent():GetName():match("oUF_Rain_MTT")
	
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
	
	ns.AddRaidIcon(self, unit)
	ns.AddAssistantIcon(self, unit)
	ns.AddLeaderIcon(self, unit)
	ns.AddMasterLooterIcon(self, unit)
	ns.AddPhaseIcon(self, unit)
	ns.AddReadyCheckIcon(self, unit)
	
	if(unit == "player" or unit == "target") then
		self:SetSize(230, 50)
	
		self.Health:SetSize(230, 30)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, cfg.FONT2, 12, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", self.Health, -3.5, -3.5)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, "[dead][offline][rain:health]")
		
		self.Power:SetSize(230, 15)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Power.value = PutFontString(self.Health, cfg.FONT2, 12, nil, "LEFT")
		self.Power.value:SetPoint("TOPLEFT", self.Health, 3.5, -3.5)
		self.Power.value.frequentUpdates = 1/4
		self:Tag(self.Power.value, "[rain:power]")
		
		ns.AddPortrait(self, unit)
		ns.AddOverlay(self, unit)
		ns.AddCastbar(self, unit)
		ns.AddCombatFeedbackText(self)
		ns.AddHealPredictionBar(self, unit)
		
		ns.AddBuffs(self, unit)
		ns.AddDebuffs(self, unit)
		
		self.Status = PutFontString(self.Portrait, cfg.FONT2, 18, "OUTLINE", "RIGHT")
		self.Status:SetPoint("RIGHT", -3.5, 2)
		self.Status:SetTextColor(0.69, 0.31, 0.31, 0.6)
		self:Tag(self.Status, "[pvp]")
	end
	
	if(unit == "pet" or unit == "focus" or (unit:find("target") and unit ~= "target")) then
		self:SetSize(110, 22)
		
		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, cfg.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", -2, -2)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, "[dead][offline][rain:healthSmall]")
		
		self.Power:SetSize(110, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Name = PutFontString(self.Health, cfg.FONT2, 9, nil, "LEFT")
		self.Name:SetPoint("TOPLEFT", 2, -2)
		self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		if (unit ~= "pet") then
			self:Tag(self.Name, "[rain:name]")
		else
			self:Tag(self.Name, "[rain:petname]")
		end
		
		ns.AddCastbar(self, unit)
	end
	
	if((unitIsInParty or unitIsPartyTarget or unitIsMT) and not unitIsPartyPet) then
		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, cfg.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", -2, -2)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, "[dead][offline][rain:healthSmall]")
		
		self.Power:SetSize(110, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Name = PutFontString(self.Health, cfg.FONT2, 9, nil, "LEFT")
		self.Name:SetPoint("TOPLEFT", 2, -2)
		self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		self:Tag(self.Name, "[rain:name]")
	end
	
	if(unitIsPartyPet) then
		self:SetSize(110, 10)
		self.Health:SetSize(110, 9)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, cfg.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("RIGHT", -2, 0)
		self:Tag(self.Health.value, "[perhp]")
		
		self.Power:Hide()
		
		self.Name = PutFontString(self.Health, cfg.FONT2, 9, nil, "LEFT")
		self.Name:SetPoint("LEFT", 2, 0)
		self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		self:Tag(self.Name, "[rain:name]")
	end
	
	if(unitIsMTT) then
		self:SetSize(110, 22)
		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
	
		self.Health.value = PutFontString(self.Health, cfg.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", -2, -2)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, "[dead][offline][rain:healthSmall]")
		
		self.Power:SetSize(110, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Name = PutFontString(self.Health, cfg.FONT2, 9, nil, "LEFT")
		self.Name:SetPoint("TOPLEFT", 2, -2)
		self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		self:Tag(self.Name, "[rain:name]")
	end
	
	if(UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end

end

oUF:RegisterStyle("Rain", Shared)
oUF:Factory(function(self)

	local playerClass = cfg.playerClass
	local spellName = ""
	
	if playerClass == "HUNTER" then
		 spellName = GetSpellInfo(34477)	-- Misdirection
	elseif playerClass == "DRUID" then
		spellName = GetSpellInfo(29166)		-- Innervate
	elseif playerClass == "PALADIN" then
		spellName = GetSpellInfo(31789)		-- Righteous Defense
	elseif playerClass == "WARRIOR" then
		spellName = GetSpellInfo(3411)		-- Intervene
	elseif playerClass == "ROGUE" then
		spellName = GetSpellInfo(57934)		-- Tricks of the Trade
	else
		spellName = "Misdirection"
	end

	self:SetActiveStyle("Rain")
	self:Spawn("player", "oUF_Rain_Player"):SetPoint("CENTER", -210, -215)
	self:Spawn("pet", "oUF_Rain_Pet"):SetPoint("BOTTOMLEFT", oUF_Rain_Player, "TOPLEFT", 0, 10)
	self:Spawn("focus", "oUF_Rain_Focus"):SetPoint("BOTTOMRIGHT", oUF_Rain_Player, "TOPRIGHT", 0, 10)
	self:Spawn("target", "oUF_Rain_Target"):SetPoint("CENTER", 210, -215)
	self:Spawn("targettarget", "oUF_Rain_TargetTarget"):SetPoint("BOTTOMRIGHT", oUF_Rain_Target, "TOPRIGHT", 0, 10)
	self:Spawn("focustarget", "oUF_Rain_FocusTarget"):SetPoint("BOTTOMLEFT", oUF_Rain_Target, "TOPLEFT", 0 , 10)
	
	if (cfg.showParty) then
		local party = self:SpawnHeader(
			"oUF_Rain_Party", nil, "party,raid",
			"showParty", true,
			"showRaid", true,
--			"showPlayer", true,
--			"showSolo", true,
			"maxColumns", 4,
			"unitsPerColumn", 1,
			"columnAnchorPoint", "LEFT",
			"columnSpacing", 7.5,
			"oUF-initialConfigFunction", ([[
				self:SetWidth(110)
				self:SetHeight(22)
				self:SetAttribute("type3", "spell")
				self:SetAttribute("spell3", %s)
			]]):format(spellName)
		)
		party:SetPoint("LEFT", UIParent, "BOTTOM", -231.25, 150)
		party:Show()
	end

	if (cfg.showParty and cfg.showPartyTargets) then
		local partyTargets = self:SpawnHeader(
			"oUF_Rain_PartyTargets", nil, "party,raid",
			"showParty", true,
			"showRaid", true,
--			"showPlayer", true,
--			"showSolo", true,
			"maxColumns", 4,
			"unitsPerColumn", 1,
			"columnAnchorPoint", "LEFT",
			"columnSpacing", 7.5,
			"oUF-initialConfigFunction", [[
				self:SetWidth(110)
				self:SetHeight(22)
				self:SetAttribute("unitsuffix", "target")
			]]
		)
		partyTargets:SetPoint("TOPLEFT", "oUF_Rain_Party", "BOTTOMLEFT", 0, -27.5)
		partyTargets:Show()
	end

	if (cfg.showParty and cfg.showPartyPets) then
		local partyPets = self:SpawnHeader(
			"oUF_Rain_PartyPets", nil, "party,raid",
			"showParty", true,
			"showRaid", true,
--			"showPlayer", true,
--			"showSolo", true,
			"maxColumns", 4,
			"unitsPerColumn", 1,
			"columnAnchorPoint", "LEFT",
			"columnSpacing", 7.5,
			"oUF-initialConfigFunction", ([[
				self:SetWidth(110)
				self:SetHeight(11)
				self:SetAttribute("unitsuffix", "pet")
				self:SetAttribute("type3", "spell")
				self:SetAttribute("spell3", %s)
			]]):format(spellName)
		)
		partyPets:SetPoint("TOPLEFT", "oUF_Rain_Party", "BOTTOMLEFT", 0, -7.5)
		partyPets:Show()
	end
	
	if (cfg.showMT) then
		local mainTanks = self:SpawnHeader(
			"oUF_Rain_MT", nil, "raid",
			"showRaid", true,
			"groupFilter", "MAINTANK",
			"yOffset", -7.5,
			"oUF-initialConfigFunction", [[
				self:SetWidth(110)
				self:SetHeight(22)
				self:SetAttribute("type3", "spell")
				self:SetAttribute("spell3", "Misdirection")
			]]
		)
		mainTanks:SetPoint("TOPLEFT", UIParent, "LEFT", 50, -50)
		mainTanks:Show()
	end
	
	if (cfg.showMT and cfg.showMTT) then
		local mainTankTargets = self:SpawnHeader(
			"oUF_Rain_MTT", nil, "raid",
			"showRaid", true,
			"groupFilter", "MAINTANK",
			"yOffset", -7.5,
			"oUF-initialConfigFunction", [[
				self:SetWidth(110)
				self:SetHeight(22)
				self:SetAttribute("unitsuffix", "target")
			]]
		)
		mainTankTargets:SetPoint("TOPLEFT", "oUF_Rain_MT", "TOPRIGHT", 7.5, 0)
		mainTankTargets:Show()
	end
end)
