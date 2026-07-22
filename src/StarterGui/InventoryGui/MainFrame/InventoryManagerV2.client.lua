--// Services
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local Players = game:GetService("Players")

--// Player
local Player = Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Mouse = Player:GetMouse()
local Camera = workspace.CurrentCamera

--// Remotes
local Remotes =          ReplicatedStorage:WaitForChild("Remotes")
local addItemEvent     = Remotes:WaitForChild("AddItem")
local removeItemEvent  = Remotes:WaitForChild("RemoveItem")
local deleteItemEvent  = Remotes:WaitForChild("DeleteItem")
local itemWarnEvent    = Remotes:WaitForChild("ItemWarn")
local equipItemEvent   = Remotes:WaitForChild("EquipItem")
local unequipItemEvent = Remotes:WaitForChild("UnequipItem")
local dropItemEvent    = Remotes:WaitForChild("DropItem")
local useItemEvent     = Remotes:WaitForChild("UseItem")

--// Modules
local ModulesFolder     = ReplicatedStorage:WaitForChild("Modules")
local Packages = ReplicatedStorage:WaitForChild("Packages")
local InventoryModule   = require(ModulesFolder:WaitForChild("InventoryModule"))
local GameConfigModule  = require(ModulesFolder:WaitForChild("GameConfigModule"))
local SecureSearch      = require(ModulesFolder:WaitForChild("SecureSearch"))
local TopBarApp = require(Packages:WaitForChild("Icon"))

--// Items
local ItemsFolder  = ReplicatedStorage:WaitForChild("Items")
local ToolsFolder  = ItemsFolder:WaitForChild("Tools")

--// UI
local MainFrame         = script.Parent
local inventoryFrame    = MainFrame.InventoryFrame
local slotsFrame        = inventoryFrame.ScrollingFrame.SlotsFrame
local SLOT_EXAMPLE      = slotsFrame.Slot_Example
local notificationFrame = MainFrame.NotificationFrame
local WARNTEXT_EXAMPLE  = notificationFrame.WarnText_Example
local infoFrame         = MainFrame.InfoFrame
local MobileGui         = Player:WaitForChild("PlayerGui"):WaitForChild("MobileGui")
local InventoryButton   = MobileGui.MainFrame.InventoryButton
local DropItemButton    = MobileGui.MainFrame.DropButton

--// Sounds
local clickSound  = MainFrame.ClickSound
local selectSound = MainFrame.SelectSound
local openSound   = MainFrame.OpenSound
local closeSound  = MainFrame.CloseSound

--// Values
local invOpen      = MainFrame.InvOpen
local OnUse        = MainFrame.OnUse
local selectedItem = nil
local slotHover    = nil

--// Pre-set capacity from character config (if exists)
do
	local moduleConfig = SecureSearch:GetInstanceType(Char, "ModuleScript")
	if moduleConfig and moduleConfig:IsA("ModuleScript") then
		local charConfig = require(moduleConfig)
		if charConfig["InvCapacity"] then
			InventoryModule.UpdateValues("MaxItems", charConfig.InvCapacity)
		end
	end
end

SLOT_EXAMPLE.Parent = ReplicatedStorage
inventoryFrame.Visible = false
StarterGui:GetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)

--// Pre-set top bar button
local invButton = TopBarApp.new()
invButton:setImage(11713331505, "Deselected")
invButton:setImage(251346502, "Selected")
invButton:setImage(11713331505, "Viewing")

script.Destroying:Connect(function()
	invButton:destroy()
end)

--//Create inventory Slots
local function CreateEmptySlots()
	for _, child in ipairs(slotsFrame:GetChildren()) do
		if child:IsA("Frame") and child.Name:match("^Slot_") then
			child:Destroy()
		end
	end
	for i = 1, InventoryModule.MaxItems do
		local s = SLOT_EXAMPLE:Clone()
		s.Parent = slotsFrame
		s.Name = ("Slot_%d"):format(i)
		s.ImageLabel.Image = ""
		s.TextAmount.Visible = false
		s.Selectable = true
		s.Visible = true
	end
