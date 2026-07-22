--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ActiveCutsceneEvent = Remotes:FindFirstChild("ActiveCutscene")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))
local TeleportModule = require(ModulesFolder:FindFirstChild("TeleportModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")
local AsylumDoor_FirstArea = Map.Doors:FindFirstChild("Asylum_DoorFirstArea")
local asylumDoorProx = AsylumDoor_FirstArea.MainDoor:WaitForChild("ProximityPrompt", 10) :: ProximityPrompt

---//Rocks Area//---
local FallFloors = InteractStuff:FindFirstChild("FallFloors")
local BrokenFloors = InteractStuff:FindFirstChild("BrokenFloors")
local KillPart = InteractStuff:FindFirstChild("KillPart")
local RocksEndPart = InteractStuff:FindFirstChild("RocksEndPart")
local RocksEndPart2 = InteractStuff:FindFirstChild("RocksEndPart2")
local RocksBarrier = InteractStuff:FindFirstChild("RocksBarrier")

--//Sounds
local HitSounds = FallFloors.HitSounds
local FallingSound = FallFloors.FallingSound
local RocksSound = FallFloors.RocksSound

--//Values
local plrsInSafe = {}
local rocksCutscenePlayed = false

if asylumDoorProx then
	local triggerConn: RBXScriptConnection? = nil
	triggerConn = asylumDoorProx.Triggered:Connect(function(plr)
		AsylumDoor_FirstArea.BillboardGui.Enabled = false
		triggerConn:Disconnect()
		triggerConn = nil
	end)
end

local function loadFallRocksFunc()
	for i, v in FallFloors:GetChildren() do
		if v:IsA("Model") and v.PrimaryPart then
			if not v:HasTag("markedFallRock") then
				v:AddTag("markedFallRock")
				
				local Collider = v.PrimaryPart
				local debounce = true
				
				Collider.Touched:Connect(function(hit)
					if not hit.Parent then return end
					if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
						local player = game.Players:GetPlayerFromCharacter(hit.Parent)
						if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 and debounce and player then
							debounce = false
							
							local TouchSnd = RocksSound:Clone()
							TouchSnd.Parent = Collider
							TouchSnd:Play()
							game.Debris:AddItem(TouchSnd, TouchSnd.TimeLength + 1)
							
							task.wait(0.5)
							
							local FallSnd = FallingSound:Clone()
							FallSnd.Parent = Collider
							FallSnd:Play()
							game.Debris:AddItem(FallSnd, FallSnd.TimeLength + 1)
							
							for i, part in v:GetChildren() do
								if part:IsA("BasePart") then
									local function disappearAnim()
										local tween = Ts:Create(part, TweenInfo.new(2.5), {Transparency = 1})
										tween:Play()
										tween.Completed:Connect(function()
											part.CanCollide = false
										end)
									end
									local function unanchor()
										part.Anchored = false
									end
									if part == v.PrimaryPart then
										task.delay(0.6, unanchor)
									else
										unanchor()
									end
									task.delay(6, disappearAnim)
								end
							end
							
							task.wait(0.9)
							
							local randomHitSnd = HitSounds:GetChildren()[math.random(1, #HitSounds:GetChildren())]:Clone()
							randomHitSnd.Parent = Collider
							randomHitSnd:Play()
							game.Debris:AddItem(randomHitSnd, randomHitSnd.TimeLength + 1)
							game.Debris:AddItem(v, 10)
						end
					end
				end)
			end
		end
	end
end

FallFloors.ChildAdded:Connect(function(child)
	loadFallRocksFunc()
end)

KillPart.Touched:Connect(function(hit)
	if not hit or not hit.Parent then return end
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local Humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid") :: Humanoid
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player then
			Humanoid.Health = 0
		end
	end
end)

local function activeRocksCutscene()
	RocksBarrier.CanCollide = true
	rocksCutscenePlayed = true
	ActiveCutsceneEvent:FireAllClients("RocksFloor") -- Active rocks cutscene
	task.wait(2)
	TeleportModule:Teleport("RocksSafe", script, true)
	task.delay(20, function()
		ObjectivesModule.CompleteObjective(true, "Explore_Asylum")
	end)
end

RocksEndPart.Touched:Connect(function(hit)
	if not hit or not hit.Parent then return end
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		
		if player and not table.find(plrsInSafe, player.Name) and not rocksCutscenePlayed then
			local totalPlrsInGame = {}
			
			for i, v in game.Players:GetPlayers() do
				if v.PlayerValues.IsAlive.Value then
					table.insert(totalPlrsInGame, v.Name)
				end
			end
			
			if #plrsInSafe >= #totalPlrsInGame then
				activeRocksCutscene()
			else
				table.insert(plrsInSafe, player.Name)
			end
		elseif not rocksCutscenePlayed then
			local totalPlrsInGame = {}
			
			for i, v in game.Players:GetPlayers() do
				if v.PlayerValues.IsAlive.Value then
					table.insert(totalPlrsInGame, v.Name)
				end
			end
			
			if #plrsInSafe >= #totalPlrsInGame then
				activeRocksCutscene()
			end
		end
	end
end)

--//This is for the players that don't wait for others players
RocksEndPart2.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		local Humanoid = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		local Player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if Humanoid.Health > 0 and Player and not rocksCutscenePlayed then
			activeRocksCutscene()
		end
	end
end)

ActiveCutsceneEvent.OnServerEvent:Connect(function(plr, event)
	if event == "RocksFloor" then
		for i, v in BrokenFloors:GetDescendants() do
			if v:IsA("BasePart") then
				v.Anchored = false
				v.CanCollide = false -- Disable the CanCollide to don't lag the game
				local function disappearAnim()
					local tween = Ts:Create(v, TweenInfo.new(2.5), {Transparency = 1})
					tween:Play()
					tween.Completed:Connect(function()
						v.CanCollide = false
					end)
				end
				task.delay(6, disappearAnim)
				game.Debris:AddItem(v, 10)
			end
		end
		
		task.wait()
		
		for i, v in FallFloors:GetDescendants() do
			if v:IsA("BasePart") then
				v.Anchored = false
				v.CanCollide = false -- Disable the CanCollide to don't lag the game
				local function disappearAnim()
					local tween = Ts:Create(v, TweenInfo.new(2.5), {Transparency = 1})
					tween:Play()
					tween.Completed:Connect(function()
						v.CanCollide = false
					end)
				end
				task.delay(6, disappearAnim)
				game.Debris:AddItem(v, 10)
			end
		end
		
		local fallSound = FallingSound:Clone()
		fallSound.Parent = InteractStuff:FindFirstChild("RocksSoundPart")
		fallSound.Volume = 3
		fallSound.RollOffMaxDistance = 150
		fallSound:Play()
		game.Debris:AddItem(fallSound, fallSound.TimeLength + 1)
		
		task.wait(1)
		
		local randomHitSound = HitSounds:GetChildren()[math.random(1, #HitSounds:GetChildren())]:Clone()
		randomHitSound.Parent = InteractStuff:FindFirstChild("RocksSoundPart")
		randomHitSound.Volume = 2
		randomHitSound.RollOffMinDistance = 100
		randomHitSound.RollOffMaxDistance = 180
		randomHitSound:Play()
		game.Debris:AddItem(randomHitSound, randomHitSound.TimeLength + 1)
	end
end)

task.wait(3) -- Delay to don't bug

loadFallRocksFunc()