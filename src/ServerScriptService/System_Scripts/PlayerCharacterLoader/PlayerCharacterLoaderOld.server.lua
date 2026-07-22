--//Services
local MarketPlaceService = game:GetService("MarketplaceService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local LoadCharFunc = Remotes:FindFirstChild("LoadChar")
local LoadCharScriptsEvent = Remotes:FindFirstChild("loadPlrCharScripts")
local loadPlrCharBind = Remotes:FindFirstChild("LoadPlrCharBind")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local SecureModule = require(ModulesFolder:FindFirstChild("SecureSearch"))
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))
local SoundPlayer = require(ModulesFolder.Utils:FindFirstChild("SoundPlayer"))
local PushRagdollModule = require(ModulesFolder:FindFirstChild("PushRagdoll"))

--//Modules
local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))

--//Values
local PlrsLoadedProperly = {}
local Items = Rs:FindFirstChild("Items"):FindFirstChild("Tools")
local enableTesting = false -- leave true to load your default character and be able to use "Play Here" function of Roblox Studio

local function fallbackCharacter(plr)
	warn("Character fallback activated for: ", plr.Name)
	
	local defaultChar = Rs.GameCharacters.Male.Larry:Clone()
	defaultChar.Name = plr.Name
	defaultChar:SetAttribute("IsCustomCharacter", true)
	defaultChar.Parent = workspace
	defaultChar:PivotTo(workspace.SpawnLocation.CFrame + Vector3.new(math.random(-2, 2), 2.5, math.random(-2, 2)))
	plr.Character = defaultChar
	
	local charConfig = require(defaultChar:FindFirstChildWhichIsA("ModuleScript"))
	
	for itemName, quantity in pairs(charConfig.StarterItems or {}) do
		local itemTemplate = Items:FindFirstChild(itemName)
		if itemTemplate then
			for i = 1, tonumber(quantity) do
				local newTool = itemTemplate:Clone()
				newTool.Parent = plr:FindFirstChild("Backpack") or plr.Backpack
			end
		else
			warn("Item not found: " .. itemName)
		end
	end
	
	for _, v in game.StarterPlayer.StarterCharacterScripts:GetChildren() do
		if not v:IsA("LocalScript") and not v:IsA("ModuleScript") then
			v:Clone().Parent = plr.Character
		end
		if v:IsA("LocalScript") and v.Name == "Animate" then
			v:Clone().Parent = plr.Character
		end
	end
	
	LoadCharScriptsEvent:FireClient(plr)
	
	local Humanoid = defaultChar:WaitForChild("Humanoid")
	local config = require(defaultChar:FindFirstChildWhichIsA("ModuleScript"))
	Humanoid.MaxHealth = config.Health
	Humanoid.Health = Humanoid.MaxHealth
	
	if workspace:FindFirstChild(plr.Name.."_RagDoll") then
		workspace:FindFirstChild(plr.Name.."_RagDoll"):Destroy()
	end
end

local function loadPlrSelectedChar(plr: Player)
	local loading = false
	local loading2 = false
	local loaded = false
	local OtherValues = plr:WaitForChild("OtherValues", 10)
	
	if OtherValues then
		local equipedPlrChar = OtherValues:WaitForChild("EquipedCharacter")
		loading = true
		if equipedPlrChar then
			loading2 = true
			local charTemplate = Rs.GameCharacters:FindFirstChild(equipedPlrChar.Value, true)
			if charTemplate then
				local newChar : Model = charTemplate:Clone()
				newChar.Name = plr.Name
				newChar:SetAttribute("IsCustomCharacter", true)
				newChar.Parent = workspace
				newChar:PivotTo(workspace.SpawnLocation.CFrame + Vector3.new(math.random(-2, 2), 2.5, math.random(-2, 2)))
				
				if not enableTesting or not game:GetService("RunService"):IsStudio() then
					plr.Character = newChar
				end
				
				local charConfig = require(charTemplate:FindFirstChildWhichIsA("ModuleScript"))
				
				for itemName, quantity in pairs(charConfig.StarterItems or {}) do
					local itemTemplate = Items:FindFirstChild(itemName)
					if itemTemplate then
						for i = 1, tonumber(quantity) do
							local newTool = itemTemplate:Clone()
							newTool.Parent = plr:FindFirstChild("Backpack") or plr.Backpack
						end
					else
						warn("Item not found: " .. itemName)
					end
				end
				
				for _, v in game.StarterPlayer.StarterCharacterScripts:GetChildren() do
					if not v:IsA("LocalScript") and not v:IsA("ModuleScript") then
						v:Clone().Parent = plr.Character
					end
					if v:IsA("LocalScript") and v.Name == "Animate" then
						v:Clone().Parent = plr.Character
					end
				end
				LoadCharScriptsEvent:FireClient(plr)
				
				local Humanoid = newChar:WaitForChild("Humanoid") :: Humanoid
				local config = require(newChar:FindFirstChildWhichIsA("ModuleScript"))
				Humanoid.MaxHealth = config.Health
				Humanoid.Health = Humanoid.MaxHealth
				PlrsLoadedProperly[plr.Name] = true
				loaded = true
				
				if workspace:FindFirstChild(plr.Name.."_RagDoll") then
					workspace:FindFirstChild(plr.Name.."_RagDoll"):Destroy()
				end
				
				if enableTesting and game:GetService("RunService"):IsStudio() then
					plr:LoadCharacterAsync()
				end
				--print("loaded from data")
			end
		else
			fallbackCharacter(plr)
		end
	else
		fallbackCharacter(plr)
	end
	
	--[[task.delay(10, function()
		if not PlrsLoadedProperly[plr.Name] then
			warn("Character fallback activated for: ", plr.Name)
			fallbackCharacter(plr)
		end
	end)]]
end

game.Players.PlayerAdded:Connect(function(plr)
	repeat task.wait() until Rs.CanLoadChar.Value == true
	repeat task.wait() until plr:FindFirstChild("OtherValues") and plr.OtherValues:FindFirstChild("EquipedCharacter")
	task.delay(2, loadPlrSelectedChar, plr)
	task.delay(20, function()
		local badge = BadgesModule:FindBadge("Entered The Asylum")
		BadgesModule:GiveBadge(plr, badge.Id)
	end)
end)

LoadCharFunc.OnServerInvoke = function(plr, event)
	if event == "buy" then
		local productID = ShopModule:GetProduct("Revive").ID
		MarketPlaceService:PromptProductPurchase(plr, productID) -- show revive product prompt
	elseif event == "use" then
		local used = false
		
		local PlayerValues = plr:WaitForChild("PlayerValues")
		local OtherValues = plr:WaitForChild("OtherValues")
		if PlayerValues and OtherValues then
			local IsAlive = PlayerValues:FindFirstChild("IsAlive") :: BoolValue
			local FreeRevives = OtherValues:FindFirstChild("FreeRevives") :: IntValue
			if FreeRevives then
				if FreeRevives.Value >= 1 then
					FreeRevives.Value -= 1
					used = true
					IsAlive.Value = true
					loadPlrSelectedChar(plr)
				end
			end
		end
		
		return used
	end
end

loadPlrCharBind.Event:Connect(function(plrToLoad: Player)
	if plrToLoad:IsA("Player") then
		loadPlrSelectedChar(plrToLoad)
	end
end)