local _, ns = ...

ns.interruptSpellNames = {}

local interruptZones = {
	-- Blackwing Descent
	754 = {
		-- Halfus
		83703, -- Shadow Nova
		-- Ascendant Council
		83070, -- Lightning Blast (Arion)
		82636, -- Rising Flames (Ignacious)
		82752, -- Hydro Lance (Feludius)
		-- Cho'gal
		91317, -- Worshipping (players)
		81713, -- Depravity (Corrupting Adherent)
		82411, -- Debilitating Beam (Darkened Creation)
		-- Sinestra
		92947, -- Unleash Essence
	},
	-- Bastion of Twilight
	758 = {
		-- Omnotron
		79710, -- Arcane Annihilator (Arcanotron)
		-- Maloriak
		77896, -- Arcane Storm
		77569, -- Release Aberrations
		-- Nefarian
		80734, -- Blast Nova (Chromatic Prototypes)
	},
}

local rainInterrupt = CreateFrame("Frame", nil, UIParent)
rainInterrupt:SetScript("OnEvent", function(self, event, ...) self[event](self, event, ...) end)
rainInterrupt:RegisterEvent("ZONE_CHANGED_NEW_AREA")

rainInterrupt:ZONE_CHANGED_NEW_AREA = function(...)
	local areaID = GetCurrentMapAreaID()
	
	if (interruptZones[areaID]) then
		for i, v in ipairs(interruptZones[areaID]) do
			ns.interruptSpellNames[i] = GetSpellInfo(interruptZones.areaID[i])
		end
	else
		table.wipe(ns.interruptSpellNames)
	end
end