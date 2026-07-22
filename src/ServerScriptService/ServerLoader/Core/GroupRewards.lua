local GroupRewards = {
	Name = "GroupRewards",
	Enabled = true
}

function GroupRewards.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local ReceiveGroupReward = Remotes:FindFirstChild("ReceiveGroupReward")
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	local UpdatePerkFunc = Remotes:FindFirstChild("UpdatePerk")
	
	local function CheckIfPlayerIsInGroup(Player)
		local groupID = 35529401
		local Value = false
		if Player:IsInGroup(groupID) then
			Value = true
		end
		return Value
	end
	
	ReceiveGroupReward.OnServerInvoke = function(Plr, check: boolean?, perkName: string)
		local OtherValues = Plr:WaitForChild("OtherValues")
		local GroupReward = OtherValues:WaitForChild("GroupReward") :: BoolValue
		
		if check then
			return CheckIfPlayerIsInGroup(Plr) and not GroupReward.Value
		end
		
		if CheckIfPlayerIsInGroup(Plr) then
			if GroupReward.Value then
				return "already received"
			end
			DataManager.SetGroupReward(Plr, true)
			DataManager.AddPerk(Plr, perkName, 1)
			UpdatePerkFunc:InvokeClient(Plr, "update") -- update perk items on inventory
			return true
		else
			return false
		end
	end
end

return GroupRewards