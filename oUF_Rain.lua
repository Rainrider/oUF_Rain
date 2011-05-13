local _, ns = ...

local cfg = ns.config
local PutFontString = ns.PutFontString

local playerClass = cfg.playerClass

-- layout rules for specific unit frames (auras, combo points, totembar, runes, holy power, shards, druid mana ...)
local UnitSpecific = {
	player = function(self)
		ns.AddSwingBar(self)
		ns.AddReputationBar(self)
		ns.AddExperienceBar(self)
		ns.AddAltPowerBar(self)
		
		if (playerClass == "DEATHKNIGHT") then
			ns.AddRuneBar(self, 230, 5)
			ns.AddTotems(self, 60, 5)
		elseif (playerClass == "PALADIN") then
			ns.AddHolyPowerBar(self, nil, 5)
		elseif (playerClass == "WARLOCK") then
			ns.AddSoulshardsBar(self, 230, 5)
		elseif (playerClass == "SHAMAN") then
			ns.AddTotems(self, nil, 5)
		elseif (playerClass == "DRUID") then
			ns.AddEclipseBar(self, 230, 7)
			ns.AddTotems(self, 30, 5)
		elseif (playerClass == "HUNTER") then
			ns.AddFocusHelper(self)
		end
		
		ns.AddCombatIcon(self)
		ns.AddRestingIcon(self)
		
		self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
			if (UnitExists("target")) then
				PlaySound("igCreatureAggroSelect")
			end
		end)
		
		self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", ns.AddThreatHighlight)
	end,
	
	target = function(self)
		self.Info = PutFontString(self.Health, ns.media.FONT2, 12, nil, "LEFT")
		self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
		self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
		self:Tag(self.Info, "[rain:role< ][rain:name][difficulty][ >rain:level][ >shortclassification]|r")
		
		ns.AddComboPointsBar(self, nil, 5)
		
		ns.AddQuestIcon(self, "target")
	end,
	
	pet = function(self)
		ns.AddHealPredictionBar(self, 110, false)
		ns.AddAltPowerBar(self) -- this is needed when the player is in vehicle. because the pet frame then holds the player unit
		
		ns.AddDebuffs(self, "pet")
		ns.AddBuffs(self, "pet")
	end,
	
	focus = function(self)
		ns.AddDebuffHighlight(self, "focus")
	end,
	
	targettarget = function(self)
		ns.AddDebuffHighlight(self, "targettarget")
	end,
}