end
CreateEmptySlots()

--//Helpers funcs
local State = {}

function State:getEquippedCount()
	local c = 0
	for _, v in ipairs(Player.Backpack:GetChildren()) do
		if v:IsA("Tool") then c += 1 end
	end
	for _, v in ipairs(Char:GetChildren()) do
		if v:IsA("Tool") then c += 1 end
	end
	return c
end

function State:isItemEquipped(itemName: string)
	for _, v in ipairs(Char:GetChildren()) do
		if v:IsA("Tool") and v.Name == itemName then return true end
	end
	for _, v in ipairs(Player.Backpack:GetChildren()) do
		if v:IsA("Tool") and v.Name == itemName then return true end
	end
	return false
end

local function showText(text: string)
	if typeof(text) ~= "string" then return end
	local cl = WARNTEXT_EXAMPLE:Clone()
	cl.Parent = notificationFrame
	cl.Size = UDim2.new(0, 0, 0, 0)
	cl.Text = text
	cl.Visible = true
	selectSound:Play()
	TweenService:Create(cl, TweenInfo.new(0.4, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Size = WARNTEXT_EXAMPLE.Size, TextTransparency = 0}):Play()
	task.wait(1)
	TweenService:Create(cl, TweenInfo.new(0.25, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	game.Debris:AddItem(cl, 1)
end

local UI = {}

function UI:updateSlotCount(slot: Frame)
	if not slot then return end
	local occupied = slot.ItemValues.Ocuped.Value
	slot.TextAmount.Visible = occupied
	if occupied then
		slot.TextAmount.Text = "x" .. slot.ItemValues.ItemAmount.Value
	end
end

function UI:resetSlot(slot: Frame)
	slot.ItemValues.Ocuped.Value = false
	slot.ItemValues.ItemAmount.Value = 0
	slot.ItemValues.ItemName.Value = ""
	slot.ItemValues.ItemDesc.Value = ""
	slot.ImageLabel.Image = ""
	slot.OptionsFrame.Visible = false
	self:updateSlotCount(slot)
end

function UI:bindSlotInteractions(slot: Frame)
	slot.Clicker.MouseButton1Click:Connect(function()
		clickSound:Play()
		if not slot.ItemValues.Ocuped.Value then return end
		
		for _, other in ipairs(slotsFrame:GetChildren()) do
			if other:IsA("Frame") and other ~= slot then
				other.OptionsFrame.Visible = false
			end
		end
		
		local itemName = slot.ItemValues.ItemName.Value
		local item = ItemsFolder:FindFirstChild(itemName)
		if not item then return end
		
		local itemConfig = require(item:FindFirstChildWhichIsA("ModuleScript"))
		slot.OptionsFrame.UseButton.Visible   = not not itemConfig.CanUse
		slot.OptionsFrame.EquipButton.Visible = not not itemConfig.CanEquip
		slot.OptionsFrame.EquipButton.Text    = State:isItemEquipped(itemName) and "Unequip" or "Equip"
		
		slot.OptionsFrame.Visible = not slot.OptionsFrame.Visible
	end)
	
	--//Hover for item tips
	slot.MouseEnter:Connect(function()
		if slot.ItemValues.Ocuped.Value then
			slotHover = slot
		end
	end)
	slot.MouseLeave:Connect(function()
		if slotHover == slot then
			slotHover = nil
		end
	end)
	
	--//Use item main
	slot.OptionsFrame.UseButton.MouseButton1Click:Connect(function()
		clickSound:Play()
		if OnUse.Value then return end
		
		local itemName = slot.ItemValues.ItemName.Value
		local item = ItemsFolder:FindFirstChild(itemName)
		if not item then return end
		
		local itemConfig = require(item:FindFirstChildWhichIsA("ModuleScript"))
		if not itemConfig.CanUse then return end
		
		local UsingItem, errmsg = itemConfig.Use(Player)
		if UsingItem == "errmsg" then
			showText(errmsg)
			return
		end
		
		useItemEvent:FireServer(itemConfig.Name)
		UIController.ChangeInventoryVisibility(true)
		
		task.delay(0.25, function()
			UIController.Rebuild()
		end)
		slotHover = nil
	end)
	
	--//Equip/Unequip
	slot.OptionsFrame.EquipButton.MouseButton1Click:Connect(function()
		local itemName = slot.ItemValues.ItemName.Value
		local currentlyEquipped = State:isItemEquipped(itemName)
		
		if not currentlyEquipped then
			if State:getEquippedCount() >= InventoryModule.MaxEquipped then
				showText("Hotbar is Full!")
				return
			end
			
			local hasTool = ToolsFolder:FindFirstChild(itemName)
			if not hasTool then return end
			
			equipItemEvent:FireServer(itemName)
			
			local cfg = require(ItemsFolder[itemName]:FindFirstChildWhichIsA("ModuleScript"))
			if cfg.EquipSound and typeof(cfg.EquipSound) == "string" and cfg.EquipSound ~= "" then
				local s = Instance.new("Sound")
				s.SoundId = cfg.EquipSound
				s.Parent = slot
				s:Play()
				game.Debris:AddItem(s, 5)
			end
		else
			unequipItemEvent:FireServer(itemName)
		end
		
		task.delay(0.05, UIController.Rebuild)
	end)
end

-- Busca um slot vazio (simples)
function UI:findFirstFreeSlot()
	for _, v in ipairs(slotsFrame:GetChildren()) do
		if v:IsA("Frame") and not v.ItemValues.Ocuped.Value then
			return v
		end
	end
	return nil
end

UIController = {}

function UIController.ChangeInventoryVisibility(justClose: boolean?)
	if Player:WaitForChild("PlayerValues"):WaitForChild("OnCutscene").Value then return end
	
	if invOpen.Value or justClose then
		Mouse.Icon = GameConfigModule.DefaultMouseIcon
		invOpen.Value = false
		closeSound:Play()
		inventoryFrame.Visible = false
		UserInputService.MouseBehavior = Enum.MouseBehavior.LockCenter
		invButton:deselect()
		
		for _, s in ipairs(slotsFrame:GetChildren()) do
			if s:IsA("Frame") then
				s.OptionsFrame.Visible = false
			end
		end
	else
		Mouse.Icon = GameConfigModule.ChangingMouseIcon
		invOpen.Value = true
		openSound:Play()
		inventoryFrame.Visible = true
	end
end

--//Create inventory UI
function UIController.Rebuild()
	local plrInventory = Player:FindFirstChild("Inventory")
	if not plrInventory then return end
	
	CreateEmptySlots()
	
	local list = {}
	for _, v in ipairs(plrInventory:GetChildren()) do
		if v:IsA("IntValue") and v.Value > 0 then
			list[v.Name] = (list[v.Name] or 0) + v.Value
		end
	end
	
	for itemName, amount in pairs(list) do
		local itemModel = ItemsFolder:FindFirstChild(itemName)
		if itemModel then
			local cfg = require(itemModel:FindFirstChildWhichIsA("ModuleScript"))
			
			local left = amount
			while left > 0 do
				local slot = UI:findFirstFreeSlot()
				if not slot then break end
				
				local put = math.min(left, InventoryModule.MaxAmount)
				left -= put
				
				slot.ItemValues.ItemName.Value  = itemName
				slot.ItemValues.ItemDesc.Value  = cfg.Description or ""
				slot.ItemValues.ItemAmount.Value= put
				slot.ImageLabel.Image           = cfg.Image or ""
				slot.ItemValues.Ocuped.Value    = true
				UI:updateSlotCount(slot)
				UI:bindSlotInteractions(slot)
			end
		end
	end
end

--//Drop item in hand
local function DropCurrentItem()
	if invOpen.Value then return end
	if Hum.Health <= 0 then return end
	
	if not selectedItem then return end
	local itemModel = ItemsFolder:FindFirstChild(selectedItem)
	if not itemModel then return end
	
	local cfg = require(itemModel:FindFirstChildWhichIsA("ModuleScript"))
	if not cfg.CanBeDroped then
		showText("Cannot drop this item.")
		return
	end
	
	dropItemEvent:FireServer(selectedItem, false)
	UIController.Rebuild()
end

--=====================================================
--// Init | Events
--=====================================================

--//Wait for player data to load to start the inventory UI
repeat task.wait() until ReplicatedStorage.CanLoadChar.Value == true
task.wait(0.5)

local totalItems = 0
local totalEquipped = -1
local itemsAdded = {}
local addLater = {}

--//Sync inventory items
for _, v in ipairs(Player.Backpack:GetChildren()) do
	if v:IsA("Tool") then
		local item = ItemsFolder:FindFirstChild(v.Name)
		if item then
			addItemEvent:FireServer(item)
			totalItems += 1
			totalEquipped += 1
			
			if totalEquipped >= InventoryModule.MaxEquipped or itemsAdded[v.Name] then
				unequipItemEvent:FireServer(v.Name)
				if itemsAdded[v.Name] then
					totalEquipped -= 1
					table.insert(addLater, item)
				end
			end
			
			itemsAdded[v.Name] = true
		end
	end
end

itemsAdded = {}

for i, item in pairs(addLater) do
	if not itemsAdded[item.Name] then
		unequipItemEvent:FireServer(item.Name)
		equipItemEvent:FireServer(item.Name)
		itemsAdded[item.Name] = true
	end
end

--//Catch tools added to backpack that are not on inventory
Player.Backpack.ChildAdded:Connect(function(child)
	if not child:IsA("Tool") then return end
	local inventory = Player:FindFirstChild("Inventory")
	if not inventory then return end
	if not (inventory:FindFirstChild(child.Name) or Char:FindFirstChild(child.Name)) then
		local itemModel = ItemsFolder:FindFirstChild(child.Name)
		if itemModel then
			addItemEvent:FireServer(itemModel)
		end
	end
end)

--//Debugs messages
itemWarnEvent.OnClientEvent:Connect(function(msg)
	showText(msg)
end)

--//Update the UI when inventory changed
addItemEvent.OnClientEvent:Connect(function()
	UIController.Rebuild()
end)

removeItemEvent.OnClientEvent:Connect(function()
	UIController.Rebuild()
end)

deleteItemEvent.OnClientEvent:Connect(function()
	UIController.Rebuild()
end)

--//PC & Console//--
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	
	local function safeFind(stack: Instance, name: string)
		local ok, inst = pcall(function() return stack:FindFirstChild(name) end)
		return ok and inst or nil
	end
	
	local plrOptions = safeFind(Player, "GameOptions")
	local OpenInventory = plrOptions and safeFind(plrOptions, "OpenInventory") or nil
	local DropItemOpt   = plrOptions and safeFind(plrOptions, "DropItem") or nil
	
	local function pressed(opt)
		if not opt then return false end
		local pc = safeFind(opt, "PcButton1") or safeFind(opt, "PcButton2")
		local console = safeFind(opt, "ConsoleButton1") or safeFind(opt, "ConsoleButton2")
		local kpc = pc and pc.Value and Enum.KeyCode[pc.Value]
		local kcon= console and console.Value and Enum.KeyCode[console.Value]
		return input.KeyCode == kpc or input.KeyCode == kcon
	end
	
	if (OpenInventory and pressed(OpenInventory)) or input.KeyCode == Enum.KeyCode.R or input.KeyCode == Enum.KeyCode.ButtonY then
		UIController.ChangeInventoryVisibility(false)
	elseif (DropItemOpt and pressed(DropItemOpt)) or input.KeyCode == Enum.KeyCode.Q or input.KeyCode == Enum.KeyCode.DPadDown then
		DropCurrentItem()
	end
end)

--//MOBILE//--
InventoryButton.MouseButton1Click:Connect(function()
	UIController.ChangeInventoryVisibility()
end)
DropItemButton.MouseButton1Click:Connect(function()
	DropCurrentItem()
end)

--//GENERAL//--
invButton:bindEvent("selected", function()
	UIController.ChangeInventoryVisibility()
end)

invButton:bindEvent("deselected", function()
	if invOpen.Value then
		UIController.ChangeInventoryVisibility(false)
	end
end)

Char.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		selectedItem = child.Name
		DropItemButton.Visible = true
		
		if not UserInputService.TouchEnabled then
			MainFrame.DropHint.Visible = true
			if UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled then
				MainFrame.DropHint.Text = "Drop Item"
				MainFrame.DpadDownIcon.Visible = true
			elseif not UserInputService.GamepadEnabled and UserInputService.KeyboardEnabled then
				MainFrame.DropHint.Text = "Press [Q] to Drop Item"
			else
				MainFrame.DropHint.Text = "Press [Q] to Drop Item or"
				MainFrame.DpadDownIcon.Visible = true
			end
		end
	end
end)
Char.ChildRemoved:Connect(function(child)
	for _, v in ipairs(Char:GetChildren()) do
		if v:IsA("Tool") then
			return
		end
	end
	
	--//Disable console/Pc drop hint
	if not UserInputService.TouchEnabled then
		MainFrame.DropHint.Visible = false
		MainFrame.DpadDownIcon.Visible = false
	end
	
	--//Disable flashlight effects if enabled
	if child.Name == "Flashlight" then
		Camera.Flashlight.FrontPart.FrontLight.Enabled = false
		Camera.Flashlight.BackPart.BackLight.Enabled = false
	end
	
	local Animator = Hum:FindFirstChild("Animator")
	if Animator then
		for _, track in ipairs(Animator:GetPlayingAnimationTracks()) do
			if track:HasTag("itemAnim") then
				track:Stop()
			end
		end
	end
	
	selectedItem = nil
	DropItemButton.Visible = false
	
	--//Clear all preview models (for now we only have the cursed doll, but maybe some more in future)
	for _, v in ipairs(workspace:GetChildren()) do
		if v:GetAttribute("PreviewModel") then
			v:Destroy()
		end
	end
	
	UIController.Rebuild()
end)

