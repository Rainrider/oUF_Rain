local _, ns = ...

local config = {
	FONT = [=[Interface\AddOns\oUF_Rain\media\fonts\russel square lt.ttf]=],
	FONT2 = [=[Interface\AddOns\oUF_Rain\media\fonts\neuropol x cd rg.ttf]=],
	TEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\normtexc]=],
	BORDER = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
	OVERLAY = [=[Interface\AddOns\oUF_Rain\media\textures\smallshadertex]=],
	BACKDROP = {
		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		insets = {top = -1, bottom = -1, left = -1, right = -1},
	},
}

ns.config = config