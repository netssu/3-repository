--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfig = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Map Stuff
local MapFolder = workspace:FindFirstChild("Map")
local InteractStuff = MapFolder:FindFirstChild("Area2_AsylumReception"):FindFirstChild("InteractStuff")
local TriggerArea2 = InteractStuff:FindFirstChild("ObjectiveRestrictedArea")
local TriggerArea2_Stop = InteractStuff:FindFirstChild("EnergyRoomTrigger")

--//Values
local Area1_Enabled = false
local Area2_Enabled = false
local CurrentEnabledArea: RBXScriptConnection = nil

local function GetRandomEvent(area: Folder)
	if not area then return end
	
	local function selectRandomEvent()
		local randomNum = math.random()
		local selectedEventRar = 1
		local eventSelected = nil
		local commonEvents = {}
		
		for _, event in area:GetChildren() do
			local success, result = pcall(function()
				return require(event)
			end)
			if success then
				if result.Rarity <= randomNum and result.Rarity <= selectedEventRar then
					eventSelected = result
					selectedEventRar = result.Rarity
					if result.Rarity >= 0.2 then
						table.insert(commonEvents, result)
					end
				end
			end
		end
		
		if eventSelected and eventSelected.OneTime then
			if eventSelected.Activated then
				selectRandomEvent()
			else
				return eventSelected
			end
		--[[elseif not eventSelected then -- testing (select a event everytime)
			if #commonEvents > 0 then
				eventSelected = commonEvents[math.random(1, #commonEvents)]
			else
				eventSelected = area:GetChildren()[math.random(1, #area:GetChildren())]
			end]]
		end
		return eventSelected
	end
	
	local randomEvent = selectRandomEvent()
	
	if randomEvent and randomEvent.Activated then
		randomEvent.Activated = true
	end
	
	return randomEvent
end

local function disconnectOldArea()
	if (CurrentEnabledArea) then
		coroutine.close(CurrentEnabledArea)
		CurrentEnabledArea = nil
	end
end

local function createNewConnection(areaFolder: Folder)
	if not areaFolder then warn("Can't start random events for undefined area.") return end
	CurrentEnabledArea = coroutine.wrap(function()
		while true do
			if GameConfig.GameMode == "Hard" then
				task.wait(30) -- Events happen more often in hard mode
			elseif GameConfig.GameMode == "Nightmare" then
				task.wait(25) -- Events happen even more often in hard mode
			else
				task.wait(36) -- normal mode
			end
			local randomNum = math.random()
			if randomNum <= GameConfig.RandomEventsFactor then
				local success, result = pcall(function()
					return GetRandomEvent(areaFolder)
				end)
				if success and result then
					result:Start()
				else
					print("Can't start event, error: ", result)
				end
			end
		end
	end)()
end

local function StartAreaRandomEvents(Area: number)
	disconnectOldArea()
	if Area == 1 then
		createNewConnection(script:FindFirstChild("Area1_Events"))
	elseif Area == 2 then
		createNewConnection(script:FindFirstChild("Area2_Events"))
	end
end

local function checkValidyPlr(hit: BasePart)
	if not hit or not hit.Parent then return false end
	if not hit.Parent:FindFirstChildWhichIsA("Humanoid") or  hit.Parent:FindFirstChildWhichIsA("Humanoid").Health <= 0 then
		return false
	end
	local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
	if not plr then return false end
	return true
end

--//Start the random events for Area 2.
TriggerArea2.Touched:Connect(function(hit)
	local validy = checkValidyPlr(hit)
	if not validy then return end
	if Area2_Enabled then return end
	
	Area2_Enabled = true
	StartAreaRandomEvents(2)
end)

--//Stop the random events for Area 2.
TriggerArea2_Stop.Touched:Connect(function(hit)
	local validy = checkValidyPlr(hit)
	if not validy then return end
	disconnectOldArea()
end)