-- shared rules between more than one unit
-- pet, focus, tot and focustarget would be basicaly the same
local Shared = function(self, unit)

	self.menu = ns.menu
	self.colors = ns.colors

	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)
	
	local unitIsPartyMember = self:GetParent():GetName():match("oUF_Rain_Party")
	local unitIsPartyOrMTTarget = self:GetAttribute("unitsuffix") == "target"
	local unitIsPartyPet = self:GetAttribute("unitsuffix") == "pet"
	local unitIsMT = self:GetParent():GetName():match("oUF_Rain_MT")
	local unitIsMTT = self:GetParent():GetName():match("oUF_Rain_MTT")
	local unitIsBoss = unit:match("boss%d")
	
	self.FrameBackdrop = CreateFrame("Frame", nil, self)
	self.FrameBackdrop:SetFrameLevel(self:GetFrameLevel() - 1)
	self.FrameBackdrop:SetPoint("TOPLEFT", self, -5, 5)
	self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, 5, -5)
	self.FrameBackdrop:SetBackdrop(ns.media.BACKDROP2)
	self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	
	self.Health = CreateFrame("StatusBar", self:GetName().."_Health", self)
	self.Health:SetStatusBarTexture(ns.media.TEXTURE)
	self.Health.colorDisconnected = true
	self.Health.colorTapping = true
	self.Health.colorClass = true
	self.Health.colorReaction = true
	self.Health.frequentUpdates = true
	self.Health:SetBackdrop(ns.media.BACKDROP)
	self.Health:SetBackdropColor(0, 0, 0)
	
	self.Health.bg = self.Health:CreateTexture(nil, "BORDER")
	self.Health.bg:SetAllPoints()
	self.Health.bg:SetTexture(ns.media.TEXTURE)
	self.Health.bg.multiplier = 0.5
	
	self.Health.PostUpdate = ns.PostUpdateHealth
	
	if (not unitIsPartyPet) then
		self.Power = CreateFrame("StatusBar", self:GetName().."_Power", self)
		self.Power:SetStatusBarTexture(ns.media.TEXTURE)
		self.Power:SetBackdrop(ns.media.BACKDROP)
		self.Power:SetBackdropColor(0, 0, 0)
	
		self.Power.colorPower = unit == "player" or unit == "pet"
		self.Power.colorClass = true
		self.Power.colorReaction = true
		self.Power.frequentUpdates = true
	
		self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
		self.Power.bg:SetAllPoints()
		self.Power.bg:SetTexture(ns.media.TEXTURE)
		self.Power.bg.multiplier = 0.5
	
		self.Power.PreUpdate = ns.PreUpdatePower
		self.Power.PostUpdate = ns.PostUpdatePower
	end
	
	ns.AddRaidIcon(self, unit)
	ns.AddPhaseIcon(self, unit)
	
	if (unit == "player" or unit == "target") then
		self:SetSize(230, 50)
	
		self.Health:SetSize(230, 30)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, ns.media.FONT2, 12, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", self.Health, -3.5, -3.5)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, "[dead][offline][rain:health]")
		
		self.Power:SetSize(230, 15)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Power.value = PutFontString(self.Health, ns.media.FONT2, 12, nil, "LEFT")
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
		ns.AddDebuffHighlight(self, unit)
		
		self.Status = PutFontString(self.Portrait, ns.media.FONT2, 18, "OUTLINE", "RIGHT")
		self.Status:SetPoint("RIGHT", -3.5, 2)
		self.Status:SetTextColor(0.69, 0.31, 0.31, 0.6)
		self:Tag(self.Status, "[pvp]")
		
		ns.AddAssistantIcon(self, unit)
		ns.AddLeaderIcon(self, unit)
		ns.AddMasterLooterIcon(self, unit)
		ns.AddPhaseIcon(self, unit)
		ns.AddReadyCheckIcon(self, unit)
	end
	
	if ((unit == "pet" or unit == "focus"
			or unit == "targettarget" or unit == "focustarget"
			or unitIsPartyMember or unitIsPartyOrMTTarget 
			or unitIsMT or unitIsBoss) and not unitIsPartyPet) then
		
		self:SetSize(110, 22)
		
		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, ns.media.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", -2, -2)
		self.Health.value.frequentUpdates = 1/4
		self:Tag(self.Health.value, "[dead][offline][rain:healthSmall]")
		
		self.Power:SetSize(110, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
		
		self.Name = PutFontString(self.Health, ns.media.FONT2, 9, nil, "LEFT")
		self.Name:SetPoint("TOPLEFT", 2, -2)
		self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		
		if (not unitIsPartyMember) then
			self:Tag(self.Name, "[rain:name]")
		else
			self:Tag(self.Name, "[rain:role][rain:name]")
		end
		
		if (unitIsPartyMember) then
			ns.AddAssistantIcon(self, unit)
			ns.AddLeaderIcon(self, unit)
			ns.AddMasterLooterIcon(self, unit)
			ns.AddReadyCheckIcon(self, unit)
			
			ns.AddDebuffHighlight(self, unit)
		end
		
		if (unitIsBoss) then
			ns.AddBuffs(self, unit)
			ns.AddCastbar(self, unit)
		end
		
		if (unit == "pet" or unit == "focus"  or unitIsPartyMember) then
			ns.AddCastbar(self, unit)
			self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", ns.AddThreatHighlight)
		end
	end
	
	if (unitIsPartyPet) then
		self:SetSize(110, 10)
		self.Health:SetSize(110, 10)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Health.value = PutFontString(self.Health, ns.media.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("RIGHT", -2, 0)
		self:Tag(self.Health.value, "[perhp]")
		
		self.Name = PutFontString(self.Health, ns.media.FONT2, 9, nil, "LEFT")
		self.Name:SetPoint("LEFT", 2, 0)
		self.Name:SetPoint("RIGHT", self.Health.value, "LEFT", -3, 0)
		self:Tag(self.Name, "[rain:name]")
	end
	
	if (UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end

end

oUF:RegisterStyle("Rain", Shared)
oUF:Factory(function(self)

	local spellName = GetSpellInfo(cfg.clickSpell[playerClass] or 6603)	-- 6603 Auto Attack
	if (not spellName) then
		spellName = GetSpellInfo(6603)
	end

	self:SetActiveStyle("Rain")
	self:Spawn("player", "oUF_Rain_Player"):SetPoint("CENTER", -210, -215)
	self:Spawn("pet", "oUF_Rain_Pet"):SetPoint("BOTTOMLEFT", oUF_Rain_Player, "TOPLEFT", 0, 10)
	self:Spawn("focus", "oUF_Rain_Focus"):SetPoint("BOTTOMRIGHT", oUF_Rain_Player, "TOPRIGHT", 0, 10)
	self:Spawn("target", "oUF_Rain_Target"):SetPoint("CENTER", 210, -215)
	self:Spawn("targettarget", "oUF_Rain_TargetTarget"):SetPoint("BOTTOMRIGHT", oUF_Rain_Target, "TOPRIGHT", 0, 10)
	self:Spawn("focustarget", "oUF_Rain_FocusTarget"):SetPoint("BOTTOMLEFT", oUF_Rain_Target, "TOPLEFT", 0 , 10)
	
	local party
	if (cfg.showParty) then
		if (cfg.horizParty) then
			party = self:SpawnHeader(
				"oUF_Rain_Party", nil, "party, raid",
				"showParty", true,
				"showRaid", true,
				"maxColumns", 4,
				"unitsPerColumn", 1,
				"columnAnchorPoint", "LEFT",
				"columnSpacing", 9.5,
				"oUF-initialConfigFunction", ([[
					self:SetWidth(110)
					self:SetHeight(22)
					self:SetAttribute("type3", "spell")
					self:SetAttribute("spell3", "%s")
				]]):format(spellName)
			)
			party:SetPoint("LEFT", UIParent, "BOTTOM", -231.25, 150)
		else
			party = self:SpawnHeader(
				"oUF_Rain_Party", nil, "party, raid",
				"showParty", true,
				"showRaid", true,
				"yOffset", -27.5,
				"oUF-initialConfigFunction", ([[
					self:SetWidth(110)
					self:SetHeight(22)
					self:SetAttribute("type3", "spell")
					self:SetAttribute("spell3", "%s")
				]]):format(spellName)
			)
			party:SetPoint("TOPLEFT", UIParent, 25, -25)
		end
		party:Show()
	end

	local partyTargets
	if (cfg.showParty and cfg.showPartyTargets) then
		if (cfg.horizParty) then
			partyTargets = self:SpawnHeader(
				"oUF_Rain_PartyTargets", nil, "party",
				"showParty", true,
				"showRaid", false,
				"maxColumns", 4,
				"unitsPerColumn", 1,
				"columnAnchorPoint", "LEFT",
				"columnSpacing", 9.5,
				"oUF-initialConfigFunction", [[
					self:SetWidth(110)
					self:SetHeight(22)
					self:SetAttribute("unitsuffix", "target")
				]]
			)
			partyTargets:SetPoint("TOPLEFT", "oUF_Rain_Party", "BOTTOMLEFT", 0, -27.5)
		else
			partyTargets = self:SpawnHeader(
				"oUF_Rain_PartyTargets", nil, "party",
				"showParty", true,
				"showRaid", false,
				"yOffset", -27.5,
				"oUF-initialConfigFunction", [[
					self:SetWidth(110)
					self:SetHeight(22)
					self:SetAttribute("unitsuffix", "target")
				]]
			)
			partyTargets:SetPoint("TOPLEFT", "oUF_Rain_Party", "TOPRIGHT", 7.5, 0)
		end
		partyTargets:Show()
	end

	local partyPets
	if (cfg.showParty and cfg.showPartyPets) then
		if (cfg.horizParty) then
			partyPets = self:SpawnHeader(
				"oUF_Rain_PartyPets", nil, "party",
				"showParty", true,
				"showRaid", false,
				"maxColumns", 4,
				"unitsPerColumn", 1,
				"columnAnchorPoint", "LEFT",
				"columnSpacing", 9.5,
				"oUF-initialConfigFunction", ([[
					self:SetWidth(110)
					self:SetHeight(11)
					self:SetAttribute("unitsuffix", "pet")
					self:SetAttribute("type3", "spell")
					self:SetAttribute("spell3", "%s")
				]]):format(spellName)
			)
		else
			partyPets = self:SpawnHeader(
				"oUF_Rain_PartyPets", nil, "party",
				"showParty", true,
				"showRaid", false,
				"yOffset", -27.5,
				"oUF-initialConfigFunction", ([[
					self:SetWidth(110)
					self:SetHeight(11)
					self:SetAttribute("unitsuffix", "pet")
					self:SetAttribute("type3", "spell")
					self:SetAttribute("spell3", "%s")
				]]):format(spellName)
			)
		end
		partyPets:SetPoint("TOPLEFT", "oUF_Rain_Party", 0, -29.5)
		partyPets:Show()
	end
	
	if (cfg.showMT) then
		local mainTanks = self:SpawnHeader(
			"oUF_Rain_MT", nil, "raid",
			"showRaid", true,
			"groupFilter", "MAINTANK",
			"yOffset", -7.5,
			"oUF-initialConfigFunction", ([[
				self:SetWidth(110)
				self:SetHeight(22)
				self:SetAttribute("type3", "spell")
				self:SetAttribute("spell3", "%s")
			]]):format(spellName)
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
	
	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		boss[i] = self:Spawn("boss"..i, "oUF_Rain_Boss"..i)
		
		if (i == 1) then
			boss[i]:SetPoint("TOP", UIParent, "TOP", 0, -20)
		else
			boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -15)
		end
	end
end)
