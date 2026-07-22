------------------//SERVICES
local ReplicatedStorage: ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players: Players = game:GetService("Players")

------------------//VARIABLES
local Remotes: Folder = ReplicatedStorage:WaitForChild("Remotes")
local AddItemEvent: RemoteEvent = Remotes:WaitForChild("AddItem")
local RemoveItemEvent: RemoteEvent = Remotes:WaitForChild("RemoveItem")
local ItemWarnEvent: RemoteEvent = Remotes:WaitForChild("ItemWarn")
local DeleteItemEvent: RemoteEvent = Remotes:WaitForChild("DeleteItem")

local ToolsFolder: Folder = ReplicatedStorage:WaitForChild("Items"):WaitForChild("Tools")
local ItemsRoot: Instance = ToolsFolder.Parent

local ItemsDisplay: BillboardGui? = script:FindFirstChild("ItemsDisplay") :: BillboardGui?
local SecureSearch = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SecureSearch"))

------------------//MAIN FUNCTIONS
local inventory = {
	MaxItems = 12,
	MaxAmount = 2,
	MaxEquipped = 5,
	HoverInteraction = true,
	InteractTransparency = 0.5,
	DisplayImportantItems = true,
}

------------------//FUNCTIONS
local function is_inventory_item_value(inst: Instance): boolean
	if not inst:IsA("IntValue") then
		return false
	end
	if inst:GetAttribute("IsInventoryItem") == true then
		return true
	end
	if ItemsRoot:FindFirstChild(inst.Name) then
		return true
	end
	return false
end

local function create_item(itemName: string, player: Player): ()
	local inventoryFolder: Folder = player:WaitForChild("Inventory") :: Folder

	local newItem: IntValue = Instance.new("IntValue")
	newItem.Name = itemName
	newItem.Value = 1
	newItem:SetAttribute("IsInventoryItem", true)
	newItem.Parent = inventoryFolder
end

local function get_inventory_count(inventoryFolder: Folder): number
	local count = 0
	for _, inst in inventoryFolder:GetChildren() do
		if is_inventory_item_value(inst) then
			count += 1
		end
	end
	return count
end

local function item_display(player: Player, itemName: string, remove: boolean?): ()
	if not itemName then
		return
	end
	if not inventory.DisplayImportantItems then
		return
	end

	local character: Model? = player.Character
	if not character then
		return
	end

	local itemInst: Instance? = ItemsRoot:FindFirstChild(itemName)
	if not itemInst then
		return
	end
	if not itemInst:FindFirstChild("IMPORTANT") then
		return
	end

	local module = SecureSearch:GetInstanceType(itemInst, "ModuleScript")
	local head = SecureSearch:GetInstance(character, "Head")
	if not module or not head then
		return
	end

	local ok, itemConfig = pcall(require, module)
	if not ok or type(itemConfig) ~= "table" then
		return
	end

	local itemIcon = itemConfig.Image
	if type(itemIcon) ~= "string" then
		return
	end

	local billBoard = SecureSearch:GetInstance(head, "ItemsDisplay") :: BillboardGui?
	if not remove then
		if billBoard then
			billBoard.PlayerToHideFrom = player
			local itemImage = billBoard:FindFirstChild(itemName)
			if itemImage then
				local amount = itemImage:FindFirstChild("amount") :: IntValue?
				local textAmount = itemImage:FindFirstChild("TextAmount") :: TextLabel?
				if amount and textAmount then
					amount.Value += 1
					textAmount.Text = "x" .. tostring(amount.Value)
				end
			else
				local example = billBoard:FindFirstChild("ImageExample")
				if not example then
					return
				end

				local clone = example:Clone()
				local amount = clone:FindFirstChild("amount") :: IntValue?
				local textAmount = clone:FindFirstChild("TextAmount") :: TextLabel?
				local image = clone :: ImageLabel?

				if amount and textAmount and image then
					image.Image = itemIcon
					clone.Visible = true
					amount.Value = 1
					textAmount.Text = "x" .. tostring(amount.Value)
					clone.Name = itemName
					clone.Parent = billBoard
				end
			end
		else
			if not ItemsDisplay then
				return
			end

			local display = ItemsDisplay:Clone()
			display.PlayerToHideFrom = player

			local example = display:FindFirstChild("ImageExample")
			if not example then
				display:Destroy()
				return
			end

			local clone = example:Clone()
			local amount = clone:FindFirstChild("amount") :: IntValue?
			local textAmount = clone:FindFirstChild("TextAmount") :: TextLabel?
			local image = clone :: ImageLabel?

			if amount and textAmount and image then
				image.Image = itemIcon
				clone.Visible = true
				amount.Value = 1
				textAmount.Text = "x" .. tostring(amount.Value)
				clone.Name = itemName
				clone.Parent = display
				display.Parent = head
			else
				display:Destroy()
			end
		end
	else
		if not billBoard then
			return
		end

		local itemImage = billBoard:FindFirstChild(itemName)
		if not itemImage then
			return
		end

		local amount = itemImage:FindFirstChild("amount") :: IntValue?
		local textAmount = itemImage:FindFirstChild("TextAmount") :: TextLabel?
		if not amount or not textAmount then
			return
		end

		if amount.Value > 1 then
			amount.Value -= 1
			textAmount.Text = "x" .. tostring(amount.Value)
		else
			itemImage:Destroy()
		end
	end
