--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local ContentPrivider = game:GetService("ContentProvider")
local MarketPlaceService = game:GetService("MarketplaceService")

--//Player
local Player = game.Players.LocalPlayer

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdateTitleFunc = Remotes:WaitForChild("UpdateTitle")
local UpdateEmoteFunc = Remotes:WaitForChild("UpdateEmote")
local UpdatePassEvent = Remotes:WaitForChild("UpdatePass")
local UpdatePerkFunc = Remotes:WaitForChild("UpdatePerk")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))
local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))

--//Sounds
local SoundsFolder = script.Parent:FindFirstChild("Sounds")
local ClickSound = SoundsFolder:FindFirstChild("ClickSound")
local InteractSound = SoundsFolder:FindFirstChild("InteractSound")

--//UI
local MainFrame = script.Parent
local EmotePreviewFrame = MainFrame.EmotePreviewFrame
local InventoryFrame = MainFrame.InventoryFrame
local TitlesInvFrame = InventoryFrame.TitlesInvFrame
local EmotesInvFrame = InventoryFrame.EmotesInvFrame
local PassesInvFrame = InventoryFrame.PassesInvFrame
local PerksInvFrame = InventoryFrame.PerksInvFrame
local OptionsFrame = InventoryFrame.OptionsFrame.Frame
local EquipEmoteFrame = InventoryFrame.EmotesEquipFrame

local TitlesExample_Frame = TitlesInvFrame:FindFirstChild("TitleItemFrame_Example")
local PassesExample_Frame = PassesInvFrame:FindFirstChild("PassItemFrame_Example")
local EmotesExample_Frame = EmotesInvFrame:FindFirstChild("EmoteItemFrame_Example")
local PerksExample_Frame = PerksInvFrame:FindFirstChild("PerksItemFrame_Example")

--//Values
local currentEmoteToEquip = nil
local rigEmoteAnimator = EmotePreviewFrame:FindFirstChild("Animator", true) :: Animator
local emotePreviewAnim = nil
local emoteAnimPlay = nil
local emoteAnimConnection = nil
local rigIdleAnim = EmotePreviewFrame.ViewportFrame.WorldModel.RigAnimator.IdleAnim
local animIdle = nil

--//Setup
TitlesExample_Frame.Parent = Rs
PassesExample_Frame.Parent = Rs
EmotesExample_Frame.Parent = Rs
PerksExample_Frame.Parent = Rs
pcall(function()
	animIdle = rigEmoteAnimator:LoadAnimation(rigIdleAnim)
	if animIdle then
		animIdle.Looped = true
		animIdle:Play()
		animIdle:AddTag("IDLE")
	end
end)

InventoryFrame:GetPropertyChangedSignal("Position"):Connect(function()
	EquipEmoteFrame.Visible = false
	EmotePreviewFrame.Visible = false
	currentEmoteToEquip = nil
	if emotePreviewAnim then
		emotePreviewAnim:Destroy()
	end
	if emoteAnimPlay then
		emoteAnimPlay:Destroy()
	end
	if emoteAnimConnection then
		coroutine.close(emoteAnimConnection)
	end
end)

local function changeFrame(frame: Frame)
	if not frame then warn("No frame received.", script:GetFullName()) return end
	for i, v in InventoryFrame:GetChildren() do
		if v:IsA("ScrollingFrame") then
			if v ~= frame then
				v.Visible = false
			end
		end
	end
	frame.Visible = true
end

--//Change sections buttons anim
local function unselectAll(ignore: Frame)
	for i, v in OptionsFrame:GetChildren() do
		if v:IsA("Frame") then
			if v ~= ignore then
				Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(0.15, 0.631)}):Play()
			else
				Ts:Create(v, TweenInfo.new(0.2), {Size = UDim2.fromScale(0.25, 0.867)}):Play()
			end
		end
	end
end

OptionsFrame.Skins_Option.Clicker.MouseButton1Click:Connect(function()
	unselectAll(OptionsFrame.Skins_Option)
	changeFrame(TitlesInvFrame)
end)

OptionsFrame.Passes_Option.Clicker.MouseButton1Click:Connect(function()
	unselectAll(OptionsFrame.Passes_Option)
	changeFrame(PassesInvFrame)
end)

OptionsFrame.Emotes_Option.Clicker.MouseButton1Click:Connect(function()
	unselectAll(OptionsFrame.Emotes_Option)
	changeFrame(EmotesInvFrame)
end)

