local FavGamePopUp = {}

--//Services
local AvatarService = game:GetService("AvatarEditorService")
local Players = game:GetService("Players")
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Player
local plr = Players.LocalPlayer
local plrGui = plr.PlayerGui

--//Modules
local Modules = Rs:WaitForChild("Modules")
local DataHandler = require(Modules.DataHandler)

function FavGamePopUp.Init()
	task.wait(5)
	
	local plrData = DataHandler:GetProfileData(plr)
	if not plrData then return end
	
	if plrData.FirstTime then return end -- first time players playing (don't show popup)
	
	local MenuGui = plrGui:WaitForChild("MenuGui")
	local FavGameFrame = MenuGui.InGameFrame.FavGameFrame
	
	local defaultSize = FavGameFrame.Size
	
	FavGameFrame.Visible = true
	FavGameFrame.Size = UDim2.new(0, 0, 0, 0)
	Ts:Create(FavGameFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = defaultSize}):Play()
	
	FavGameFrame.OkButton.MouseButton1Click:Connect(function()
		FavGameFrame.Visible = false
		AvatarService:PromptSetFavorite(game.PlaceId, Enum.AvatarItemType.Asset, true)
	end)
end

return FavGamePopUp