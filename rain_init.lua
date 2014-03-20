local addon, ns = ...

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) if self[event] then self[event](self, ...) end end)
frame:RegisterEvent("ADDON_LOADED")

function frame:ADDON_LOADED(name)
	if name ~= addon then return end

	frame:UnregisterEvent("ADDON_LOADED")

	oUF_RainDB = oUF_RainDB or {}
	ns.db = oUF_RainDB
end
