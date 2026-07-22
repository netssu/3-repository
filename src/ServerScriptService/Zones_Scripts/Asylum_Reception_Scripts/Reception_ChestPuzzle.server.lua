--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local InspectEvent = Remotes:FindFirstChild("Inspect")
local ChestPuzzleEvent = Remotes:FindFirstChild("chestPuzzle")

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Chest Puzzle
local Chest = InteractStuff:FindFirstChild("Chest")
local proxChest = Instance.new("ProximityPrompt", Chest.Interact)

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))

--//Values
local openedChest = false
local currentPlrInspecting = nil
local defaultPaperClipPos = Chest.Paper_Clip.CFrame
local clipConnection : RBXScriptConnection = nil

--//Setup
Chest.BillboardGui.Enabled = false
proxChest.MaxActivationDistance = GameConfigModule.InteractDistance
proxChest.RequiresLineOfSight = false
proxChest.Style = Enum.ProximityPromptStyle.Custom
proxChest.HoldDuration = 0.15
proxChest.ActionText = "Inspect"
proxChest.ObjectText = "Chest"

local function clipAnim()
	return coroutine.create(function()
		while true do
			Ts:Create(Chest.Paper_Clip, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {CFrame = Chest.PaperClipFlickPos1.CFrame}):Play()
			task.wait(0.3)
			Ts:Create(Chest.Paper_Clip, TweenInfo.new(0.3, Enum.EasingStyle.Linear), {CFrame = Chest.PaperClipFlickPos2.CFrame}):Play()
			task.wait(0.3)
		end
	end)
end

local function changePaperClip(state: boolean)
	if state then
		Chest.Interact.ClipSound:Play()
		local tween = Ts:Create(Chest.Paper_Clip, TweenInfo.new(0.3), {Transparency = 0, CFrame = Chest.PaperClipPos.CFrame})
		tween:Play()
		tween.Completed:Connect(function()
			if currentPlrInspecting ~= nil then
				if (clipConnection) then
					coroutine.close(clipConnection)
					clipConnection = nil
				end
				clipConnection = clipAnim()
				coroutine.resume(clipConnection)
			end
		end)
	else
		if clipConnection then
			coroutine.close(clipConnection)
			clipConnection = nil
		end
		Chest.Interact.ClipSound2:Play()
		Ts:Create(Chest.Paper_Clip, TweenInfo.new(0.3), {CFrame = defaultPaperClipPos}):Play()
		Ts:Create(Chest.Paper_Clip, TweenInfo.new(0.1), {Transparency = 1}):Play()
	end
end

proxChest.Triggered:Connect(function(plr)
	if plr.Character then
		local char = plr.Character
		local humanoid = char:WaitForChild("Humanoid")
		if humanoid and humanoid.Health > 0 and currentPlrInspecting == nil and not openedChest then
			if char:FindFirstChild("Paper Clip") and char:FindFirstChild("Paper Clip"):IsA("Tool") then
				proxChest.Enabled = false
				currentPlrInspecting = plr
				InspectEvent:FireClient(plr, "InspectON", Chest.CamPart)
				Chest.BillboardGui.Enabled = false
				task.delay(0.5, changePaperClip, true)
				
				local toolOnHand = char:FindFirstChildWhichIsA("Tool")
				if toolOnHand then
					toolOnHand.Parent = plr.Backpack
				end
				
				local puzzleGui = Chest.ChestPuzzleGui:Clone()
				puzzleGui.Parent = plr.PlayerGui
				puzzleGui.Enabled = true
			else
				DialogModule.Dialog(false, plr, nil,"Maybe I could unlock this chest if I had a paper clip.")
			end
		end
	end
end)

local function removePuzzleUI(plr: Player)
	if not plr then return end
	if plr.PlayerGui:FindFirstChild(Chest.ChestPuzzleGui.Name) then
		plr.PlayerGui:FindFirstChild(Chest.ChestPuzzleGui.Name):Destroy()
	end
end

InspectEvent.OnServerEvent:Connect(function(plr, event)
	if event == "InspectOFF" and currentPlrInspecting then
		removePuzzleUI(plr)
		currentPlrInspecting = nil
		if not openedChest then
			proxChest.Enabled = true
			Chest.BillboardGui.Enabled = true
		end
		changePaperClip(false)
	end
end)

ChestPuzzleEvent.OnServerEvent:Connect(function(plr, event)
	if event == "level" then
		Ts:Create(Chest.Paper_Clip, TweenInfo.new(0.08), {CFrame = Chest.PaperClipFlickPos3.CFrame}):Play()
		Chest.Interact.ClickSound:Play()
	elseif event == "lose" then
		Chest.Interact.BrokeSound:Play()
		InventoryModule.RemoveItem(plr, "Paper Clip")
		changePaperClip(false)
		
		task.wait(0.5)
		
		removePuzzleUI(plr)
		InspectEvent:FireClient(plr, "InspectOFF") -- camera back to normal
		currentPlrInspecting = nil
		proxChest.Enabled = true
	elseif event == "win" then
		Chest.Interact.UnlockSound:Play()
		changePaperClip(false)
		--InventoryModule.RemoveItem(plr, "Paper Clip")
		InventoryModule.DeleteItem("Paper Clip") -- remove paper clip from all players inventory
		
		for i, v in Chest.PadLock:GetDescendants() do
			if v:IsA("BasePart") then
				v.Anchored = false
			end
		end
		
		task.wait(0.7)
		
		openedChest = true
		InspectEvent:FireClient(plr, "InspectOFF") -- camera back to normal
		currentPlrInspecting = nil
		proxChest.Enabled = false
		removePuzzleUI(plr)
		
		task.wait(0.3)
		
		Chest.Interact.ChestOpen:Play()
		Ts:Create(Chest.Hinge, TweenInfo.new(0.5, Enum.EasingStyle.Sine), {CFrame = Chest.OpenedChestPos.CFrame}):Play()
	end
end)

--//Paper clips respawn
while true do
	task.wait(30)
	if openedChest then
		break
	end
	
	local paperClips = {}
	for i, v in Map.Items:GetChildren() do
		if v.Name == "Paper Clip" then
			table.insert(paperClips, v)
		end
	end
	
	if #paperClips < 10 then
		local paperClipsSpawn = InteractStuff:FindFirstChild("PaperClips_Spawn")
		local alredyChoosen = {}
		local times = 25
		
		for i=1, times do
			local randomSpawn = paperClipsSpawn:GetChildren()[math.random(1, #paperClipsSpawn:GetChildren())]
			if alredyChoosen[randomSpawn] then times += 1 continue end
			local newPaperClip = Rs.Items:FindFirstChild("Paper Clip"):Clone()
			if not newPaperClip.PrimaryPart then continue end
			newPaperClip:PivotTo(randomSpawn.CFrame)
			newPaperClip.Parent = Map.Items
			alredyChoosen[randomSpawn] = true
		end
		
		print("respawned paper clips")
		table.clear(alredyChoosen)
	end
	table.clear(paperClips)
end