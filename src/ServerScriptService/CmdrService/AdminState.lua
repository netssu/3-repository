local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Inventory = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("InventoryModule"))
local Items = ReplicatedStorage:WaitForChild("Items")
local Tools = Items:WaitForChild("Tools")

local AdminState = {}

local function applyNoclip(character: Model, enabled: boolean)
	for _, instance in character:GetDescendants() do
		if instance:IsA("BasePart") then
			if enabled then
				if instance:GetAttribute("CmdrOriginalCanCollide") == nil then
					instance:SetAttribute("CmdrOriginalCanCollide", instance.CanCollide)
				end
				instance.CanCollide = false
			else
				local original = instance:GetAttribute("CmdrOriginalCanCollide")
				if typeof(original) == "boolean" then
					instance.CanCollide = original
					instance:SetAttribute("CmdrOriginalCanCollide", nil)
				end
			end
		end
	end
end

function AdminState.applyCharacterState(player: Player, character: Model)
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		local lastHealth = humanoid.Health
		humanoid.HealthChanged:Connect(function(health)
			if player:GetAttribute("CmdrGodMode") and health < lastHealth then
				humanoid.Health = math.max(lastHealth, humanoid.MaxHealth)
				return
			end
			lastHealth = health
		end)
	end

	applyNoclip(character, player:GetAttribute("CmdrNoclip") == true)
	character.DescendantAdded:Connect(function(instance)
		if player:GetAttribute("CmdrNoclip") and instance:IsA("BasePart") then
			if instance:GetAttribute("CmdrOriginalCanCollide") == nil then
				instance:SetAttribute("CmdrOriginalCanCollide", instance.CanCollide)
			end
			instance.CanCollide = false
		end
	end)
end

function AdminState.setGodMode(player: Player, enabled: boolean)
	player:SetAttribute("CmdrGodMode", enabled)
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if enabled and humanoid then
		humanoid.Health = humanoid.MaxHealth
	end
end

function AdminState.setNoclip(player: Player, enabled: boolean)
	player:SetAttribute("CmdrNoclip", enabled)
	if player.Character then
		applyNoclip(player.Character, enabled)
	end
end

function AdminState.giveItem(player: Player, itemName: string): boolean | string
	local item = Tools:FindFirstChild(itemName) or Items:FindFirstChild(itemName)
	if not item then
		return "Item not found: " .. itemName
	end

	if Inventory.AddItem(player, item, false) then
		return true
	end
	return "Could not give item; the inventory may be full."
end

return AdminState
