--//Services
local DataStore = game:GetService("DataStoreService")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local GameConfigModule = require(Rs:FindFirstChild("GameConfig"))

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local UpdatePlrOptions = Remotes:FindFirstChild("UpdatePlrOptions")
local UpdatePlrWins = Remotes:FindFirstChild("UpdatePlrWins")

--//Player Data
local PlrData = DataStore:GetDataStore(GameConfigModule.datastorekey)

game.Players.PlayerAdded:Connect(function(Plr)
	---------[Primary Values]---------
	local leaderstats = Instance.new("Folder", Plr)
	leaderstats.Name = "leaderstats"
	
	local Wins = Instance.new("IntValue", leaderstats)
	Wins.Name = "Wins"
	Wins.Value = 0 -- Default Value
	
	---------[Secondary Values]---------
	local OtherValues = Instance.new("Folder", Plr)
	OtherValues.Name = "OtherValues"
	
	local FreeRevives = Instance.new("IntValue", OtherValues)
	FreeRevives.Name = "FreeRevives"
	FreeRevives.Value = 0 -- Default Value
	
	local GroupRevive = Instance.new("BoolValue", OtherValues)
	GroupRevive.Name = "GroupRevive"
	GroupRevive.Value = false
	
	local EquipedCharacter = Instance.new("StringValue", OtherValues)
	EquipedCharacter.Name = "EquipedCharacter"
	EquipedCharacter.Value = "Mike Wheeler" -- Default Value
	
	---------[Player Options]-----------
	local GameOptions = Instance.new("Folder", Plr)
	GameOptions.Name = "GameOptions"
	
	local InterfaceStyle = Instance.new("BoolValue", GameOptions)
	InterfaceStyle.Name = "InterfaceStyle"
	InterfaceStyle.Value = true -- Realistic / Pratical
	
	local GraphicsMode = Instance.new("BoolValue", GameOptions)
	GraphicsMode.Name = "GraphicsMode"
	GraphicsMode.Value = false -- Realistic / Basic
	
	local MotionBlur = Instance.new("BoolValue", GameOptions)
	MotionBlur.Name = "MotionBlur"
	MotionBlur.Value = true -- Disabled / Enabled
	
	local GameTips = Instance.new("BoolValue", GameOptions)
	GameTips.Name = "GameTips"
	GameTips.Value = true -- Disabled / Enabled
	
	local RunMode = Instance.new("BoolValue", GameOptions)
	RunMode.Name = "RunMode"
	RunMode.Value = false -- Hold / Toggle
	
	local CrouchMode = Instance.new("BoolValue", GameOptions)
	CrouchMode.Name = "CrouchMode"
	CrouchMode.Value = true -- Hold / Toggle
	
	local OpenInventory = Instance.new("Folder", GameOptions)
	OpenInventory.Name = "OpenInventory"
	
	--Open Inventory Default Buttons--
	local PcButton_1 = Instance.new("StringValue", OpenInventory)
	PcButton_1.Name = "PcButton1"
	PcButton_1.Value = "R"
	
	local ConsoleButton_1 = Instance.new("StringValue", OpenInventory)
	ConsoleButton_1.Name = "ConsoleButton1"
	ConsoleButton_1.Value = "ButtonY" --Enum.KeyCode.[ButtonY]
	--Open Inventory Default Buttons--
	
	local DropItem = Instance.new("Folder", GameOptions)
	DropItem.Name = "DropItem"
	
	--Drop Item Buttons--
	local PcButton_2 = Instance.new("StringValue", DropItem)
	PcButton_2.Name = "PcButton2"
	PcButton_2.Value = "Q"
	
	local ConsoleButton_2 = Instance.new("StringValue", DropItem)
	ConsoleButton_2.Name = "ConsoleButton2"
	ConsoleButton_2.Value = "DPadDown" --Enum.KeyCode.[DPadDown]
	--Drop Item Buttons--
	
	local InteractButton = Instance.new("Folder", GameOptions)
	InteractButton.Name = "InteractButton"
	
	--Interact Buttons--
	local PcButton_3 = Instance.new("StringValue", InteractButton)
	PcButton_3.Name = "PcButton3"
	PcButton_3.Value = "E"
	
	local ConsoleButton_3 = Instance.new("StringValue", InteractButton)
	ConsoleButton_3.Name = "ConsoleButton3"
	ConsoleButton_3.Value = "ButtonX" --Enum.KeyCode.[ButtonX]
	--Interact Buttons--
	
	local loaded = false
	
	local success, Data = pcall(function()
		return PlrData:GetAsync(Plr.UserId)
	end)
	if success and Data then
		if Data.Wins then -- In case if the value is nil
			Wins.Value = Data.Wins
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
		if Data.Options then
			for i, Option in GameOptions:GetChildren() do
				if Option.Name == OpenInventory.Name then
					if Data.Options["PcButton1"] then
						OpenInventory.PcButton1.Value = Data.Options["PcButton1"].Value
					end
					if Data.Options["ConsoleButton1"] then
						OpenInventory.ConsoleButton1.Value = Data.Options["ConsoleButton1"].Value
					end
				elseif Option.Name == DropItem.Name then
					if Data.Options["PcButton2"] then
						DropItem.PcButton2.Value = Data.Options["PcButton2"].Value
					end
					if Data.Options["ConsoleButton2"] then
						DropItem.ConsoleButton2.Value = Data.Options["ConsoleButton2"].Value
					end
				elseif Option.Name == InteractButton.Name then
					if Data.Options["PcButton3"] then
						InteractButton.PcButton3.Value = Data.Options["PcButton3"].Value
					end
					if Data.Options["ConsoleButton3"] then
						InteractButton.ConsoleButton3.Value = Data.Options["ConsoleButton3"].Value
					end
				elseif not Option:IsA("Folder") then
					if Data.Options[Option.Name] then
						GameOptions:FindFirstChild(Option.Name).Value = Data.Options[Option.Name].Value
					end
				end
			end
		end
		loaded = true
		Rs.CanLoadChar.Value = true
	end
	
	task.delay(10, function()
		if not loaded then
			loaded = true
			Rs.CanLoadChar.Value = true
		end
	end)
end)

