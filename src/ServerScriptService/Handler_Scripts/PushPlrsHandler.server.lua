--//Services
local Players = game:GetService("Players")
local MarketplaceService = game:GetService("MarketplaceService")

local promptsConn = {}

Players.PlayerAdded:Connect(function(plr)
	plr.CharacterAdded:Connect(function(char)
		local prompt = Instance.new("ProximityPrompt")
		local rootPart = char:WaitForChild("HumanoidRootPart")
		
		if promptsConn[plr.Name] then
			promptsConn[plr.Name]:Disconnect()
			promptsConn[plr.Name] = nil
		end
		
		if rootPart then
			prompt.Parent = rootPart
			prompt.Style = Enum.ProximityPromptStyle.Custom
			prompt.MaxActivationDistance = 5.2
			prompt.ActionText = "Push"
			prompt.RequiresLineOfSight = false
			promptsConn[plr.Name] = prompt.Triggered:Connect(function(player)
				local plrValues = player:WaitForChild("PlayerValues")
				if plrValues then
					local SelectedPushPlayer = plrValues:WaitForChild("SelectedPushPlayer")
					if SelectedPushPlayer then
						local plrToPush = Players:GetPlayerFromCharacter(prompt.Parent.Parent)
						if plrToPush then
							SelectedPushPlayer.Value = tostring(plrToPush.UserId)
							MarketplaceService:PromptProductPurchase(player, 3384093042)
						end
					end
				end
			end)
		else
			prompt:Destroy()
		end
	end)
end)

--//Cleanup propmts connections
Players.PlayerRemoving:Connect(function(plr)
	if promptsConn[plr.Name] then
		promptsConn[plr.Name]:Disconnect()
		promptsConn[plr.Name] = nil
	end
end)