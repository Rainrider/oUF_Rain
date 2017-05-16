local _, ns = ...

ns.colors = setmetatable({
	disconnected = {0.42, 0.37, 0.32},
	health = {0.17, 0.17, 0.24},
	power = setmetatable({
		-- original colors contained in FrameXML/UnitFrame.lua (table PowerColorBar)
		["MANA"] = {0.31, 0.45, 0.63},
		["RAGE"] = {0.69, 0.31, 0.31},
		["FOCUS"] = {0.71, 0.43, 0.27},
		["ENERGY"] = {1, 0.87, 0.4},
		["RUNES"] = {0.55, 0.57, 0.61},
	}, {__index = oUF.colors.power}),
	smooth = setmetatable({
		0.69, 0.31, 0.31,
		0.71, 0.43, 0.27,
		0.17, 0.17, 0.24,
	}, {__index = oUF.colors.smooth}),
	totems = {
		{ 181/255,  73/255,  33/255 }, -- red
		{  74/255, 142/255,  41/255 }, -- green
		{  57/255, 146/255, 181/255 }, -- blue
		{ 132/255,  56/255, 231/255 }, -- violet
		{ 229/255, 178/255,   0/255 }, -- yellow
	},
}, {__index = oUF.colors})

ns.colors.power[0] = ns.colors.power["MANA"]
ns.colors.power[1] = ns.colors.power["RAGE"]
ns.colors.power[2] = ns.colors.power["FOCUS"]
ns.colors.power[3] = ns.colors.power["ENERGY"]
ns.colors.power[4] = ns.colors.power["COMBO_POINTS"]
ns.colors.power[5] = ns.colors.power["RUNES"]
ns.colors.power[6] = ns.colors.power["RUNIC_POWER"]
ns.colors.power[7] = ns.colors.power["SOUL_SHARDS"]
ns.colors.power[8] = ns.colors.power["LUNAR_POWER"]
ns.colors.power[9] = ns.colors.power["HOLY_POWER"]
ns.colors.power[11] = ns.colors.power["MAELSTROM"]
ns.colors.power[12] = ns.colors.power["CHI"]
ns.colors.power[13] = ns.colors.power["INSANITY"]
ns.colors.power[16] = ns.colors.power["ARCANE_CHARGES"]
ns.colors.power[17] = ns.colors.power["FURY"]
ns.colors.power[18] = ns.colors.power["PAIN"]
