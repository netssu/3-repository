--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Assets
local PatientEnemy = Rs:FindFirstChild("Monsters"):FindFirstChild("Enemies"):FindFirstChild("Crazy_Patient")

--//Map Stuff
local Map = workspace:FindFirstChild("Map")
local Area1 = Map:FindFirstChild("Area1_Entrance")
local InteractStuff = Area1:FindFirstChild("InteractStuff")
local NPCs_SpawnArea = InteractStuff:FindFirstChild("NPCs_SpawnArea")

local function spawnEnemies()
	local enemy = PatientEnemy:GetChildren()[math.random(1, #PatientEnemy:GetChildren())]:Clone()
	enemy.Parent = workspace
	
	local randomPosOnSpawnArea = NPCs_SpawnArea.Position + Vector3.new(math.random(-NPCs_SpawnArea.Size.X/2, NPCs_SpawnArea.Size.X/2), 0, math.random(-NPCs_SpawnArea.Size.Z/2, NPCs_SpawnArea.Size.Z/2))
	enemy.PrimaryPart:PivotTo(CFrame.new(randomPosOnSpawnArea))
end

local amountOfEnemies = math.random(2, 4)
for i=1, amountOfEnemies do
	spawnEnemies()
	task.wait(0.5)
end