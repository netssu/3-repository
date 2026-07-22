--//Services
local MarketplaceService = game:GetService("MarketplaceService")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local ShopModule = require(Modules.ShopModule)

--//Variables
local trigger = script.Parent
local characterPass = ShopModule:GetPass("Eleven")

trigger.Touched:Connect(function(hit)
	if not hit or not hit.Parent then return end
	
	local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
	if not plr then return end
	
	MarketplaceService:PromptGamePassPurchase(plr, characterPass.ID)
end)