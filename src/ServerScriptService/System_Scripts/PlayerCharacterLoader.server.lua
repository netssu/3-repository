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

local function resetPlayerAppearance(humanoid: Humanoid)
	local emptyDescription = Instance.new("HumanoidDescription")
	
	emptyDescription.Head = 0
	emptyDescription.Torso = 0
	emptyDescription.LeftArm = 0
	emptyDescription.RightArm = 0
	emptyDescription.LeftLeg = 0
	emptyDescription.RightLeg = 0
	
	emptyDescription.Shirt = 0
	emptyDescription.Pants = 0
	emptyDescription.GraphicTShirt = 0

	humanoid:ApplyDescriptionAsync(emptyDescription)
end

local function applyCustomCharacter(plr: Player, charTemplate: Model)
	plr:LoadCharacterAsync()
	local char = plr.Character or plr.CharacterAdded:Wait()

	local humanoid = char:WaitForChild("Humanoid")

	resetPlayerAppearance(humanoid)
	
	local head = char:WaitForChild("Head")

	-- =========================
	-- BODY COLORS
	-- =========================
	local oldColors = char:FindFirstChildOfClass("BodyColors")
	if oldColors then
		oldColors:Destroy()
	end

	local templateColors = charTemplate:FindFirstChildOfClass("BodyColors")
	if templateColors then
		templateColors:Clone().Parent = char
	end

	-- =========================
	-- ACCESSORYES
	-- =========================
	for _, v in ipairs(char:GetChildren()) do
		if v:IsA("Accessory") then
			v:Destroy()
		end
	end

	for _, v in ipairs(charTemplate:GetChildren()) do
		if v:IsA("Accessory") then
			v:Clone().Parent = char
		end
	end

	-- =========================
	-- FACES
	-- =========================
	for _, v in ipairs(head:GetChildren()) do
		if v:IsA("Decal") then
			v:Destroy()
		end
	end

	local templateHead = charTemplate:FindFirstChild("Head")
	if templateHead then
		for _, v in ipairs(templateHead:GetChildren()) do
			if v:IsA("Decal") then
				v:Clone().Parent = head
			end
		end
	end

	-- =========================
	-- CLOTHES
	-- =========================
	for _, class in ipairs({ "Shirt", "Pants" }) do
		local old = char:FindFirstChildOfClass(class)
		if old then old:Destroy() end

		local fromTemplate = charTemplate:FindFirstChildOfClass(class)
		if fromTemplate then
			fromTemplate:Clone().Parent = char
		end
	end

	-- =========================
	-- CUSTOM ANIMATIONS
	-- =========================
	local oldAnimate = char:FindFirstChild("Animate")
	if oldAnimate then
		oldAnimate:Destroy()
	end

	local templateAnimate = charTemplate:FindFirstChild("Animate")
	if not templateAnimate then
		templateAnimate = game.StarterPlayer.StarterCharacterScripts:FindFirstChild("Animate")
	end

	if templateAnimate then
		templateAnimate:Clone().Parent = char
	end

	if not humanoid:FindFirstChildOfClass("Animator") then
		Instance.new("Animator", humanoid)
	end

	-- =========================
	-- STATS
	-- =========================
	local config = require(charTemplate:FindFirstChildWhichIsA("ModuleScript"))
	humanoid.MaxHealth = config.Health
	humanoid.Health = humanoid.MaxHealth

	char:SetAttribute("IsCustomCharacter", true)
	workspace.CurrentCamera.CameraSubject = humanoid

	LoadCharScriptsEvent:FireClient(plr)
end

local function fallbackCharacter(plr)
	warn("Fallback character for:", plr.Name)
	
	local defaultTemplate = Rs.GameCharacters.Male.Larry
	if not defaultTemplate then
		plr:LoadCharacter()
		return
	end
	
	applyCustomCharacter(plr, defaultTemplate)
end

local function loadPlrSelectedChar(plr: Player)
	local OtherValues = plr:WaitForChild("OtherValues", 10)
	if not OtherValues then
		warn("OtherValues missing, fallback")
		return
	end
	
	local equipedPlrChar = OtherValues:WaitForChild("EquipedCharacter")
	if not equipedPlrChar then
		warn("EquipedCharacter missing")
		return
	end
	
	local charTemplate = Rs.GameCharacters:FindFirstChild(equipedPlrChar.Value, true)
	if not charTemplate then
		warn("Character template not found:", equipedPlrChar.Value)
		return
	end
	
	applyCustomCharacter(plr, charTemplate)
	
	--// Starter items
	local charConfig = require(charTemplate:FindFirstChildWhichIsA("ModuleScript"))
	for itemName, quantity in pairs(charConfig.StarterItems or {}) do
		local itemTemplate = Items:FindFirstChild(itemName)
		if itemTemplate then
			for i = 1, quantity do
				itemTemplate:Clone().Parent = plr.Backpack
			end
		end
	end
	
	--// Remove old ragdoll character
	local rag = workspace:FindFirstChild(plr.Name .. "_RagDoll")
	if rag then
		rag:Destroy()
	end
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