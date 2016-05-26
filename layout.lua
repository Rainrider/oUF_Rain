local _, ns = ...

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
		ns.AddReputationBar(self)
		ns.AddExperienceBar(self)
		ns.AddAltPowerBar(self)
		ns.AddTotems(self, 215, 5, 1)
		ns.AddComboPointsBar(self, 215, 5, 1)

		if (playerClass == "DEATHKNIGHT") then
			ns.AddRuneBar(self, 215, 5, 1)
		elseif (playerClass == "DRUID") then
			-- TODO: lunar power
		elseif (playerClass == "MONK") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
		elseif (playerClass == "PALADIN") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
		elseif (playerClass == "PRIEST") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
		elseif (playerClass == "WARLOCK") then
			ns.AddClassPowerIcons(self, 215, 5, 1)
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
		local info = PutFontString(self.Health, ns.media.FONT2, 12, nil, "LEFT")
		info:SetPoint("TOPLEFT", 3.5, -3.5)
		info:SetPoint("RIGHT", self.Health.value, "LEFT", -5, 0)
		self:Tag(info, "[rain:role< ][rain:name][difficulty][ >rain:level][ >shortclassification]|r")
		self.Info = info

		ns.AddQuestIcon(self)
		ns.AddResurrectIcon(self)
		ns.AddRangeCheck(self)

		self:Tag(self.Power.value, "[rain:power]")
	end,

	pet = function(self)
		ns.AddAltPowerBar(self) -- this is needed when the player is in vehicle. because the pet frame then holds the player unit

		ns.AddAuras(self, "pet")
		ns.AddRangeCheck(self)
	end,

	focus = function(self)
		ns.AddDebuffs(self, "focus")
		ns.AddDispelHighlight(self, "focus")
	end,

	targettarget = function(self)
		ns.AddDispelHighlight(self, "targettarget")
	end,
}

