local parentBarWidth
local parentBarTex
local terminationPoints = select(5, GetTalentInfo(2, 12)) -- (http://www.wowhead.com/spell=83490)
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax
local UnitPowerMax = UnitPowerMax

local GetFocusPrediction = function()
	local focusPrediction = 9
 
	if terminationPoints then
		if (UnitHealth("target") / UnitHealthMax("target") <= 0.25) then
			focusPrediction = focusPrediction + terminationPoints * 3 -- +3 focus per talent point
		end
	end
	
	return focusPrediction
end

local GetSpellFocusCost = function(talentTree, focusSpark)
	local spellFocusCost
	local bmSpell = focusSpark.bmSpell or 34026	-- Kill Command
	local mmSpell = focusSpark.mmSpell or 53209	-- Chimera Shot
	local svSpell = focusSpark.svSpell or 53301	-- Explosive Shot

	if (talentTree == 3 and IsSpellKnown(svSpell)) then		-- SURVIVAL
		spellFocusCost = select(4, GetSpellInfo(svSpell))
	elseif (talentTree == 2 and IsSpellKnown(mmSpell)) then	-- MARKMANSHIP
		spellFocusCost = select(4, GetSpellInfo(mmSpell))
	elseif (IsSpellKnown(bmSpell)) then
		spellFocusCost = select(4, GetSpellInfo(bmSpell))
	end
	
	return spellFocusCost
end

local UpdateFocusGain = function(self, event, unit, spellName, spellRank, seqID, spellID)
	if (unit ~= "player") then return end
	if (spellID == 77767 or spellID == 56641) then
		focusGain = self.FocusGain
	
		if (event == "UNIT_SPELLCAST_START") then
			focusGain:SetWidth(GetFocusPrediction() * parentBarWidth / UnitPowerMax("player", 2))
			focusGain:SetPoint("LEFT", parentBarTex, "RIGHT", 0, 0)
			focusGain:Show()
		else
			focusGain:Hide()
		end
		
		if (focusGain.PostUpdate) then
			return focusGain:PostUpdate(event, unit, spellName, spellID)
		end
	end
end

local UpdateFocusSpark = function(self, event, ...)
	local focusSpark = self.FocusSpark
	if (focusSpark.PreUpdate) then
		focusSpark:PreUpdate()
	end
	
	local spellFocusCost = GetSpellFocusCost(GetPrimaryTalentTree(), focusSpark)
	
	if (spellFocusCost and self.unit ~= "vehicle") then
		local sparkXPos = spellFocusCost * parentBarWidth / UnitPowerMax("player", 2)
		local xOffset = focusSpark:GetWidth() / 2
		focusSpark:SetPoint("LEFT", sparkXPos - xOffset, 0)
		focusSpark:Show()
	else
		focusSpark:Hide()
	end

	if (focusSpark.PostUpdate) then
		return focusSpark:PostUpdate(sparkXPos, xOffset)
	end
end

local Update = function(self, event, ...)
	if (self.realUnit and self.realUnit ~= "player") then return end -- update the player frame when in vehicle
	if (not self.realUnit and self.unit ~= "player") then return end

	if (event:match("UNIT_SPELLCAST_")) then
		UpdateFocusGain(self, event, ...)
	else
		UpdateFocusSpark(self, event, ...)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, "ForceUpdate", element.__owner.unit)
end

local Enable = function(self)
	local _, playerClass = UnitClass("player")
	if (playerClass ~= "HUNTER" or self.unit ~= "player") then return end

	local focusSpark = self.FocusSpark
	local focusGain = self.FocusGain
	
	if (focusSpark) then
		focusSpark.__owner = self
		focusSpark.ForceUpdate = ForceUpdate

		parentBarWidth = focusSpark:GetParent():GetWidth()

		if (focusSpark:IsObjectType("Texture") and not focusSpark:GetTexture()) then
			focusSpark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark")
			focusSpark:SetBlendMode("ADD")
		end

		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", Update)
		self:RegisterEvent("LEARNED_SPELL_IN_TAB", Update)
	end

	if (focusGain) then
		focusGain.__owner = self
		focusGain.ForceUpdate = ForceUpdate
		
		parentBarWidth = focusGain:GetParent():GetWidth()
		parentBarTex = focusGain:GetParent():GetStatusBarTexture()

		if (focusGain:IsObjectType("Texture") and not focusGain:GetTexture()) then
			focusGain:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
		end

		self:RegisterEvent("UNIT_SPELLCAST_START", Update)
		self:RegisterEvent("UNIT_SPELLCAST_STOP", Update)
		self:RegisterEvent("UNIT_SPELLCAST_FAILED", Update)
		self:RegisterEvent("UNIT_SPELLCAST_INTERRUPTED", Update)
	end

	return true
end

local Disable = function(self)
	if (self.FocusSpark) then
		self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
		self:UnregisterEvent("LEARNED_SPELL_IN_TAB")
	end
	
	if (self.FocusGain) then
		self:UnregisterEvent("UNIT_SPELLCAST_START")
		self:UnregisterEvent("UNIT_SPELLCAST_STOP")
		self:UnregisterEvent("UNIT_SPELLCAST_FAILED")
		self:UnregisterEvent("UNIT_SPELLCAST_INTERRUPTED")
	end
end

oUF:AddElement("FocusHelper", Update, Enable, Disable)