--//Services
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local addItemEvent = Remotes:WaitForChild("AddItem")
local removeItemEvent = Remotes:WaitForChild("RemoveItem")
local deleteItemEvent = Remotes:WaitForChild("DeleteItem")
local itemWarnEvent = Remotes:WaitForChild("ItemWarn")
local equipItemEvent = Remotes:WaitForChild("EquipItem")
local unequipItemEvent = Remotes:WaitForChild("UnequipItem")
local dropItemEvent = Remotes:WaitForChild("DropItem")
local useItemEvent = Remotes:WaitForChild("UseItem")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local InventoryModule = require(ModulesFolder:WaitForChild("InventoryModule"))
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))
local SecureSearch = require(ModulesFolder:WaitForChild("SecureSearch"))

--//UI
local MainFrame = script.Parent
local inventoryFrame = MainFrame.InventoryFrame
local slotsFrame = inventoryFrame.ScrollingFrame.SlotsFrame
local SLOT_EXAMPLE = slotsFrame.Slot_Example
local notificationFrame = MainFrame.NotificationFrame
local WARNTEXT_EXAMPLE = notificationFrame.WarnText_Example
local infoFrame = MainFrame.InfoFrame
local MobileGui = game.Players.LocalPlayer:WaitForChild("PlayerGui"):WaitForChild("MobileGui")
local InventoryButton = MobileGui.MainFrame.InventoryButton
local DropItemButton = MobileGui.MainFrame.DropButton

--//Player
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

--//Sounds
local clickSound = MainFrame.ClickSound
local selectSound = MainFrame.SelectSound
local openSound = MainFrame.OpenSound
local closeSound = MainFrame.CloseSound

--//Values
local invOpen = MainFrame.InvOpen
local OnUse = MainFrame.OnUse
local selectedItem = nil
local slotHover = false
--local equipedSlot = nil
local changeItemsDebounce = true
local equipedItems = {}

--//Items
local ItemsFolder = Rs:WaitForChild("Items")
local ToolsFolder = ItemsFolder:WaitForChild("Tools")

--//Pre-set
local moduleConfig = SecureSearch:GetInstanceType(Char, "ModuleScript")
if moduleConfig and moduleConfig:IsA("ModuleScript") then
	local charConfig = require(moduleConfig)
	if charConfig["InvCapacity"] then
		InventoryModule.UpdateValues("MaxItems", charConfig.InvCapacity)
	end
end

SLOT_EXAMPLE.Parent = Rs
inventoryFrame.Visible = false
StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)
for i=1, InventoryModule.MaxItems do
	local newSlot = SLOT_EXAMPLE:Clone()
	newSlot.Parent = slotsFrame
	newSlot.Name = "Slot_"..i
	newSlot.ImageLabel.Image = ""
	newSlot.TextAmount.Visible = false
	newSlot.Selectable = true
end

