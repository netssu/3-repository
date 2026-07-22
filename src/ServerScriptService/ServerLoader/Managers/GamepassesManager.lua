local GamepassesManager = {}

function GamepassesManager.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local MarketPlaceService = game:GetService("MarketplaceService")
	local DataStore = game:GetService("DataStoreService")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local RewardWarnEvent = Remotes:FindFirstChild("RewardWarnEvent")
	
	--//Constants
	local passes = {
		["Eleven"] = ShopModule:GetPass("Eleven"),
		["Will_Byers"] = ShopModule:GetPass("Will Byers"),
		["Jonathan_Byers"] = ShopModule:GetPass("Jonathan Byers")
	}
	
	MarketPlaceService.PromptGamePassPurchaseFinished:Connect(function(plr: Player, passId, purchased)
		if passId == passes.Eleven.ID then
			local success, ownPass = pcall(function()
				return MarketPlaceService:UserOwnsGamePassAsync(plr.UserId, passId)
			end)
			if success and ownPass then
				RewardWarnEvent:FireClient(plr, "Character", 0, "Eleven")
				DataManager.AddNewChar(plr, "Eleven")
			end
		elseif passId == passes.Will_Byers.ID then
			local success, ownPass = pcall(function()
				return MarketPlaceService:UserOwnsGamePassAsync(plr.UserId, passId)
			end)
			if success and ownPass then
				RewardWarnEvent:FireClient(plr, "Character", 0, "Will Byers")
				DataManager.AddNewChar(plr, "Will Byers")
			end
		elseif passId == passes.Jonathan_Byers.ID then
			local success, ownPass = pcall(function()
				return MarketPlaceService:UserOwnsGamePassAsync(plr.UserId, passId)
			end)
			if success and ownPass then
				RewardWarnEvent:FireClient(plr, "Character", 0, "Jonathan Byers")
				DataManager.AddNewChar(plr, "Jonathan Byers")
			end
		end
	end)
end

return GamepassesManager