local SocialService = game:GetService("SocialService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer

local HUD = Player.PlayerGui.HUD
local Invite = HUD.RightSideButtons.Invite
local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

-- Function to check whether the player can send an invite
local function canSendGameInvite(sendingPlayer)
	local success, canSend = pcall(function()
		return SocialService:CanSendGameInviteAsync(sendingPlayer)
	end)
	return success and canSend
end

Invite.MouseButton1Click:Connect(function()
	local canInvite = canSendGameInvite(Player)
	if canInvite then
		SocialService:PromptGameInvite(Player)
	end	
end)
