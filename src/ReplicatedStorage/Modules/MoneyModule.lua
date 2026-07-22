local MoneyModule = {}

--//Services
local Rs = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local MarketPlaceService = game:GetService("MarketplaceService")
local ServerScriptService = game:GetService("ServerScriptService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local MoneyEarnEvent = Remotes:FindFirstChild("MoneyEarn")

--//Values
local MoneyPass_2x = 1328215468 -- 2x Money gamepass

function MoneyModule.Give(plr: Player, amount: number)
	local earnAmount = amount
	local multiplier = 1
	
	if amount > 300 then warn("Invalid coin amount received from player:", plr.Name, plr.UserId, "| Amount:", amount) return end
	
	--//Game pass multiplier
	pcall(function()
		if MarketPlaceService:UserOwnsGamePassAsync(plr.UserId, MoneyPass_2x) then
			multiplier += 1
		end
	end)
	
	earnAmount = earnAmount * multiplier
	
	if RunService:IsServer() then
		local DataManager = require(ServerScriptService.Data.DataManager)
		DataManager.AddCoins(plr, earnAmount)
		MoneyEarnEvent:FireClient(plr, earnAmount) -- Show coins animation
	elseif RunService:IsClient() then
		MoneyEarnEvent:FireServer(earnAmount) -- update amount on server script and show animation
	end
end

return MoneyModule