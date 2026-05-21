local ContentProvider = game:GetService("ContentProvider")
local LoadUI = script:WaitForChild("LoadScreen"):Clone()
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")
local Camera = workspace.CurrentCamera
local camPart = game.ReplicatedFirst:WaitForChild("LoadScreenCamera")

Camera.CameraType = Enum.CameraType.Scriptable
Camera.CFrame = camPart.CFrame

repeat task.wait() until game:IsLoaded()

local LoadRemote = RS:WaitForChild("Remotes").LoadRemote
local GameAssets = game.ReplicatedStorage:GetDescendants()
local NOofGameAssets = #GameAssets
local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- FIX: Sem timeout, espera até aparecer de verdade
local HUD = PlayerGui:WaitForChild("HUD")

LoadUI.Parent = PlayerGui
LoadUI.LoadingFrame.BackgroundTransparency = 0.45
local Connection
local LoadingText = LoadUI.LoadingFrame.LoadingText
local SkipButton = LoadUI.LoadingFrame.SkipButton

HUD.Enabled = false

LoadUI.Destroying:Once(function()
	print("Load Ui Destroyed")
	Camera.CameraType = Enum.CameraType.Custom
	if Player.Character then
		Camera.CFrame = Player.Character:WaitForChild("HumanoidRootPart").CFrame
	end
	LoadRemote:FireServer("ClosedLoadScreen")
	PlayerGui.HUD.Enabled = true
	if Connection then
		Connection:Disconnect()
		Connection = nil
	end
end)

local mouse = Player:GetMouse()
local maxTilt = 10

Connection = game:GetService("RunService").RenderStepped:Connect(function()
	Camera.CFrame = camPart.CFrame * CFrame.Angles(
		math.rad((((mouse.Y - mouse.ViewSizeY / 2) / mouse.ViewSizeY)) * -maxTilt),
		math.rad((((mouse.X - mouse.ViewSizeX / 2) / mouse.ViewSizeX)) * -maxTilt),
		0
	)
end)

for i = 1, 5 do
	LoadingText.Text = math.floor(i / NOofGameAssets * 100) .. "%"
	task.wait(math.random(1, 2) / 2)
end

LoadUI.LoadingFrame.Tip.Visible = true
LoadUI.LoadingFrame.Tip.Size = UDim2.fromScale(0, 0)
TS:Create(LoadUI.LoadingFrame.Tip, TweenInfo.new(0.25, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2.fromScale(0.379, 0.04)}):Play()

SkipButton.Visible = true
SkipButton.Size = UDim2.fromScale(0, 0)
TS:Create(SkipButton, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0, false, 0), {Size = UDim2.fromScale(0.2, 0.1)}):Play()

SkipButton.MouseButton1Click:Connect(function()
	LoadUI:Destroy()
end)

for i, Asset in pairs(GameAssets) do
	ContentProvider:PreloadAsync({Asset})
	LoadingText.Text = math.floor(i / NOofGameAssets * 100) .. "%"
end

task.wait(1)
LoadUI:Destroy()