--//Drop items when die
Hum.Died:Connect(function()
	local head = SecureSearch:GetInstance(Char, "Head")
	local bb = head and SecureSearch:GetInstance(head, "ItemsDisplay")
	if bb then bb:Destroy() end
	
	local toDrop = {}
	local inv = Player:FindFirstChild("Inventory")
	if inv then
		for _, v in ipairs(inv:GetChildren()) do
			if v:IsA("IntValue") and v.Value > 0 then
				for _ = 1, v.Value do
					table.insert(toDrop, v.Name)
				end
			end
		end
	end
	
	for _, name in ipairs(toDrop) do
		dropItemEvent:FireServer(name, true)
		task.wait()
	end
	
	UIController.Rebuild()
end)

--//Position the tool tip
RunService.RenderStepped:Connect(function()
	if invOpen.Value then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	else
		infoFrame.Visible = false
	end
	
	if slotHover and invOpen.Value and slotHover:FindFirstChild("ItemValues") then
		infoFrame.Visible = true
		infoFrame.Tittle.Text = slotHover.ItemValues.ItemName.Value
		infoFrame.Desc.Text   = slotHover.ItemValues.ItemDesc.Value
		
		TweenService:Create(infoFrame, TweenInfo.new(0.1), {BackgroundTransparency = 0}):Play()
		TweenService:Create(infoFrame.Tittle, TweenInfo.new(0.1), {BackgroundTransparency = 0, TextTransparency = 0}):Play()
		TweenService:Create(infoFrame.Desc, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	else
		TweenService:Create(infoFrame, TweenInfo.new(0.1), {BackgroundTransparency = 1}):Play()
		TweenService:Create(infoFrame.Tittle, TweenInfo.new(0.1), {BackgroundTransparency = 1, TextTransparency = 1}):Play()
		TweenService:Create(infoFrame.Desc, TweenInfo.new(0.1), {TextTransparency = 1}):Play()
	end
	
	infoFrame.Position = UDim2.fromOffset(Mouse.X, Mouse.Y + 30)
end)

UIController.Rebuild()
