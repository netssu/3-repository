local CoinsService = {}

--//Services
local ServerStorage = game:GetService("ServerStorage")
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local MoneyModule = require(ModulesFolder:FindFirstChild("MoneyModule"))

--//Constants
local Map = workspace:FindFirstChild("Map")
local VFX = Rs:FindFirstChild("VFX")
local CoinsSpawn = Map:FindFirstChild("CoinsSpawn")
local Assets = ServerStorage:FindFirstChild("Assets")

local Coin_5 = Assets:FindFirstChild("Coin_5")
local Coin_10 = Assets:FindFirstChild("Coin_10")
local ItemEffect = VFX:FindFirstChild("ItemEffect")
local COIN_INTERACT_DISTANCE = 10

function CoinsService:Init()
	local maxCoins = #CoinsSpawn:GetChildren()
	maxCoins = math.floor(maxCoins * (math.random(50, 70) / 100 ))
	
	for i=1, maxCoins do
		local randomSpawn = CoinsSpawn:GetChildren()[math.random(1, #CoinsSpawn:GetChildren())]
		local randomCoin = math.random(1, 5)
		
		local newCoin = nil
		if randomCoin >= 4 then
			newCoin = Coin_10:Clone()
		else
			newCoin = Coin_5:Clone()
		end
		
		newCoin.Parent = workspace.Map.InteractParts
		newCoin:PivotTo(randomSpawn.CFrame)
		randomSpawn:Destroy()
		
		local effect = ItemEffect:Clone()
		effect.Parent = newCoin.Coin_Base
		
		local prox = Instance.new("ProximityPrompt", newCoin.Coin_Base)
		prox.MaxActivationDistance = math.max(GameConfigModule.InteractDistance, COIN_INTERACT_DISTANCE)
		prox.Style = Enum.ProximityPromptStyle.Custom
		prox.ObjectText = "Coin"
		prox.ActionText = "Collect"
		
		prox.Triggered:Once(function(plr)
			local number = tonumber(newCoin.Name:match("%d+"))
			prox.Enabled = false
			MoneyModule.Give(plr, number)
			newCoin:Destroy()
		end)
	end
	
	print("Spawned ".. maxCoins .." coins.")
end

function CoinsService:Start()
	--print("STARTED: ", script.Name)
end

return CoinsService
