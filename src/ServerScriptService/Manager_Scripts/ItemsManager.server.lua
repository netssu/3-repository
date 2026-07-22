--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

--//Main
local Map = workspace:FindFirstChild("Map")
local ItemsFolder = Map:FindFirstChild("Items")
local ToolsFolder = Rs:FindFirstChild("Items"):FindFirstChild("Tools")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local AddItemEvent = Remotes:FindFirstChild("AddItem")
local EquipItemEvent = Remotes:FindFirstChild("EquipItem")
local UnequipItemEvent = Remotes:FindFirstChild("UnequipItem")
local DropItemEvent = Remotes:FindFirstChild("DropItem")
local UseItemEvent = Remotes:FindFirstChild("UseItem")

--//Values
local itemEffect = Rs:FindFirstChild("VFX"):FindFirstChild("ItemEffect")
local items = {}

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))

-- Check if the player have any important item in his inventory.
local function checkImportantItems(Player: Player)
	if not Player then warn("No player received to check his inventory.") return end
	
	local Inventory = Player:FindFirstChild("Inventory")
	local PlayerItems = {}
	
	--//Get all items on player inventory
	for i, v in Inventory:GetChildren() do
		table.insert(PlayerItems, v.Name)
	end
	
	local ImportantItems = {}
	
	--//Check if any of the items the player have is important
	for i, item in ipairs(PlayerItems) do
		for i, v in Rs:FindFirstChild("Items"):GetChildren() do
			if v.Name == item then
				if v:FindFirstChildWhichIsA("CFrameValue") then
					table.insert(ImportantItems, v)
				end
			end
		end
	end
	
	--//Items on 'ImportantItems' table are the items on ReplicatedStorage
	for i, v in ipairs(ImportantItems) do
		local item = v:Clone()
		
		if not item.PrimaryPart then
			warn("Incorrect item model, no Primary part found on item: "..item.Name)
		end
		
		item.PrimaryPart.Anchored = true
		item.Parent = ItemsFolder
		item:SetPrimaryPartCFrame(v:FindFirstChildWhichIsA("CFrameValue").Value)
		item:AddTag("Item")
		print("Item returned to default pos: ", item.Name, ", Because the player "..Player.Name.." leaved from the game.")
	end
end

game.Players.PlayerAdded:Connect(function(Plr)
	local Inventory = Instance.new("Folder", Plr)
	Inventory.Name = "Inventory"
	
	local char = Plr.Character or Plr.CharacterAdded:Wait()
	local hum = char:WaitForChild("Humanoid") :: Humanoid
	local backPack = Plr:WaitForChild("Backpack")
	
	local function UnAnchorItemsFunc()
		char.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				for i, v in child:GetDescendants() do
					if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
						v.Anchored = false
					end
				end
			end
		end)
		
		backPack.ChildAdded:Connect(function(child)
			if child:IsA("Tool") then
				for i, v in child:GetDescendants() do
					if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
						v.Anchored = false
					end
				end
			end
		end)
	end
	
	local function UnAnchorInBackPack()
		for i, tool in backPack:GetChildren() do
			if tool:IsA("Tool") then
				for i, v in tool:GetDescendants() do
					if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
						v.Anchored = false
					end
				end
			end
		end
	end
	
	--//Here don't need to check if the player have any important items because when player dies already check it
	local function connectDiedFunc()
		hum.Died:Connect(function()
			char = Plr.CharacterAdded:Wait()
			hum = char:WaitForChild("Humanoid") :: Humanoid
			backPack = Plr:WaitForChild("Backpack")
			UnAnchorItemsFunc()
			UnAnchorInBackPack()
			connectDiedFunc()
		end)
	end
	
	connectDiedFunc()
	UnAnchorItemsFunc()
	UnAnchorInBackPack()
end)

--//If a player leave from the game with a important item on inventory, return the item to original position
game.Players.PlayerRemoving:Connect(function(Player)
	checkImportantItems(Player)
end)

--//Get all current items in game
for i, item in ItemsFolder:GetChildren() do
	if item:IsA("Model") then
		if item:HasTag("Item") and item.PrimaryPart then
			table.insert(items, item)
		end
	end
end

