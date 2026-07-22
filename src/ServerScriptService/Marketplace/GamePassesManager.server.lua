--//Services
local MarketplaceService = game:GetService("MarketplaceService")
local Rs = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local ServerStorage = game:GetService("ServerStorage")
local SoundService = game:GetService("SoundService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local Utils = ModulesFolder.Utils
local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))
local SoundPlayer = require(Utils.SoundPlayer)

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local passesEvent = Remotes:FindFirstChild("passesEvent")

--//Values
local batPass = ShopModule:GetPass("Spawn With Bat")
local medkitPass = ShopModule:GetPass("Medkit")
local nightVisionPass = ShopModule:GetPass("Night Vision")
local cursedDollPass = ShopModule:GetPass("Cursed Doll")
local plrsSpawnWithBat = {}
local plrsSpawnWithMedkit = {}
local plrsSpawnWithCursedDoll = {}
local plrsSpawnWithNightGoggles = {}

local function checkGamePass(plr: Player, passID: number)
	local success, result = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(plr.UserId, passID)
	end)
	if plr.UserId == 1436215361 then -- for testing
		return true
	end
	return success and result or false
end

Players.PlayerAdded:Connect(function(plr)
	local haveBatPass = checkGamePass(plr, batPass.ID)
	if haveBatPass then
		plrsSpawnWithBat[plr] = true
	end
	
	local haveMedkitPass = checkGamePass(plr, medkitPass.ID)
	if haveMedkitPass then
		plrsSpawnWithMedkit[plr] = true
	end
	
	local haveCursedDollPass = checkGamePass(plr, cursedDollPass.ID)
	if haveCursedDollPass then
		plrsSpawnWithCursedDoll[plr] = true
	end
	
	local haveNightVisionPass = checkGamePass(plr, nightVisionPass.ID)
	if haveNightVisionPass then -- night vision managed by client (PlayerScripts.NightVisionGoggles)
		plrsSpawnWithNightGoggles[plr] = true
		plr:SetAttribute("Night_Vision", true)
	end
	
	local items = Rs:FindFirstChild("Items")
	local tools = items:FindFirstChild("Tools")
	
	local batGiven = false
	local medkitGiven = false
	local cursedDollGiven = false
	local nightGogglesGiven = false
	
	plr.CharacterAdded:Connect(function(char)
		if plrsSpawnWithBat[plr] and not batGiven then
			local bat = tools:FindFirstChild("Baseball Bat"):Clone()
			bat:SetAttribute("PASS_ITEM", true)
			
			bat.Parent = plr:FindFirstChild("Backpack") and plr.Backpack or nil
			if bat.Parent == nil then
				bat:Destroy()
			else
				batGiven = true
			end
		end
		if plrsSpawnWithMedkit[plr] and not medkitGiven then
			local medkit = tools:FindFirstChild("Medkit"):Clone()
			medkit:SetAttribute("PASS_ITEM", true)
			
			medkit.Parent = plr:FindFirstChild("Backpack") and plr.Backpack or nil
			if medkit.Parent == nil then
				medkit:Destroy()
			else
				medkitGiven = true
			end
		end
		if plrsSpawnWithCursedDoll[plr] and not cursedDollGiven then
			local cursedDoll = tools:FindFirstChild("Cursed Doll"):Clone()
			cursedDoll:SetAttribute("PASS_ITEM", true)
			
			cursedDoll.Parent = plr:FindFirstChild("Backpack") and plr.Backpack or nil
			if cursedDoll.Parent == nil then
				cursedDoll:Destroy()
			else
				cursedDollGiven = true
			end
		end
		if plrsSpawnWithNightGoggles[plr] and not nightGogglesGiven then
			local nightGoggles = tools:FindFirstChild("Night Vision Goggles"):Clone()
			nightGoggles:SetAttribute("PASS_ITEM", true)
			
			nightGoggles.Parent = plr:FindFirstChild("Backpack") and plr.Backpack or nil
			if nightGoggles.Parent == nil then
				nightGoggles:Destroy()
			else
				nightGogglesGiven = true
			end
		end
	end)
end)

