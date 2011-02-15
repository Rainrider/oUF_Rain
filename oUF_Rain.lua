local _, ns = ...

local cfg = ns.config

local playerClass = select(2, UnitClass("player"))

local backdrop = {
	bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
	edgeFile = cfg.BORDER,
	edgeSize = 2,
	insets = {top = 2, left = 2, bottom = 2, right = 2},
}

local colors = setmetatable({
	power = setmetatable({
		["MANA"] = {0.31, 0.45, 0.63},
		["RAGE"] = {0.69, 0.31, 0.31},
		["FOCUS"] = {0.71, 0.43, 0.27},
		["ENERGY"] = {0.65, 0.63, 0.35},
		["HAPPINESS"] = {0.19, 0.58, 0.58},
		["RUNES"] = {0.55, 0.57, 0.61},
		["RUNIC_POWER"] = {0, 0.82, 1},
		["AMMOSLOT"] = {0.8, 0.6, 0},
		["FUEL"] = {0, 0.55, 0.5},
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
		["HOLY_POWER"] = {0.95, 0.93, 0.15},	
		["SOUL_SHARDS"] = {0.5, 0.0, 0.56},
	}, {__index = oUF.colors.power}),
	happiness = setmetatable({
		[1] = {0.69, 0.31, 0.31},
		[2] = {0.65, 0.63, 0.35},
		[3] = {0.33, 0.59, 0.33},
	}, {__index = oUF.colors.happiness}),
}, {__index = oUF.colors})

oUF.colors.power["MANA"] = {0.31, 0.45, 0.63}

-- pre and post function go here

local function PostUpdateHealth(health, unit, min, max)
	if not UnitIsConnected(unit) or UnitIsDeadOrGhost(unit) then
		local class = select(2, UnitClass(unit))
		local color = UnitIsPlayer(unit) and oUF.colors.class[class] or {0.84, 0.75, 0.65}

		health:SetValue(0)
		health.bg:SetVertexColor(color[1] * 0.5, color[2] * 0.5, color[3] * 0.5)
--[[ This is included in the health tag
		if not UnitIsConnected(unit) then
			health.value:SetText("|cffD7BEA5".._G["PLAYER_OFFLINE"].."|r")
		elseif UnitIsDead(unit) then
			health.value:SetText("|cffD7BEA5".._G["DEAD"].."|r")
		elseif UnitIsGhost(unit) then
			health.value:SetText("|cffD7BEA5".."Ghost".."|r")
		end		--]]
	elseif UnitIsTapped(unit) and not UnitIsTappedByPlayer(unit) then
		health:SetStatusBarColor(unpack(oUF.colors.tapped))
		health.bg:SetVertexColor(0.15, 0.15, 0,15)
	else
		local r, g, b
		r, g, b = oUF.ColorGradient(min/max, 0.69, 0.31, 0.31, 0.71, 0.43, 0.27, 0.17, 0.17, 0.24)

		health:SetStatusBarColor(r, g, b)
		health.bg:SetVertexColor(0.15, 0.15, 0.15)
		
		-- TODO health value coloring / doable with tags?
		r, g, b = oUF.ColorGradient(min/max, 0.69, 0.31, 0.31, 0.65, 0.63, 0.35, 0.33, 0.59, 0.33)
		if min ~= max then
			health.value:SetTextColor(r, g, b)
		else
			health.value:SetTextColor(r, g, b)
		end
		
	end

end

local function PreUpdatePower(power, unit)
	local _, pName = UnitPowerType(unit)
	
	local color = colors.power[pName]
	if color then
		power:SetStatusBarColor(unpack(color))
	end
end

local function PostUpdatePower(Power, unit, min, max)
	local pType, pName = UnitPowerType(unit)
	local color = colors.power[pName]
	
	if color then
		Power.value:SetTextColor(unpack(color))
	end
end


-- layout rules for specific unit frames (auras, combo points, totembar, runes, holy power, shards, druid mana ...)
local UnitSpecific = {
	player = function(self)
		ns.AddPortrait(self, nil, nil)
		ns.AddOverlay(self)
		ns.AddCombatFeedbackText(self)
		ns.AddHealPredictionBar(self, 230, true)
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
		ns.AddPortrait(self, nil, nil)
		ns.AddOverlay(self)
		ns.AddCombatFeedbackText(self)
		ns.AddHealPredictionBar(self, 230, true)
		ns.AddComboPointsBar(self, nil, 5)
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
	
	self.FrameBackdrop = CreateFrame("Frame", nil, self)
	self.FrameBackdrop:SetFrameLevel(self:GetFrameLevel() - 1)
	self.FrameBackdrop:SetPoint("TOPLEFT", self, -5, 5)
	self.FrameBackdrop:SetPoint("BOTTOMRIGHT", self, 5, -5)
	self.FrameBackdrop:SetBackdrop(backdrop)
	self.FrameBackdrop:SetBackdropColor(0, 0, 0, 0)
	self.FrameBackdrop:SetBackdropBorderColor(0, 0, 0)
	
	-- health bar
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
	
	self.Health.PostUpdate = PostUpdateHealth
	
	self.Health.value = self.Health:CreateFontString(nil, "OVERLAY")
	self.Health.value:SetPoint("TOPRIGHT", self.Health, -2, -5)
	self.Health.value:SetFont(cfg.FONT, 12, "OUTLINE")
	self.Health.value:SetJustifyH("RIGHT")
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
	
	self.Power.value = self.Health:CreateFontString(nil, "OVERLAY")
	self.Power.value:SetPoint("TOPLEFT", self.Health, 2, -5)
	self.Power.value:SetFont(cfg.FONT, 12, "OUTLINE")
	self.Power.value:SetJustifyH("LEFT")
	self:Tag(self.Power.value, "[rain:perpp][rain:power]")
	
	self.Power.PreUpdate = PreUpdatePower
	self.Power.PostUpdate = PostUpdatePower
	
	if(unit == "player" or unit == "target") then
		-- set frame size
		self:SetSize(230, 50)
	
		self.Health:SetSize(230, 30)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Power:SetSize(230, 15)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
	end
	
	if(unit == "pet" or unit == "focus" or unit:find("target") and unit ~= "target") then
		self:SetSize(110, 22)
		
		self.Health:SetSize(110, 15)
		self.Health:SetPoint("TOPRIGHT")
		self.Health:SetPoint("TOPLEFT")
		
		self.Power:SetSize(110, 5)
		self.Power:SetPoint("BOTTOMRIGHT")
		self.Power:SetPoint("BOTTOMLEFT")
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