OptionsFrame.Perks_Option.Clicker.MouseButton1Click:Connect(function()
	unselectAll(OptionsFrame.Perks_Option)
	changeFrame(PerksInvFrame)
end)

EquipEmoteFrame.CancelButton.MouseButton1Click:Connect(function()
	ClickSound:Play()
	EquipEmoteFrame.Visible = false
	currentEmoteToEquip = nil
end)

EquipEmoteFrame.CancelButton.MouseEnter:Connect(function()
	InteractSound:Play()
end)

--//UI Animations
for i, v in OptionsFrame:GetChildren() do
	if v:IsA("Frame") then
		local Clicker = v:FindFirstChild("Clicker") :: TextButton
		local ItemText = v:FindFirstChild("TextLabel") :: TextLabel
		local DefaultTextColor = ItemText.TextColor3
		Clicker.MouseEnter:Connect(function()
			InteractSound:Play()
			Ts:Create(ItemText, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(116, 248, 255)}):Play()
		end)
		Clicker.MouseLeave:Connect(function()
			Ts:Create(ItemText, TweenInfo.new(0.15), {TextColor3 = DefaultTextColor}):Play()
		end)
		Clicker.MouseButton1Click:Connect(function()
			ClickSound:Play()
		end)
	end
end

local function updateEquippedEmotes()
	local plrOtherValues = Player:WaitForChild("OtherValues")
	local plrEquipedEmotes = nil
	
	if plrOtherValues then
		plrEquipedEmotes = plrOtherValues:WaitForChild("EquipedEmotes")
	end
	if not plrEquipedEmotes then return end
	
	for i, v in pairs(plrEquipedEmotes:GetChildren()) do
		local emoteName = v.Value
		local emoteIcon = ""
		for _, v in ipairs(ShopModule.Items.Emotes) do
			if v.Name == emoteName then
				emoteIcon = v.Img
				break
			end
		end
		for _, posButton in EquipEmoteFrame.PosList_Frame:GetChildren() do
			if posButton:IsA("TextButton") then
				if posButton.posText.Text == v.Name then
					posButton.EmoteIcon.Image = "rbxassetid://"..emoteIcon
					posButton.EmoteName.Text = emoteName
					posButton.EquipedEmote.Value = emoteName
					break
				else
					continue
				end
			end
		end
	end
end

--//Equip emote buttons
for i, button in EquipEmoteFrame.PosList_Frame:GetChildren() do
	if button:IsA("TextButton") then
		button.MouseButton1Click:Connect(function()
			ClickSound:Play()
			if currentEmoteToEquip ~= nil then
				local emoteIcon = ""
				local posToGo = button.posText.Text
				local oldEmote = button.EquipedEmote.Value
				
				for _, v in ipairs(ShopModule.Items.Emotes) do
					if v.Name == currentEmoteToEquip then
						emoteIcon = v.Img
						break
					end
				end
				
				local equipped = UpdateEmoteFunc:InvokeServer(currentEmoteToEquip, posToGo)
				if equipped then
					button.EmoteName.Text = currentEmoteToEquip
					button.EmoteIcon.Image = "rbxassetid://"..emoteIcon
					button.EquipedEmote.Value = currentEmoteToEquip
				end
				
				--//Update emotes items list
				for _, v in ipairs(EmotesInvFrame:GetChildren()) do
					if v:IsA("Frame") then
						if v.Name == currentEmoteToEquip.."_Emote" then
							v.EquipButton.PriceText.Text = "Equipped"
						elseif v.Name == oldEmote.."_Emote" then
							v.EquipButton.PriceText.Text = "Equip"
						end
					end
				end
				
				updateEquippedEmotes()
				
				currentEmoteToEquip = nil
				task.wait(0.38)
				EquipEmoteFrame.Visible = false
			end
		end)
		button.MouseEnter:Connect(function()
			InteractSound:Play()
		end)
	end
end

local function equipTitle(titleName: string)
	local equipped = UpdateTitleFunc:InvokeServer(titleName)
	if equipped then
		return true
	end
	return false
end

