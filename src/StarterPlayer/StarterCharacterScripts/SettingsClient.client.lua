--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local MS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

--REFERENCES
local Player = Players.LocalPlayer
local PlayerPlotRem = RS:WaitForChild("Remotes").PlayerPlotRemote
local UpgradeRem = RS:WaitForChild("Remotes").UpgradeRemote
local LayoutBtnBindable = RS:WaitForChild("Remotes").LayoutBtnBindable
local Camera = workspace.CurrentCamera

--MODULES
local UpgradesDictionary = require(RS:WaitForChild("Modules").UpgradesDictionary)
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

local Character = script.Parent
repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
local MarketButtons:Frame = PlayerGui:WaitForChild("HUD").FarmersMarketButtons
local RestaurantUpgradesUI:Frame = PlayerGui:WaitForChild("HUD").RestaurantUpgrades
local StorageBoxframe:Frame = PlayerGui:WaitForChild("HUD").StorageBoxFrame

--CHARACTER
local HRP = Character:WaitForChild("HumanoidRootPart")
local Humanoid = Character:WaitForChild("Humanoid") 

local LeaderstatValues = Player:FindFirstChild("leaderstatValues")
local PlayerStats = Player:FindFirstChild("PlayerStats")
local PlayerInfo = Player:WaitForChild("PlayerInfo")

local SettingsFrame = HUD.Settings


for i,BTN in pairs(SettingsFrame:GetDescendants()) do
	if BTN:IsA("GuiButton") then
		BTN.MouseButton1Click:Connect(function()
			if BTN.Name == "Close" then
				local Tween = TS:Create(BTN.Parent,TweenInfo.new(0.45,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Position = UDim2.fromScale(1.5,0.5)})
				Tween:Play()
				Tween.Completed:Once(function()
					BTN.Parent.Visible = false
				end)
			elseif BTN.Name == "OnOrOff" then
				local Setting = BTN.Parent.Name
				if Setting == "BackgroundMusic" and RS:WaitForChild("Assets").SFX.BackgroundMusic.Volume > 0 then
					RS:WaitForChild("Assets").SFX.BackgroundMusic.Volume = 0
					TS:Create(BTN.White,TweenInfo.new(0.25),{Position = UDim2.fromScale(0.2,0.5)}):Play()
					BTN.RedGradient.Enabled = true
					BTN.GreenGradient.Enabled = false
				elseif Setting == "BackgroundMusic" and RS:WaitForChild("Assets").SFX.BackgroundMusic.Volume <= 0 then
					RS:WaitForChild("Assets").SFX.BackgroundMusic.Volume = 0.25
					TS:Create(BTN.White,TweenInfo.new(0.25),{Position = UDim2.fromScale(0.787,0.5)}):Play()
					BTN.RedGradient.Enabled = false
					BTN.GreenGradient.Enabled = true
				end
				if Setting == "LowGraphics" and BTN.RedGradient.Enabled == false then
					TS:Create(BTN.White,TweenInfo.new(0.25),{Position = UDim2.fromScale(0.2,0.5)}):Play()
					BTN.RedGradient.Enabled = true
					BTN.GreenGradient.Enabled = false
				elseif Setting == "LowGraphics" and BTN.RedGradient.Enabled == true then
					TS:Create(BTN.White,TweenInfo.new(0.25),{Position = UDim2.fromScale(0.787,0.5)}):Play()
					BTN.RedGradient.Enabled = false
					BTN.GreenGradient.Enabled = true
				end
			end
		end)
	end
end