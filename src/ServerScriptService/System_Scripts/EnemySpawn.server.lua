--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Map Stuff
local Map = workspace:FindFirstChild("Map")
local Area2_Reception = Map:FindFirstChild("Area2_AsylumReception")
local NPCsFolder_Reception = Area2_Reception:FindFirstChild("NPCs")
local SpawnParts_Reception = NPCsFolder_Reception:FindFirstChild("SpawnParts")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Values
local minPlrDist = 30
local maxTries = 100 -- If reach maxTries, the system will stop spawning enemies

local function spawnEnemies(EnemyToSpawn: Folder, SpawnPartsFolder: Folder, FolderToGo: Folder, SpawnTimes: number)
	local spawnedSpots = {}
	local ignoreSpots = {}
	local currentTries = 0
	
	for i=1, SpawnTimes do
		task.wait(0.3) -- To don't lag
		
		local posToGo = SpawnPartsFolder:GetChildren()[math.random(1, #SpawnPartsFolder:GetChildren())]
		
		local function checkCloserPlrs(part: BasePart)
			for i, plr in game.Players:GetPlayers() do
				if plr.Character and plr.Character:FindFirstChild("HumanoidRootPart") then
					if (plr.Character:FindFirstChild("HumanoidRootPart").Position - part.Position).Magnitude <= minPlrDist then
						ignoreSpots[part] = true
					end
				end
			end
		end
		
		checkCloserPlrs(posToGo)
		
		local function spawnEnemy()
			local randomNum = math.random()
			local spawnFactor = GameConfigModule.EnemiesSpawnFactor
			
			if GameConfigModule.GameMode == "Hard" then
				spawnFactor += 5
			elseif GameConfigModule.GameMode == "Nightmare" then
				spawnFactor += 10
			end
			
			if randomNum <= spawnFactor/100 then
				local enemy = EnemyToSpawn:GetChildren()[math.random(1, #EnemyToSpawn:GetChildren())]:Clone() --EnemyToSpawn:Clone()
				enemy.Parent = FolderToGo
				enemy.PrimaryPart:PivotTo(posToGo.CFrame)
				spawnedSpots[posToGo] = true
			end
		end
		
		local function findNewSpawn()
			if ignoreSpots[posToGo] then
				repeat task.wait()
					currentTries += 1
					posToGo = SpawnPartsFolder:GetChildren()[math.random(1, #SpawnPartsFolder:GetChildren())]
				until not ignoreSpots[posToGo] and not spawnedSpots[posToGo] or currentTries >= maxTries
				
				checkCloserPlrs(posToGo)
				
				if ignoreSpots[posToGo] or spawnedSpots[posToGo] then
					if currentTries < maxTries then
						findNewSpawn()
					end
				else
					spawnEnemy()
				end
			else
				spawnEnemy()
			end
		end
		
		findNewSpawn()
	end
	--print("Ignored spots:", ignoreSpots, "spawned amount:", spawnedSpots)
end

task.wait(10) -- Time before spawn the enemies

local CrazyPatient = Rs:FindFirstChild("Monsters"):FindFirstChild("Enemies"):FindFirstChild("Crazy_Patient")

spawnEnemies(CrazyPatient, SpawnParts_Reception, NPCsFolder_Reception, 100)