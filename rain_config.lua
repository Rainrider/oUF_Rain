--[[==========================
	DESCRIPTION:
	Configuration for oUF_Rain
	==========================--]]
local _, ns = ...

ns.config = {
	showParty = true,
	showPartyTargets = true,
	showPartyPets = true,
	showRaid = true,
	showMT = true,
	showMTT = true,
	playerClass = select(2, UnitClass("player"))
}