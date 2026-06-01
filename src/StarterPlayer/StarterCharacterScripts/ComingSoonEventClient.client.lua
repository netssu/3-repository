--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local MS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local SocialService = game:GetService("SocialService")
local Workspace = game:GetService("Workspace")
local AvatarEditorService = game:GetService("AvatarEditorService")

local CashCollectionFolder = workspace.Map.CenterPoint.CashCollection
local Player = Players.LocalPlayer

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")
--CHARACTER
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid") 
local OrigStudsOffset = nil

for i,EventPrompt in pairs(CS:GetTagged("EventPrompt")) do
	if EventPrompt:IsA("ProximityPrompt") then
		OrigStudsOffset = EventPrompt.Parent.InfoDisplay.StudsOffset
		print(OrigStudsOffset, " is the studd offset")
		EventPrompt.Triggered:Connect(function(Plr)
			SocialService:PromptRsvpToEventAsync("4788951831592174155")
		end)
		EventPrompt.PromptShown:Connect(function()
			local PromptParent = EventPrompt.Parent.Parent
			local InfoDisplay = PromptParent.PrimaryPart.InfoDisplay
			TS:Create(InfoDisplay,TweenInfo.new(0.3),{StudsOffset = Vector3.new(0,-1.25,0)}):Play()
			print("Prompt shown and Tweened!")
		end)
		EventPrompt.PromptHidden:Connect(function()
			local PromptParent = EventPrompt.Parent.Parent
			local InfoDisplay = PromptParent.PrimaryPart.InfoDisplay
			TS:Create(InfoDisplay,TweenInfo.new(0.3),{StudsOffset = OrigStudsOffset}):Play()
			print("Prompt Hidden and Tweened Back!")
		end)
	end
end


