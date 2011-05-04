local _, ns = ...

local function GetShotFocusCost(talentTree)
	local shotFocusCost = 0
	if talentTree == 3 and IsSpellKnown(53301) then -- SURVIVAL
		shotFocusCost = select(4, GetSpellInfo(53301)) -- Explosive Shot
	elseif talentTree == 2 and IsSpellKnown(53209) then -- MARKMANSHIP
		shotFocusCost = select(4, GetSpellInfo(53209)) -- Chimera Shot
	elseif IsSpellKnown(34026) then
		shotFocusCost = select(4, GetSpellInfo(34026)) -- Kill Command
	end
	
	return shotFocusCost
end

local function GetFocusSparkPosition(powerBarWidth)
	local talentTree = GetPrimaryTalentTree()
	local shotFocusCost = GetShotFocusCost(talentTree)
	
	return (shotFocusCost * powerBarWidth / UnitPowerMax("player", 2))
end
ns.GetFocusSparkPosition = GetFocusSparkPosition