-- shared rules between more than one unit
-- pet, focus, tot and focustarget would be basicaly the same
local Shared = function(self, unit)

	self.colors = ns.colors

	self:RegisterForClicks("AnyDown")
	self:SetScript("OnEnter", UnitFrame_OnEnter)
	self:SetScript("OnLeave", UnitFrame_OnLeave)

	local unitIsPartyMember = self:GetParent():GetName():match("^oUF_Rain_Party$") -- could use unit == "party" here as long as showRaid is false on the party header
	local unitIsPartyOrMTTarget = unit == "partytarget" or unit == "maintanktarget"
	local unitIsPartyPet = unit == "partypet"
	local unitIsMT = unit == "maintank"
	local unitIsBoss = unit:match("^boss%d$")

	local frameBackdrop = CreateFrame("Frame", nil, self)
	frameBackdrop:SetFrameLevel(self:GetFrameLevel() - 1)
	frameBackdrop:SetPoint("TOPLEFT", self, -5, 5)
	frameBackdrop:SetPoint("BOTTOMRIGHT", self, 5, -5)
	frameBackdrop:SetBackdrop(ns.media.BACKDROP2)
	frameBackdrop:SetBackdropColor(0, 0, 0, 0)
	frameBackdrop:SetBackdropBorderColor(0, 0, 0)
	self.FrameBackdrop = frameBackdrop

	local health = CreateFrame("StatusBar", self:GetName().."_Health", self)
	health:SetStatusBarTexture(ns.media.TEXTURE)
	health.colorTapping = true
	health.colorDisconnected = true
	health.colorSmooth = true
	health.frequentUpdates = unit == "player" or unit == "target" or unitIsBoss -- TODO: remove unitIsBoss here when Blizzard fixes UNIT_HEALTH for boss units
	health:SetBackdrop(ns.media.BACKDROP)
	health:SetBackdropColor(0, 0, 0)
	self.Health = health

	local hbBG = health:CreateTexture(nil, "BORDER")
	hbBG:SetAllPoints()
	hbBG:SetTexture(ns.media.TEXTURE)
	hbBG:SetVertexColor(0.15, 0.15, 0.15)
	health.background = hbBG

	health.Override = ns.UpdateHealth

	local power

	if (not unitIsPartyPet) then
		power = CreateFrame("StatusBar", self:GetName().."_Power", self)
		power:SetStatusBarTexture(ns.media.TEXTURE)
		power:SetBackdrop(ns.media.BACKDROP)
		power:SetBackdropColor(0, 0, 0)

		power.altPowerColor = {0, 0.5, 1}
		power.colorPower = unit == "player" or unit == "pet" or unitIsBoss
		power.colorClass = true
		power.colorReaction = true
		power.frequentUpdates = unit == "player" or unit == "target"

		if (unitIsBoss) then
			power.displayAltPower = true
		end

		local pbBG = power:CreateTexture(nil, "BORDER")
		pbBG:SetAllPoints()
		pbBG:SetTexture(ns.media.TEXTURE)
		pbBG.multiplier = 0.5
		power.bg = pbBG

		power.PostUpdate = unit == "player" and playerClass == "MONK" and ns.UpdateMonkStagger or ns.PostUpdatePower
		self.Power = power
	end

	ns.AddRaidIcon(self)
	ns.AddPhaseIcon(self)

	if (unit == "player" or unit == "target") then
		self:SetSize(230, 50)

		health:SetSize(230, 30)
		health:SetPoint("TOPRIGHT")
		health:SetPoint("TOPLEFT")

		local healthValue = PutFontString(health, ns.media.FONT2, 12, nil, "RIGHT")
		healthValue:SetPoint("TOPRIGHT", health, -3.5, -3.5)
		self:Tag(healthValue, "[rain:health]")
		health.value = healthValue

		power:SetSize(230, 15)
		power:SetPoint("BOTTOMRIGHT")
		power:SetPoint("BOTTOMLEFT")

		local powerValue = PutFontString(health, ns.media.FONT2, 12, nil, "LEFT")
		powerValue:SetPoint("TOPLEFT", health, 3.5, -3.5)
		power.value = powerValue

		ns.AddPortrait(self)
		ns.AddOverlay(self, unit)
		ns.AddCastbar(self, unit)
		ns.AddHealPredictionBar(self, unit)
		ns.AddThreatHighlight(self)

		if (unit == "player" and ns.cfg.showPlayerBuffs or unit == "target") then
			ns.AddBuffs(self, unit)
		end
		ns.AddDebuffs(self, unit)
		ns.AddDispelHighlight(self, unit)

		local pvpStatus = PutFontString(self.Portrait, ns.media.FONT2, 18, "OUTLINE", "RIGHT")
		pvpStatus:SetPoint("RIGHT", -3.5, 2)
		pvpStatus:SetTextColor(0.69, 0.31, 0.31, 0.6)
		self:Tag(pvpStatus, "[pvp]")

		self:HookScript("OnEnter", function(self)
			if (UnitIsUnit("player", unit) and UnitIsPVP(unit)) then
				local pvpTimer = GetPVPTimer() / 1000 -- remaining seconds
				if (pvpTimer < 300 and pvpTimer > 0) then
					pvpStatus:SetText(format("%d:%02d", floor(pvpTimer / 60), pvpTimer % 60))
				end
			end
		end)

		self:HookScript("OnLeave", function(self)
			pvpStatus:UpdateTag()
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

	if (unit ~= "player" and unit ~= "target" and not unitIsPartyPet) then

		health:SetSize(110, 15)
		health:SetPoint("TOPRIGHT")
		health:SetPoint("TOPLEFT")

		local healthValue = PutFontString(health, ns.media.FONT2, 9, nil, "RIGHT")
		healthValue:SetPoint("TOPRIGHT", -2, -2)
		if (unitIsBoss) then
			self:Tag(healthValue, "[rain:bossHealth]")
		else
			self:Tag(healthValue, "[rain:healthSmall]")
		end
		health.value = healthValue

		power:SetSize(110, 5)
		power:SetPoint("BOTTOMRIGHT")
		power:SetPoint("BOTTOMLEFT")

		local name = PutFontString(health, ns.media.FONT2, 9, nil, "LEFT")
		name:SetPoint("TOPLEFT", 2, -2)
		name:SetPoint("RIGHT", healthValue, "LEFT", -3, 0)

		if (not unitIsPartyMember) then
			self:Tag(name, "[rain:name]")
		else
			self:Tag(name, "[rain:role][rain:name]")

			ns.AddAssistantIcon(self)
			ns.AddLeaderIcon(self)
			ns.AddMasterLooterIcon(self)
			ns.AddReadyCheckIcon(self)
			ns.AddResurrectIcon(self)

			--ns.AddAuras(self, unit)
			ns.AddDispelHighlight(self, unit)
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
			ns.AddThreatHighlight(self)
		end
	end

	if (unitIsPartyPet) then
		health:SetSize(110, 10)
		health:SetPoint("TOPRIGHT")
		health:SetPoint("TOPLEFT")

		local healthValue = PutFontString(health, ns.media.FONT2, 9, nil, "RIGHT")
		healthValue:SetPoint("RIGHT", -2, 0)
		self:Tag(healthValue, "[perhp<%]")
		health.value = healthValue

		local name = PutFontString(health, ns.media.FONT2, 9, nil, "LEFT")
		name:SetPoint("LEFT", 2, 0)
		name:SetPoint("RIGHT", healthValue, "LEFT", -3, 0)
		self:Tag(name, "[rain:name]")

		ns.AddRangeCheck(self)
	end

	if (UnitSpecific[unit]) then
		return UnitSpecific[unit](self)
	end
end

local raid = {}

oUF:RegisterStyle("Rain", Shared)
oUF:RegisterStyle("RainRaid", ns.RaidStyle)
oUF:Factory(function(self)
	local cfg = ns.cfg

	local spellName = GetSpellInfo(cfg.clickSpell[playerClass] or 6603)	-- 6603 Auto Attack

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

SLASH_OUF_RAIN1 = "/raintest"
SlashCmdList.OUF_RAIN = function(group)
	if group == "raid" then
		local raid = {}
		oUF:SetActiveStyle("RainRaid")
		for i = 1, 8 do
			local header = oUF:SpawnHeader(
				"oUF_Rain_TestRaidGroup"..i, nil, "solo",
				"showSolo", true,
				"showRaid", true,
				"yOffset", -7.5,
				"oUF-initialConfigFunction", [[
					self:SetWidth(64)
					self:SetHeight(30)
				]]
			)
			raid[i] = header
			if (i == 1) then
				header:SetPoint("LEFT", UIParent, 150, -15)
			else
				header:SetPoint("TOPLEFT", raid[i - 1], "TOPRIGHT", 7.5, 0)
			end
		end
	elseif group == "party" then
		oUF:SetActiveStyle("Rain")
		local party = oUF:SpawnHeader(
				"oUF_Rain_TestParty", nil, "solo",
				"showSolo", true,
				"showParty", true, -- need this or else oUF gets confused about the unit
				"maxColumns", 4,
				"unitsPerColumn", 1,
				"columnAnchorPoint", "LEFT",
				"columnSpacing", 9.5,
				"oUF-initialConfigFunction", [[
					self:SetWidth(110)
					self:SetHeight(22)
				]]
			)
		party:SetPoint("LEFT", UIParent, "BOTTOM", -231.25, 130)
	end
end
