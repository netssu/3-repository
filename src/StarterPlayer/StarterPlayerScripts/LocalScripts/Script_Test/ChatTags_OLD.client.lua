wait(6)
local textchatservice = game:GetService("TextChatService")
local players = game:GetService("Players")

textchatservice.OnIncomingMessage = function(message: TextChatMessage)
	local properties = Instance.new("TextChatMessageProperties")

	if message.TextSource then
		local player = players:GetPlayerByUserId(message.TextSource.UserId)
		local tag = ""

		if player then
			if player:GetRankInGroup(35529401) == 4 then
				properties.PrefixText = tag.."<font color='".."#d36767".."'>".."[tester]" .."</font> "..player.Name..": "
			elseif  player:GetRankInGroup(35529401) == 5 then
				properties.PrefixText = tag.."<font color='".."#afc530".."'>".."[mod]" .."</font> "..player.Name..": "
			elseif  player:GetRankInGroup(35529401) == 6 then
				properties.PrefixText = tag.."<font color='".."#3a9c66".."'>".."[admin]" .."</font> "..player.Name..": "
			elseif  player:GetRankInGroup(35529401) == 7 then
				properties.PrefixText = tag.."<font color='".."#3a5c9c".."'>".."[manager]" .."</font> "..player.Name..": "
			elseif player:GetRankInGroup(35529401) == 8 or player:GetRankInGroup(35529401) == 9 or player:GetRankInGroup(35529401) == 10 then
				properties.PrefixText = tag.."<font color='".."#e2ae61".."'>".."[dev]" .."</font> "..player.Name..": "
			elseif player:GetRankInGroup(35529401) == 254 then
				properties.PrefixText = tag.."<font color='".."#d65252".."'>".."[co-owner]" .."</font> "..player.Name..": "
			elseif player:GetRankInGroup(35529401) == 255 then
				properties.PrefixText = tag.."<font color='".."#cc61e2".."'>".."[owner]" .."</font> "..player.Name..": "
			else
				properties.PrefixText = tag.."<font color='".."#ff97ff".."'>".."[a]" .."</font> "..player.Name..": "
			end
		end
	end

	return properties
end