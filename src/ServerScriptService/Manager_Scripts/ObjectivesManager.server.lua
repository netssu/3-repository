--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local NewObjectiveEvent = Remotes:FindFirstChild("NewObjective")

--//Objectives Parts
local Map = workspace:FindFirstChild("Map")
local InteractParts = Map:FindFirstChild("InteractParts")
local ObjectivesParts = InteractParts:FindFirstChild("ObjectivesParts")
local NewObjectiveParts = {}
local EndObjectiveParts = {}

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local ObjectivesModule = require(ModulesFolder:FindFirstChild("ObjectivesModule"))

--[[Receive new objectives from client and fire to all clients (Client > Module > Server > Module)
A bit weird, but that's how it works.]]--
NewObjectiveEvent.OnServerEvent:Connect(function(Plr, Name: string, Title: string, Description: string)
	local alreadyExist = ObjectivesModule.CheckIfExist(Name)
	if alreadyExist then return end -- To don't duplicate some objetive
	ObjectivesModule.NewObjective(true, Name, Title, Description)
end)

task.wait(3) --Delay to don't bug

for i, v in ObjectivesParts:GetChildren() do
	if v:HasTag("StartObjective") then
		table.insert(NewObjectiveParts, v)
	elseif v:HasTag("EndObjective") then
		table.insert(EndObjectiveParts, v)
	end
end

for i, v: BasePart in ipairs(NewObjectiveParts) do
	local debounce = true
	
	--//Create a new objective
	v.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player and debounce then
				local ObjectiveFolder = v:FindFirstChildWhichIsA("Folder")
				
				if ObjectiveFolder then
					local ObjectiveTitle = ObjectiveFolder:FindFirstChild("Title")
					local ObjectiveDescription = ObjectiveFolder:FindFirstChild("Description")
					
					if ObjectiveTitle and ObjectiveDescription then
						debounce = false
						ObjectivesModule.NewObjective(true, ObjectiveFolder.Name, ObjectiveTitle.Value, ObjectiveDescription.Value)
					end
				end
			end
		end
	end)
end

for i, v: BasePart in ipairs(EndObjectiveParts) do
	local debounce = true
	
	--//End a existing objective
	v.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if player and debounce then
				local ObjectiveFolder = v:FindFirstChildWhichIsA("Folder")
				if ObjectiveFolder then
					local CompletingObjective = ObjectivesModule.CompleteObjective(true, ObjectiveFolder.Name)
					if CompletingObjective then --Returns true if completed the objective, false if doesn't exist
						debounce = false
					end
				end
			end
		end
	end)
end