local function saveData(plr)
	local plrOptions = {}
	
	if plr:FindFirstChild("GameOptions") then
		for i, v: Instance in plr.GameOptions:GetDescendants() do
			if not v:IsA("Folder") then
				plrOptions[v.Name] = {
					["Value"] = v.Value;
					["Name"] = v.Name;
				}
			end
		end
	end
	
	local plrData = {
		["Wins"] = plr.leaderstats.Wins.Value;
		["FreeRevives"] = plr.OtherValues.FreeRevives.Value;
		["GroupRevive"] = plr.OtherValues.GroupRevive.Value;
		["EquipedCharacter"] = plr.OtherValues.EquipedCharacter.Value;
		["Options"] = plrOptions;
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

local plrsWinDebounce = {}

UpdatePlrWins.OnServerEvent:Connect(function(plr, amount)
	if plr and amount and not plrsWinDebounce[plr.Name] then
		plr.leaderstats.Wins.Value += amount
		plrsWinDebounce[plr.Name] = true
		task.delay(20, function() plrsWinDebounce[plr.Name] = nil end)
	end
end)

UpdatePlrOptions.OnServerEvent:Connect(function(plr, Option, NewValue, NewKeyCode)
	local GameOptions = plr:FindFirstChild("GameOptions")
	if GameOptions then
		if Option == "OpenInventory" then
			if NewValue == "PC" then
				GameOptions:FindFirstChild(Option).PcButton1.Value = NewKeyCode
			else
				GameOptions:FindFirstChild(Option).ConsoleButton1.Value = NewKeyCode
			end
		elseif Option == "DropItem" then
			if NewValue == "PC" then
				GameOptions:FindFirstChild(Option).PcButton2.Value = NewKeyCode
			else
				GameOptions:FindFirstChild(Option).ConsoleButton2.Value = NewKeyCode
			end
		elseif Option == "InteractButton" then
			if NewValue == "PC" then
				GameOptions:FindFirstChild(Option).PcButton3.Value = NewKeyCode
			else
				GameOptions:FindFirstChild(Option).ConsoleButton3.Value = NewKeyCode
			end
		elseif GameOptions:FindFirstChild(Option) then
			GameOptions:FindFirstChild(Option).Value = NewValue
		end
		UpdatePlrOptions:FireClient(plr)
	end
end)