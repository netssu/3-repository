--//Services
local Ts = game:GetService("TweenService")

--//Tool
local tool = script.Parent
local Handle = tool.Handle

--//Remotes
local activeEvent = tool.activeEvent

activeEvent.OnServerEvent:Connect(function(plr, targetPos)
	local flashbangModel = Handle:Clone()
	flashbangModel.Parent = workspace
	
	local flashbangMain = require(flashbangModel.flashbangMain)
	flashbangMain.Init(plr, targetPos)
end)