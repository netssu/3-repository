local VC_Checker = {}

function VC_Checker.Init()
	--//Services
	local VoiceChatService = game:GetService("VoiceChatService")
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Remotes
	local Remotes = Rs:WaitForChild("Remotes")
	local CheckVcFunc = Remotes:WaitForChild("CheckVc")
	
	--//Player
	local Plr = game.Players.LocalPlayer
	
	CheckVcFunc.OnClientInvoke = function()
		if VoiceChatService:IsVoiceEnabledForUserIdAsync(Plr.UserId) then
			return true
		else
			return false
		end
	end
end

return VC_Checker