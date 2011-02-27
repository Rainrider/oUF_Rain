local _, ns = ...
local cfg = ns.config

local function GetShotFocusCost(talentTree)
	local shotFocusCost = 0
	if talentTree == 3 then -- SURVIVAL
		shotFocusCost = select(4, GetSpellInfo(53301)) -- Explosive Shot
	elseif talentTree == 2 then -- MARKMANSHIP
		shotFocusCost = select(4, GetSpellInfo(53209)) -- Chimera Shot
	else
		shotFocusCost = select(4, GetSpellInfo(34026)) -- Kill Command
	end
	
	return shotFocusCost
end

local function GetMaxFocus(talentTree)
	local maxFocus = 100
	if talentTree == 1 then
		-- get info about Kindred Spirits
		local numPointsSpent = select(5, GetTalentInfo(1, 16))
		if numPointsSpent == 2 then
			maxFocus = maxFocus * 1.1	-- 10% more focus
		elseif numPointsSpent == 1 then
			maxFocus = maxFocus * 1.05	-- 5% more focus
		end
	end
	
	return maxFocus
end

local function GetFocusSparkXPoint(powerBarWidth)
	local talentTree = GetPrimaryTalentTree()
	local shotFocusCost = GetShotFocusCost(talentTree)
	local maxFocus = GetMaxFocus()
	
	return (shotFocusCost * powerBarWidth / maxFocus)
end
ns.GetFocusSparkXPoint = GetFocusSparkXPoint