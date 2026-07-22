--[[
	DataService.lua by @TinyGecko920
	Edited by @Thurzin54
]]

local BadgeService = game:GetService("BadgeService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.Packages
local Promise = require(Packages.Promise)
local ReplicaService = require(Packages.ReplicaService)
local Knit = require(Packages.Knit)

local ProfileStore = require(ServerScriptService.ServerPackages.ProfileStore)
local SaveStructure = require(script.SaveStructure)

local Configs = ReplicatedStorage.Configs
local Badges = require(Configs.Badges)
local General = require(Configs.General)

local DataService = {
	Name = "DataService",
	Client = {},
	Profiles = {},
	Replicas = {},
	PlayerProfileClassToken = ReplicaService.NewClassToken("PlayerData_" .. General.StoreVersion),
	PrayerStore = ProfileStore.New("PlayerData_" .. General.StoreVersion, SaveStructure),
}

function DataService:GetProfile(player: Player)
	return self.Profiles[player]
end

function DataService.Client:GetProfileData(player: Player)
	local data
	local profile = self.Server.Profiles[player]
	if profile then
		data = profile.Data
	end
	
	return data
end

function DataService:GetReplica(player: Player)
	return Promise.new(function(Resolve, Reject)
		assert(typeof(player) == "Instance" and player:IsDescendantOf(Players), "Value passed is not a valid player")
		
		if not self.Profiles[player] and not self.Replicas[player] then
			repeat
				if player then
					task.wait()
				else
					Reject("Player left the game")
				end
			until self.Profiles[player] and self.Replicas[player]
		end
		
		local Profile = self.Profiles[player]
		local Replica = self.Replicas[player]
		if Profile and Profile:IsActive() then
			if Replica and Replica:IsActive() then
				Resolve(Replica)
			else
				Reject("Replica did not exist or wasn't active")
			end
		else
			Reject("Profile did not exist or wasn't active")
		end
	end)
end

function DataService:_awardBadge(player: Player, badgeId: number)
	if not badgeId or badgeId == 0 then
		warn("[DataService] Can't give badge to player:", player, "invalid badgeId.")
		return
	end
	
	local userOwnsBadge = false
	pcall(function()
		userOwnsBadge = BadgeService:UserHasBadgeAsync(player.UserId, badgeId)
	end)

	if not userOwnsBadge then
		-- Award badge to player
		pcall(function()
			BadgeService:AwardBadge(player.UserId, badgeId)
		end)
	end
end

-- more functions like that can be added to handler when creating data values
function DataService:_createNumberValue(name: string, value: number, parent: Instance)
	local newValue = Instance.new("NumberValue")
	newValue.Name = name
	newValue.Value = value
	newValue.Parent = parent
end

function NewEquippedValue(name: string, value: string?, parent: Instance): StringValue
	local stringValue = Instance.new("StringValue")
	stringValue.Name = name
	stringValue.Value = value or ""
	stringValue.Parent = parent
	return stringValue
end

function DataService:_giveLeaderstats(player: Player)
	local profile = self.Profiles[player]
	if not profile then
		return
	end

	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	leaderstats.Parent = player

	-- Reset checkpoint to stage value
	profile.Data.Checkpoint = profile.Data.Stage

	-- Create number values
	self:_createNumberValue("Kills", profile.Data.Kills, leaderstats)
	self:_createNumberValue("Coins", profile.Data.Coins, leaderstats)
	
	-- other values
	for valueName: string, data: { Value: number, Parent: Instance } in pairs({
		["Deaths"] = { Value = profile.Data.Deaths, Parent = player },
		["TimePlayed"] = { Value = profile.Data.TimePlayed, Parent = player },
		}) do
		self:_createNumberValue(valueName, data.Value, data.Parent)
	end
	
	-- values also can be created manually:
	--[[
		local exampleValue = Instance.new("StringValue")
		exampleValue.Name = "Example"
		exampleValue.Value = profile.Data.ExampleValue
		exampleValue.Parent = player
	]]
	
	-- example of equipped items save:
	--[[NewEquippedValue("EquippedChatTag", profile.Data.EquippedChatTag, equippedItems)
	local equippedHalo = NewEquippedValue("EquippedHalo", profile.Data.EquippedHalo, equippedItems)
	local equippedTrail = NewEquippedValue("EquippedTrail", profile.Data.EquippedTrail, equippedItems)]]
end

function PlayerAdded(player: Player)
	local profile = DataService.PrayerStore:StartSessionAsync("Player_" .. player.UserId .. "_" .. General.StoreVersion, {
		Cancel = function()
			return player.Parent ~= Players
		end,
	})
	if not profile then
		player:Kick("Failed to load data. Please try again later.")
		return
	end
	
	profile:AddUserId(player.UserId)
	profile:Reconcile()
	
	profile.OnSessionEnd:Connect(function()
		DataService.Profiles[player] = nil
		DataService.Replicas[player]:Destroy()
		DataService.Replicas[player] = nil
		player:Kick("Data error ocurred. Please rejoin.")
	end)

	if player:IsDescendantOf(Players) == true then
		DataService.Profiles[player] = profile
		DataService:_giveLeaderstats(player)
		
		local Replica = ReplicaService.NewReplica({
			ClassToken = DataService.PlayerProfileClassToken,
			Tags = { ["Player"] = player },
			Data = profile.Data,
			Replication = "All",
		})
		
		DataService.Replicas[player] = Replica
		
		-- Track deaths -- example how to count certain values
		player.CharacterAdded:Connect(function(character: Model)
			local humanoid = character:WaitForChild("Humanoid")
			if humanoid:IsA("Humanoid") then
				humanoid.Died:Connect(function()
					profile.Data.Deaths += 1
				end)
			end
		end)
		
		-- here you can track/update periodic values, like time played
		coroutine.wrap(function()
			while Players:FindFirstChild(player.Name) do
				task.wait(1)
				profile.Data.TimePlayed += 1
				
				local timePlayed = player:FindFirstChild("TimePlayed")
				if timePlayed and timePlayed:IsA("NumberValue") then
					timePlayed.Value = profile.Data.TimePlayed
				end
			end
		end)()
	else
		profile:EndSession()
	end
	
	-- How to give badges when player joins, also can be given when certain values reach some amount
	if Badges.Welcome ~= nil then
		-- Award Welcome Badge if the player does not already own it
		DataService:_awardBadge(player, Badges.Welcome)
	end
end

function DataService:_setAsync(player, value, orderedDatastore)
	pcall(function()
		orderedDatastore:SetAsync("Player_" .. player.UserId, value)
	end)
end

function DataService:KnitInit()
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(PlayerAdded, player)
	end
	
	Players.PlayerAdded:Connect(PlayerAdded)
	
	Players.PlayerRemoving:Connect(function(player)
		if self.Profiles[player] then
			self.Profiles[player]:EndSession()
		end
	end)
end

return DataService