end

local function check_hotbar(player: Player, itemName: string): (number, boolean)
	local hotbarCount, alreadyOnHotbar = 0, false

	local function check_container(container: Instance): ()
		for _, v in container:GetChildren() do
			if v:IsA("Tool") then
				hotbarCount += 1
				if v.Name == itemName then
					alreadyOnHotbar = true
				end
			end
		end
	end

	check_container(player.Backpack)

	local character = player.Character
	if character then
		check_container(character)
	end

	return hotbarCount, alreadyOnHotbar
end

------------------//MAIN FUNCTIONS
inventory.AddItem = function(player: Player, item: Instance | string, justAdd: boolean): boolean
	local inventoryFolder: Folder = player:WaitForChild("Inventory") :: Folder
	local itemValue: IntValue? = nil
	local itemName = typeof(item) == "string" and item or item.Name :: string
	
	for _, child in inventoryFolder:GetChildren() do
		if is_inventory_item_value(child) and child.Name == itemName then
			local v = child :: IntValue
			if v:GetAttribute("IsInventoryItem") ~= true then
				v:SetAttribute("IsInventoryItem", true)
			end
			if v.Value < inventory.MaxAmount then
				itemValue = v
				break
			end
		end
	end
	
	local hotbarCount, alreadyOnHotbar = check_hotbar(player, itemName)
	
	local function equip_item(): ()
		if hotbarCount >= inventory.MaxEquipped then
			return
		end
		if alreadyOnHotbar then
			return
		end
		
		local toolItem = ToolsFolder:FindFirstChild(itemName)
		if not toolItem then
			return
		end

		local toolClone = toolItem:Clone()
		toolClone.Parent = player.Backpack
	end
	
	if itemValue then
		AddItemEvent:FireClient(player, itemName) --item
		if not justAdd then
			ItemWarnEvent:FireClient(player, "+1 " .. itemName)
		end
		itemValue.Value += 1
		equip_item()
		item_display(player, item.Name, false)
		return true
	end

	if get_inventory_count(inventoryFolder) < inventory.MaxItems then
		AddItemEvent:FireClient(player, item)
		if not justAdd then
			ItemWarnEvent:FireClient(player, "+1 " .. itemName)
		end
		create_item(itemName, player)
		equip_item()
		item_display(player, itemName, false)
		return true
	end

	if not justAdd then
		ItemWarnEvent:FireClient(player, "Inventory is full!")
	end
	return false
end

inventory.RemoveItem = function(player: Player, itemName: string): boolean
	local inventoryFolder = player:FindFirstChild("Inventory") :: Folder?
	if not inventoryFolder then
		return false
	end

	local itemValue = inventoryFolder:FindFirstChild(itemName) :: IntValue?
	if not itemValue then
		return false
	end

	local removed = false

	local character = player.Character
	if character then
		local tool = character:FindFirstChild(itemName)
		if tool and tool:IsA("Tool") then
			tool:Destroy()
			removed = true
		end
	end

	if not removed then
		local toolInBackpack = player.Backpack:FindFirstChild(itemName)
		if toolInBackpack and toolInBackpack:IsA("Tool") then
			toolInBackpack:Destroy()
		end
	end

	if itemValue.Value > 1 then
		item_display(player, itemName, true)
		ItemWarnEvent:FireClient(player, "-1 " .. itemName)
		itemValue.Value -= 1
	else
		item_display(player, itemName, true)
		ItemWarnEvent:FireClient(player, "-1 " .. itemName)
		itemValue:Destroy()
		DeleteItemEvent:FireClient(player, itemName)
	end

	return true
end

inventory.DeleteItem = function(itemName: string): ()
	for _, player in Players:GetPlayers() do
		local inventoryFolder: Folder = player:WaitForChild("Inventory") :: Folder
		local itemValue = inventoryFolder:FindFirstChild(itemName) :: IntValue?

		local character = player.Character
		if character then
			local itemTool = character:FindFirstChild(itemName)
			if itemTool and itemTool:IsA("Tool") then
				itemTool:Destroy()
			end
		end

		local itemBackpack = player.Backpack:FindFirstChild(itemName)
		if itemBackpack and itemBackpack:IsA("Tool") then
			itemBackpack:Destroy()
		end

		if itemValue then
			item_display(player, itemName, true)
			ItemWarnEvent:FireClient(player, "-1 " .. itemName)
			itemValue:Destroy()
			DeleteItemEvent:FireClient(player, itemName)
		end
	end
end

inventory.UpdateValues = function(value: string, newValue: any): ()
	if inventory[value] ~= nil then
		inventory[value] = newValue
	else
		warn("Can't find value:", value)
	end
end

------------------//INIT
return inventory
