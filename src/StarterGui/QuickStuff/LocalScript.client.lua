local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local QuickRem = RS:WaitForChild("Remotes").QuickRemote
local Player = Players.LocalPlayer

repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

local GiveBtn = script.Parent.Frame.Give
local Stat = script.Parent.Frame.Stat
local Amount = script.Parent.Frame.Amount

GiveBtn.MouseButton1Click:Connect(function()
	QuickRem:FireServer("Give",Stat.Text,tonumber(Amount.Text))
end)