local function showText(text: string)
	if typeof(text) == "string" then
		local cl = WARNTEXT_EXAMPLE:Clone()
		cl.Parent = notificationFrame
		cl.Size = UDim2.new(0, 0, 0, 0)
		cl.Text = text
		cl.Visible = true
		selectSound:Play()
		
		Ts:Create(cl, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = WARNTEXT_EXAMPLE.Size, TextTransparency = 0}):Play()
		task.wait(1)
		Ts:Create(cl, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
		game.Debris:AddItem(cl, 1)
	end
end

-- Check is can equip a new item.
local function equipItem(item: string)
	local Item = ToolsFolder:FindFirstChild(item)
	if Item then
		if #equipedItems < InventoryModule.MaxEquipped then
			equipItemEvent:FireServer(item)
			return true
		end
	end
	return false
end

local function unequipItem(item: string)
	for i, v in pairs(Player.Backpack:GetChildren()) do
		if v.Name == item then
			unequipItemEvent:FireServer(item)
			return true
		end
	end
	for i, v in pairs(Player.Character:GetChildren()) do
		if v:IsA("Tool") and v.Name == item then
			unequipItemEvent:FireServer(item)
			return true
		end
	end
	return false
end

local function updateUI(slot: Frame)
	if slot then
		if slot.ItemValues.Ocuped.Value then
			slot.TextAmount.Visible = true
			slot.TextAmount.Text = "x"..slot.ItemValues.ItemAmount.Value
		else
			slot.TextAmount.Visible = false
		end
	end
end

local function resetSlot(slot)
	if slot then
		slot.ItemValues.Ocuped.Value = false
		slot.ItemValues.ItemAmount.Value = 0
		slot.ItemValues.ItemName.Value = ""
		slot.ItemValues.ItemDesc.Value = ""
		slot.ImageLabel.Image = ""
	end
end

-- Change the inventory visible state.
local function changeInv(justClose: boolean)
	if Player:WaitForChild("PlayerValues"):WaitForChild("OnCutscene").Value then return end
	
	if invOpen.Value or justClose then
		Mouse.Icon = GameConfigModule.DefaultMouseIcon --Default mouse icon
		invOpen.Value = false
		closeSound:Play()
		inventoryFrame.Visible = false
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
		
		for i, otherslot in slotsFrame:GetChildren() do
			if otherslot:IsA("Frame") then
				otherslot.OptionsFrame.Visible = false
			end
		end
	else
		Mouse.Icon = GameConfigModule.ChangingMouseIcon --Inventory mouse icon
		invOpen.Value = true
		openSound:Play()
		inventoryFrame.Visible = true
	end
end

local function getCurrentItemsEquiped()
	local amount = 0
	for i, v in Player.Backpack:GetChildren() do
		if v:IsA("Tool") then
			amount += 1
		end
	end
	for i, v in Player.Character:GetChildren() do
		if v:IsA("Tool") then
			amount += 1
		end
	end
	return amount
end

local function loadSlotFunc()
	for i, slot in slotsFrame:GetChildren() do
		if slot:IsA("Frame") then
			slot.Clicker.MouseButton1Click:Connect(function()
				clickSound:Play()
				if slot.ItemValues.Ocuped.Value then
					slot.OptionsFrame.Visible = not slot.OptionsFrame.Visible
					local item = ItemsFolder[slot.ItemValues.ItemName.Value]
					local onTable = false
					
					--//Make options of another slots invisble if any
					if slot.OptionsFrame.Visible then
						for i, otherslot in slotsFrame:GetChildren() do
							if otherslot:IsA("Frame") then
								if otherslot ~= slot then
									otherslot.OptionsFrame.Visible = false
								end
							end
						end
					end
					
					if item then
						local itemConfig = require(item:FindFirstChildWhichIsA("ModuleScript"))
						if itemConfig.CanUse then
							slot.OptionsFrame.UseButton.Visible = true
						else
							slot.OptionsFrame.UseButton.Visible = false
						end
						if itemConfig.CanEquip then
							slot.OptionsFrame.EquipButton.Visible = true
						else
							slot.OptionsFrame.EquipButton.Visible = false
						end
						
						--//Detect if the item is already equiped
						for i, v in pairs(equipedItems) do
							if v == itemConfig.Name then
								onTable = true
							end
						end
						--//Check for possible items that are equipeds, but not on table
						for i, v in Player.Character:GetChildren() do
							if v.Name == itemConfig.Name and not onTable then
								onTable = true
								table.insert(equipedItems, v.Name)
								break
							end
						end
						for i, v in Player.Backpack:GetChildren() do
							if v.Name == itemConfig.Name and not onTable then
								onTable = true
								table.insert(equipedItems, v.Name)
								break
							end
						end
						
						if onTable then
							slot.OptionsFrame.EquipButton.Text = "Unequip"
						else
							slot.OptionsFrame.EquipButton.Text = "Equip"
						end
					end
				end
			end)
			slot.MouseEnter:Connect(function()
				if slot.ItemValues.Ocuped.Value then
					slotHover = slot
				end
			end)
			slot.MouseLeave:Connect(function()
				if slot.ItemValues.Ocuped.Value then
					slotHover = nil
				end
			end)
			slot.OptionsFrame.UseButton.MouseButton1Click:Connect(function()
				clickSound:Play()
				local item = ItemsFolder[slot.ItemValues.ItemName.Value]
				if item and not OnUse.Value then --verificar se está olhando o relógio/notepad
					local itemConfig = require(item:FindFirstChildWhichIsA("ModuleScript"))
					if itemConfig.CanUse then
						local UsingItem, errmsg = itemConfig.Use(Player)
						
						if UsingItem == "errmsg" then --Return error if can't use the item
							showText(errmsg) --Show the error message
							return
						end
						
						useItemEvent:FireServer(itemConfig.Name)
						changeInv(true)
						
						if slot.ItemValues.ItemAmount.Value <= 1 then
							resetSlot(slot)
							for i, v in pairs(equipedItems) do
								if v == slot.ItemValues.ItemName.Value then
									table.remove(equipedItems, i)
								end
							end
						else
							slot.ItemValues.ItemAmount.Value -= 1
							for i, v in pairs(equipedItems) do
								if v == slot.ItemValues.ItemName.Value then
									table.remove(equipedItems, i)
								end
							end
						end
						
						updateUI(slot)
						slotHover = nil
						slot.OptionsFrame.Visible = false
					end
				end
			end)
			slot.OptionsFrame.EquipButton.MouseButton1Click:Connect(function()
				if slot.OptionsFrame.EquipButton.Text == "Equip" then
					local currentItems = getCurrentItemsEquiped()
					if currentItems > InventoryModule.MaxEquipped then showText("Hotbar is Full!") return end
					if not changeItemsDebounce then return end
					changeItemsDebounce = false
					
					local alreadyEquiped = false
					local onEquipedTable = 0
					
					--//Check for duplicated items on equipedItems table
					for i, v in pairs(equipedItems) do
						if v == slot.ItemValues.ItemName.Value then
							alreadyEquiped = true
							onEquipedTable += 1 -- Check if there a clone of this item o equiped table
						end
					end
					--//Check for duplicated items on Player Char
					for i, v in pairs(Char:GetChildren()) do
						if v:IsA("Tool") then
							if v.Name == slot.ItemValues.ItemName.Value then
								alreadyEquiped = true
							end
						end
					end
					--//Check for duplicated items on Player Backpack
					for i, v in pairs(Player.Backpack:GetChildren()) do
						if v:IsA("Tool") then
							if v.Name == slot.ItemValues.ItemName.Value then
								alreadyEquiped = true
							end
						end
					end
					
					if alreadyEquiped then
						if onEquipedTable > 1 then
							table.remove(equipedItems, onEquipedTable) --Remove the item from the table
						end
						
						if #equipedItems > InventoryModule.MaxEquipped then --Remove the first item that was equiped
							local firstEquipedItem = 0
							for i, v in pairs(equipedItems) do
								firstEquipedItem = i
								break
							end
							table.remove(equipedItems, firstEquipedItem)
						end
						
						slot.OptionsFrame.EquipButton.Text = "Unequip"
						task.wait(0.1)
						changeItemsDebounce = true
						return
					end
					
					local itemEquip = equipItem(slot.ItemValues.ItemName.Value)
					local itemConfig = require(ItemsFolder[slot.ItemValues.ItemName.Value]:FindFirstChildWhichIsA("ModuleScript"))
					local sound = Instance.new("Sound", slot)
					sound.SoundId = itemConfig.EquipSound
					sound:Play()
					
					if itemEquip then
						slot.OptionsFrame.EquipButton.Text = "Unequip"
						table.insert(equipedItems, slot.ItemValues.ItemName.Value)
						--equipedSlot = slot
					else
						showText("Hotbar is full!")
					end
					game.Debris:AddItem(sound, 5)
					task.wait(0.1)
					changeItemsDebounce = true
				else
					local itemUnequip = unequipItem(slot.ItemValues.ItemName.Value)
					
					if itemUnequip then
						slot.OptionsFrame.EquipButton.Text = "Equip"
						for i, v in pairs(equipedItems) do
							if v == slot.ItemValues.ItemName.Value then
								table.remove(equipedItems, i)
							end
						end
					else
						slot.OptionsFrame.EquipButton.Text = "Equip"
						showText("Cannot unequip this item.")
						
						--//Check if theres a clone of this item on equipedItems table, if find, remove the item.
						if #equipedItems > 0 then
							for i, v in pairs(equipedItems) do
								if v == slot.ItemValues.ItemName.Value then
									table.remove(equipedItems, i)
								end
							end
						end
					end
					--equipedSlot = nil
				end
			end)
		end
	end
end

local function getFreeSlot(item, onlyFreeSlot: boolean)
	if not item then return end
	local slot = nil
	local slotsWithSameItem = {}
	
	if onlyFreeSlot then
		for i, v in slotsFrame:GetChildren() do
			if v:IsA("Frame") then
				if not v.ItemValues.Ocuped.Value then
					slot = v
					break
				end
			end
		end
		return slot
	end
	
	for i, v in slotsFrame:GetChildren() do
		if v:IsA("Frame") then
			if v.ItemValues.Ocuped.Value and item.Name == v.ItemValues.ItemName.Value and v.ItemValues.ItemAmount.Value < InventoryModule.MaxAmount then
				table.insert(slotsWithSameItem, v)
			end
		end
	end
	
	for i, slot in pairs(slotsWithSameItem) do
		if slot.ItemValues.ItemAmount.Value < InventoryModule.MaxAmount then
			slot.ItemValues.ItemAmount.Value += 1
			updateUI(slot)
			return "added"
		end
	end
	
	for i, v in slotsFrame:GetChildren() do
		if v:IsA("Frame") then
			if not v.ItemValues.Ocuped.Value and item.Name ~= v.ItemValues.ItemName.Value then
				slot = v
				break
			end
		end
	end
	return slot
end

local function updateInvSlots()
	local plrInventory = Player:WaitForChild("Inventory")
	if plrInventory then
		for i, v in slotsFrame:GetChildren() do
			if v:IsA("Frame") then
				v:Destroy()
			end
		end
		for i=1, InventoryModule.MaxItems do
			local newSlot = SLOT_EXAMPLE:Clone()
			newSlot.Parent = slotsFrame
			newSlot.Visible = true
			newSlot.Name = "Slot_"..i
			newSlot.ImageLabel.Image = ""
			newSlot.TextAmount.Visible = false
			newSlot.Selectable = true
		end
		for i, item in plrInventory:GetChildren() do
			local itemName = item.Name
			local itemAmount = item.Value
			local slot = getFreeSlot(itemName, true)
			
			if slot then
				local itemConfig = require(ItemsFolder[itemName]:FindFirstChildWhichIsA("ModuleScript"))
				
				slot.ItemValues.ItemName.Value = itemName
				slot.ItemValues.ItemDesc.Value = itemConfig.Description
				slot.ItemValues.ItemAmount.Value = itemAmount
				slot.ImageLabel.Image = itemConfig.Image
				slot.ItemValues.Ocuped.Value = true
				slot.TextAmount.Visible = true
				slot.TextAmount.Text = "x"..tostring(slot.ItemValues.ItemAmount.Value)
			end
		end
	end
	loadSlotFunc()
end

local function getItemSlot(Item: string)
	local itemsSlot = {}
	local itemSelected = nil
	
	--//Get all items of the same type on inventory
	for i, v in slotsFrame:GetChildren() do
		if v:IsA("Frame") then
			if v.ItemValues.ItemName.Value == Item then
				table.insert(itemsSlot, v)
			end
		end
	end
	
	--//Get the item with the lowest amount
	for i, v in pairs(itemsSlot) do
		if not itemSelected then
			itemSelected = v
		end
		if v.ItemValues.ItemAmount.Value < itemSelected.ItemValues.ItemAmount.Value then
			itemSelected = v
		end
	end
	return itemSelected
end

local function dropItem(item, dying)
	if item then
		if dying then
			dropItemEvent:FireServer(item, dying)
			return true
		end
		local itemOnHand = Char:FindFirstChild(item)
		if itemOnHand then
			dropItemEvent:FireServer(item, false)
			return true
		end
	end
	return false
end

addItemEvent.OnClientEvent:Connect(function(item)
	if item then
		local ITEM = ItemsFolder[item.Name]
		local Slot = getFreeSlot(item)
		local itemConfig = require(ITEM:FindFirstChildWhichIsA("ModuleScript"))
		
		if Slot == "added" then return end
		
		if Slot then
			Slot.ItemValues.Ocuped.Value = true
			Slot.ItemValues.ItemAmount.Value = 1
			Slot.ItemValues.ItemName.Value = itemConfig.Name
			Slot.ItemValues.ItemDesc.Value = itemConfig.Description
			Slot.ImageLabel.Image = itemConfig.Image
			updateUI(Slot)
		end
	end
end)

removeItemEvent.OnClientEvent:Connect(function(item)
	if item then
		updateInvSlots()
		--[[local slot = getItemSlot(item)
		if slot then
			if slot.ItemValues.ItemAmount.Value <= 1 then
				slot.ItemValues.Ocuped.Value = false
				slot.ItemValues.ItemAmount.Value = 0
				slot.ItemValues.ItemName.Value = ""
				slot.ItemValues.ItemDesc.Value = ""
				slot.ImageLabel.Image = ""
			else
				slot.ItemValues.ItemAmount.Value -= 1
			end
			for i, v in pairs(equipedItems) do
				if v == item then
					table.remove(equipedItems, i)
					if v == selectedItem then
						selectedItem = nil
					end
					break
				end
			end
			updateUI(slot)
		end]]
	end
end)

deleteItemEvent.OnClientEvent:Connect(function(item)
	if item then
		updateInvSlots()
		--[[local slot = getItemSlot(item)
		if slot then
			slot.ItemValues.Ocuped.Value = false
			slot.ItemValues.ItemAmount.Value = 0
			slot.ItemValues.ItemName.Value = ""
			slot.ItemValues.ItemDesc.Value = ""
			slot.ImageLabel.Image = ""
			updateUI(slot)
			for i, v in pairs(equipedItems) do
				if v == item then
					table.remove(equipedItems, i)
					if v == selectedItem then
						selectedItem = nil
					end
					break
				end
			end
		end]]
	end
end)

repeat task.wait()
until Rs.CanLoadChar.Value == true
task.wait(1)

--//Put in inventory items that are in Player Backpack / Starterpack
for i, v in Player.Backpack:GetChildren() do
	if v:IsA("Tool") then
		local item = ItemsFolder:FindFirstChild(v.Name)
		if item then
			addItemEvent:FireServer(item)
		end
	end
	task.wait()
end

--//Add items that are on player backpack/character to inventory layout if don't loaded correctly
Player.Backpack.ChildAdded:Connect(function(child)
	local inventory = Player:WaitForChild("Inventory")
	if inventory then
		local item = inventory:FindFirstChild(child.Name) or Char:FindFirstChild(child.Name)
		if not item then
			addItemEvent:FireServer(item)
		end
	end
end)

--//Show debug messages send by the server
itemWarnEvent.OnClientEvent:Connect(function(event)
	showText(event)
end)

local function DropCurrentItem()
	if not invOpen.Value and Hum.Health > 0 then
		
		if not selectedItem then return end
		
		local itemModel = ItemsFolder:FindFirstChild(selectedItem)
		
		if not itemModel then return end
		
		local itemConfig = require(itemModel:FindFirstChildWhichIsA("ModuleScript"))
		
		if not itemConfig.CanBeDroped then showText("Cannot drop this item.") return end
		
		local itemDrop = dropItem(selectedItem)
		updateInvSlots()
		
		if itemDrop then
			--if equipedSlot then
			--	print(equipedSlot)
			--	if equipedSlot.ItemValues.ItemAmount.Value <= 1 then
			--		resetSlot(equipedSlot)
			--		print("reseted slot: ", equipedSlot)
			--	else
			--		equipedSlot.ItemValues.ItemAmount.Value -= 1
			--	end
			
			--	for i, v in pairs(equipedItems) do
			--		if v == selectedItem then
			--			table.remove(equipedItems, i)
			--		end
			--	end
			
			--	equipedSlot.OptionsFrame.EquipButton.Text = "Equip"
			--	updateUI(equipedSlot)
			--	slotHover = nil
			--	selectedItem = nil
			--	equipedSlot = nil
			--	return
			--end
			
			--[[local itemSlot = getItemSlot(itemDrop)
			if itemSlot then
				print("droping item: ", itemSlot.ItemValues.ItemName.Value)
				if itemSlot.ItemValues.ItemAmount.Value <= 1 then
					resetSlot(itemSlot)
				else
					itemSlot.ItemValues.ItemAmount.Value -= 1
				end
				for i, v in pairs(equipedItems) do
					if v == selectedItem then
						table.remove(equipedItems, i)
					end
				end
				itemSlot.OptionsFrame.EquipButton.Text = "Equip"
				updateUI(itemSlot)
				slotHover = nil
				selectedItem = nil
			end]]
			
			--[[for i, slot in slotsFrame:GetChildren() do
				if slot:IsA("Frame") then
					if slot.ItemValues.ItemName.Value == selectedItem then
						print("droping item: ", slot.ItemValues.ItemName.Value)
						if slot.ItemValues.ItemAmount.Value <= 1 then
							resetSlot(slot)
						else
							slot.ItemValues.ItemAmount.Value -= 1
						end
						
						for i, v in pairs(equipedItems) do
							if v == selectedItem then
								table.remove(equipedItems, i)
							end
						end
						
						slot.OptionsFrame.EquipButton.Text = "Equip"
						updateUI(slot)
						slotHover = nil
						selectedItem = nil
						--equipedSlot = nil
						break
					end
				end
			end]]
		end
	end
end

--//PC & Console
UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	
	local function getInstance(stack: Instance, needle: string)
		if not stack or not needle then return end
		local success, keycode = pcall(function()
			return stack:FindFirstChild(needle)
		end)
		if success then
			return keycode
		else
			warn("Can find instance:", needle, " on stack:", stack)
		end
		return nil
	end
	
	local plrOptions = getInstance(Player, "GameOptions")
	local OpenInventory = nil
	local DropItem = nil
	local buttonConsole1 = nil
	local buttonPc1 = nil
	local buttonConsole2 = nil
	local buttonPc2 = nil
	
	if plrOptions then
		OpenInventory = getInstance(plrOptions, "OpenInventory")
		DropItem = getInstance(plrOptions, "DropItem")
		if OpenInventory then
			buttonPc1 = getInstance(OpenInventory, "PcButton1")
			buttonConsole1 = getInstance(OpenInventory, "ConsoleButton1")
		end
		if DropItem then
			buttonPc2 = getInstance(DropItem, "PcButton2")
			buttonConsole2 = getInstance(DropItem, "ConsoleButton2")
		end
	end
	
	if buttonConsole1 and buttonPc1 and buttonConsole2 and buttonPc2 then
		if input.KeyCode == Enum.KeyCode[buttonPc1.Value] or input.KeyCode == Enum.KeyCode[buttonConsole1.Value] then
			changeInv() -- Open/Close Inventory
		elseif input.KeyCode == Enum.KeyCode[buttonPc2.Value] or input.KeyCode == Enum.KeyCode[buttonConsole2.Value] then
			DropCurrentItem() -- Drop current holding item if any
			return
		end
	else
		--//Will check for the default KeyCodes if don't find the Player Options
		if input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
			changeInv() -- Open/Close Inventory
		elseif input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.DPadDown then
			DropCurrentItem() -- Drop current holding item if any
			return
		end
	end
end)

