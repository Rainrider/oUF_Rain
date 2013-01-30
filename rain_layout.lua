﻿local _, ns = ...

local major, minor, rev = strsplit(".", GetAddOnMetadata("oUF", "version"))
minor = minor or 0
rev = rev or 0
local oUFversion = major * 1000 + minor * 100 + rev

assert(oUFversion >= 1600, "Consider updating your version of oUF to at least 1.6")

local PutFontString = ns.PutFontString

local playerClass = ns.playerClass

-- layout rules for specific unit frames (auras, combo points, totembar, runes, holy power, shards, druid mana ...)
local UnitSpecific = {
	player = function(self)
		ns.AddSwingBar(self)
		ns.AddReputationBar(self)
		ns.AddExperienceBar(self)
		ns.AddAltPowerBar(self)

		if (playerClass == "DEATHKNIGHT") then
			ns.AddRuneBar(self, 215, 5, 1)
			ns.AddTotems(self, 60, 5)
		elseif (playerClass == "DRUID") then
			ns.AddEclipseBar(self, 230, 7)
			ns.AddTotems(self, 30, 5)
		elseif (playerClass == "MONK") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
		elseif (playerClass == "PALADIN") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
		elseif (playerClass == "PRIEST") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
		elseif (playerClass == "SHAMAN") then
			ns.AddTotems(self, nil, 5)
		elseif (playerClass == "WARLOCK") then
			ns.AddWarlockPowerBar(self, 215, 5, 1)
		end

		ns.AddCombatIcon(self)
		ns.AddRestingIcon(self)

		self:RegisterEvent("PLAYER_TARGET_CHANGED", function()
			if (UnitExists("target")) then
				PlaySound("igCreatureAggroSelect")
			else
				PlaySound("igCreatureAggroDeselect")
			end
		end)

		self:Tag(self.Power.value, "[rain:power][ - >rain:altmana]")
	end,

	target = function(self)
		self.Info = PutFontString(self.Health, ns.media.FONT2, 12, nil, "LEFT")
		self.Info:SetPoint("TOPLEFT", 3.5, -3.5)
		self.Info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
		self:Tag(self.Info, "[rain:role< ][rain:name][difficulty][ >rain:level][ >shortclassification]|r")

		ns.AddComboPointsBar(self, 215, 5, 1)

		ns.AddQuestIcon(self)
		ns.AddResurrectIcon(self)
		ns.AddRangeCheck(self)

		self:Tag(self.Power.value, "[rain:power]")
	end,

	pet = function(self)
		ns.AddAltPowerBar(self) -- this is needed when the player is in vehicle. because the pet frame then holds the player unit

		ns.AddDebuffs(self, "pet")
		ns.AddBuffs(self, "pet")
		ns.AddRangeCheck(self)
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

	local unitIsPartyMember = self:GetParent():GetName():match("^oUF_Rain_Party$") -- could use unit == "party" here as long as showRaid is false on the party header
	local unitIsPartyOrMTTarget = unit == "partytarget" or unit == "maintanktarget"
	local unitIsPartyPet = unit == "partypet"
	local unitIsMT = unit == "maintank"
	local unitIsBoss = unit:match("^boss%d$")

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

		self.Power.altPowerColor = {0, 0.5, 1}
		self.Power.colorPower = unit == "player" or unit == "pet" or unitIsBoss
		self.Power.colorClass = true
		self.Power.colorReaction = true
		self.Power.frequentUpdates = true

		if (unitIsBoss) then
			self.Power.displayAltPower = true
		end

		self.Power.bg = self.Power:CreateTexture(nil, "BORDER")
		self.Power.bg:SetAllPoints()
		self.Power.bg:SetTexture(ns.media.TEXTURE)
		self.Power.bg.multiplier = 0.5

		self.Power.PostUpdate = ns.PostUpdatePower
	end

	ns.AddRaidIcon(self, unit)
	ns.AddPhaseIcon(self)

	if (unit == "player" or unit == "target") then
		self:SetSize(230, 50)

		self.Health:SetSize(230, 30)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")

		self.Health.value = PutFontString(self.Health, ns.media.FONT2, 12, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", self.Health, -3.5, -3.5)
		self:Tag(self.Health.value, "[dead][offline][rain:health]")

		self.Power:SetSize(230, 15)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")

		self.Power.value = PutFontString(self.Health, ns.media.FONT2, 12, nil, "LEFT")
		self.Power.value:SetPoint("TOPLEFT", self.Health, 3.5, -3.5)

		ns.AddPortrait(self)
		ns.AddOverlay(self, unit)
		ns.AddCastbar(self, unit)
		ns.AddHealPredictionBar(self, unit)

		if (unit == "player" and ns.cfg.showPlayerBuffs or unit == "target") then
			ns.AddBuffs(self, unit)
		end
		ns.AddDebuffs(self, unit)
		ns.AddDebuffHighlight(self, unit)

		self.Status = PutFontString(self.Portrait, ns.media.FONT2, 18, "OUTLINE", "RIGHT")
		self.Status:SetPoint("RIGHT", -3.5, 2)
		self.Status:SetTextColor(0.69, 0.31, 0.31, 0.6)
		self:Tag(self.Status, "[pvp]")

		self:HookScript("OnEnter", function(self)
			if (UnitIsUnit("player", unit) and UnitIsPVP(unit)) then
				local pvpTimer = GetPVPTimer() / 1000 -- remaining seconds
				if (pvpTimer < 300 and pvpTimer > 0) then
					self.Status:SetText(format("%d:%02d", floor(pvpTimer / 60), pvpTimer % 60))
				end
			end
		end)

		self:HookScript("OnLeave", function(self)
			self.Status:UpdateTag()
		end)

		ns.AddAssistantIcon(self)
		ns.AddLeaderIcon(self)
		ns.AddMasterLooterIcon(self)
		ns.AddReadyCheckIcon(self)
	end

	if (unit == "pet" or unit == "focus"
			or unit == "targettarget" or unit == "focustarget") then
		self:SetSize(110, 22)
	end

	if ((unit == "pet" or unit == "focus"
			or unit == "targettarget" or unit == "focustarget"
			or unitIsPartyMember or unitIsPartyOrMTTarget
			or unitIsMT or unitIsBoss) and not unitIsPartyPet) then

		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")

		self.Health.value = PutFontString(self.Health, ns.media.FONT2, 9, nil, "RIGHT")
		self.Health.value:SetPoint("TOPRIGHT", -2, -2)
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

			ns.AddAssistantIcon(self)
			ns.AddLeaderIcon(self)
			ns.AddMasterLooterIcon(self)
			ns.AddReadyCheckIcon(self)
			ns.AddResurrectIcon(self)

			ns.AddAuras(self, unit)
			ns.AddDebuffHighlight(self, unit)
			ns.AddRangeCheck(self)
		end

		if (unitIsMT) then
			ns.AddResurrectIcon(self)
			ns.AddRangeCheck(self)
		end

		if (unitIsBoss) then
			ns.AddBuffs(self, unit)
			ns.AddCastbar(self, unit)
		end

		if (unit == "pet" or unit == "focus"  or unitIsPartyMember) then
			ns.AddCastbar(self, unit)
			ns.AddHealPredictionBar(self, unit)
			self:RegisterEvent("UNIT_THREAT_SITUATION_UPDATE", ns.AddThreatHighlight)
		end
	end

	if (unitIsPartyPet) then
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

		ns.AddRangeCheck(self)
	end

	if (UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

oUF:RegisterStyle("Rain", Shared)
oUF:RegisterStyle("RainRaid", ns.RaidStyle)
oUF:Factory(function(self)
	local cfg = ns.cfg

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
				"oUF_Rain_Party", nil, "party",
				"showParty", true,
				"showRaid", false,
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
			party:SetPoint("LEFT", UIParent, "BOTTOM", -231.25, 130)
		else
			party = self:SpawnHeader(
				"oUF_Rain_Party", nil, "party",
				"showParty", true,
				"showRaid", false,
				"yOffset", -27.5,
				"oUF-initialConfigFunction", ([[
					self:SetWidth(110)
					self:SetHeight(22)
					self:SetAttribute("type3", "spell")
					self:SetAttribute("spell3", "%s")
				]]):format(spellName)
			)
			party:SetPoint("TOPLEFT", UIParent, 125, -25)
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
			partyTargets:SetPoint("TOPLEFT", oUF_Rain_Party, "BOTTOMLEFT", 0, -27.5)
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
			partyTargets:SetPoint("TOPLEFT", oUF_Rain_Party, "TOPRIGHT", 7.5, 0)
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
		partyPets:SetPoint("TOPLEFT", oUF_Rain_Party, 0, -29.5)
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
		mainTankTargets:SetPoint("TOPLEFT", oUF_Rain_MT, "TOPRIGHT", 7.5, 0)
		mainTankTargets:Show()
	end

	local boss = {}
	for i = 1, MAX_BOSS_FRAMES do
		boss[i] = self:Spawn("boss"..i, "oUF_Rain_Boss"..i)
		boss[i]:SetSize(110, 22)

		if (i == 1) then
			boss[i]:SetPoint("TOP", UIParent, "TOP", 0, -20)
		else
			boss[i]:SetPoint("TOP", boss[i-1], "BOTTOM", 0, -15)
		end
	end

	self:SetActiveStyle("RainRaid")
	-- TODO: add options for horizontal grow / filtering
	if (cfg.showRaid) then
		local hiddenParent = CreateFrame("Frame")
		hiddenParent:Hide()
		CompactRaidFrameContainer:UnregisterAllEvents()
		CompactRaidFrameContainer:Hide()
		CompactRaidFrameContainer:SetParent(hiddenParent)

		local raid = {} -- need that for positioning the groups

		for i = 1, NUM_RAID_GROUPS do
			local raidGroup = self:SpawnHeader(
				"oUF_Rain_RaidGroup" .. i, nil, "raid",
				"showRaid", true,
				"groupFilter", i,
				"yOffset", -7.5,
				"oUF-initialConfigFunction", ([[
					self:SetWidth(64)
					self:SetHeight(30)
					self:SetAttribute("type3", "spell")
					self:SetAttribute("spell3", "%s")
				]]):format(spellName)
			)
			table.insert(raid, raidGroup)

			if (i == 1) then
				raidGroup:SetPoint("TOPLEFT", UIParent, 15, -15)
			else
				raidGroup:SetPoint("TOPLEFT", raid[i - 1], "TOPRIGHT", 7.5, 0)
			end
		end
	end
end)

oUF:RegisterInitCallback(function(self)
	if (self:IsElementEnabled("DebuffHighlight")) then
		self:DisableElement("DebuffHighlight")
	end

	if (self:IsElementEnabled("Experience")) then
		self:DisableElement("Experience")
	end

	return true
end)
