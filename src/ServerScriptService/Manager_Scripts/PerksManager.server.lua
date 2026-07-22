--//Services
local Rs = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local InventoryManager = require(ModulesFolder:FindFirstChild("InventoryModule"))
local DataHandler = require(ModulesFolder:FindFirstChild("DataHandler"))
local DataManager = require(ServerScriptService.Data:FindFirstChild("DataManager"))
local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))

--//Items stuff
local ItemsFolder = Rs:FindFirstChild("Items")
local ToolsFolder = ItemsFolder:FindFirstChild("Tools")

Players.PlayerAdded:Connect(function(plr)
	repeat task.wait() until Rs:FindFirstChild("CanLoadChar") and Rs:FindFirstChild("CanLoadChar").Value
	
	task.wait(3)
	
	local profileData = DataHandler:GetProfileData(plr)
	if not profileData then return end
	
	for perkName, perkActivated in profileData.EquipedPerks do
		if perkActivated then
			local perkItem = ShopModule:GetPerk(perkName)
			if perkItem and perkItem.Type == "Item" then
				local itemTool = ToolsFolder:FindFirstChild(perkName)
				if not itemTool then continue end
				
				InventoryManager.AddItem(plr, itemTool, true)
				DataManager.RemovePerk(plr, perkName, 1) -- perkAmount - thisValue (1)
			end
		end
	end
end)