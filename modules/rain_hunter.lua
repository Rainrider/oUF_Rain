local _, ns = ...
local cfg = ns.config

print("oUF Rain: Hunter module loaded.")

local shotFocusCost = 0
local maxFocus = 100
local talentTree = GetPrimaryTalentTree()

local function SetShotFocusCost()
	talentTree = GetPrimaryTalentTree()
	if talentTree == 3 then -- SURVIVAL
		shotFocusCost = select(4, GetSpellInfo(53301)) -- Explosive Shot
	elseif talentTree == 2 then -- MARKMANSHIP
		shotFocusCost = select(4, GetSpellInfo(53209)) -- Chimera Shot
	else
		talentTree = 1
		shotFocusCost = select(4, GetSpellInfo(34026)) -- Kill Command
	end
end

local function SetMaxFocus()
	maxFocus = 100
	if talentTree == 1 then
		-- get info about Kindred Spirits
		local numTalentPoints = select(5, GetTalentInfo(1, 16))
		if numTalentPoints == 2 then
			maxFocus = maxFocus * 1.1	-- 10% more focus
		elseif numTalentPoints == 1 then
			maxFocus = maxFocus * 1.05	-- 5% more focus
		end
	end
end

local function GetFocusSparkXPoint(powerBarWidth)
	-- make sure we have the correct data
	SetShotFocusCost()
	SetMaxFocus()
	
	print("shotfocusCost: ", shotFocusCost, " talentTree: ", talentTree)
	return (shotFocusCost * powerBarWidth / maxFocus)
end
ns.GetFocusSparkXPoint = GetFocusSparkXPoint