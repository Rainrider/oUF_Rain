local addon, ns = ...

local oUFversion = GetAddOnMetadata("oUF", "version")
if(not oUFversion:find('@')) then
	local major, minor, rev = strsplit(".", oUFversion)
	oUFversion = major * 1000 + minor * 100 + rev

	assert(oUFversion >= 7000, "Consider updating your version of oUF to at least 7.0.0")
end

if (AdiDebug) then
	ns.Debug = AdiDebug:Embed({}, addon)
else
	ns.Debug = function() end
end
