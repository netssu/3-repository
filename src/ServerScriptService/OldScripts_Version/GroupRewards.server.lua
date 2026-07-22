--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ReceiveGroupReward = Remotes:FindFirstChild("ReceiveGroupReward")

--//Modules
local GroupModule = require(Rs:FindFirstChild("GameConfig"):FindFirstChild("GroupData"))

--//Map
local MapFolder = workspace:FindFirstChild("Map")
local InteractStuff = MapFolder:FindFirstChild("InteractStuff")
local GroupRewardsModel = InteractStuff:FindFirstChild("GroupRewards")
local GroupRewardsGui = GroupRewardsModel:FindFirstChild("Screen"):FindFirstChild("SurfaceGui"):FindFirstChild("MainFrame")

local function CheckIfPlayerIsInGroup(Player)
	local groupID = GroupModule.groupid
	local Value = false
	if Player:IsInGroup(groupID) then
		Value = true
	end
	return Value
end

ReceiveGroupReward.OnServerInvoke = function(Plr, check: boolean?)
	local OtherValues = Plr:FindFirstChild("OtherValues")
	local GroupRevive = OtherValues:FindFirstChild("GroupRevive") :: BoolValue
	local FreeRevives = OtherValues:FindFirstChild("FreeRevives") :: IntValue
	
	if check then
		if CheckIfPlayerIsInGroup(Plr) and GroupRevive.Value == true then
			return true
		end
		return false
	end
	
	if CheckIfPlayerIsInGroup(Plr) then
		if GroupRevive.Value then
			return "already received"
		end
		GroupRevive.Value = true
		FreeRevives.Value += 1
		return true
	else
		return false
	end
end