local function createEmoteItem(ItemName: string)
	local newItem = EmotesExample_Frame:Clone()
	newItem.Name = ItemName.."_Emote"
	newItem.ItemName.Text = ItemName.." Emote"
	newItem.Visible = true
	newItem.Parent = EmotesInvFrame
	
	local icon = ""
	local emoteId = ""
	
	for _, v in ipairs(ShopModule.Items.Emotes) do
		if v.Name == ItemName then
			icon = v.Img
			emoteId = v.AnimId
			break
		end
	end
	
	newItem.ItemIcon.Image = "rbxassetid://"..icon
	
	local plrEquipedEmotes = Player:WaitForChild("OtherValues"):WaitForChild("EquipedEmotes")
	for i, emote in plrEquipedEmotes:GetChildren() do
		if emote.Value == ItemName then
			newItem.EquipButton.PriceText.Text = "Equipped"
		end
	end
	
	newItem.EquipButton.MouseButton1Click:Connect(function()
		ClickSound:Play()
		currentEmoteToEquip = ItemName
		EquipEmoteFrame.Visible = true
	end)
	newItem.EquipButton.MouseEnter:Connect(function()
		InteractSound:Play()
	end)
	newItem.PreviewButton.MouseButton1Click:Connect(function()
		if emotePreviewAnim then
			emotePreviewAnim:Destroy()
		end
		if emoteAnimPlay then
			emoteAnimPlay:Destroy()
		end
		if emoteAnimConnection then
			coroutine.close(emoteAnimConnection)
		end
		
		emotePreviewAnim = Instance.new("Animation")
		emotePreviewAnim.AnimationId = "rbxassetid://"..emoteId
		
		for _, v in rigEmoteAnimator:GetPlayingAnimationTracks() do
			if not v:HasTag("IDLE") then
				v:Stop()
			end
		end
		
		emoteAnimPlay = rigEmoteAnimator:LoadAnimation(emotePreviewAnim)
		emoteAnimPlay.Priority = Enum.AnimationPriority.Action2
		
		emoteAnimConnection = coroutine.create(function()
			while true do
				emoteAnimPlay:Play()
				emoteAnimPlay.Stopped:Wait()
				if animIdle and not animIdle.IsPlaying then
					animIdle:Play()
				end
				task.wait(math.random(100, 200)/100)
			end
		end)
		coroutine.resume(emoteAnimConnection)
		
		EmotePreviewFrame.Visible = true
		EmotePreviewFrame.EmoteNameText.Text = ItemName
		EmotePreviewFrame.EmotePriceText.Text = ""
	end)
end

local function createTitleItem(ItemName: string)
	local plrEquipedTitle = Player:WaitForChild("OtherValues"):WaitForChild("EquipedTitle")
	local newItem = TitlesExample_Frame:Clone()
	local titleStyle = nil
	
	--print("Creating title item: ", ItemName)
	
	for _, v in ipairs(ShopModule.Items.Titles) do
		if v.Name == ItemName then
			titleStyle = v.TextStyle:Clone()
			break
		end
	end
	
	newItem.Name = ItemName.."_Title"
	newItem.ItemName.Text = ItemName.. " Title"
	newItem.Visible = true
	newItem.TitleName.Visible = false
	newItem.Parent = TitlesInvFrame
	
	if titleStyle then
		titleStyle.Parent = newItem
		titleStyle.Size = newItem.TitleName.Size
		titleStyle.Position = newItem.TitleName.Position
	end
	
	--//Check if the item is equipped
	if plrEquipedTitle then
		if plrEquipedTitle.Value == ItemName then
			newItem.EquipButton.PriceText.Text = "Equipped"
		end
	end
	
	newItem.EquipButton.MouseButton1Click:Connect(function()
		ClickSound:Play()
		if newItem.EquipButton.PriceText.Text == "Equip" then
			newItem.EquipButton.PriceText.Text = "Equipped"
			equipTitle(ItemName)
			for _, v in TitlesInvFrame:GetChildren() do
				if v:IsA("Frame") and v ~= newItem then
					v.EquipButton.PriceText.Text = "Equip"
				end
			end
		end
	end)
	newItem.EquipButton.MouseEnter:Connect(function()
		InteractSound:Play()
	end)
end

local function createPassItem(ItemName: string, Icon: string)
	if PassesInvFrame:FindFirstChild(ItemName.."_Pass") then return end
	
	local newItem = PassesExample_Frame:Clone()
	newItem.Name = ItemName.."_Pass"
	newItem.ItemName.Text = ItemName
	newItem.Visible = true
	newItem.Parent = PassesInvFrame
	newItem.EquipButton.PriceText.Text = "Owned"
	newItem.ItemIcon.Image = "rbxassetid://"..Icon
end

--//Update passes list when the player buy a new Game pass
UpdatePassEvent.Event:Connect(function(passId: number)
	local passInfo = MarketPlaceService:GetProductInfo(passId, Enum.InfoType.GamePass)
	local passName = passInfo.Name
	local passIcon = passInfo.IconImageAssetId
	createPassItem(passName, passIcon)
end)