--//Mobile
InventoryButton.MouseButton1Click:Connect(function()
	changeInv()
end)

DropItemButton.MouseButton1Click:Connect(function()
	DropCurrentItem()
end)

Char.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		selectedItem = child.Name
		DropItemButton.Visible = true
	end
end)

Char.ChildRemoved:Connect(function(child)
	--//Detect if there an equiped item, before changing the values to default
	for i, v in pairs(Char:GetChildren()) do
		if v:IsA("Tool") then
			return
		end
	end
	if child.Name == "Flashlight" then
		Camera.Flashlight.FrontPart.FrontLight.Enabled = false
		Camera.Flashlight.BackPart.BackLight.Enabled = false
	end
	
	local Animator = Hum:WaitForChild("Animator") :: Animator
	for i, v: AnimationTrack in Animator:GetPlayingAnimationTracks() do
		if v:HasTag("itemAnim") then
			v:Stop()
		end
	end
	
	selectedItem = nil
	DropItemButton.Visible = false
	
	--//Destrou preview models of tools on workspace
	for _, v in workspace:GetChildren() do
		if v:GetAttribute("PreviewModel") then
			v:Destroy()
		end
	end
end)

Hum.Died:Connect(function()
	local itemsToDrop = {}
	local head = SecureSearch:GetInstance(Char, "Head")
	local billBoard = nil
	
	if head then
		billBoard = SecureSearch:GetInstance(head, "ItemsDisplay")
	end
	
	if billBoard then
		billBoard:Destroy()
	end
	
	for i, v in slotsFrame:GetChildren() do
		if v:IsA("Frame") then
			if v.ItemValues.Ocuped.Value then
				for i=1, v.ItemValues.ItemAmount.Value do
					table.insert(itemsToDrop, v.ItemValues.ItemName.Value)
				end
			end
		end
	end
	
	for i, item in pairs(itemsToDrop) do
		local itemDrop = dropItem(item, true)
		if itemDrop then
			for i, slot in slotsFrame:GetChildren() do
				if slot:IsA("Frame") then
					if slot.ItemValues.ItemName.Value == item then
						if slot.ItemValues.ItemAmount.Value > 1 then
							slot.ItemValues.ItemAmount.Value -= 1
						else
							resetSlot(slot)
						end
						updateUI(slot)
						for i, v in pairs(equipedItems) do
							if v.Name == selectedItem then
								table.remove(equipedItems, i)
							end
						end
					end
				end
			end
		end
	end
end)

