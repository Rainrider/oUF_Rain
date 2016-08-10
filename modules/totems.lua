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
		local total = 0
		totem:SetValue(1 - (GetTime() - start) / duration)
		totem:SetScript("OnUpdate", function(totem, elapsed)
			total = total + elapsed
			if total >= 0.9 then
				total = 0
				totem:SetValue(1 - (GetTime() - start) / duration)
			end
		end)
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
		totems:PostUpdate(slot, numShown)
	end
end

local Path = function(self, ...)
	return (self.CustomTotems.Override or UpdateTotem)(self, ...)
end

local Update = function(self, event)
	local totems = self.CustomTotems

	for i = 1, #totems do
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

	local color = ns.colors.class[select(2, _G.UnitClass("player"))]
	local r, g, b = color[1], color[2], color[3]

	for i = 1, 5 do
		local totem = totems[i]

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

		totem.UpdateTooltip = UpdateTooltip

		totem:Hide()
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
