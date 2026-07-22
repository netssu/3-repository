task.wait(6)

--//Services
local TextChatService = game:GetService("TextChatService")
local Players = game:GetService("Players")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local GameConfigModule = require(Rs:WaitForChild("GameConfig"))

TextChatService.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")
	
	if message then
		local player = Players:GetPlayerByUserId(message.TextSource.UserId)
		local tag = ""
		
		if not player then return end
		
		local function getRankInGroup()
			return player:GetRankInGroup(GameConfigModule.groupid)
		end
		
		local plrRank = getRankInGroup()
		local selectedRank = nil
		local oldrank = nil
		local isOngroup = plrRank > 0
		
		for _, v in pairs(GameConfigModule.ChatTags) do
			local roleRank = v[1]
			if plrRank >= roleRank then
				if not oldrank or roleRank > oldrank then
					oldrank = roleRank
					selectedRank = v
				end
			end
		end
		
		if not selectedRank then return end
		
		local rankColor = "#"..selectedRank[6]
		local rankName = selectedRank[2]
		
		local groupRankTag = "<font color='"..rankColor.."'>"..rankName.."</font>"
		local groupMemberTag = "<font color='#07b0ff'>[Member]</font>"
		
		if isOngroup then
			properties.PrefixText = tag..groupRankTag..groupMemberTag.." "..player.DisplayName..": "
		else
			properties.PrefixText = tag..groupRankTag.." "..player.DisplayName..": "
		end
	end
	
	return properties
end