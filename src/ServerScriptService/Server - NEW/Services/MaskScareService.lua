local MaskScareService = {}

--//Services
local MarketplaceService = game:GetService("MarketplaceService")
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Modules
local GameConfigModule = require(Rs.Modules.GameConfigModule)
local Trove = require(Rs.Packages.Trove)
local Component = require(Rs.Packages.Component)

local scareMasks = Component.new({
	Tag = "ScaryMask",
	Ancestors = { workspace },
	Extensions = {},
})

function scareMasks:Construct()
	self._trove = Trove.new()
end

scareMasks.Started:Connect(function(component)
	local maskPart = component.Instance :: BasePart
	
	assert(maskPart:IsA("BasePart"),
		"[MaskScareService] Expexted BasePart, got:",
		maskPart
	)
	
	local prox = Instance.new("ProximityPrompt", maskPart)
	prox.MaxActivationDistance = GameConfigModule.InteractDistance
	prox.Style = Enum.ProximityPromptStyle.Custom
	prox.ActionText = "Jumpscare Everyone!"
	prox.ObjectText = "$49"
	
	pcall(function()
		local productInfo = MarketplaceService:GetProductInfo(3435647011, Enum.InfoType.Product)
		prox.ObjectText = productInfo and "$"..productInfo.PriceInRobux or "$49"
	end)
	
	component._trove:Connect(prox.Triggered, function(plr)
		MarketplaceService:PromptProductPurchase(plr, 3435647011)
	end)
	
	local highlight = maskPart:FindFirstChildWhichIsA("Highlight") :: Highlight
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

scareMasks.Stopped:Connect(function(component)
	component._trove:Destroy()
end)

function MaskScareService:Init()
	--print("INITIALIZED: ", script.Name)
end

function MaskScareService:Start()
	--print("STARTED: ", script.Name)
end

return MaskScareService