--//Objective structure params example:
local ObjectivesModule = {
	["Name"] = "Key1Objective", -- Objective Identifier
	["Title"] = "Collect a metal Key", -- Objective display name
	["Description"] = "Explore the place and search for a metal key...", -- Objective description
}

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local NewObjectiveEvent = Remotes:FindFirstChild("NewObjective")

--//Objectives
local CurrentObjectives = Rs:WaitForChild("CurrentGameObjectives")

--//Function to create a new objective params (Global values, to be acessed by client)
local function CreateObjectiveParams(NameValue: string, Title: string, Description: string)
	local Objective = Instance.new("Folder", CurrentObjectives)
	Objective.Name = NameValue
	
	local ObjectiveTitle = Instance.new("StringValue", Objective)
	ObjectiveTitle.Name = "Title"
	ObjectiveTitle.Value = Title
	
	local ObjectiveDescription = Instance.new("StringValue", Objective)
	ObjectiveDescription.Name = "Description"
	ObjectiveDescription.Value = Description
end

-- Create a new objective for all players in game.
ObjectivesModule.NewObjective = function(OnServer: boolean, Name: string, Title: string, Description: string)
	if OnServer then
		if not Name or not Title or not Description then warn("Incorrect objective Params.") end
		CreateObjectiveParams(Name, Title, Description)
	else
		if not Name or not Title or not Description then warn("Incorrect objective Params.") end
		NewObjectiveEvent:FireServer(Name, Title, Description)
	end
end

-- Complete a objective for all players in game.
ObjectivesModule.CompleteObjective = function(OnServer: boolean, Name: string)
	--//When completing a objective, Title value is boolean
	if OnServer then
		local currentObjective = CurrentObjectives:FindFirstChild(Name)
		if currentObjective then
			currentObjective.Parent = CurrentObjectives:FindFirstChild("CompletedObjectives")
			return true
		else
			return false
		end
	else
		NewObjectiveEvent:FireServer(Name, true)
	end
end

-- Check if already exist a current objetive which the same name related
ObjectivesModule.CheckIfExist = function(Name: string)
	if CurrentObjectives:FindFirstChild(Name) then
		return true
	else
		return false
	end
end

return ObjectivesModule
