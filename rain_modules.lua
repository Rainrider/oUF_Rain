--[[====================================================================================
	DESCRIPTION:
	Contains functions for additing functionality through modules not part of oUF itself
	====================================================================================--]]

--[[ TODO:	WeaponEnchant
			DebuffHighlight
			AuraWatch
]]

local _, ns = ...

local cfg = ns.config
local PutFontString = ns.PutFontString
local numTotems = MAX_TOTEMS

local function AddCombatFeedbackText(self)
	if (not IsAddOnLoaded("oUF_CombatFeedback")) then return end

	self.CombatFeedbackText = PutFontString(self.Overlay, cfg.FONT, 14, "OUTLINE", "LEFT")
	self.CombatFeedbackText:SetPoint("CENTER", 0, 5)
	self.CombatFeedbackText.colors = {
		DAMAGE = {0.69, 0.31, 0.31},
		CRUSHING = {0.69, 0.31, 0.31},
		CRITICAL = {0.69, 0.31, 0.31},
		GLANCING = {0.69, 0.31, 0.31},
		STANDARD = {0.84, 0.75, 0.65},
		IMMUNE = {0.84, 0.75, 0.65},
		ABSORB = {0.84, 0.75, 0.65},
		BLOCK = {0.84, 0.75, 0.65},
		RESIST = {0.84, 0.75, 0.65},
		MISS = {0.84, 0.75, 0.65},
		HEAL = {0.33, 0.59, 0.33},
		CRITHEAL = {0.33, 0.59, 0.33},
		ENERGIZE = {0.31, 0.45, 0.63},
		CRITENERGIZE = {0.31, 0.45, 0.63},
	}
end
ns.AddCombatFeedbackText = AddCombatFeedbackText

local function AddDruidMushrooms(self)
	self.TotemBar = {}
	self.TotemBar.Destroy = true
	local r, g, b = unpack(ns.colors.class[cfg.playerClass])
	self.TotemBar.colors = {
		[1] = {r, g, b},
		[2] = {r, g, b},
		[3] = {r, g, b},
	}

	for i = 1, 3 do
		self.TotemBar[i] = CreateFrame("StatusBar", "oUF_Rain_Mushroom"..i, self.Overlay)
		self.TotemBar[i]:SetSize(30, 3)
		if i == 1 then
			self.TotemBar[i]:SetPoint("BOTTOM", self.Overlay, "TOP", 0, 0)
		elseif i == 2 then
			self.TotemBar[i]:SetPoint("RIGHT", self.TotemBar[1], "LEFT", -1, 0)
		else
			self.TotemBar[i]:SetPoint("LEFT", self.TotemBar[1], "RIGHT", 1, 0)
		end
		self.TotemBar[i]:SetStatusBarTexture(cfg.TEXTURE)
		self.TotemBar[i]:SetBackdrop(cfg.BACKDROP)
		self.TotemBar[i]:SetBackdropColor(1, 1, 1)
		
		self.TotemBar[i].bg = self.TotemBar[i]:CreateTexture(nil, "BORDER")
		self.TotemBar[i].bg:SetAllPoints()
		self.TotemBar[i].bg:SetTexture(cfg.TEXTURE)
		self.TotemBar[i].bg:SetVertexColor(0.15, 0.15, 0.15)
	end
end
ns.AddDruidMushrooms = AddDruidMushrooms

-- TODO: rested bar 
--		math.min(curXP + rested, maxXP) -- this would be the rested bar
local function AddExperienceBar(self)
	if IsAddOnLoaded("oUF_Experience") then
		self.Experience = CreateFrame("StatusBar", "oUF_Rain_Experience", self)
		self.Experience:SetHeight(5)
		self.Experience:SetPoint("TOPLEFT", self.Health, "TOPLEFT", 0, 7.5)
		self.Experience:SetPoint("TOPRIGHT", self.Health, "TOP", -2, 7.5)
		self.Experience:SetStatusBarTexture(cfg.TEXTURE)
		self.Experience:SetStatusBarColor(0.67, 0.51, 1)
		self.Experience:SetBackdrop(cfg.BACKDROP)
		self.Experience:SetBackdropColor(0, 0, 0)
		self.Experience:SetAlpha(0)
		
		self.Experience:EnableMouse()
		self.Experience:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
		self.Experience:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

		self.Experience.bg = self.Experience:CreateTexture(nil, "BORDER")
		self.Experience.bg:SetAllPoints(self.Experience)
		self.Experience.bg:SetTexture(cfg.TEXTURE)
		self.Experience.bg:SetVertexColor(0.15, 0.15, 0.15)
		
		self.Experience.Tooltip = function(self)
			local unit = self:GetParent().unit
			local curXP, maxXP
			if (unit == "pet") then
				curXP, maxXP = GetPetExperience()
			else
				curXP, maxXP = UnitXP(unit), UnitXPMax(unit)
			end
			local bars = unit == "pet" and 6 or 20
			local rested = GetXPExhaustion()
	 		
			GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
			GameTooltip:AddLine(string.format("XP: %d / %d (%d%% - %d bars)", curXP, maxXP, curXP/maxXP * 100, bars * curXP / maxXP))
			GameTooltip:AddLine(string.format("Remaining: %d (%d%% - %d bars)", maxXP - curXP, (maxXP - curXP) / maxXP * 100, bars * (maxXP - curXP) / maxXP))
			if (unit == "player" and rested and rested > 0) then
				GameTooltip:AddLine(string.format("|cff0090ffRested: +%d (%d%%)", rested, rested / maxXP * 100))
			end
			GameTooltip:Show()
		end
		
		self.Experience:HookScript("OnLeave", GameTooltip_Hide)
		self.Experience:HookScript("OnEnter", self.Experience.Tooltip)
	end