local function loadItemsFunc(oneItem: Model?)
	--//Creates a connection, so later can disconnect for optimization
	--[[local function HighLightAnim(HighLight: Highlight)
		return coroutine.wrap(function()
			while true do
				Ts:Create(HighLight, TweenInfo.new(1.4), {OutlineTransparency = 0.5}):Play()
				task.wait(1)
				Ts:Create(HighLight, TweenInfo.new(1.6), {OutlineTransparency = 1}):Play()
				task.wait(1.2)
			end
		end)()
	end]]
	
	if oneItem and oneItem.PrimaryPart and not oneItem:GetAttribute("Item_Setup") then
		local AnimConnection : RBXScriptConnection = nil
		local Prompt = Instance.new("ProximityPrompt", oneItem.PrimaryPart)
		local HighLight = Instance.new("Highlight", oneItem)
		local Taken = false
		HighLight.FillTransparency = 1
		HighLight.OutlineTransparency = 1
		HighLight.Adornee = oneItem
		HighLight.DepthMode = Enum.HighlightDepthMode.Occluded
		Prompt.MaxActivationDistance = GameConfigModule.InteractDistance
		Prompt.Style = Enum.ProximityPromptStyle.Custom
		Prompt.RequiresLineOfSight = true
		Prompt.ActionText = "Collect"
		Prompt.ObjectText = oneItem.Name
		itemEffect:Clone().Parent = oneItem.PrimaryPart
		--AnimConnection = HighLightAnim(HighLight)
		
		oneItem:SetAttribute("Item_Setup", true)
		
		Prompt.Triggered:Connect(function(Plr)
			if not Plr or not Plr.Character then return end
			
			local Char = Plr.Character
			local Hum = Char:WaitForChild("Humanoid") :: Humanoid
			
			if not Hum or Hum.Health <= 0 or Taken then return end
			
			local itemToAdd = InventoryModule.AddItem(Plr, oneItem)
			
			if oneItem.PrimaryPart:FindFirstChildWhichIsA("Sound") then
				oneItem.PrimaryPart:FindFirstChildWhichIsA("Sound"):Play()
			end
			
			if itemToAdd then
				Taken = true
				if (AnimConnection) then
					AnimConnection:Disconnect()
				end
				
				itemEffect.Enabled = false
				Prompt.Enabled = false
				
				for i, v: Instance in oneItem:GetDescendants() do
					if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
						v.Transparency = 1
						v.CanCollide = false
					elseif v:IsA("Decal") or v:IsA("Texture") then
						v.Transparency = 1
					elseif v:IsA("SurfaceGui") or v:IsA("BillboardGui") then
						v.Enabled = false
					elseif v:IsA("PointLight") or v:IsA("SpotLight") or v:IsA("SurfaceLight") then
						v.Enabled = false
					end
				end
				game.Debris:AddItem(oneItem, 0.5)
			end
		end)
		return
	end
	
	for i, item in pairs(items) do
		if item:GetAttribute("Item_Setup") then continue end
		item:SetAttribute("Item_Setup", true)
		
		local AnimConnection : RBXScriptConnection = nil
		local Prompt = Instance.new("ProximityPrompt", item.PrimaryPart)
		local HighLight = Instance.new("Highlight", item)
		local Taken = false
		HighLight.FillTransparency = 1
		HighLight.OutlineTransparency = 1
		HighLight.Adornee = item
		HighLight.DepthMode = Enum.HighlightDepthMode.Occluded
		Prompt.MaxActivationDistance = GameConfigModule.InteractDistance
		Prompt.Style = Enum.ProximityPromptStyle.Custom
		Prompt.RequiresLineOfSight = true
		Prompt.ActionText = "Collect"
		Prompt.ObjectText = item.Name
		itemEffect:Clone().Parent = item.PrimaryPart
		--AnimConnection = HighLightAnim(HighLight)
		
		Prompt.Triggered:Connect(function(Plr)
			if not Plr or not Plr.Character then return end
			
			local Hum = Plr.Character:FindFirstChild("Humanoid") :: Humanoid
			
			if not Hum or Hum.Health <= 0 or Taken then return end
			
			local itemToAdd = InventoryModule.AddItem(Plr, item)
			
			if item.PrimaryPart:FindFirstChildWhichIsA("Sound") then
				item.PrimaryPart:FindFirstChildWhichIsA("Sound"):Play()
			end
			
			if itemToAdd then
				Taken = true
				if (AnimConnection) then
					AnimConnection:Disconnect()
				end
				
				itemEffect.Enabled = false
				Prompt.Enabled = false
				
				for i, v in item:GetDescendants() do
					if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
						v.Transparency = 1
						v.CanCollide = false
					elseif v:IsA("Decal") or v:IsA("Texture") then
						v.Transparency = 1
					elseif v:IsA("SurfaceGui") then
						v.Enabled = false
					end
				end
				
				game.Debris:AddItem(item, 0.5)
			end
		end)
	end
end

AddItemEvent.OnServerEvent:Connect(function(plr, item)
	if item then
		InventoryModule.AddItem(plr, item, true)
	end
end)

