local eventsManager = {}

function eventsManager.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Modules
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	local Events = require(Rs.Modules.Configs.Events)
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local RewardWarnEvent = Remotes:FindFirstChild("RewardWarnEvent")
	local CheckEvent = Remotes:FindFirstChild("CheckEvent")
	
	CheckEvent.OnServerInvoke = function(plr: Player, eventName: string, award: boolean)
		if Events[eventName] then
			local _, eventEnded = Events:CalculateTimeLeft(eventName)
			if eventEnded then
				warn("[CheckEvent] Event:", eventName, "already ended! |", plr)
				return
			end
			
			--//Return the total amount collected of plushies (15 for exclusive character)
			if eventName == "Xmas_2025" then
				local plrData = DataManager.GetProfileData(plr)
				if not plrData then return end
				
				if not plrData.Events.Xmas_2025.Plushies then
					plrData.Events.Xmas_2025.Plushies = {}
				end
				
				local amount = 0
				
				for _, v in plrData.Events.Xmas_2025.Plushies do
					amount += 1
				end
				
				if award then
					if amount >= 15 then -- give exclusive character (elf) to player
						DataManager.AddNewChar(plr, "Elf")
						RewardWarnEvent:FireClient(plr, "Character", nil, "Elf")
					end
				end
				
				--print("player current have: ", amount, "plushies.")
				
				return amount
			end
		end
	end
end

return eventsManager