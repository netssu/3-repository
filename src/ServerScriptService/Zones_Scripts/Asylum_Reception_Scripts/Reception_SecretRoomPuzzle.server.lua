--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Secret Room
local SecretRoomFolder = InteractStuff:FindFirstChild("SecretRoom")
local Statues_Pos = SecretRoomFolder:FindFirstChild("Statues_Pos")
local StatuesCutscene = Map.Cutscenes:FindFirstChild("StatuesCutscene")

--//Locker 137
local DoorsFolder = Map:FindFirstChild("Doors")
local Locker_137 = DoorsFolder:FindFirstChild("Locker_137")
local ProxLocker = Locker_137.MainDoor:WaitForChild("ProximityPrompt", 30)
local ProxPadLock = Instance.new("ProximityPrompt", Locker_137.MainDoor)

local Vault = InteractStuff:FindFirstChild("Vault")

--//Values
local CurrentStatues_Pos = {}
local CorrectCrystals = {}
local unlockedLocker = false
local givenObjective = false
local completedPuzzle = false
local puzzleReward = math.random(10, 15)

--//Setup
Locker_137.BillboardGui.Enabled = false
Vault.BillboardGui.Enabled = false
ProxPadLock.MaxActivationDistance = GameConfigModule.InteractDistance
ProxPadLock.RequiresLineOfSight = false
ProxPadLock.Style = Enum.ProximityPromptStyle.Custom
ProxPadLock.HoldDuration = 0.15
ProxPadLock.ActionText = "Unlock"
ProxPadLock.ObjectText = "Locker 137"

if ProxLocker then
	ProxLocker.Enabled = false
end

ProxPadLock.Triggered:Connect(function(plr)
	if not unlockedLocker then
		local char = plr.Character
		local hum = char:WaitForChild("Humanoid")
		if hum and hum.Health > 0 and char:FindFirstChild("Locker Key") then
			InventoryModule.DeleteItem("Locker Key")
			ObjectivesModule.CompleteObjective(true, "Locker_137")
			Locker_137.Locked.Value = false
			ProxLocker.Enabled = true
			ProxPadLock.Enabled = false
			unlockedLocker = true
			Locker_137.PadLock.Base.UnlockSound:Play()
			Locker_137.PadLock.Base.Anchored = false
			Locker_137.BillboardGui.Enabled = false
			Vault.BillboardGui.Enabled = true
		else
			if not givenObjective then
				givenObjective = true
				ObjectivesModule.NewObjective(true, "Locker_137", "Unlock Locker 137", "Find a key to unlock the Locker 137.")
			end
			DialogModule.Dialog(false, plr, nil, "Locked, I'll need a key to open this Locker.")
		end
	end
end)

-- Start the Puzzle cutscene.
local function PlayCustceneStatues()
	task.wait(1)
	ActiveCutsceneEvent:FireAllClients("StatuesCutscene")
	task.delay(3, function()
		local zoneToGo = Map:FindFirstChild("TeleportZones"):FindFirstChild("StatuesCutscene").Name
		TeleportModule:Teleport(zoneToGo, script, true, true)
	end)
end

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "OpenGate" then
		StatuesCutscene:FindFirstChild("Concrete_Passage").OpenSound:Play()
		Ts:Create(StatuesCutscene:FindFirstChild("Concrete_Passage"), TweenInfo.new(4.2), {CFrame = StatuesCutscene:FindFirstChild("PassageOpenPos").CFrame}):Play()
		
		task.wait(3.5)
		
		local keyClone = Rs.Items:FindFirstChild("Locker Key"):Clone()
		keyClone.Parent = Rs
		
		Map.Items["Locker Key"].PrimaryPart.Anchored = false
		Ts:Create(Map.Items["Locker Key"].Locker_Key.RopeConstraint, TweenInfo.new(3.8), {Length = 0.8}):Play()
		
		task.wait(8.5)
		
		Map.Items["Locker Key"]:Destroy()
		keyClone.Parent = Map.Items
		keyClone:PivotTo(Rs.Items:FindFirstChild("Locker Key").IMPORTANT.Value)
	end
end)

-- Check if completed the Puzzle.
local function checkIfIsCorrect()
	local correct = true
	for i, v in SecretRoomFolder:GetChildren() do
		if string.find(v.Name, "Crystal_") then
			if CorrectCrystals[v.Name] and CorrectCrystals[v.Name] == true then
				continue
			else
				correct = false
				if not CorrectCrystals[v.Name] then
					CorrectCrystals[v.Name] = false
				end
			end
		end
	end
	return correct
end

