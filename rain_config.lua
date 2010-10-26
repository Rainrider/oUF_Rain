local _, ns = ...

local config = {
	FONT = [=[Interface\AddOns\oUF_Rain\russel square lt.ttf]=],
	TEXTURE = [=[Interface\ChatFrame\ChatFrameBackground]=],
	BACKDROP = {
		bgFile = TEXTURE, insets = {top = -1, bottom = -1, left = -1, right = -1}
	},
}

ns.config = config