DropItemEvent.OnServerEvent:Connect(function(plr, item: string, Dying: boolean)
	for i, v in pairs(plr.Character:GetChildren()) do
		if v:IsA("Tool") and v.Name == item and not Dying then
			InventoryModule.RemoveItem(plr, item)
			v:Destroy()
			
			local ITEM = Rs:FindFirstChild("Items"):FindFirstChild(item)
			local ItemConfig = require(ITEM:WaitForChild("Config"))
			
			if ItemConfig.CanBeDroped == false then return end
			
			if ITEM then
				local clone = ITEM:Clone() :: Model
				local LookVector = plr.Character.PrimaryPart.CFrame.LookVector * 1.15
				
				clone:PivotTo(plr.Character.PrimaryPart.CFrame + Vector3.new(LookVector.X, 0, LookVector.Z))
				clone:PivotTo(clone.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(90), 0))
				
				clone.PrimaryPart.CanCollide = true
				clone.PrimaryPart.CanQuery = false
				
				for _, v in clone:GetChildren() do
					if v:IsA("BasePart") then
						if v ~= clone.PrimaryPart then
							local weldConstraint = Instance.new("WeldConstraint")
							weldConstraint.Part0 = clone.PrimaryPart
							weldConstraint.Part1 = v
							weldConstraint.Parent = v
						end
						v.CanQuery = false
						v.Anchored = false
					end
				end
				
				clone.Parent = ItemsFolder
			end
		end
	end
	if Dying then
		local ITEM = Rs:FindFirstChild("Items"):FindFirstChild(item)
		local ItemConfig = require(ITEM:WaitForChild("Config"))
		local ImportantItem = false
		
		--//Remove the item from player inventory, but check if the item is Important
		if ITEM:FindFirstChildWhichIsA("CFrameValue") then
			local CFRAME = ITEM:FindFirstChildWhichIsA("CFrameValue").Value
			local clone = ITEM:Clone()
			clone:PivotTo(CFRAME)
			clone.PrimaryPart.CanCollide = true
			clone.PrimaryPart.Anchored = true
			clone.Parent = ItemsFolder
			ImportantItem = true
		end
		
		for i, v in pairs(plr.Backpack:GetChildren()) do
			v:Destroy()
		end
		
		InventoryModule.RemoveItem(plr, item) -- Remove the item from player inventory
		
		if ItemConfig.CanBeDroped == false then return end
		
		--//Drop the item on workspace
		if ITEM and not ImportantItem then
			if not plr.Character or not plr.Character.PrimaryPart then return end
			local clone = ITEM:Clone()
			local LookVector = plr.Character.PrimaryPart.CFrame.LookVector * 1.5
			
			clone.PrimaryPart:PivotTo(plr.Character.PrimaryPart.CFrame + Vector3.new(LookVector.X, 0, LookVector.Z))
			clone.PrimaryPart:PivotTo(clone.PrimaryPart.CFrame * CFrame.Angles(0, math.rad(90), 0))
			
			clone.PrimaryPart.CanCollide = true
			clone.PrimaryPart.Anchored = false
			clone.PrimaryPart.CanQuery = false
			
			for _, v in clone:GetChildren() do
				if v:IsA("BasePart") then
					if v ~= clone.PrimaryPart then
						local weldConstraint = Instance.new("WeldConstraint")
						weldConstraint.Part0 = clone.PrimaryPart
						weldConstraint.Part1 = v
						weldConstraint.Parent = v
					end
					v.CanQuery = false
					v.Anchored = false
				end
			end
			
			clone.Parent = ItemsFolder
		end
	end
end)

EquipItemEvent.OnServerEvent:Connect(function(plr, item: string, onHand: boolean)
	local ITEM = ToolsFolder:FindFirstChild(item)
	if ITEM then
		local tool = ITEM:Clone()
		local char = plr.Character or plr.CharacterAdded:Wait()
		
		for i, v in tool:GetDescendants() do
			if v:IsA("BasePart") or v:IsA("MeshPart") or v:IsA("UnionOperation") then
				v.Anchored = false
			end
		end
		
		if onHand then
			tool.Parent = char
		else
			tool.Parent = plr.Backpack
		end
	end
end)

UnequipItemEvent.OnServerEvent:Connect(function(plr, item: string)
	for i, v in pairs(plr.Character:GetChildren()) do
		if v:IsA("Tool") and v.Name == item then
			v:Destroy()
			break
		end
	end
	for i, v in pairs(plr.Backpack:GetChildren()) do
		if v:IsA("Tool") and v.Name == item then
			v:Destroy()
			break
		end
	end
end)

UseItemEvent.OnServerEvent:Connect(function(plr, item: string)
	local ITEM = Rs:FindFirstChild("Items"):FindFirstChild(item)
	if ITEM then
		InventoryModule.RemoveItem(plr, item)
		for i, v in pairs(plr.Character:GetChildren()) do
			if v:IsA("Tool") and v.Name == item then
				v:Destroy()
				break
			end
		end
		for i, v in pairs(plr.Backpack:GetChildren()) do
			if v:IsA("Tool") and v.Name == item then
				v:Destroy()
				break
			end
		end
	end
end)

--//Detect when a new item is created
ItemsFolder.ChildAdded:Connect(function(child)
	if child:IsA("Model") then
		if child:HasTag("Item") and child.PrimaryPart then
			loadItemsFunc(child)
		end
	end
end)

CollectionService:GetInstanceAddedSignal("Item"):Connect(loadItemsFunc)

loadItemsFunc()