local function checkCorrectStatues()
	local crystal1 = SecretRoomFolder:FindFirstChild("Crystal_1")
	local crystal6 = SecretRoomFolder:FindFirstChild("Crystal_6")
	
	local crystal3 = SecretRoomFolder:FindFirstChild("Crystal_3")
	local crystal4 = SecretRoomFolder:FindFirstChild("Crystal_4")
	
	local played = false
	
	for i, v in SecretRoomFolder:FindFirstChild("Statue_Eyes1"):GetDescendants() do
		if v:IsA("ParticleEmitter") then
			if crystal1.Material == Enum.Material.Neon and crystal6.Material == Enum.Material.Neon then
				if not v.Enabled then
					v.Enabled = true
					if not played then
						played = true
						local sound = SecretRoomFolder:FindFirstChild("FireSound"):Clone()
						sound.Parent = v.Parent
						sound:Play()
						game.Debris:AddItem(sound, sound.TimeLength + 1)
					end
				end
			else
				v.Enabled = false
			end
		end
	end
	
	for i, v in SecretRoomFolder:FindFirstChild("Statue_Eyes2"):GetDescendants() do
		if v:IsA("ParticleEmitter") then
			if crystal3.Material == Enum.Material.Neon and crystal4.Material == Enum.Material.Neon then
				if not v.Enabled then
					v.Enabled = true
					if not played then
						played = true
						local sound = SecretRoomFolder:FindFirstChild("FireSound"):Clone()
						sound.Parent = v.Parent
						sound:Play()
						game.Debris:AddItem(sound, sound.TimeLength + 1)
					end
				end
			else
				v.Enabled = false
			end
		end
	end
end

--//Pillars Prompt Function
for i, v in Statues_Pos:GetChildren() do
	if v:IsA("BasePart") then
		local state = false
		local prox = Instance.new("ProximityPrompt", v)
		prox.MaxActivationDistance = GameConfigModule.InteractDistance
		prox.RequiresLineOfSight = false
		prox.Style = Enum.ProximityPromptStyle.Custom
		prox.HoldDuration = 0.12
		prox.ActionText = "Put"
		prox.Enabled = false
		
		--[[old version:
		prox.Triggered:Connect(function(plr)
			local char = plr.Character
				
			for i, item in char:GetChildren() do
				if item:IsA("Tool") then
					if string.find(item.Name, "Statue") then
						state = true
						prox.Enabled = false
						
						for i, pos in pairs(CurrentStatues_Pos) do
							if pos == v.Name then
								state = false
								break
							end
						end
						
						if not state then warn("Position is Ocuped!") break end
						
						local itemModel = Rs.Items:FindFirstChild(item.Name):Clone() :: Model
						itemModel.PrimaryPart.Anchored = true
						InventoryModule.DeleteItem(item.Name)
						item:Destroy()
						
						itemModel.Parent = Map.Items
						itemModel:PivotTo(v.CFrame)
						itemModel.PrimaryPart.Orientation = Vector3.new(itemModel.PrimaryPart.Orientation.X, math.random(-360, 360), itemModel.PrimaryPart.Orientation.Z)
						
						local number = string.match(itemModel.Name, "%d+")
						if string.match(v.Name, number) then
							local Crystal = SecretRoomFolder:FindFirstChild("Crystal_"..number) :: BasePart
							Crystal.Material = Enum.Material.Neon
							CorrectCrystals[Crystal.Name] = true
						end
						
						if CurrentStatues_Pos[item.Name] then
							CurrentStatues_Pos[item.Name] = v.Name
						end
						
						local completed = checkIfIsCorrect()
						if completed then -- win
							warn("Completed Statues Puzzle!")
							MoneyModule.Give(plr, puzzleReward)
							for i, v: Model in Map.Items:GetChildren() do
								if string.find(v.Name, "Statue") and v:HasTag("Item") then
									local primaryPart = v.PrimaryPart
									local prox = primaryPart:WaitForChild("ProximityPrompt")
									prox.Enabled = false
								end
							end
							PlayCustceneStatues()
						end
						break
					end
				end
			end
			
			checkCorrectStatues()
			
			if not state then
				DialogModule.Dialog(false, plr, nil, "You need to pick up a Statue to place it here.", true)
			end
		end)]]
		
		prox.Triggered:Connect(function(plr)
			local char = plr.Character
			if not char then return end
			
			--//Check if the position is free
			if v:GetAttribute("Busy") then
				DialogModule.Dialog(false, plr, nil, "Another statue is already placed here.", true)
				return
			end
			
			for _, item in ipairs(char:GetChildren()) do
				if item:IsA("Tool") and string.find(item.Name, "Statue") then
					v:SetAttribute("Busy", true)
					prox.Enabled = false
					
					local itemModel = Rs.Items:FindFirstChild(item.Name):Clone() :: Model
					itemModel.PrimaryPart.Anchored = true
					InventoryModule.DeleteItem(item.Name)
					item:Destroy()
					
					itemModel.Parent = Map.Items
					itemModel:PivotTo(v.CFrame)
					itemModel.PrimaryPart.Orientation = Vector3.new(
						itemModel.PrimaryPart.Orientation.X,
						math.random(-360, 360),
						itemModel.PrimaryPart.Orientation.Z
					)
					
					local number = string.match(itemModel.Name, "%d+")
					if string.match(v.Name, number) then
						local Crystal = SecretRoomFolder:FindFirstChild("Crystal_"..number) :: BasePart
						Crystal.Material = Enum.Material.Neon
						CorrectCrystals[Crystal.Name] = true
					end
					
					CurrentStatues_Pos[itemModel.Name] = v.Name
					
					if checkIfIsCorrect() and not completedPuzzle then -- win
						warn("Completed Statues Puzzle!")
						completedPuzzle = true
						MoneyModule.Give(plr, puzzleReward)
						
						for _, placedStatue: Model in Map.Items:GetChildren() do
							if string.find(placedStatue.Name, "Statue") and placedStatue:HasTag("Item") then
								local part = placedStatue.PrimaryPart
								local prompt = part:FindFirstChildWhichIsA("ProximityPrompt")
								if prompt then
									prompt.Enabled = false
								end
							end
						end
						
						PlayCustceneStatues()
					end
					
					checkCorrectStatues()
					return
				end
			end
			
			DialogModule.Dialog(false, plr, nil, "You need to pick up a Statue to place it here.", true)
		end)
	end
