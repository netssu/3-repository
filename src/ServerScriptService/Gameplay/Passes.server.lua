local MS = game:GetService("MarketplaceService")
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local DataStoreModule = require(SS:WaitForChild("Modules").MainDataModule)

local PASSES = {
	["x3TimesRadius"] = 1683505672,
	["Magnet"] = 1683645969,
	["x2Rebirths"] = 1779204083,
	["x2Cash"] = 1778736163,
	["x2Food"] = 1780493951,
	["x2GourmetFood"] = 1779498046,
	["x2Ingredients"] = 1779810015,
}

-- Handle a completed prompt and purchase
local function onPromptPurchaseFinished(player, purchasedPassID, purchaseSuccess)
	local PassID = nil
	local PassName = nil
	for i,v in pairs(PASSES) do
		if purchasedPassID == v then
			PassID = v
			PassName = i
			break
		end
	end
	if PassID == nil or PassName == nil then
		return
	end
	if purchaseSuccess and purchasedPassID == PassID and PassName then
		print(player.Name .. " purchased the Pass with ID " .. PassID)
		-- Assign the user the ability or bonus related to the pass
	end
end

-- Connect PromptGamePassPurchaseFinished events to the function
MS.PromptGamePassPurchaseFinished:Connect(onPromptPurchaseFinished)


