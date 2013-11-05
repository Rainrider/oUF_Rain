local _, ns = ...

ns.colors = setmetatable({
	cpoints = {
		{1, 0.68, 0.35},
		{1, 0.6, 0.18},
		{1, 0.5, 0},
		{0.87, 0.45, 0},
		{0.71, 0.37, 0},
	},
	disconnected = {0.84, 0.75, 0.65},
	power = setmetatable({
		-- original colors contained in FrameXML/UnitFrame.lua (table PowerColorBar)
		["MANA"] = {0.31, 0.45, 0.63},
		["RAGE"] = {0.69, 0.31, 0.31},
		["FOCUS"] = {0.71, 0.43, 0.27},
		["ENERGY"] = {0.65, 0.63, 0.35},
		["CHI"] = {0.71, 1, 0.92},
		["RUNES"] = {0.55, 0.57, 0.61},
		["RUNIC_POWER"] = {0, 0.82, 1},
		["HOLY_POWER"] = {0.95, 0.93, 0.65},
		["SOUL_SHARDS"] = {0.5, 0.32, 0.55},
		["AMMOSLOT"] = {0.8, 0.6, 0},
		["FUEL"] = {0, 0.55, 0.5},
		-- for list of available power types look in FrameXML/GlobalStrings.lua
		["POWER_TYPE_STEAM"] = {0.55, 0.57, 0.61},
		["POWER_TYPE_PYRITE"] = {0.60, 0.09, 0.17},
	}, {__index = oUF.colors.power}),
	smooth = setmetatable({
		0.69, 0.31, 0.31,
		0.71, 0.43, 0.27,
		0.17, 0.17, 0.24,
	}, {__index = oUF.colors.smooth}),
	runes = setmetatable({
		{0.69, 0.31, 0.31},	-- blood
		{0.33, 0.59, 0.33},	-- unholy
		{0.31, 0.45, 0.63},	-- frost
		{0.84, 0.75, 0.75},	-- death
	}, {__index = oUF.colors.runes}),
	totems = {
		[FIRE_TOTEM_SLOT] = { 181/255, 073/255, 033/255 },
		[EARTH_TOTEM_SLOT] = { 074/255, 142/255, 041/255 },
		[WATER_TOTEM_SLOT] = { 057/255, 146/255, 181/255 },
		[AIR_TOTEM_SLOT] = { 132/255, 056/255, 231/255 },
	},
}, {__index = oUF.colors})

ns.colors.power[0] = ns.colors.power["MANA"]
ns.colors.power[1] = ns.colors.power["RAGE"]
ns.colors.power[2] = ns.colors.power["FOCUS"]
ns.colors.power[3] = ns.colors.power["ENERGY"]
ns.colors.power[4] = ns.colors.power["UNUSED"]
ns.colors.power[5] = ns.colors.power["RUNES"]
ns.colors.power[6] = ns.colors.power["RUNIC_POWER"]
ns.colors.power[7] = ns.colors.power["SOUL_SHARDS"]
ns.colors.power[8] = ns.colors.power["ECLIPSE"]
ns.colors.power[9] = ns.colors.power["HOLY_POWER"]
