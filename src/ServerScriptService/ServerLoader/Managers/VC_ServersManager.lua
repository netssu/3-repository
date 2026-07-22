local VC_ServersTeleport = {}

function VC_ServersTeleport.Init()
	--//Services
	local TeleportService = game:GetService("TeleportService")
	local Rs = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local CheckVcFunc = Remotes:FindFirstChild("CheckVc")
	local WarnTextEvent = Remotes:WaitForChild("WarnTeleportEvent") -- Just to warn to player on screen
	
	--//Modules
	local GameConfig = require(Rs:FindFirstChild("GameConfig"))
	
	--//Voice Chat Stuff
	local InteractStuff = workspace:FindFirstChild("Map"):FindFirstChild("InteractStuff")
	local teleporterModel = InteractStuff:FindFirstChild("Teleport_VC_Servers")
	local triggerPart = teleporterModel.TriggerPart
	
	--//Values
	local placeID_Normal = 134201953034119
	local placeId_VC = 85285898345004 -- VC servers | CHANGE
	local plrsDebounce = {}
	
	task.delay(3, function()
		-- If the server is VC only, change the teleporter to normal places
		if GameConfig.VoiceChatOnlyServer then
			print("VOICE CHAT SERVER")
			local BillBoard = teleporterModel.PromptPart.BillboardGui
			local mainFrame = BillBoard.MainFrame
			local textLabel = mainFrame:FindFirstChild("TextLabel")
			local neonPart = teleporterModel:FindFirstChild("NeonPart")
			if neonPart then
				neonPart.Color = Color3.fromRGB(173, 109, 109)
			end
			if textLabel then
				textLabel.Text = "Back to Normal Servers 🎮"
			end
		end
	end)
	
	triggerPart.Touched:Connect(function(hit)
		if not hit or not hit.Parent then return end
		
		local player = Players:GetPlayerFromCharacter(hit.Parent)
		if not player then return end
		
		if plrsDebounce[player] then return end
		plrsDebounce[player] = true
		
		if GameConfig.VoiceChatOnlyServer then -- Is a voice chat server (teleport to normal place)
			local success, errmsg = pcall(function()
				TeleportService:Teleport(placeID_Normal, player)
			end)
			if not success then
				warn("[VC Servers] Failed to teleport (to normal place) player:", player.Name, "Error:", errmsg)
				return
			end
		else -- Is a normal server (teleport to voice chat place)
			local hasVC = CheckVcFunc:InvokeClient(player)
			if hasVC then
				local success, errmsg = pcall(function()
					TeleportService:Teleport(placeId_VC, player)
				end)
				if not success then
					warn("[VC Servers] Failed to teleport player:", player.Name, "Error:", errmsg)
					return
				end
				
				task.delay(1, function()
					plrsDebounce[player] = nil
				end)
			else
				WarnTextEvent:FireClient(player, "Only players with Voice Chat enabled can join, sorry!")
				task.delay(1, function()
					plrsDebounce[player] = nil
				end)
			end
		end
	end)
	
	Players.PlayerAdded:Connect(function(plr)
		if GameConfig.VoiceChatOnlyServer then
			local hasVC = CheckVcFunc:InvokeClient(plr)
			if not hasVC then
				plr:Kick("You need Voice Chat Enabled to join in this server!")
			end
		end
	end)
end

return VC_ServersTeleport