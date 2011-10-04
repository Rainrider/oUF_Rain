--[[====================================================================================
	DESCRIPTION:
	Contains functions for additing functionality through modules not part of oUF itself
	====================================================================================--]]

--[[ TODO:	WeaponEnchant
			AuraWatch
]]

local _, ns = ...

local cfg = ns.config
local PutFontString = ns.PutFontString

local AddCombatFeedbackText = function(self)
	if (not IsAddOnLoaded("oUF_CombatFeedback")) then return end

	self.CombatFeedbackText = PutFontString(self.Overlay, ns.media.FONT, 14, "OUTLINE", "LEFT")
	self.CombatFeedbackText:SetPoint("CENTER", 0, 5)
	self.CombatFeedbackText.colors = ns.combatFeedbackColors
end
ns.AddCombatFeedbackText = AddCombatFeedbackText

local AddDebuffHighlight = function(self, unit)
	self.DebuffHighlight = CreateFrame("Frame", self:GetName().."_DebuffHighlight", self.Health)
	self.DebuffHighlight:SetAllPoints()
	self.DebuffHighlight:SetFrameLevel(self.DebuffHighlight:GetParent():GetFrameLevel() + 1)
	
	self.DebuffHighlightFilter = cfg.dispelTypeFilter

	self.DebuffHighlightTexture = self.DebuffHighlight:CreateTexture(nil, "OVERLAY")
	self.DebuffHighlightTexture:SetAllPoints()
	self.DebuffHighlightTexture:SetTexture(ns.media.HIGHLIGHTTEXTURE)
	self.DebuffHighlightTexture:SetBlendMode("ADD")
	self.DebuffHighlightTexture:SetVertexColor(0, 0, 0, 0)
	
	if (unit == "player" or unit == "target") then
		self.DebuffHighlightIcon = self.Overlay:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIcon:SetSize(18, 18)
		
		self.DebuffHighlightIconOverlay = self.Overlay:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIconOverlay:SetPoint("TOPLEFT", self.DebuffHighlightIcon, -3.5, 3.5)
		self.DebuffHighlightIconOverlay:SetPoint("BOTTOMRIGHT", self.DebuffHighlightIcon, 3.5, -3.5)
	else
		self.DebuffHighlightIcon = self.Health:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIcon:SetSize(16, 16)
		
		self.DebuffHighlightIconOverlay = self.DebuffHighlight:CreateTexture(nil, "OVERLAY")
		self.DebuffHighlightIconOverlay:SetPoint("TOPLEFT", self.DebuffHighlightIcon, -1, 1)
		self.DebuffHighlightIconOverlay:SetPoint("BOTTOMRIGHT", self.DebuffHighlightIcon, 1, -1)
	end
	self.DebuffHighlightIcon:SetPoint("CENTER")
	self.DebuffHighlightIcon:SetTexCoord(0.1, 0.9, 0.1, 0.9)
	self.DebuffHighlightIconOverlay:SetTexture(ns.media.BTNTEXTURE)
	self.DebuffHighlightIconOverlay:SetVertexColor(0, 0, 0, 0)
end
ns.AddDebuffHighlight = AddDebuffHighlight
	