local function createPerkItem(ItemName: string, Icon: string, Desc: string, Amount: number, equipedPerks)
	if PerksInvFrame:FindFirstChild(ItemName.."_Perk") then -- already exists
		return
	end
	
	local itemPerk = PerksExample_Frame:Clone()
	itemPerk.Name = ItemName.."_Perk"
	itemPerk.ItemName.Text = ItemName
	itemPerk.Visible = true
	itemPerk.Parent = PerksInvFrame
	itemPerk.EquipButton.PriceText.Text = "Equip"
	itemPerk.ItemIcon.Image = Icon
	itemPerk.ItemAmount.Text = "x"..tostring(Amount)
	itemPerk.Desc.Value = tostring(Desc)
	itemPerk.Amount.Value = Amount
	
	local perkEquipped = false
	
	local function changeDisplayState(state: boolean)
		if state then -- equip the perk
			itemPerk.EquipButton.PriceText.Text = "Unequip"
			--change color to red
		else -- unequip the perk
			itemPerk.EquipButton.PriceText.Text = "Equip"
			--change color to blue again
		end
	end
	
	--Check if the perk is equipped
	if equipedPerks and equipedPerks[ItemName] then
		perkEquipped = true
		changeDisplayState(true)
	end
	
	itemPerk.EquipButton.MouseButton1Click:Connect(function()
		ClickSound:Play()
		perkEquipped = UpdatePerkFunc:InvokeServer("change", ItemName, perkEquipped)
		if typeof(perkEquipped) ~= "boolean" then return end -- action failed to execute
		changeDisplayState(perkEquipped)
	end)
	
	itemPerk.EquipButton.MouseEnter:Connect(function()
		InteractSound:Play()
	end)
	
	itemPerk.Clicker.MouseButton1Click:Connect(function()
		ClickSound:Play()
		--TODO: display info frame about the perk
	end)
end

local function createItem(Item: Instance?)
	if not Item then return end
	
	if Item:IsA("StringValue") then
		if Item.Value == "Titles" then
			createTitleItem(Item.Name)
		elseif Item.Value == "Emotes" then
			createEmoteItem(Item.Name)
		end
	end
end

local function setupItemPerks()
	--//Perk Items
	local profileData = DataHandler:GetProfileData(Player)
	if not profileData then return end
	
	local OwnedPerks = profileData.OwnedPerks
	local EquipedPerks = profileData.EquipedPerks
	
	for _, perkItem in pairs(ShopModule.Perks) do
		local perkAmount = OwnedPerks[perkItem.Name]
		if perkAmount then
			local perkFrame = PerksInvFrame:FindFirstChild(perkItem.Name.."_Perk")
			if perkFrame then -- update amount UI if perk already exists
				if perkFrame:FindFirstChild("Amount") then
					perkFrame.Amount.Value = perkAmount
				end
				if perkFrame:FindFirstChild("ItemAmount") then
					perkFrame.ItemAmount.Text = "x"..tostring(perkAmount)
				end
				continue
			end
			createPerkItem(perkItem.Name, perkItem.Img, perkItem.Desc, perkAmount, EquipedPerks)
		end
	end
end

--//Update inventory perks UI when new perk is added to player inventory
UpdatePerkFunc.OnClientInvoke = function(action: string)
	if action == "update" then
		setupItemPerks()
	end
end

local function setupInventory()
	task.spawn(setupItemPerks)
	
	local plrOtherValues = Player:WaitForChild("OtherValues")
	local plrInventory
	if plrOtherValues then
		plrInventory = plrOtherValues:WaitForChild("OwnedItems")
	end
	if not plrInventory then warn("Can't catch ", Player.Name, "Inventory.") return end
	
	--//Setup equipped emotes
	updateEquippedEmotes()
	
	--//Catch new item when player buy/redeem it.
	plrInventory.ChildAdded:Connect(function(child)
		createItem(child)
	end)
	
	for i, v in pairs(plrInventory:GetChildren()) do
		createItem(v)
	end
	
	for i, v in pairs(ShopModule.Passes) do
		if v.Enabled then
			local passInfo = MarketPlaceService:GetProductInfo(v.ID, Enum.InfoType.GamePass)
			local passName = passInfo.Name
			local passIcon = passInfo.IconImageAssetId
			if MarketPlaceService:UserOwnsGamePassAsync(Player.UserId, v.ID) then
				createPassItem(passName, passIcon)
			end
		end
	end
end

setupInventory()