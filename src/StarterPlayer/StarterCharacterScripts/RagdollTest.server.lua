repeat wait() until script.Parent:IsA("Model")

local char = script.Parent
local R15 = require(script:WaitForChild("R15"))
local plr = game:GetService("Players"):GetPlayerFromCharacter(char)
local hum = char:WaitForChild("Humanoid")
local autoLoads = game:GetService("Players").CharacterAutoLoads

local function setNetworkOwner()
	for i, bp in pairs(char:GetChildren()) do
		if bp:IsA("BasePart") and bp:CanSetNetworkOwnership() then
			bp:SetNetworkOwner(plr)
		end
	end
end

hum.Died:Connect(function()
	R15(char)
	setNetworkOwner()
	if autoLoads == true then
		delay(3, function()
			plr:LoadCharacter()
		end)
	end
end)