local AddExperienceBar = function(self)
	self.Experience = CreateFrame("StatusBar", "oUF_Rain_Experience", self)
	self.Experience:SetHeight(5)
	self.Experience:SetPoint("BOTTOMLEFT", self.Health, "TOPLEFT", 0, 2.5)
	self.Experience:SetPoint("BOTTOMRIGHT", self.Health, "TOP", -2, 2.5)
	self.Experience:SetStatusBarTexture(ns.media.TEXTURE)
	self.Experience:SetStatusBarColor(0.67, 0.51, 1)
	self.Experience:SetBackdrop(ns.media.BACKDROP)
	self.Experience:SetBackdropColor(0, 0, 0)
	self.Experience:SetAlpha(0)
		
	self.Experience:EnableMouse()
	self.Experience:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
	self.Experience:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

	self.Experience.Rested = CreateFrame("StatusBar", "oUF_Rain_Experience_Rested", self.Experience)
	self.Experience.Rested:SetPoint("TOPLEFT", self.Experience:GetStatusBarTexture(), "TOPRIGHT", 0, 0)
	self.Experience.Rested:SetPoint("BOTTOMRIGHT", self.Experience, 0, 0)
	self.Experience.Rested:SetStatusBarTexture(ns.media.TEXTURE)
	self.Experience.Rested:SetStatusBarColor(0, 0.56, 1)
	self.Experience.Rested:SetBackdrop(ns.media.BACKDROP)
	self.Experience.Rested:SetBackdropColor(0, 0, 0)

	self.Experience.Tooltip = function(self)
		local curXP, maxXP = UnitXP("player"), UnitXPMax("player")
		local bars = 20
		local rested = GetXPExhaustion()
		GameTooltip:SetOwner(self, "ANCHOR_TOPRIGHT", 0, 5)
		GameTooltip:AddLine(string.format("XP: %d / %d (%d%% - %.1f bars)", curXP, maxXP, curXP/maxXP * 100 + 0.5, bars * curXP / maxXP))
		GameTooltip:AddLine(string.format("Remaining: %d (%d%% - %.1f bars)", maxXP - curXP, (maxXP - curXP) / maxXP * 100 + 0.5, bars * (maxXP - curXP) / maxXP))
		if (rested and rested > 0) then
			GameTooltip:AddLine(string.format("|cff0090ffRested: +%d (%d%%)", rested, rested / maxXP * 100 + 0.5))
		end
		GameTooltip:Show()
	end
		
	self.Experience:HookScript("OnLeave", GameTooltip_Hide)
	self.Experience:HookScript("OnEnter", self.Experience.Tooltip)
end
ns.AddExperienceBar = AddExperienceBar

local AddFocusHelper = function(self)
	self.FocusSpark = self.Power:CreateTexture(nil, "OVERLAY")
	self.FocusSpark:SetWidth(10)
	self.FocusSpark:SetHeight(self.Power:GetHeight() * 1.85)
	
	self.FocusSpark.bmSpell = cfg.bmSpell -- Kill Command
	self.FocusSpark.mmSpell = cfg.mmSpell -- Chimera Shot
	self.FocusSpark.svSpell = cfg.svSpell -- Explosive Shot
	
	self.FocusGain = self.Power:CreateTexture(nil, "OVERLAY")
	self.FocusGain:SetHeight(self.Power:GetHeight())
	self.FocusGain:SetTexture(ns.media.TEXTURE)
	self.FocusGain:SetVertexColor(0, 1, 0, 0.3)
end
ns.AddFocusHelper = AddFocusHelper

local AddReputationBar = function(self)
	if (not IsAddOnLoaded("oUF_Reputation")) then return end
	
	self.Reputation = CreateFrame("StatusBar", "oUF_Rain_Reputation", self)
	self.Reputation:SetHeight(5)
	self.Reputation:SetPoint("TOPLEFT", self.Health, "TOP", 2, 7.5)
	self.Reputation:SetPoint("TOPRIGHT", self.Health, "TOPRIGHT", 0, 7.5)
	self.Reputation:SetStatusBarTexture(ns.media.TEXTURE)
	self.Reputation:SetBackdrop(ns.media.BACKDROP)
	self.Reputation:SetBackdropColor(0, 0, 0)
	self.Reputation:SetAlpha(0)
	
	self.Reputation:EnableMouse()
	self.Reputation:HookScript("OnEnter", function(self) self:SetAlpha(1) end)
	self.Reputation:HookScript("OnLeave", function(self) self:SetAlpha(0) end)

	self.Reputation.bg = self.Reputation:CreateTexture(nil, "BORDER")
	self.Reputation.bg:SetAllPoints(self.Reputation)
	self.Reputation.bg:SetTexture(ns.media.TEXTURE)
	self.Reputation.bg:SetVertexColor(0.15, 0.15, 0.15)

	self.Reputation.colorStanding = true
		
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
ns.AddReputationBar = AddReputationBar

local AddSwingBar = function(self)
	if (not IsAddOnLoaded("oUF_Swing")) then return end
		
	self.Swing = CreateFrame("Frame", self:GetName().."_Swing", self)
	self.Swing:SetHeight(3)
	self.Swing:SetPoint("TOPLEFT", self, "TOPLEFT", 0, 7)
	self.Swing:SetPoint("TOPRIGHT", self, "TOPRIGHT", 0, 7)
	self.Swing.texture = ns.media.TEXTURE
	self.Swing.color = {0.55, 0.57, 0.61, 1}
	self.Swing.textureBG = ns.media.TEXTURE
	self.Swing.colorBG = {0, 0, 0, 0.6}
	
	self.Swing.hideOoc = true
end
ns.AddSwingBar = AddSwingBar
