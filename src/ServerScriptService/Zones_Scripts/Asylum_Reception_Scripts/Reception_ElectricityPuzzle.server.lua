--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")
local GamePuzzlesEvent = Remotes:FindFirstChild("gamePuzzles")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Eletricity Puzzle
local EletricityBlock = InteractStuff:FindFirstChild("Eletricity_Block")
local EletricBox = InteractStuff:FindFirstChild("EletricBox")
local CablesFolder = EletricBox:FindFirstChild("Cables")
local Cable_Entry1 = CablesFolder:FindFirstChild("Cable_Entry1")
local Cable_Entry2 = CablesFolder:FindFirstChild("Cable_Entry2")
local Cable_Entry3 = CablesFolder:FindFirstChild("Cable_Entry3")
local Main_Connector = CablesFolder:FindFirstChild("Main_Connector")
local RotationSound = EletricBox:FindFirstChild("RotationSounds")
local proxEletricBox = Instance.new("ProximityPrompt", EletricBox.Interact)
local EletricBox_ConsoleGui = EletricBox:FindFirstChild("EletricityPuzzle_ConsoleGui")

--//Values
local currentPlr = nil
local puzzleReward = 20
local barrierDebounce = true
local moveDebounce = true
local depuration = false -- for testing
local puzzleCompleted = false
local cables = {}

--//Setup
EletricBox.BillboardGui.Enabled = false
EletricityBlock.BillboardGui.Enabled = false
proxEletricBox.MaxActivationDistance = GameConfigModule.InteractDistance
proxEletricBox.RequiresLineOfSight = false
proxEletricBox.Style = Enum.ProximityPromptStyle.Custom
proxEletricBox.HoldDuration = 0.15
proxEletricBox.ActionText = "Inspect"
proxEletricBox.ObjectText = "Power Box"

EletricityBlock.Barrier.Touched:Connect(function(hit)
	if hit.Parent and hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local hum = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		if hum.Health > 0 then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player and barrierDebounce and not puzzleCompleted then
				barrierDebounce = false
				DialogModule.Dialog(false, player, nil, "I can't pass by here with the electricity on.")
				
				local energySound = EletricityBlock.Barrier.EletrocutedSound:Clone()
				local rootPart = hit.Parent:FindFirstChild("HumanoidRootPart")
				energySound.Parent = rootPart or EletricityBlock.Barrier
				energySound:Play()
				hum.Health -= hum.Health * 0.08 -- 8% of the current health
				game.Debris:AddItem(energySound, energySound.TimeLength + 1)
				
				local badge = BadgesModule:FindBadge("Eletrocuted")
				BadgesModule:GiveBadge(player, badge.Id)
				
				task.wait(1)
				barrierDebounce = true
			elseif puzzleCompleted then
				EletricityBlock.BillboardGui.Enabled = false
			end
		end
	end
end)

local function playSound(sound: Sound, parent: Instance)
	if not sound or not sound:IsA("Sound") then return end
	local snd = sound:Clone()
	if not parent then
		snd.Parent = sound.Parent
	else
		snd.Parent = parent
	end
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

local function checkIfIsCorrect()
	local correct1 = false
	local correct2 = false
	local correct3 = false
	local correct4 = false
	
	if Cable_Entry1.On.Value then
		correct1 = true
	end
	if Cable_Entry2.On.Value then
		correct2 = true
	end
	if Cable_Entry3.On.Value then
		correct3 = true
	end
	if Main_Connector.On.Value then
		correct4 = true
	end
	
	if correct1 and correct2 and correct3 and correct4 then
		return true
	end
	return false
end

--//Function for depuration
local function makeRayCastVisible(origin: Vector3, direction: Vector3)
	if not depuration then return end
	local ray = Ray.new(origin, direction)
	local hit, position = workspace:FindPartOnRay(ray)
	if hit then
		local distance = (origin - position).Magnitude
		local p = Instance.new("Part")
		p.CanQuery = false
		p.CanTouch = false
		p.Size = Vector3.new(0.02, 0.02, distance)
		p.CFrame = CFrame.new(origin, position) * CFrame.new(0, 0, -distance / 2)
		p.Anchored = true
		p.CanCollide = false
		p.Transparency = 0.5
		p.Material = Enum.Material.Neon
		p.Color = Color3.fromRGB(255, 0, 0)
		p.Parent = workspace
		game.Debris:AddItem(p, 5)
	end
end

