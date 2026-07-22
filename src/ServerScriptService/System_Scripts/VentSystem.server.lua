--//Services
local Rs = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local GameConfig = require(Modules:FindFirstChild("GameConfigModule"))
local SoundPlayer = require(Modules.Utils:FindFirstChild("SoundPlayer"))

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local CamAnimEvent = Remotes:FindFirstChild("CamAnim")

--//Values
local TAG = "VentModel"
local ventModels = {}

--//Vents Stuff
local VentEffect = script.VentEffect

local function addVentModel(obj: Instance)
	if ventModels[obj] then return end -- already exists
	
	local InteractPart = obj:FindFirstChild("InteractPart") :: BasePart
	local LeavePos = obj:FindFirstChild("LeavePos") :: BasePart
	local JoinPos = obj:FindFirstChild("JoinPos") :: BasePart
	
	if not InteractPart or not LeavePos or not JoinPos then return end
	
	local prox = Instance.new("ProximityPrompt", InteractPart)
	prox.MaxActivationDistance = GameConfig.InteractDistance
	prox.ActionText = "Interact"
	prox.ObjectText = "Vent"
	prox.Style = Enum.ProximityPromptStyle.Custom
	prox.RequiresLineOfSight = false
	prox.HoldDuration = 0.1
	
	local plrOnVent: Player = nil
	local plrDetections: {RBXScriptConnection} = {}
	local debounce = true
	
	local function clearPlrDetections()
		for _, v in plrDetections do
			v:Disconnect()
			v = nil
		end
	end
	
	ventModels[obj] = prox.Triggered:Connect(function(plr)
		if not debounce then return end
		debounce = false
		
		if plrOnVent == plr then -- leave the current player from vent
			plrOnVent = nil
			local char = plr.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
				local newPos = Vector3.new(LeavePos.Position.X, hrp.Position.Y + 1, LeavePos.Position.Z)
				
				local lookVector = LeavePos.CFrame.LookVector
				lookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
				
				--//Make the player camera back to normal
				CamAnimEvent:FireClient(plr, "NormalCam")
				
				local newCF = CFrame.new(newPos, lookVector)
				hrp.Anchored = true
				hrp.CFrame = newCF
				hrp.Anchored = false
				
				SoundPlayer:PlaySound(VentEffect, InteractPart)
				
				--//Stop the idle vent animation
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				local animator = hum and hum:FindFirstChildWhichIsA("Animator")
				if animator then
					for _, v in animator:GetPlayingAnimationTracks() do
						if v:HasTag("IDLE_VENT") then
							v:Stop()
						end
					end
				end
				
				if hum then hum.WalkSpeed = GameConfig.PlayerDefaultSpeed end
				
				local plrValues = plr:FindFirstChild("PlayerValues")
				local OnSafe = plrValues and plrValues:FindFirstChild("OnSafe") :: BoolValue
				if OnSafe then OnSafe.Value = false end
				
				clearPlrDetections()
				
				task.wait(0.3)
			end
		elseif plrOnVent == nil then -- join new player on vent if free
			local char = plr.Character
			if char and char:FindFirstChild("HumanoidRootPart") then
				plrOnVent = plr
				local hrp = char:FindFirstChild("HumanoidRootPart") :: BasePart
				local newPos = JoinPos.Position
				
				local lookVector = JoinPos.CFrame.LookVector
				lookVector = Vector3.new(lookVector.X, 0, lookVector.Z).Unit
				
				local camCF = JoinPos.CFrame + Vector3.new(0, 0.5, 0)
				
				plr:SetAttribute("Hide", true)
				
				--//Make cam animation for player
				CamAnimEvent:FireClient(plr, "MakeAnim", camCF)
				
				local newCF = CFrame.new(newPos, lookVector * 10)
				hrp.Anchored = true
				hrp.CFrame = newCF
				
				local plrValues = plr:FindFirstChild("PlayerValues")
				local OnSafe = plrValues and plrValues:FindFirstChild("OnSafe") :: BoolValue
				if OnSafe then OnSafe.Value = true end
				
				SoundPlayer:PlaySound(VentEffect, InteractPart)
				
				--//Play idle vent animation
				local hum = char:FindFirstChildWhichIsA("Humanoid")
				local animator = hum and hum:FindFirstChildWhichIsA("Animator")
				if animator then
					local idleAnim = animator:LoadAnimation(script.VentIdle)
					idleAnim:AddTag("IDLE_VENT")
					idleAnim:Play()
					idleAnim.Looped = true
					idleAnim.Priority = Enum.AnimationPriority.Action4
				end
				
				if hum then hum.WalkSpeed = 0 end
				
				plrDetections = {
					plr.AncestryChanged:Connect(function(_, parent)
						if not parent or parent ~= game:GetService("Players") then
							if plrOnVent == plr then
								plrOnVent = nil
							end
							clearPlrDetections()
						end
					end),
					
					hum.Died:Connect(function()
						if plrOnVent == plr then
							plrOnVent = nil
						end
						clearPlrDetections()
					end)
				}
				
				task.wait(0.3)
			end
		end
		
		debounce = true
	end)
end

local function removeVentModel(obj: Instance)
	if ventModels[obj] then
		ventModels[obj]:Disconnect()
		ventModels[obj] = nil
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(addVentModel)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(removeVentModel)

for _, v in CollectionService:GetTagged(TAG) do
	addVentModel(v)
end