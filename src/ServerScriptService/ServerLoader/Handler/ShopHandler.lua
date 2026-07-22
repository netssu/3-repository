local shopModule = {}

function shopModule.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local MarketPlaceService = game:GetService("MarketplaceService")
	local DataStore = game:GetService("DataStoreService")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))
	local GameConfig = require(Rs:FindFirstChild("GameConfig"))
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local GetPassesInfoFunc = Remotes:FindFirstChild("GetPassesInfo") or Instance.new("RemoteFunction", Remotes)
	local GetProductsInfoFunc = Remotes:FindFirstChild("GetProductsInfo") or Instance.new("RemoteFunction", Remotes)
	local PurchaseItemFunc = Remotes:FindFirstChild("PurchaseItem") or Instance.new("RemoteFunction", Remotes)
	local UpdateTitleFunc = Remotes:FindFirstChild("UpdateTitle") or Instance.new("RemoteFunction", Remotes)
	local UpdateEmoteFunc = Remotes:FindFirstChild("UpdateEmote") or Instance.new("RemoteFunction", Remotes)
	local UseCodeFunc = Remotes:FindFirstChild("UseCode") or Instance.new("RemoteFunction", Remotes)
	local RewardWarnEvent = Remotes:FindFirstChild("RewardWarnEvent")
	local UpdatePerkFunc = Remotes:FindFirstChild("UpdatePerk")
	local PurchasePerkFunc = Remotes:FindFirstChild("PurchasePerk")
	local ClaimAllDailyRewards = Remotes:FindFirstChild("ClaimAllDailyRewards")
	local SpinPurchaseEvent = Remotes:FindFirstChild("SpinPurchase")
	GetPassesInfoFunc.Name = "GetPassesInfo"
	GetProductsInfoFunc.Name = "GetProductsInfo"
	PurchaseItemFunc.Name = "PurchaseItem"
	UpdateTitleFunc.Name = "UpdateTitle"
	UpdateEmoteFunc.Name = "UpdateEmote"
	UseCodeFunc.Name = "UseCode"
	
	GetPassesInfoFunc.OnServerInvoke = function(plr)
		--local passesInfo = {}
		
		--for _, pass in pairs(ShopModule.Passes) do
		--	if not pass.Enabled then print("Game Pass (".. pass.ID ..") is Disabled.") continue end
		--	local success, result = pcall(function()
		--		local info = MarketPlaceService:GetProductInfo(pass.ID, Enum.InfoType.GamePass)
		--		return info
		--	end)
		--	if success then
		--		table.insert(passesInfo, result)
		--	else
		--		warn("Can't get pass info (", pass.ID, "), error: ", result)
		--	end
		--end
		
		--return passesInfo
		
		warn(ShopModule.Passes)
		return ShopModule.Passes
	end
	
	GetProductsInfoFunc.OnServerInvoke = function(plr, typeInfo: string?)
		local productsInfo = {}
		
		if typeInfo == "Perks" then
			for _, perk in pairs(ShopModule.Perks) do
				if not perk.Enabled then print("Perk (".. perk.ID ..") is Disabled.") continue end
				local success, result = pcall(function()
					return MarketPlaceService:GetProductInfo(perk.ID, Enum.InfoType.Product)
				end)
				if success then
					productsInfo[perk.ID] = result
				else
					warn("Can't get product info (", perk.ID, "), error: ", result)
				end
			end
		else
			for _, product in pairs(ShopModule.Products) do
				--if not product.Enabled then print("Product (".. product.ID ..") is Disabled.") continue end
				local success, result = pcall(function()
					return MarketPlaceService:GetProductInfoAsync(product.ID, Enum.InfoType.Product)
				end)
				if success then
					table.insert(productsInfo, result)
				else
					warn("Can't get product info (", product.ID, "), error: ", result)
				end
			end
		end
		
		return productsInfo
	end
	
	PurchaseItemFunc.OnServerInvoke = function(plr, itemName)
		local itemInstance = nil
		local itemType = nil
		local foundItem = false
		
		for i, class in pairs(ShopModule.Items) do
			if foundItem then break end
			for _, item in pairs(class) do
				if item.Name == itemName then
					itemInstance = item
					itemType = i
					foundItem = true
					break
				end
			end
		end
		
		local profileData = DataHandler:GetProfileData(plr)
		if not profileData then return false end
		
		if itemInstance and itemType then
			if profileData.Coins >= itemInstance.Price then
				DataManager.AddItem(plr, itemName, tostring(itemType))
				DataManager.RemoveCoins(plr, itemInstance.Price)
				
				--print(plr.Name, "purchased: ", itemName, "Type:", item.Value)
				return true
			end
		end
		return false
	end
	
	--//Purchase perks in shop vendor
	PurchasePerkFunc.OnServerInvoke = function(plr: Player, perkName: string)
		local perkItem = ShopModule:GetPerk(perkName)
		
		local profileData = DataHandler:GetProfileData(plr)
		if not profileData then return false end
		
		if perkItem then
			if profileData.Coins >= perkItem.price then
				DataManager.AddPerk(plr, perkName, 1)
				DataManager.RemoveCoins(plr, perkItem.price)
				RewardWarnEvent:FireClient(plr, "Perk", 1, perkName) -- Perk UI anim
				UpdatePerkFunc:InvokeClient(plr, "update") -- update perk items on inventory
				return true
			end
		end
		return false
	end
	
	--//Equiping functions
	UpdateTitleFunc.OnServerInvoke = function(plr: Player, newTitle: string)
		local plrEquipedTitle = plr:WaitForChild("OtherValues"):WaitForChild("EquipedTitle")
		if plrEquipedTitle then
			DataManager.EquipTitle(plr, newTitle)
			--print(plr.Name, "equiped", newTitle)
			return true
		end
		return false
	end
	
	UpdateEmoteFunc.OnServerInvoke = function(plr: Player, newEmote: string, pos: string)
		local plrEquipedEmotes = plr:WaitForChild("OtherValues"):WaitForChild("EquipedEmotes")
		if plrEquipedEmotes then
			DataManager.EquipEmote(plr, newEmote, pos)
			
			--//Unequip the same emote on other pos -- [already done on DataManager.EquipEmote]
			
			--print(plr.Name, "equiped", newEmote, "on pos", pos)
			return true
		end
		return false
	end
	
	UpdatePerkFunc.OnServerInvoke = function(plr: Player, action: string, perkName: string, changeState: boolean?)
		if action == "change" then
			local plrData = DataHandler:GetProfileData(plr)
			if not plrData then return end
			
			local perkInv = plrData.OwnedPerks
			if not perkInv[perkName] then return end
			
			if plrData.EquipedPerks[perkName] then
				DataManager.EquipPerk(plr, perkName, perkInv[perkName], not changeState)
				if changeState then
					return false
				else
					return true
				end
			elseif #plrData.EquipedPerks < GameConfig.maxEquippedPerks then
				DataManager.EquipPerk(plr, perkName, perkInv[perkName], true)
				return true
			end
		elseif action == "add" then
			-- in this case 'changeState' is the perk amount to be added
			DataManager.AddPerk(plr, perkName, changeState)
			UpdatePerkFunc:InvokeClient(plr, "update") -- update perk items on inventory
			return true
		end
	end
	
	UseCodeFunc.OnServerInvoke = function(plr: Player, codeName)
		if ShopModule.Codes[codeName] and ShopModule.Codes[codeName].Enabled then
			local plrCodes = plr:WaitForChild("OtherValues"):WaitForChild("AwardedCodes")
			if not plrCodes:FindFirstChild(codeName) then
				--[[local newCode = Instance.new("BoolValue", plrCodes)
				newCode.Name = codeName
				newCode.Value = true]]
				
				DataManager.AddCode(plr, codeName)
				
				for i, v in pairs(ShopModule.Codes[codeName].Reward) do
					if i == "Coins" then
						DataManager.AddCoins(plr, v)
						RewardWarnEvent:FireClient(plr, i, v) -- Coins UI anim
					elseif i == "FreeRevives" then
						DataManager.AddFreeRevive(plr, v)
						RewardWarnEvent:FireClient(plr, i, v) -- Earn UI anim
					end
				end
				--print(plr.Name, "redeemed code:", codeName)
				return true
			else
				return "already"
			end
		end
		return false
	end
	
	local products = {
		["Coins_50"] = ShopModule:GetProduct("Coins_50"),
		["Coins_200"] = ShopModule:GetProduct("Coins_200"),
		["Coins_500"] = ShopModule:GetProduct("Coins_500"),
		["Coins_1200"] = ShopModule:GetProduct("Coins_1200"),
		["Coins_1600"] = ShopModule:GetProduct("Coins_1600"),
		["Coins_2000"] = ShopModule:GetProduct("Coins_2000"),
		["Coins_5200"] = ShopModule:GetProduct("Coins_5200"),
		
		-- game perks
		["Cursed Doll"] = ShopModule:GetPerk("Cursed Doll"),
		["Medkit"] = ShopModule:GetPerk("Medkit"),
		["Baseball Bat"] = ShopModule:GetPerk("Baseball Bat"),
		["Bandage"] = ShopModule:GetPerk("Bandage"),
	}
	
	local processedReceipts = {}
	local donationProducts = require(workspace.Boards:FindFirstChild("Products"))
	
	--//Check when a player purchase a product
	MarketPlaceService.ProcessReceipt = function(receiptInfo)
		local purchaseId = receiptInfo.PurchaseId
		if processedReceipts[purchaseId] then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		
		local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
		if not player then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		
		local productId = receiptInfo.ProductId
		
		if productId == 3441545085 then -- claim all daily rewards
			local plrProfileData = DataHandler:GetProfileData(player)
			if plrProfileData then
				ClaimAllDailyRewards:Fire(player)
			end
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		
		if productId == 3491931922 then -- buy +1 spin
			SpinPurchaseEvent:FireClient(player, true)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		
		-- give the product reward
		task.spawn(function()
			for _, product in pairs(products) do
				if product.ID == productId then
					if product.Reward then
						for rewardType, rewardAmount in pairs(product.Reward) do
							if rewardType == "Coins" then
								local coins = player:FindFirstChild("leaderstats") and player.leaderstats:FindFirstChild("Coins")
								if coins then
									DataManager.AddCoins(player, rewardAmount)
									RewardWarnEvent:FireClient(player, rewardType, rewardAmount) -- Coins UI anim
								end
							end
						end
					else -- is a game perk
						DataManager.AddPerk(player, product.Name, 1)
						RewardWarnEvent:FireClient(player, "Perk", 1, product.Name) -- Perk UI anim
						UpdatePerkFunc:InvokeClient(player, "update") -- update perk items on inventory
					end
				end
			end
		end)
		
		--//Update donators board data
		local donationProduct = nil
		for i, v in pairs(donationProducts.Products) do
			if v.ProductId == productId then
				donationProduct = v
				break
			end
		end
		
		if donationProduct ~= nil then
			DataStore:GetOrderedDataStore("TopDonators"):IncrementAsync(player.UserId, donationProduct.ProductPrice)
		end
		
		processedReceipts[purchaseId] = true
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
end

return shopModule