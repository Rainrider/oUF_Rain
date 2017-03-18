local addon, ns = ...

local oUFversion = GetAddOnMetadata("oUF", "version")
if(not oUFversion:find('@')) then
	local major, minor, rev = strsplit(".", oUFversion)
	minor = minor or 0
	rev = rev or 0
	local oUFversion = major * 1000 + minor * 100 + rev

	assert(oUFversion >= 1600, "Consider updating your version of oUF to at least 1.6")
end

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
