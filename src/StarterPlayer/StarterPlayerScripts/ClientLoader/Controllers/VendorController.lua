--!nonstrict

local vendorController = {}

function vendorController.Init()
	--//Services
	local Ts = game:GetService("TweenService")
	local Rs = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local MarketplaceService = game:GetService("MarketplaceService")
	local SoundService = game:GetService("SoundService")
	
	--//Player
	local Player = Players.LocalPlayer
	local PlrGui = Player.PlayerGui
	
	--//Modules
	local ModulesFolder = Rs:WaitForChild("Modules")
	local ShopModule = require(ModulesFolder:WaitForChild("ShopModule"))
	local SoundPlayer = require(ModulesFolder.Utils:WaitForChild("SoundPlayer"))
	
	--//Remotes
	local Remotes = Rs:WaitForChild("Remotes")
	local GetProductsInfo = Remotes:WaitForChild("GetProductsInfo")
	local PurchasePerkFunc = Remotes:WaitForChild("PurchasePerk")
	
	--//Vendor Stuff
	local Map = workspace:WaitForChild("Map")
	local InteractStuff = Map:WaitForChild("InteractStuff")
	local VendorModel = InteractStuff:WaitForChild("ShopVendor")
	local InteractProx = VendorModel:WaitForChild("InteractPart"):WaitForChild("ProximityPrompt")
	
	--//UI
	local VendorGui = PlrGui:WaitForChild("VendorGui")
	local MainFrame = VendorGui:WaitForChild("MainFrame")
	local ShopFrame = MainFrame:WaitForChild("ShopFrame")
	local InfoFrame = ShopFrame:WaitForChild("InfoFrame")
	local ItemsList = ShopFrame:WaitForChild("ItemsFrame")
	local CloseButton = ShopFrame:WaitForChild("CloseButton")
	local ItemFrameExample = ItemsList:WaitForChild("ItemFrame_Example")
	
	--//Values
	local SelectedItem = nil
	local shopEnabled = false
	local purchaseDebounce = true
	local defaultSize = ShopFrame.Size
	
	type Perk = {[string]: any}
	type PerkInfo = {[string]: any}
	
	--//Utils
	local function changeShopFrame(state: boolean)
		if state then
			ShopFrame.Visible = true
			ShopFrame.Size = UDim2.new(0, 0, 0, 0)
			Ts:Create(ShopFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = defaultSize}):Play()
		else
			local tween = Ts:Create(ShopFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)})
			tween:Play()
			tween.Completed:Wait()
			ShopFrame.Visible = false
		end
	end
	
	local function buildNewItem(perkItem: Perk, perkInfo: PerkInfo): Frame
		local newItem = ItemFrameExample:Clone()
		newItem.Parent = ItemsList
		newItem.ItemIcon.Image = perkItem.Img
		newItem.ItemName.Text = perkItem.Name
		newItem.Visible = true
		
		local clicker = newItem.PreviewButton
		
		if clicker then
			clicker.MouseButton1Click:Connect(function()
				SoundPlayer:PlaySound(SoundService.Effects.ClickSound)
				InfoFrame.CurrentItem.Value = perkItem.Name
				InfoFrame.ItemIcon.Image = perkItem.Img
				InfoFrame.ItemName.Text = perkItem.Name
				InfoFrame.ItemDesc.Text = perkItem.Desc
				InfoFrame.BuyRobuxButton.PriceText.Text = perkInfo.PriceInRobux
				InfoFrame.BuyCoinsButton.PriceText.Text = perkItem.price
			end)
			
			clicker.MouseEnter:Connect(function()
				SoundPlayer:PlaySound(SoundService.Effects.InteractSound)
			end)
		end
		
		return newItem
	end
	
	--//Setup shop vendor UI and functions
	local function shopVendorConstruct()
		ItemFrameExample.Parent = Rs
		
		local shopItems = {}
		local perksProducts = GetProductsInfo:InvokeServer("Perks")
		
		for _, perkItem in pairs(ShopModule.Perks) do
			local perkInfo = perksProducts[tostring(perkItem.ID)]
			local itemFrame: Frame = buildNewItem(perkItem, perkInfo)
			if not itemFrame then continue end -- Failed to create this item on shop
			shopItems[perkItem.Name] = perkItem.ID
		end
		
		local buyCoinsButton = InfoFrame.BuyCoinsButton
		local buyRobuxButton = InfoFrame.BuyRobuxButton
		
		--//Buy this perk in coins
		buyCoinsButton.MouseButton1Click:Connect(function()
			SoundPlayer:PlaySound(SoundService.Effects.ClickSound)
			if purchaseDebounce then
				purchaseDebounce = false
				
				local purchasedItem = PurchasePerkFunc:InvokeServer(InfoFrame.CurrentItem.Value, "Coins")
				if purchasedItem then
					SoundService.Effects.PurchaseSound:Play()
				else
					pcall(function() -- Prompt coins purchase if player doesnt have enough coins
						local coins500 = ShopModule:GetProduct("Coins_500")
						if coins500 and coins500.ID then
							MarketplaceService:PromptProductPurchase(Player, coins500.ID)
						end
					end)
					SoundService.Effects.IncorrectSound:Play()
				end
				
				task.wait(0.7)
				
				purchaseDebounce = true
			end
		end)
		
		--//Show a prompt to player buy this perk in robux
		buyRobuxButton.MouseButton1Click:Connect(function()
			SoundPlayer:PlaySound(SoundService.Effects.ClickSound)
			if shopItems[InfoFrame.CurrentItem.Value] then
				MarketplaceService:PromptProductPurchase(Player, shopItems[InfoFrame.CurrentItem.Value])
			end
		end)
		
		buyCoinsButton.MouseEnter:Connect(function()
			SoundService.Effects.InteractSound:Play()
		end)
		
		buyRobuxButton.MouseEnter:Connect(function()
			SoundService.Effects.InteractSound:Play()
		end)
	end
	
	InteractProx.Triggered:Connect(function(plr)
		if plr ~= Player then return end -- another player triggered this prompt
		shopEnabled = not shopEnabled
		SoundPlayer:PlaySound(SoundService.Effects.ClickSound)
		changeShopFrame(shopEnabled)
	end)
	
	CloseButton.MouseButton1Click:Connect(function()
		SoundPlayer:PlaySound(SoundService.Effects.ClickSound)
		shopEnabled = false
		changeShopFrame(false)
	end)
	
	CloseButton.MouseEnter:Connect(function()
		SoundPlayer:PlaySound(SoundService.Effects.InteractSound)
	end)
	
	Player.CharacterAdded:Connect(function()
		changeShopFrame(false)
	end)
	
	shopVendorConstruct()
end

return vendorController