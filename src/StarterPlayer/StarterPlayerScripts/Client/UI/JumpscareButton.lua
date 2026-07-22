local JumpscareButton = {
	DataLoad = false
}

--//Services
local Players = game:GetService("Players")
local Rs = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--//Modules
local Packages = Rs:WaitForChild("Packages")
local TopBarApp = require(Packages.Icon)

--//Constants
local IconDefault = 13821906546

function JumpscareButton:Init()
	local scareButton = TopBarApp.new()
	scareButton:setImage(IconDefault, "Deselected")
	scareButton:setImage(IconDefault, "Selected")
	scareButton:setImage(IconDefault, "Viewing")
	
	scareButton:setOrder(2)
	
	scareButton:bindEvent("toggled", function()
		scareButton:deselect()
		MarketplaceService:PromptProductPurchase(Players.LocalPlayer, 3435647011)
	end)
end

function JumpscareButton:Start()
	
end

return JumpscareButton