local function updatePathConnections()
	local starterRayParams = RaycastParams.new()
	starterRayParams.FilterType = Enum.RaycastFilterType.Exclude
	
	local connections = {} -- All connections found
	local visited = {} -- To avoid infinite loops
	
	local function calculateEnergyPath(startPart)
		local queue = { startPart } -- Queue for connections to be calculed
		
		while #queue > 0 do
			local currentPart = table.remove(queue, 1)
			
			if not visited[currentPart] then
				visited[currentPart] = true -- Mark that already calculed this connection
				table.insert(connections, currentPart)
				
				--//Get the connection model
				local connectionModel = currentPart.Parent.Parent
				
				if connectionModel then
					--//Get all the another connections in the same model
					for _, part in pairs(connectionModel:GetDescendants()) do
						if part:IsA("BasePart") and part.Name == "Connection" and not visited[part] then
							table.insert(connections, part)
							table.insert(queue, part) -- Add to the queue a new connection to be calculed
						end
					end
				end
				
				--//Calculate the current connection
				local origin_ = currentPart.CFrame.Position
				local direction_ = currentPart.CFrame.LookVector * 10
				local raycastResult = workspace:Raycast(origin_, direction_, starterRayParams)
				makeRayCastVisible(origin_, direction_)
				
				if raycastResult and raycastResult.Instance and raycastResult.Instance.Name == "Connection" then
					if not visited[raycastResult.Instance] then
						table.insert(queue, raycastResult.Instance) -- Add a new connection to be calculed
					end
				end
			end
		end
	end
	
	local origin = Cable_Entry1.Entry1.Connection.CFrame.Position
	local direction = Cable_Entry1.Entry1.Connection.CFrame.LookVector * 10
	local firstResult = workspace:Raycast(origin, direction, starterRayParams)
	makeRayCastVisible(origin, direction)
	
	if firstResult and firstResult.Instance and firstResult.Instance.Name == "Connection" then
		calculateEnergyPath(firstResult.Instance)
	end
	
	--//Turn off another connections
	for _, connectionModel in pairs(CablesFolder:GetDescendants()) do
		if connectionModel:IsA("Model") then
			local connectionPart = connectionModel:FindFirstChild("Connection", true)
			if connectionPart and not visited[connectionPart] then
				local lightPart = connectionModel.Parent:FindFirstChild("LightPart")
				if lightPart then
					if connectionModel.Parent.Name == "Cable_Entry1" or connectionModel.Parent.Name == "Cable_Entry2" or connectionModel.Parent.Name == "Cable_Entry3" then
						lightPart.Color = Color3.new(0.686275, 0.266667, 0.266667)
					else
						lightPart.Color = Color3.new(0.239216, 0.239216, 0.239216)
					end
				end
				if connectionModel.Parent:FindFirstChild("On") then
					connectionModel.Parent:FindFirstChild("On").Value = false
				end
			end
		end
	end
	
	--//Get all connections and turn on
	for _, connection in pairs(connections) do
		if connection.Parent and connection.Parent.Parent then
			local lightPart = connection.Parent.Parent:FindFirstChild("LightPart")
			if lightPart then
				lightPart.Material = Enum.Material.Neon
				if connection.Parent.Parent.Name == "Cable_Entry1" or connection.Parent.Parent.Name == "Cable_Entry2" or connection.Parent.Parent.Name == "Cable_Entry3" then
					lightPart.Color = Color3.new(0.309804, 0.686275, 0.25098)
				else
					lightPart.Color = Color3.new(0.741176, 0.741176, 0.741176)
				end
			end
			if connection.Parent.Parent:FindFirstChild("On") then
				connection.Parent.Parent:FindFirstChild("On").Value = true
			end
		end
	end
end

local function moveEnergyConnector(EnergyConnector: Model)
	if not EnergyConnector:IsA("Model") then return end
	if not EnergyConnector:FindFirstChild("Hinge") then return end
	local hinge = EnergyConnector:FindFirstChild("Hinge")
	local rotationPos = CFrame.Angles(math.rad(90), 0, 0)
	Ts:Create(hinge, TweenInfo.new(0.2), {CFrame = hinge.CFrame * rotationPos}):Play()
	task.wait(0.2)
	updatePathConnections()
end

