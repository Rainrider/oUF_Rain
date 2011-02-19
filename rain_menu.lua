--[[===============================
	DESCRIPTION:
	Contains the menus for oUF_Rain
	===============================--]]

local name, ns = ...

local dropdown = CreateFrame("Frame", name .. "DropDown", UIParent, "UIDropDownMenuTemplate")

function ns:menu()
	dropdown:SetParent(self)
	return ToggleDropDownMenu(1, nil, dropdown, "cursor", 0, 0)
end

local function init(self)
	local unit = self:GetParent().unit
	local menu, name, id

	if(not unit) then
		return
	end

	if(UnitIsUnit(unit, "player")) then
		menu = "SELF"
	elseif(UnitIsUnit(unit, "vehicle")) then
		-- NOTE: vehicle check must come before pet check for accuracy's sake because
		-- a vehicle may also be considered your pet
		menu = "VEHICLE"
	elseif(UnitIsUnit(unit, "pet")) then
		menu = "PET"
	elseif(UnitIsPlayer(unit)) then
		id = UnitInRaid(unit)
		if(id) then
			menu = "RAID_PLAYER"
			name = GetRaidRosterInfo(id)
		elseif(UnitInParty(unit)) then
			menu = "PARTY"
		else
			menu = "PLAYER"
		end
	else
		menu = "TARGET"
		name = RAID_TARGET_ICON
	end

	if(menu) then
		UnitPopup_ShowMenu(self, menu, unit, name, id)
	end
end

UIDropDownMenu_Initialize(dropdown, init, "MENU")