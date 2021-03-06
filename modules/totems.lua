local _, ns = ...

local oUF = ns.oUF or _G.oUF
local GetTime = _G.GetTime
local GetTotemInfo = _G.GetTotemInfo

local UpdateTooltip = function(totem)
	_G.GameTooltip:SetTotem(totem:GetID())
end

local OnEnter = function(totem)
	if not totem:IsVisible() then return end

	if totem.Icon then
		totem.Icon:Show()
	end

	_G.GameTooltip:SetOwner(totem, "ANCHOR_BOTTOMRIGHT")
	totem:UpdateTooltip()
end

local OnLeave = function(totem)
	if totem.Icon then
		totem.Icon:Hide()
	end
	_G.GameTooltip:Hide()
end

local OnUpdate = function(totem, elapsed)
	local lastUpdate = totem.lastUpdate + elapsed
	if lastUpdate >= 0.5 then
		local timeLeft = totem.timeLeft - lastUpdate
		totem:SetValue(timeLeft)
		totem.timeLeft = timeLeft
		totem.lastUpdate = 0
	else
		totem.lastUpdate = lastUpdate
	end
end

local shown = {}
local numShown = 0
local UpdateTotem = function(self, event, slot)
	local totems = self.CustomTotems
	if slot > #totems then return end

	local totem = totems[slot]
	local _, _, start, duration, icon = GetTotemInfo(slot)

	if duration > 0 then
		if totem.Icon then
			totem.Icon:SetTexture(icon)
		end
		totem:SetMinMaxValues(-duration, 0)
		totem.timeLeft = start - GetTime()
		totem:Show()
		if not shown[slot] then
			numShown = numShown + 1
			shown[slot] = true
		end
	else
		if shown[slot] then
			numShown = numShown - 1
			shown[slot] = nil
		end
		totem:Hide()
	end

	if totems.PostUpdate then
		totems:PostUpdate(slot, numShown, start, duration, icon)
	end
end

local Path = function(self, ...)
	return (self.CustomTotems.Override or UpdateTotem)(self, ...)
end

local Update = function(self, event)
	for i = 1, #self.CustomTotems do
		Path(self, event, i)
	end
end

local ForceUpdate = function(element)
	return Update(element.__owner, "ForceUpdate")
end

local Enable = function(self)
	local totems = self.CustomTotems
	if not totems then return end

	totems.__owner = self
	totems.ForceUpdate = ForceUpdate

	for i = 1, #totems do
		local totem = totems[i]
		
		local color = ns.colors.totems[i]
		local r, g, b = color[1], color[2], color[3]

		totem:SetStatusBarTexture(ns.media.TEXTURE)
		totem:SetStatusBarColor(r, g, b)
		totem:SetBackdrop(ns.media.BACKDROP)
		totem:SetBackdropColor(0, 0, 0)

		local bg = totem:CreateTexture(nil, "BORDER")
		bg:SetAllPoints()
		bg:SetColorTexture(r * 0.5, g * 0.5, b * 0.5)

		totem:SetMinMaxValues(0, 1)
		totem:SetID(i)

		totem:EnableMouse(true)
		totem:SetScript("OnEnter", OnEnter)
		totem:SetScript("OnLeave", OnLeave)
		totem:SetScript("OnUpdate", OnUpdate)
		totem.lastUpdate = 0

		totem.UpdateTooltip = UpdateTooltip
	end


	self:RegisterEvent("PLAYER_TOTEM_UPDATE", Path, true)

	local TotemFrame = _G.TotemFrame
	TotemFrame:UnregisterEvent"PLAYER_TOTEM_UPDATE"
	TotemFrame:UnregisterEvent"PLAYER_ENTERING_WORLD"
	TotemFrame:UnregisterEvent"UPDATE_SHAPESHIFT_FORM"
	TotemFrame:UnregisterEvent"PLAYER_TALENT_UPDATE"

	return true
end

local Disable = function(self)
	local totems = self.CustomTotems
	if not totems then return end

	for i = 1, #totems do
		totems[i]:Hide()
	end

	self:UnregisterEvent("PLAYER_TOTEM_UPDATE", Path)

	local TotemFrame = _G.TotemFrame
	TotemFrame:RegisterEvent"PLAYER_TOTEM_UPDATE"
	TotemFrame:RegisterEvent"PLAYER_ENTERING_WORLD"
	TotemFrame:RegisterEvent"UPDATE_SHAPESHIFT_FORM"
	TotemFrame:RegisterEvent"PLAYER_TALENT_UPDATE"
end

oUF:AddElement("CustomTotems", Update, Enable, Disable)