local function setupConnections()
	for i = 1, 50 do
		local randomNum = math.random(1, #CablesFolder:GetChildren())
		local randomCable = CablesFolder:GetChildren()[randomNum]
		if randomCable and randomCable.Name ~= "Main_Connector" then
			moveEnergyConnector(randomCable)
		end
		task.wait()
	end
end

setupConnections()

proxEletricBox.Triggered:Connect(function(plr)
	if plr.Character then
		local char = plr.Character
		if char:FindFirstChild("Humanoid") and char:FindFirstChild("Humanoid").Health > 0 then
			if currentPlr == nil and not puzzleCompleted then
				EletricBox.BillboardGui.Enabled = false
				currentPlr = plr
				proxEletricBox.Enabled = false
				InspectEvent:FireClient(plr, "InspectON", EletricBox.CamPart, true)
				
				local toolOnHand = char:FindFirstChildWhichIsA("Tool")
				if toolOnHand then
					toolOnHand.Parent = plr.Backpack
				end
				
				local gui = EletricBox_ConsoleGui:Clone()
				gui.Parent = plr.PlayerGui
				gui.Name = "ELETRICBOX_CONSOLE_GUI"
			end
		end
	end
end)

local function solvePuzzleFunc(plr: Player)
	print("Solved eletricity puzzle.")
	puzzleCompleted = true
	EletricBox.BillboardGui.Enabled = false
	EletricityBlock.BillboardGui.Enabled = true

	EletricBox.Interact.CorrectSound:Play()
	EletricityBlock.Barrier.CanCollide = false
	--EletricityBlock.Barrier.CanTouch = false
	EletricityBlock.Barrier.CanQuery = false

	for i, v in EletricityBlock.Effects:GetDescendants() do
		v:Destroy()
	end

	barrierDebounce = false
	
	if plr then
		local badge = BadgesModule:FindBadge("Cut the Power")
		BadgesModule:GiveBadge(plr, badge.Id)
		MoneyModule.Give(plr, puzzleReward)
	end
end

GamePuzzlesEvent.OnServerEvent:Connect(function(plr, action)
	if action == "eletricity_SOLVED" then
		if plr == currentPlr then
			solvePuzzleFunc(plr)
		end
	end
end)

InspectEvent.OnServerEvent:Connect(function(plr, event)
	if event == "InspectOFF" then
		if plr == currentPlr then
			currentPlr = nil
			proxEletricBox.Enabled = true
			
			--//Remove puzzle UI
			if plr.PlayerGui:FindFirstChild("ELETRICBOX_CONSOLE_GUI") then
				plr.PlayerGui:FindFirstChild("ELETRICBOX_CONSOLE_GUI"):Destroy()
			end
			
			if not puzzleCompleted then
				EletricBox.BillboardGui.Enabled = true
			end
			
			for i, v in CablesFolder:GetChildren() do
				if v:IsA("Model") then
					if v:FindFirstChild("Highlight") then
						local highlight = v.Highlight :: Highlight
						Ts:Create(highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
					end
				end
			end
		end
	end
end)

local function loadConnectionsFunc()
	for i, v in CablesFolder:GetChildren() do
		if v:IsA("Model") then
			if not v:FindFirstChild("ClickDetector") then continue end
			if v:HasTag("markedCable") then continue end
			v:AddTag("markedCable")
			
			local clicker = v.ClickDetector :: ClickDetector
			local highlight = v.Highlight :: Highlight
			local onValue = v.On
			local hinge = v.Hinge
			--highlight.Adornee = v:FindFirstChildWhichIsA("BasePart") or v.PrimaryPart
			
			clicker.MouseClick:Connect(function(plr)
				if not (plr == currentPlr) then return end
				if moveDebounce then
					moveDebounce = false
					
					local randomSound = RotationSound:GetChildren()[math.random(1, #RotationSound:GetChildren())]
					playSound(randomSound, hinge)
					
					moveEnergyConnector(v)
					local correct = checkIfIsCorrect()
					if correct then -- win
						solvePuzzleFunc(plr)
						return
					end
					moveDebounce = true
				end
			end)
			
			--[[
			clicker.MouseHoverEnter:Connect(function(plr)
				if not (plr == currentPlr) then return end
				Ts:Create(highlight, TweenInfo.new(0.1), {OutlineTransparency = 0.5}):Play()
			end)
			
			clicker.MouseHoverLeave:Connect(function(plr)
				if not (plr == currentPlr) then return end
				Ts:Create(highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
			end)
			]]
		end
	end
end

CablesFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		loadConnectionsFunc()
	end
end)

loadConnectionsFunc()