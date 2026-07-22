--//Services
local DataStore = game:GetService("DataStoreService")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local GameConfigModule = require(Rs:FindFirstChild("GameConfig"))

--//Player Data
local PlrData = DataStore:GetDataStore(GameConfigModule.datastorekey)

game.Players.PlayerAdded:Connect(function(Plr)
	---------[Primary Values]---------
	local leaderstats = Instance.new("Folder", Plr)
	leaderstats.Name = "leaderstats"
	
	local Wins = Instance.new("IntValue", leaderstats)
	Wins.Name = "Wins"
	Wins.Value = 0 -- Default Value
	
	local Coins = Instance.new("IntValue", leaderstats)
	Coins.Name = "Coins"
	Coins.Value = 0
	
	---------[Secondary Values]---------
	local OtherValues = Instance.new("Folder", Plr)
	OtherValues.Name = "OtherValues"
	
	local FreeRevives = Instance.new("IntValue", OtherValues)
	FreeRevives.Name = "FreeRevives"
	FreeRevives.Value = 3
	
	local GroupRevive = Instance.new("BoolValue", OtherValues)
	GroupRevive.Name = "GroupRevive"
	GroupRevive.Value = false
	
	local OwnedCharacters = Instance.new("Folder", OtherValues)
	OwnedCharacters.Name = "OwnedCharacters"
	
	local EquipedCharacter = Instance.new("StringValue", OtherValues)
	EquipedCharacter.Name = "EquipedCharacter"
	EquipedCharacter.Value = "Larry" -- Default Value
	
	local success, Data = pcall(function()
		return PlrData:GetAsync(Plr.UserId)
	end)
	if success and Data then
		if Data.Wins then -- In case if the value is nil
			Wins.Value = Data.Wins
		end
		if Data.Coins then
			Coins.Value = Data.Coins
		end
		if Data.FreeRevives then
			FreeRevives.Value = Data.FreeRevives
		end
		if Data.GroupRevive then
			GroupRevive.Value = Data.GroupRevive
		end
		if Data.EquipedCharacter then
			EquipedCharacter.Value = Data.EquipedCharacter
		end
		if Data.OwnedCharacters then
			for i, v in Data.OwnedCharacters do
				local newChar = Instance.new("StringValue", OwnedCharacters)
				newChar.Name = v
			end
		end
	end
end)

local function saveData(plr)
	local OwnedChars = {}
	
	for i, v in plr.OtherValues.OwnedCharacters:GetChildren() do
		table.insert(OwnedChars, v.Name)
	end
	
	local plrData = {
		["Wins"] = plr.leaderstats.Wins.Value;
		["Coins"] = plr.leaderstats.Coins.Value;
		["FreeRevives"] = plr.OtherValues.FreeRevives.Value;
		["GroupRevive"] = plr.OtherValues.GroupRevive.Value;
		["EquipedCharacter"] = plr.OtherValues.EquipedCharacter.Value;
		["OwnedCharacters"] = OwnedChars;
	}
	
	local success, errmsg = pcall(function()
		PlrData:SetAsync(plr.UserId, plrData)
	end)
	if not success then
		warn("Can't save "..plr.Name.." Data, error: ".. errmsg)
	end
end

game:BindToClose(function()
	for i, v in game.Players:GetPlayers() do
		saveData(v)
	end
end)

game.Players.PlayerRemoving:Connect(function(plr)
	saveData(plr)
end)