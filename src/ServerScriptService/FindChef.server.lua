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


RunService.Heartbeat:Connect(function()
	local Plots = workspace.Plots
	for i,v in pairs(Plots:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Parent.Parent.Name == "Chef" or v.Parent.Parent.Parent.Name == "Chef" or v.Parent.Name == "Chef" then
				if v.Name == "Torso" or v.Name == "UpperTorso" or v.Name == "LowerTorso" or v.Name == "Head" then
					v.CanCollide = true
				else
					v.CanCollide = false
				end
			end
		end
	end
	--print(PlayerPlot:FindFirstChild("Chef",true)," Cheff is at : ",PlayerPlot:FindFirstChild("Chef",true).HumanoidRootPart.Position)
end)	


