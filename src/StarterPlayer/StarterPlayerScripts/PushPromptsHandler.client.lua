--//Player
local Plr = game.Players.LocalPlayer

local promptConn: RBXScriptConnection? = nil

local function onCharacterAdded(char: Model)
	local rootPart = char:WaitForChild("HumanoidRootPart")
	if promptConn then
		promptConn:Disconnect()
		promptConn = nil
	end

	local function removeOwnPushPrompt(instance: Instance)
		if instance:IsA("ProximityPrompt") then
			instance:Destroy()
		end
	end

	for _, child in rootPart:GetChildren() do
		removeOwnPushPrompt(child)
	end

	promptConn = rootPart.ChildAdded:Connect(removeOwnPushPrompt)
end

Plr.CharacterAdded:Connect(onCharacterAdded)

if Plr.Character then
	onCharacterAdded(Plr.Character)
end
