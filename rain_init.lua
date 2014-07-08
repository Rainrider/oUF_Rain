local addon, ns = ...

local frame = CreateFrame("Frame")
frame:SetScript("OnEvent", function(self, event, ...) if self[event] then self[event](self, ...) end end)
--frame:RegisterEvent("ADDON_LOADED")

if (AdiDebug) then
	ns.Debug = AdiDebug:Embed({}, addon)
else
	ns.Debug = function() end
end

function frame:ADDON_LOADED(name)
	if name ~= addon then return end

	frame:UnregisterEvent("ADDON_LOADED")
end
