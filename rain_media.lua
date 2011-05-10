--[[==========================
	DESCRIPTION:
	Textures and Co. for oUF_Rain
	==========================--]]

local _, ns = ...

ns.media = {
	FONT = [=[Interface\AddOns\oUF_Rain\media\fonts\russel square lt.ttf]=],
	FONT2 = [=[Interface\AddOns\oUF_Rain\media\fonts\neuropol x cd rg.ttf]=],
	TEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\normtexc]=],
	BTNTEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\buttonnormal]=],
	HIGHLIGHTTEXTURE = [=[Interface\AddOns\oUF_Rain\media\textures\highlighttex]=],
	BORDER = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
	OVERLAY = [=[Interface\AddOns\oUF_Rain\media\textures\smallshadertex]=],
	RAIDICONS = [=[Interface\AddOns\oUF_Rain\media\icons\raidicons]=],
	BACKDROP = {
		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		insets = {top = -1, bottom = -1, left = -1, right = -1},
	},
	BACKDROP2 = {
		bgFile = [=[Interface\ChatFrame\ChatFrameBackground]=],
		edgeFile = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
		edgeSize = 2,
		insets = {top = 2, left = 2, bottom = 2, right = 2},
	},
	BORDERBACKDROP = {
		bgFile = nil,
		edgeFile = [=[Interface\AddOns\oUF_Rain\media\textures\glowTex3]=],
		edgeSize = 4,
		insets = {top = 2, left = 2, bottom = 2, right = 2},
	},
}