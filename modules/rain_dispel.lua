--[[
		self.DebuffHightlight = Frame (to create the textures with)
		self.DebuffHighlight.filter = boolean ( true = only debuffs player can dispell )
		self.DebuffHighlight.whitelist = Table ( contains a list of spellIDs to always display: use spellID = true/false )
		
		self.DebuffHighlightBackdrop = Frame ( GetBackdrop() ~= nil )
		self.DebuffHighlightBackdropBorder = boolean ( true = color backdrop border )
		self.DebuffHighlightTexture = Texture ( GetTexture() ~= nil )
		self.DebuffHighlightIcon = Texture
		self.DebuffHighlightIconOverlay = Texture
--]]
local playerClass = select(2, UnitClass("player"))
local useWhitelist = false

local dispelList = {
	Curse = false,
	Desease = false,
	Magic = false,
	Poison = false,
}

local whitelist = {}

local debuffTypeColor = {}
for dispelType, color in pairs(_G["DebuffTypeColor"]) do
	debuffTypeColor[dispelType] = color
end

local function HasTalent(tabIndex, talentIndex, inspect, pet)
	local rank = select(5, GetTalentInfo(tabIndex, talentIndex, inspect, pet, nil))
	if rank > 0 then
		return true
	end
end

local UpdateDispelList = {
	["DRUID"] = function()
		if IsSpellKnown(2782) then					-- Remove Corruption
			dispelList.Curse = true
			dispelList.Poison = true
			if HasTalent(3, 17, false, false) then	-- Nature's Cure
				dispelList.Magic = true
			else
				dispelList.Magic = false
			end
		else
			dispelList.Curse = false
			dispelList.Poison = false
		end
	end,
	["MAGE"] = function()
		if IsSpellKnown(475) then					-- Remove Curse
			dispelList.Curse = true
		else
			dispelList.Curse = false
		end
	end,
	["PALADIN"] = function()
		if IsSpellKnown(4987) then					-- Cleanse
			dispelList.Desease = true
			dispelList.Poison = true
			if HasTalent(1, 14, false, false) then	-- Sacred Cleansing
				dispelList.Magic = true
			else
				dispelList.Magic = false
			end
		else
			dispelList.Desease = false
			dispelList.Poison = false
		end
	end,
	["PRIEST"] = function()
		if IsSpellKnown(528) then					-- Cure Desease
			dispelList.Desease = true
			if HasTalent(2, 14, false, false) then	-- Body and Soul
				dispelList.Poison = true
			else
				dispelList.Poison = false
			end
		else
			dispelList.Desease = false
		end
		if IsSpellKnown(527) then					-- Dispel Magic
			dispelList.Magic = true
		else
			dispelList.Magic = false
		end
	end,
	["SHAMAN"] = function()
		if IsSpellKnown(51886) then					-- Cleanse Spirit
			dispelList.Curse = true 
			if HasTalent(3, 12, false, false) then	-- Improved Cleanse Spirit
				dispelList.Magic = true
			else
				dispelList.Magic = false
			end
		else
			dispelList.Curse = false
		end
	end,
	["WARLOCK"] = function()
		if IsSpellKnown(89808, true) then			-- Single Magic (Imp ability)
			dispelList.Magic = true
		else
			dispelList.Magic = false
		end
	end,
}

local function GetWhiteList(userWhitelist)
	for k, v in pairs(userWhitelist) do
		if v then
			whitelist[k] = v -- TODO: maybe make it an array if they are faster
		end
	end
end

local function GetDispelType(unit, filter, useWhitelist)
	if not UnitCanAssist("player", unit) then return end

	-- name, rank, texture, stackCount, dispelType, duration, expireTime, caster, isStealable, shouldConsolidate, spellID, canApplyAura, isBossDebuff
	local name, _, texture, _, dispelType, _, _, _, _, _, spellID
	local i = 1
	
	while true do
		name, _, texture, _, dispelType, _, _, _, _, _, spellID = UnitDebuff(unit, i)
		if not texture then break end
		--if (dispelType and not filter) or (useWhitelist and whitelist[spellID]) or (filter and dispelList[dispelType]) then -- TODO:  implement whitelist
		if (not filter) or (filter and dispelList[dispelType]) then
			return dispelType, texture
		end
		i = i + 1
	end
end

local function CheckForPet(self, event, unit)
	if unit ~= "player" or playerClass ~= "WARLOCK" then return end
	
	UpdateDispelList[playerClass]()
end

local function CheckTalentPoints(self, event, count, levels)
	-- don't update on just a level up
	print(event, "count:", count, "levels:", levels)
	if levels > 0 then return end

	UpdateDispelList[playerClass]()
end

local function Update(self, event, unit)
	if unit ~= self.unit then return end
	
	local color
	local dispelType, texture = GetDispelType(unit, self.DebuffHighlight.filter, useWhitelist)
	
	if not dispelType then
		dispelType = "none"
	end
	
	color = debuffTypeColor[dispelType]
	
	if self.DebuffHighlightTexture then
		if texture then
			self.DebuffHighlightTexture:SetVertexColor(color.r, color.g, color.b, 1)
		else
			self.DebuffHighlightTexture:SetVertexColor(0, 0, 0, 0)
		end
	end
	
	if self.DebuffHighlightIcon then
		if texture then
			self.DebuffHighlightIcon:SetTexture(texture)
		else
			self.DebuffHighlightIcon:SetTexture(nil)
		end
		if self.DebuffHighlightIconOverlay then
			if texture then
				self.DebuffHighlightIconOverlay:SetVertexColor(color.r, color.g, color.b, 1)
			else
				self.DebuffHighlightIconOverlay:SetVertexColor(0, 0, 0, 0)
			end
		end
	end
end

local function Enable(self)
	if not self.DebuffHighlight then return end
	
	-- exit if we filter by type and are not a dispeling class or we don't have a whitelist
	--if (self.DebuffHighlight.filter and not UpdateDispelList[playerClass]) or not self.DebuffHighlight.whitelist then return end
	
	-- fetch the user's whitelist
	if self.DebuffHighlight.whitelist then
		if type(self.DebuffHighlight.whitelist) ~= "table" then
			error("Whitelist must be a table.")
		else
			GetWhiteList(self.DebuffHighlight.whitelist)
			useWhitelist = true
		end
	end
	
	-- Populate the dispelList
	if UpdateDispelList[playerClass] then
		UpdateDispelList[playerClass]()
	end

	self:RegisterEvent("UNIT_AURA", Update)
	
	-- we don't need these if we only filter by whitelist
	if UpdateDispelList[playerClass] then
		self:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED", UpdateDispelList[playerClass]) -- FIXME: fails on classes not in UpdateDispelList
		self:RegisterEvent("LEARNED_SPELL_IN_TAB", UpdateDispelList[playerClass])
		self:RegisterEvent("CHARACTER_POINTS_CHANGED", CheckTalentPoints)
		self:RegisterEvent("UNIT_PET", CheckForPet)
	end
	
	return true
end

local function Disable(self)
	if self.DebuffHighlight then
		self:UnregisterEvent("UNIT_AURA")
		if UpdateDispelList[playerClass] then
			self:UnregisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
			self:UnregisterEvent("LEARNED_SPELL_IN_TAB")
			self:UnregisterEvent("CHARACTER_POINTS_CHANGED")
			self:UnregisterEvent("UNIT_PET")
		end
	end
end

oUF:AddElement("rain_dispell", Update, Enable, Disable)