end

-- Statue function when player take it.
local function connectStatues()
	for i, statue: Model in Map.Items:GetChildren() do
		if string.find(statue.Name, "Statue") and not statue:HasTag("connected_puzzle") then
			local primaryPart = statue.PrimaryPart
			local prox = primaryPart:WaitForChild("ProximityPrompt") :: ProximityPrompt
			statue:AddTag("connected_puzzle")
			
			--[[if not prox then warn("Prox not found: ", statue) end
			prox.Enabled = true
			
			prox.Triggered:Connect(function(plr)
				local pos = CurrentStatues_Pos[statue.Name]
				if pos and pos ~= "none" then
					local number = string.match(CurrentStatues_Pos[statue.Name], "%d+")
					local pos = Statues_Pos:FindFirstChild(CurrentStatues_Pos[statue.Name])
					local posProx = pos:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt
					local Crystal = SecretRoomFolder:FindFirstChild("Crystal_"..number) :: BasePart
					Crystal.Material = Enum.Material.Glass
					posProx.Enabled = true
					pos:SetAttribute("Busy", nil)
					
					if CorrectCrystals[Crystal.Name] then
						CorrectCrystals[Crystal.Name] = false
					end
					
					CurrentStatues_Pos[statue.Name] = nil
					
					checkCorrectStatues()
				end
			end)]]
		end
	end
end

-- Setup the puzzle.
local function setupPuzzle()
	local alreadyUsedPos = {}
	for i, v in Map.Items:GetChildren() do
		if v:HasTag("Item") and v:IsA("Model") and string.find(v.Name, "Statue") then
			local randomPos = nil
			
			repeat wait()
				randomPos = Statues_Pos:GetChildren()[math.random(1, #Statues_Pos:GetChildren())]
			until not alreadyUsedPos[randomPos]
			
			v:PivotTo(randomPos.CFrame)
			v.PrimaryPart.Orientation = Vector3.new(v.PrimaryPart.Orientation.X, math.random(-360, 360), v.PrimaryPart.Orientation.Z)
			alreadyUsedPos[randomPos] = true
			
			--[[
			local itemOnRs = Rs.Items:FindFirstChild(v.Name)
			itemOnRs:FindFirstChildWhichIsA("CFrameValue").Value = v.PrimaryPart.CFrame
			]]
			
			local number = string.match(v.Name, "%d+")
			if string.match(randomPos.Name, number) then
				local Crystal = SecretRoomFolder:FindFirstChild("Crystal_"..number) :: BasePart
				Crystal.Material = Enum.Material.Neon
				CorrectCrystals[Crystal.Name] = true
			end
			
			CurrentStatues_Pos[v.Name] = randomPos.Name
		end
	end
end

task.wait(5)

setupPuzzle()
--connectStatues()
checkCorrectStatues()

Map.Items.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:HasTag("Item") then
		if string.find(child.Name, "Statue") then
			--connectStatues()
		end
	end
end)

Map.Items.ChildRemoved:Connect(function(child)
	if child:IsA("Model") and child:HasTag("Item") then
		if string.find(child.Name, "Statue") then
			local statuePos = CurrentStatues_Pos[child.Name]
			if not statuePos then return end
			local pos = Statues_Pos:FindFirstChild(CurrentStatues_Pos[child.Name])
			
			if pos then
				local posProx = pos:FindFirstChildWhichIsA("ProximityPrompt") :: ProximityPrompt
				local number = string.match(CurrentStatues_Pos[child.Name], "%d+") 
				local Crystal = SecretRoomFolder:FindFirstChild("Crystal_"..number) :: BasePart
				Crystal.Material = Enum.Material.Glass
				posProx.Enabled = true
				pos:SetAttribute("Busy", nil)
				
				if CorrectCrystals[Crystal.Name] then
					CorrectCrystals[Crystal.Name] = false
				end
				
				CurrentStatues_Pos[child.Name] = nil
				
				checkCorrectStatues()
			end
		end
	end
end)