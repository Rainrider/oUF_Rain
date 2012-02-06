--[[===============================================
	DESCRIPTION:
	Contains functions for adding icons to oUF_Rain
	===============================================--]]

local _, ns = ...

local AddAssistantIcon = function(self, unit)
	self.Assistant = self.Health:CreateTexture(nil, "OVERLAY")
	self.Assistant:SetSize(16, 16)
	self.Assistant:SetPoint("TOPLEFT", -8.5, 8.5)
end
ns.AddAssistantIcon = AddAssistantIcon

local AddCombatIcon = function(self)
	self.Combat = self.Health:CreateTexture(nil, "OVERLAY")
	self.Combat:SetSize(20, 20)
	self.Combat:SetPoint("TOP", 0, 1)
end
ns.AddCombatIcon = AddCombatIcon

local AddLeaderIcon = function(self, unit)
	self.Leader = self.Health:CreateTexture(nil, "OVERLAY")
	self.Leader:SetSize(16, 16)
	self.Leader:SetPoint("TOPLEFT", -8.5, 8.5)
end
ns.AddLeaderIcon = AddLeaderIcon

local AddMasterLooterIcon = function(self, unit)
	self.MasterLooter = self.Health:CreateTexture(nil, "OVERLAY")
	self.MasterLooter:SetSize(16, 16)
	self.MasterLooter:SetPoint("TOPRIGHT", 8.5, 8.5)
end
ns.AddMasterLooterIcon = AddMasterLooterIcon

local AddPhaseIcon = function(self, unit)
	self.PhaseIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.PhaseIcon:SetSize(16, 16)
	self.PhaseIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
end
ns.AddPhaseIcon = AddPhaseIcon

local AddQuestIcon = function(self, unit)
	self.QuestIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.QuestIcon:SetSize(16, 16)
	self.QuestIcon:SetPoint("TOPRIGHT", 8.5, 8.5)
end
ns.AddQuestIcon = AddQuestIcon

local AddRaidIcon = function(self, unit)
	self.RaidIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.RaidIcon:SetTexture([=[Interface\AddOns\oUF_Rain\media\icons\raidicons]=])
	if (unit ~= "player" and unit ~= "target") then
		self.RaidIcon:SetSize(14, 14)
		self.RaidIcon:SetPoint("TOP", 0, 10)
	else
		self.RaidIcon:SetSize(18, 18)
		self.RaidIcon:SetPoint("TOP", 0, 10)
	end
end
ns.AddRaidIcon = AddRaidIcon

-- oUF checks ready status only for raid and party
local AddReadyCheckIcon = function(self, unit)
	self.ReadyCheck = self.Health:CreateTexture(nil, "OVERLAY")
	self.ReadyCheck:SetSize(16, 16)
	self.ReadyCheck:SetPoint("RIGHT", -5, 0)
	
	self.ReadyCheck.finishedTime = 10
	self.ReadyCheck.fadeTime = 3
end
ns.AddReadyCheckIcon = AddReadyCheckIcon

local AddRestingIcon = function(self)
	self.Resting = self.Power:CreateTexture(nil, "OVERLAY")
	self.Resting:SetSize(16, 16)
	self.Resting:SetPoint("BOTTOMLEFT", -8.5, -8.5)
end
ns.AddRestingIcon = AddRestingIcon

local AddResurrectIcon = function(self, unit)
	self.ResurrectIcon = self.Health:CreateTexture(nil, "OVERLAY")
	self.ResurrectIcon:SetSize(16, 16)
	self.ResurrectIcon:SetPoint("CENTER")
end
ns.AddResurrectIcon = AddResurrectIcon
