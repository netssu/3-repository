local MaskScareService = {}

--//Services
local MarketplaceService = game:GetService("MarketplaceService")
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Modules
local GameConfigModule = require(Rs.Modules.GameConfigModule)
local Trove = require(Rs.Packages.Trove)
local Component = require(Rs.Packages.Component)

local batTools = Component.new({
	Tag = "BatTool",
	Ancestors = { workspace },
	Extensions = {},
})

--//Constants
local toolProduct = 3382855969

function batTools:Construct()
	self._trove = Trove.new()
end

batTools.Started:Connect(function(component)
	local batToolModel = component.Instance :: Model
	
	assert(batToolModel:IsA("Model"),
		"[BatToolsService] Expected Model, got:",
		batToolModel
	)
	
	local prox = Instance.new("ProximityPrompt", batToolModel.PrimaryPart)
	prox.MaxActivationDistance = GameConfigModule.InteractDistance
	prox.Style = Enum.ProximityPromptStyle.Custom
	prox.ActionText = "Hit Enemies!"
	prox.ObjectText = "$29"
	
	pcall(function()
		local productInfo = MarketplaceService:GetProductInfo(toolProduct, Enum.InfoType.Product)
		prox.ObjectText = productInfo and "$"..productInfo.PriceInRobux or "$29"
	end)
	
	component._trove:Connect(prox.Triggered, function(plr)
		MarketplaceService:PromptProductPurchase(plr, toolProduct)
	end)
	
	local highlight = batToolModel:FindFirstChildWhichIsA("Highlight") :: Highlight
	if highlight then
		coroutine.wrap(function()
			while true do
				Ts:Create(highlight, TweenInfo.new(1), {OutlineTransparency = 1}):Play()
				task.wait(1)
				Ts:Create(highlight, TweenInfo.new(1.5), {OutlineTransparency = 0.4}):Play()
				task.wait(1.5)
			end
		end)()
	end
end)

batTools.Stopped:Connect(function(component)
	component._trove:Destroy()
end)

function MaskScareService:Init()
	--print("INITIALIZED: ", script.Name)
end

function MaskScareService:Start()
	--print("STARTED: ", script.Name)
end

return MaskScareService