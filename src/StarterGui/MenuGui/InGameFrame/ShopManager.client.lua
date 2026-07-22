--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local MarketPlaceService = game:GetService("MarketplaceService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local GetPassesInfoFunction = Remotes:WaitForChild("GetPassesInfo", 10)
local GetProductsInfoFunction = Remotes:WaitForChild("GetProductsInfo", 10)
local PurchaseItemFunc = Remotes:WaitForChild("PurchaseItem", 10)
local UpdatePassEvent = Remotes:WaitForChild("UpdatePass", 10)
local UseCodeFunc = Remotes:WaitForChild("UseCode", 10)

--//Player
local Plr = game.Players.LocalPlayer

--//UI
local ShopMainFrame = script.Parent:FindFirstChild("ShopFrame")
local CloseButton = ShopMainFrame.CloseBT
local ShopListFrame = ShopMainFrame:FindFirstChild("ShopFrame")
local CodesFrame = ShopMainFrame:FindFirstChild("CodesFrame")
local ItemsListFrame = ShopMainFrame:FindFirstChild("SkinsFrame")
local EmotePreviewFrame = script.Parent:FindFirstChild("EmotePreviewFrame")

local Session_1_Shop = ShopListFrame:FindFirstChild("Session_1")
local Session_2_Shop = ShopListFrame:FindFirstChild("Session_2")
local Session_3_Shop = ShopListFrame:FindFirstChild("Session_3")
local PassSession1_Example = Session_1_Shop:FindFirstChild("PassFrame_Example")
local PassSession2_Example = Session_2_Shop:FindFirstChild("PassFrame_Example")
local ProductSession3_Example = Session_3_Shop:FindFirstChild("ProductFrame_Example")

local Session_1_Items = ItemsListFrame:FindFirstChild("Session_1")
local Session_2_Items = ItemsListFrame:FindFirstChild("Session_2")
local ItemSession1_Example = Session_1_Items:FindFirstChild("ItemFrame_Example")
local ItemSession2_Example = Session_2_Items:FindFirstChild("ItemFrame_Example")

local CodesTextBox = CodesFrame:FindFirstChild("TextBox")
local CodesConfirmButton = CodesFrame:FindFirstChild("ConfirmButton")

--//Sounds
local SoundsFolder = script.Parent:FindFirstChild("Sounds")

--//Values - Rig
local rigEmoteAnimator = EmotePreviewFrame:FindFirstChild("Animator", true) :: Animator
local emotePreviewAnim = nil
local emoteAnimPlay = nil
local emoteAnimConnection = nil
local rigIdleAnim = EmotePreviewFrame.ViewportFrame.WorldModel.RigAnimator.IdleAnim
local animIdle = nil
local defaultProductIcon = "rbxassetid://128558764879677"

--//Setup
PassSession1_Example.Parent = Rs
PassSession2_Example.Parent = Rs
ProductSession3_Example.Parent = Rs
ItemSession1_Example.Parent = Rs
ItemSession2_Example.Parent = Rs

pcall(function()
	animIdle = rigEmoteAnimator:LoadAnimation(rigIdleAnim)
	if animIdle then
		animIdle.Looped = true
		animIdle:Play()
		animIdle:AddTag("IDLE")
	end
end)

ShopMainFrame:GetPropertyChangedSignal("Visible"):Connect(function()
	if not ShopMainFrame.Visible then
		EmotePreviewFrame.Visible = false
	end
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

CloseButton.MouseButton1Click:Connect(function()
	EmotePreviewFrame.Visible = false
end)

local function makePassOwned(PassFrame: Frame)
	if not PassFrame then return end
	
	PassFrame.BuyButton.PriceText.Text = "Owned"
	PassFrame.BuyButton.BackgroundColor3 = Color3.fromRGB(97, 184, 206)
	--PassFrame.BuyButton.UIStroke.Color = Color3.fromRGB(49, 104, 127)
	
	--[[
	local newColorSequence = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(54, 116, 143)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(125, 223, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 117, 144))
	}
	
	PassFrame.BuyButton.UIGradient.Color = newColorSequence
	PassFrame.BuyButton.UIGradient.Rotation = 0
	]]
end

MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(plr, passId, purchased)
	if plr == Plr and purchased then
		SoundsFolder.PurchaseSound:Play()
		UpdatePassEvent:Fire(passId) -- Update plr inventory game passes
		for i, v in pairs(Session_1_Shop:GetChildren()) do
			task.wait()
			if v:IsA("Frame") then
				if tonumber(v.PassID.Value) == passId then
					makePassOwned(v)
				end
			end
		end
		for i, v in pairs(Session_2_Shop:GetChildren()) do
			task.wait()
			if v:IsA("Frame") then
				if tonumber(v.PassID.Value) == passId then
					makePassOwned(v)
				end
			end
		end
	else
		return
	end
end)

--//Get the most popular passes based on the 'Sales' value
local function getPopularPasses(passesInfo)
	local passes = {} -- Get all validy passes
	for _, pass in pairs(passesInfo) do
		if pass.IsForSale then
			table.insert(passes, pass)
		end
	end
	
	table.sort(passes, function(a, b)
		return (a.Sales or 0) > (b.Sales or 0)
	end)
	
	local popularPasses = {} -- Get the top passes with most sales
	for i = 1, math.min(ShopModule.Config.MaxPopularPasses or 5, #passes) do
		--table.insert(popularPasses, passes[i])
		popularPasses[passes[i].Name] = passes[i]
	end
	
	return popularPasses
end

local function createPassFrame(Style: Frame, Session: Frame, Name: string, Price: number, Icon: string, Desc: string, ID: number)
	local newPass = Style:Clone()
	newPass.Parent = Session
	newPass.Name = Name
	newPass.PassName.Text = Name
	newPass.PassID.Value = ID
	newPass.BuyButton.PriceText.Text = "$"..tostring(Price)
	newPass.PassIcon.Image = Icon
	newPass.Visible = true
	
	if MarketPlaceService:UserOwnsGamePassAsync(Plr.UserId, newPass.PassID.Value) then
		makePassOwned(newPass)
	end
	
	newPass.BuyButton.MouseButton1Click:Connect(function()
		SoundsFolder.ClickSound:Play()
		if MarketPlaceService:UserOwnsGamePassAsync(Plr.UserId, newPass.PassID.Value) then
			makePassOwned(newPass)
		else
			MarketPlaceService:PromptGamePassPurchase(Plr, newPass.PassID.Value)
		end
	end)
end

local function createProductFrame(Style: Frame, Session: Frame, Name: string, Price: number, Icon: string, ID: number)
	local newProduct = Style:Clone()
	local imageIcon = Icon
	
	if not imageIcon or imageIcon == "rbxassetid://" or imageIcon == "rbxassetid://0" then
		imageIcon = defaultProductIcon
	end
	
	newProduct.Name = Name
	newProduct.ProductName.Text = Name
	newProduct.ProductID.Value = ID
	newProduct.BuyButton.PriceText.Text = "$"..tostring(Price)
	newProduct.ProductIcon.Image = imageIcon
	newProduct.Visible = true
	newProduct.Parent = Session
	
	print("creting new product: ", newProduct, Session)
	
	newProduct.BuyButton.MouseButton1Click:Connect(function()
		SoundsFolder.ClickSound:Play()
		MarketPlaceService:PromptProductPurchase(Plr, newProduct.ProductID.Value)
	end)
end

local function get_products_info(list: {any}, infoType: Enum.InfoType, label: string): {any}
	local out = {}

	for _, item in list do
		if not item.Enabled then
			print(label, item.ID, "is not enabled.")
			continue
		end
		local ok, info = pcall(MarketPlaceService.GetProductInfoAsync, MarketPlaceService, item.ID, infoType)
		if ok then
			table.insert(out, info)
		else
			warn("Can't get " .. label .. " info (", item.ID, "), error: ", info)
		end
	end

	return out
end

local function setupShopUI()
	local passes = GetPassesInfoFunction:InvokeServer()
	local products = GetProductsInfoFunction:InvokeServer()
	
	local passesInfo = get_products_info(passes, Enum.InfoType.GamePass, "Game Pass")
	local productsInfo = get_products_info(products, Enum.InfoType.Product, "Product")

	if passesInfo then
		local popularPasses = getPopularPasses(passesInfo)
		
		--//Create all passes
		for i, passInfo in pairs(passesInfo) do
			local Name = passInfo.Name
			local Price = passInfo.PriceInRobux
			local Icon = passInfo.IconImageAssetId
			local Desc = passInfo.Description
			local TotalSales = passInfo.Sales
			local PassID = passInfo.TargetId
			
			local IsForSale = passInfo.IsForSale
			local ProductType = passInfo.ProductType
			
			if IsForSale and ProductType == "Game Pass" then -- Verification
				createPassFrame(PassSession1_Example, Session_2_Shop, Name, Price, "rbxassetid://"..Icon, Desc, PassID) -- All Passes
				local popularPass = popularPasses[Name]
				if popularPass == passInfo then
					createPassFrame(PassSession2_Example, Session_1_Shop, Name, Price, "rbxassetid://"..Icon, Desc, PassID)-- Popular Passes
				end
			end
		end
	end
	if productsInfo then
		--//Create all products
		for i, productInfo in pairs(productsInfo) do
			local Name = productInfo.DisplayName -- Translated name
			local Price = productInfo.PriceInRobux
			local Icon = productInfo.IconImageAssetId
			local Desc = productInfo.Description
			local ProductID = productInfo.ProductId
			createProductFrame(ProductSession3_Example, Session_3_Shop, Name, Price, "rbxassetid://"..Icon, ProductID) -- All Products
		end
	end
end

local function changeToOwned(button: TextButton)
	if not button then return end
	
	local newColorSequence = ColorSequence.new{
		ColorSequenceKeypoint.new(0, Color3.fromRGB(54, 116, 143)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(125, 223, 255)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(54, 117, 144))
	}
	
	button.BuyButton.PriceText.Text = "Owned"
	--[[button.BuyButton.BackgroundColor3 = Color3.fromRGB(85, 181, 225)
	button.BuyButton.UIGradient.Color = newColorSequence
	button.BuyButton.UIGradient.Rotation = 0
	button.BuyButton.UIStroke.Color = Color3.fromRGB(50, 85, 111)]]
end

local function createEmoteItem(Name: string, Icon: string, Price: number, emoteId: string)
	local newItem = ItemSession1_Example:Clone()
	newItem.Parent = Session_1_Items
	newItem.Name = Name.."_Emote"
	newItem.ItemName.Text = Name.." Emote"
	newItem.BuyButton.PriceText.Text = "$"..tostring(Price)
	newItem.ItemIcon.Image = "rbxassetid://"..tostring(Icon)
	newItem.Visible = true
	
	local plrOtherValues = Plr:WaitForChild("OtherValues")
	local OwnedItems
	if plrOtherValues then
		OwnedItems = plrOtherValues:WaitForChild("OwnedItems")
	end
	
	task.wait()
	
	if OwnedItems and OwnedItems:FindFirstChild(Name) then
		changeToOwned(newItem)
	end
	
	--//Buy function
	if OwnedItems then
		newItem.BuyButton.MouseButton1Click:Connect(function()
			if not OwnedItems:FindFirstChild(Name) then -- Check if plr already have this item
				local purchased = PurchaseItemFunc:InvokeServer(Name)
				if purchased then
					SoundsFolder.PurchaseSound:Play()
					changeToOwned(newItem)
				else
					SoundsFolder.IncorrectSound:Play()
					print("Can't buy item:", Name)
				end
			else
				SoundsFolder.ClickSound:Play()
				changeToOwned(newItem)
			end
		end)
		newItem.BuyButton.MouseEnter:Connect(function()
			SoundsFolder.InteractSound:Play()
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
			EmotePreviewFrame.EmoteNameText.Text = Name
			EmotePreviewFrame.EmotePriceText.Text = "$"..Price
		end)
	end
end

local function createTitleItem(Name: string, Price: number, Title: TextLabel)
	local newItem = ItemSession2_Example:Clone()
	newItem.Parent = Session_2_Items
	newItem.Name = Name.."_Title"
	newItem.ItemName.Text = Name.. " Title"
	newItem.BuyButton.PriceText.Text = "$"..tostring(Price)
	newItem.Visible = true
	newItem.TitleName.Visible = false
	
	local titleText = Title:Clone()
	titleText.Parent = newItem
	titleText.Size = newItem.TitleName.Size
	titleText.Position = newItem.TitleName.Position
	titleText.Visible = true
	
	local plrOtherValues = Plr:WaitForChild("OtherValues")
	local OwnedItems
	if plrOtherValues then
		OwnedItems = plrOtherValues:FindFirstChild("OwnedItems")
	end
	
	task.wait()
	
	if OwnedItems:FindFirstChild(Name) then
		changeToOwned(newItem)
	end
	
	--//Buy function
	if OwnedItems then
		newItem.BuyButton.MouseButton1Click:Connect(function()
			if not OwnedItems:FindFirstChild(Name) then -- Check if plr already have this item
				local purchased = PurchaseItemFunc:InvokeServer(Name)
				if purchased then
					SoundsFolder.PurchaseSound:Play()
					changeToOwned(newItem)
				else
					SoundsFolder.IncorrectSound:Play()
					print("Can't buy item:", Name)
				end
			else
				SoundsFolder.ClickSound:Play()
				changeToOwned(newItem)
			end
		end)
		newItem.BuyButton.MouseEnter:Connect(function()
			SoundsFolder.InteractSound:Play()
		end)
	end
end

local function setupItemsUI()
	local emotesItems = {}
	local titlesItems = {}
	
	local plrOtherValues = Plr:WaitForChild("OtherValues")
	local OwnedItems
	if plrOtherValues then
		OwnedItems = plrOtherValues:FindFirstChild("OwnedItems")
	end
	
	--//Get emotes items
	for _, emote in pairs(ShopModule.Items.Emotes) do
		if typeof(emote) ~= "table" then continue end
		if emote.Enabled and not (emote.Price <= 0) then
			table.insert(emotesItems, emote)
		elseif emote.Enabled and emote.Price <= 0 then
			if not OwnedItems then continue end
			if not OwnedItems:FindFirstChild(emote.Name) then
				local purchase = PurchaseItemFunc:InvokeServer(emote.Name)
				if not purchase then
					warn("Can't redeem free item (emote):", emote.Name)
				end
			end
		end
	end
	
	--//Get titles items
	for _, title in pairs(ShopModule.Items.Titles) do
		if typeof(title) ~= "table" then continue end
		if title.Enabled and not (title.Price <= 0) then
			table.insert(titlesItems, title)
		elseif title.Enabled and title.Price <= 0 and not title.Limited then -- Automatically redeem free items (default)
			if not OwnedItems then continue end
			if not OwnedItems:FindFirstChild(title.Name) then
				local purchase = PurchaseItemFunc:InvokeServer(title.Name)
				if not purchase then
					warn("Can't redeem free item (title):", title.Name)
				end
			end
		end
	end
	
	--session 1 = emotes
	--session 2 = titles
	
	--//Create emote items
	for _, emoteInstance in pairs(emotesItems) do
		createEmoteItem(emoteInstance.Name, emoteInstance.Img, emoteInstance.Price, emoteInstance.AnimId)
	end
	
	--//Create plr title items
	for _, titleInstance in pairs(titlesItems) do
		if titleInstance.Limited then continue end
		createTitleItem(titleInstance.Name, titleInstance.Price, titleInstance.TextStyle)
	end
end

--//Check if the code is validy and redeem it
local function redeemCode()
	local function incorrectCode()
		SoundsFolder.IncorrectSound:Play()
		CodesConfirmButton.TextLabel.Text = "Invalid Code!"
		task.delay(2, function() CodesConfirmButton.TextLabel.Text = "Confirm" end)
	end
	
	local currentText = CodesTextBox.Text
	if ShopModule.Codes[currentText] then
		if ShopModule.Codes[currentText].Enabled then
			local awardCode = UseCodeFunc:InvokeServer(currentText)
			if awardCode == true then
				SoundsFolder.PurchaseSound:Play()
				CodesConfirmButton.TextLabel.Text = "Code Awarded!"
				task.delay(2, function() CodesConfirmButton.TextLabel.Text = "Confirm" end)
			elseif awardCode == "already" then
				SoundsFolder.IncorrectSound:Play()
				CodesConfirmButton.TextLabel.Text = "Already Claimed!"
				task.delay(2, function() CodesConfirmButton.TextLabel.Text = "Confirm" end)
			else
				incorrectCode()
			end
		end
	else
		incorrectCode()
	end
end

CodesTextBox.InputBegan:Connect(function(input)
	if input.KeyCode == Enum.KeyCode.Return then
		redeemCode()
	end
end)

CodesConfirmButton.MouseButton1Click:Connect(function()
	SoundsFolder.ClickSound:Play()
	redeemCode()
end)

CodesConfirmButton.MouseEnter:Connect(function()
	SoundsFolder.InteractSound:Play()
	Ts:Create(CodesConfirmButton.TextLabel, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(255, 215, 53)}):Play()
end)

CodesConfirmButton.MouseLeave:Connect(function()
	Ts:Create(CodesConfirmButton.TextLabel, TweenInfo.new(0.2), {TextColor3 = Color3.fromRGB(216, 216, 216)}):Play()
end)

setupItemsUI()
setupShopUI()