Mouse.Move:Connect(function()
	if invOpen.Value then
		for i, slot in slotsFrame:GetChildren() do
			if slot:IsA("Frame") then
				if Mouse.X >= slot.AbsolutePosition.X and Mouse.X <= slot.AbsolutePosition.X + slot.AbsoluteSize.X then
					if Mouse.Y >= slot.AbsolutePosition.Y and Mouse.Y <= slot.AbsolutePosition.Y + slot.AbsoluteSize.Y then
						if slot.ItemValues.Ocuped.Value then
							slotHover = slot
						else
							slotHover = nil
						end
					end
				end
			end
		end
	end
end)

RunService.RenderStepped:Connect(function(dt: number)
	if invOpen.Value then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
	else
		infoFrame.Visible = false
	end
	if slotHover and invOpen.Value then
		infoFrame.Visible = true
		infoFrame.Tittle.Text = slotHover.ItemValues.ItemName.Value
		infoFrame.Desc.Text = slotHover.ItemValues.ItemDesc.Value
		Ts:Create(infoFrame, TweenInfo.new(0.1), {BackgroundTransparency = 0, }):Play()
		Ts:Create(infoFrame.Tittle, TweenInfo.new(0.1), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
		Ts:Create(infoFrame.Desc, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	else
		Ts:Create(infoFrame, TweenInfo.new(0.1), {BackgroundTransparency = 1, }):Play()
		Ts:Create(infoFrame.Tittle, TweenInfo.new(0.1), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		Ts:Create(infoFrame.Desc, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
	end
	infoFrame.Position = UDim2.fromOffset(Mouse.X, Mouse.Y + 30)
end)

loadSlotFunc()