end
ns.AddExperienceBar = AddExperienceBar

local function AddHunterFocusSpark(self)
	self.FocusSpark = CreateFrame("Frame", "FocusSpark", self.Power)
	self.FocusSpark:SetWidth(10)
	self.FocusSpark:SetHeight(self.Power:GetHeight() * 1.85)
	self.FocusSpark:SetPoint("LEFT", ns.GetFocusSparkXPoint(self.Power:GetWidth()) - 5, 0)
	
	self.FocusSpark.backdrop = self.FocusSpark:CreateTexture(nil, "OVERLAY")
	self.FocusSpark.backdrop:SetAllPoints(self.FocusSpark)
	self.FocusSpark.backdrop:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
	self.FocusSpark.backdrop:SetBlendMode("ADD")
	
	self.FocusSpark:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
	self.FocusSpark:RegisterEvent("LEARNED_SPELL_IN_TAB")
	self.FocusSpark:SetScript("OnEvent", function(frame, eventName, spellID, tabID)
		frame:ClearAllPoints()
		frame:SetPoint("LEFT", ns.GetFocusSparkXPoint(self.Power:GetWidth()) - 5, 0)
	end)
end
ns.AddHunterFocusSpark = AddHunterFocusSpark

local function AddReputationBar(self)
	if IsAddOnLoaded("oUF_Reputation") then
		self.Reputation = CreateFrame("StatusBar", "oUF_Rain_Reputation", self)
		self.Reputation:SetHeight(5)
		self.Reputation:SetPoint("TOPLEFT", self.Health, "TOP", 2, 7.5)
		self.Reputation:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", 0, 7.5)
		self.Reputation:SetStatusBarTexture(cfg.TEXTURE)
		self.Reputation:SetBackdrop(cfg.BACKDROP)
		self.Reputation:SetBackdropColor(0, 0, 0)
		self.Reputation:SetAlpha(0)
		
		self.Reputation:EnableMouse()
		self.Reputation:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
		self.Reputation:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

		self.Reputation.bg = self.Reputation:CreateTexture(nil, "BORDER")
		self.Reputation.bg:SetAllPoints(self.Reputation)
		self.Reputation.bg:SetTexture(cfg.TEXTURE)
		self.Reputation.bg:SetVertexColor(0.15, 0.15, 0.15)

		self.Reputation.PostUpdate = function(bar, unit, min, max)
			local name, id = GetWatchedFactionInfo()
			bar:SetStatusBarColor(unpack(oUF.colors.reaction[id]))
		end
		
		self.Reputation.Tooltip = function(self)
			local name, id, min, max, value = GetWatchedFactionInfo()
	 		GameTooltip:SetOwner(self, "ANCHOR_TOPLEFT", 0, 5)
			GameTooltip:AddLine(string.format("%s (%s)", name, _G["FACTION_STANDING_LABEL"..id]))
			GameTooltip:AddLine(string.format("%d / %d (%d%%)", value - min, max - min, (value - min) / (max - min) * 100))
			GameTooltip:Show()
		end
		
		self.Reputation:HookScript("OnLeave", GameTooltip_Hide)
		self.Reputation:HookScript("OnEnter", self.Reputation.Tooltip)
	end
end
ns.AddReputationBar = AddReputationBar

local function AddSwingBar(self)
	if IsAddOnLoaded("oUF_Swing") then
		
		self.Swing = CreateFrame("Frame", self:GetName().."_Swing", self)
		self.Swing:SetHeight(3)
		self.Swing:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 7)
		self.Swing:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 7)
		--self.Swing:SetBackdrop(cfg.BACKDROP)
		--self.Swing:SetBackdropColor(0, 0, 0)
		self.Swing.texture = cfg.TEXTURE
		self.Swing.color = {0.55, 0.57, 0.61, 1}
		self.Swing.textureBG = cfg.TEXTURE
		self.Swing.colorBG = {0, 0, 0, 0.6}
			
		self.Swing.hideOoc = true
	end
end
ns.AddSwingBar = AddSwingBar

local function AddTotemBar(self, width, height)
	if (not IsAddOnLoaded("oUF_TotemBar")) then return end

	self.TotemBar = {}
	self.TotemBar.Destroy = true
	
	for i = 1, numTotems do
		self.TotemBar[i] = CreateFrame("StatusBar", "oUF_Rain_TotemBar"..i, self)
		self.TotemBar[i]:SetSize((215 - numTotems - 1) / numTotems, height)
		self.TotemBar[i]:SetPoint("BOTTOMLEFT", self.Overlay, (i - 1) * (214 / numTotems) + 1, 1)
		self.TotemBar[i]:SetFrameLevel(self.Overlay:GetFrameLevel() + 1)
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