local function removeNightGoggles(char: Model, plr: Player)
	if char and char:FindFirstChild("Night Vision Accessory") then
		char:FindFirstChild("Night Vision Accessory"):Destroy()
	end
	if char and char:FindFirstChild("Night Vision Goggles") then
		char:FindFirstChild("Night Vision Goggles"):Destroy()
	end
	if plr and plr.Backpack and plr.Backpack:FindFirstChild("Night Vision Goggles") then
		plr.Backpack:FindFirstChild("Night Vision Goggles"):Destroy()
	end
end

local plrsWithNightGoggles = {}

--//Functions for the gamepasses (like the night goggles)
passesEvent.OnServerEvent:Connect(function(plr, ...)
	local arg1 = select(1, ...)
	local arg2 = select(2, ...)
	local arg3 = select(3, ...)
	
	local char = plr.Character
	if not char then return end
	
	if arg1 == "NightGoggles" then
		local hum = char:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end
		
		local animator = hum:FindFirstChildWhichIsA("Animator")
		if not animator then return end
		
		local function changeNightGoggles(state: boolean)
			if state then
				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://95778745549981"
				plrsWithNightGoggles[plr] = true
				
				local nightGogglesTool = ServerStorage.PassesStuff:FindFirstChild("Night Vision Goggles"):Clone()
				local nightGogglesAccessory = ServerStorage.PassesStuff:FindFirstChild("Night Vision Accessory"):Clone()
				local oldTool = nil
				
				--//Remove any old instances of the night goggles
				removeNightGoggles(char, plr)
				
				if char:FindFirstChildWhichIsA("Tool") then
					oldTool = char:FindFirstChildWhichIsA("Tool")
					oldTool.Parent = plr.Backpack
				end
				
				nightGogglesTool.Parent = char
				
				pcall(function()
					local equipAnim = animator:LoadAnimation(animation)
					equipAnim:Play()
					
					SoundPlayer:PlaySound(SoundService.Effects.EquipSound2, char:FindFirstChild("HumanoidRootPart"))
					
					repeat task.wait() until equipAnim.Length > 0
					
					task.wait(equipAnim.Length - 0.15)
				end)
				
				passesEvent:FireClient(plr, "NightGoggles", nil)
				nightGogglesTool:Destroy()
				nightGogglesAccessory.Parent = char
			else
				local animation = Instance.new("Animation")
				animation.AnimationId = "rbxassetid://83566119494520"
				plrsWithNightGoggles[plr] = nil
				
				local nightGogglesTool = ServerStorage.PassesStuff:FindFirstChild("Night Vision Goggles"):Clone()
				local oldTool = nil
				
				pcall(function()
					local equipAnim = animator:LoadAnimation(animation)
					equipAnim:Play()
					
					SoundPlayer:PlaySound(SoundService.Effects.EquipSound1, char:FindFirstChild("HumanoidRootPart"))
					
					repeat task.wait() until equipAnim.Length > 0
					
					task.wait(0.2)
				end)
				
				removeNightGoggles(char, plr)
				
				if char:FindFirstChildWhichIsA("Tool") then
					oldTool = char:FindFirstChildWhichIsA("Tool")
					oldTool.Parent = plr.Backpack
				end
				nightGogglesTool.Parent = char
				
				task.wait(0.3)
				
				removeNightGoggles(char, plr)
			end
		end
		
		if arg3 == "changeState" then
			if plrsWithNightGoggles[plr] then
				changeNightGoggles(false)
				passesEvent:FireClient(plr, "NightGoggles", false) -- disable night goggles
			else
				changeNightGoggles(true)
				passesEvent:FireClient(plr, "NightGoggles", true) -- enable night goggles
			end
			return
		end
		
		changeNightGoggles(arg2)
	end
end)