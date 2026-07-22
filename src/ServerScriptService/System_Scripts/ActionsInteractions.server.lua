--//Services
local CollectionService = game:GetService("CollectionService")
local ContentProvider = game:GetService("ContentProvider")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ChangeCamEvent = Remotes:FindFirstChild("ChangeCam")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))

--//Values
local Dummy = Rs:FindFirstChild("Dummy")
local ActionTAG = "ActionZone"
local maxElapsedTime = 50
local ActionZones = {}

local function connectActionFunc(plr: Player, anim: Animation, startPart: BasePart, endPart: BasePart, sound: Sound)
	if not plr or not plr.Character then return end
	if not anim or not startPart or not endPart then return end
	
	local originalChar = plr.Character
	local HRP = originalChar:FindFirstChild("HumanoidRootPart") :: BasePart
	if not HRP then return end
	
	local stopped = false
	local fakeChar = Dummy:Clone()
	local animElapsedTime = 0
	fakeChar.Name = "FakeChar_"..plr.UserId
	fakeChar.Parent = workspace
	
	for _, v in originalChar:GetChildren() do
		if v:IsA("Accessory") then
			v:Clone().Parent = fakeChar
		elseif v:IsA("BodyColors") then
			v:Clone().Parent = fakeChar
		elseif v:IsA("Shirt") then
			v:Clone().Parent = fakeChar
		elseif v:IsA("Pants") then
			v:Clone().Parent = fakeChar
		end
		
		if v.Name == "Head" then
			if v:FindFirstChild("face") then
				fakeChar.Head.face.Texture = v:FindFirstChild("face").Texture
			end
		end
	end
	
	for _, obj in ipairs(fakeChar:GetDescendants()) do
		if obj:IsA("Script") or obj:IsA("LocalScript") or obj:IsA("Tool") then
			obj:Destroy()
		end
	end
	
	fakeChar:SetPrimaryPartCFrame(CFrame.new(startPart.Position, startPart.Position + startPart.CFrame.LookVector))
	
	for _, part in ipairs(originalChar:GetDescendants()) do
		if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
			part.Transparency = 1
		end
	end
	
	local animator = fakeChar:FindFirstChildOfClass("Humanoid"):FindFirstChildOfClass("Animator")
	local track = animator:LoadAnimation(anim)
	HRP.Anchored = true
	
	if sound then
		local snd = sound:Clone()
		snd.Parent = fakeChar:FindFirstChild("HumanoidRootPart") or startPart
		snd:Play()
		game.Debris:AddItem(snd, snd.TimeLength + 2)
	end
	
	repeat task.wait() animElapsedTime += 1 until track.Length > 0 or animElapsedTime >= maxElapsedTime
	
	track:Play()
	ChangeCamEvent:FireClient(plr, true, fakeChar.Name)
	
	local function leaveFromAction()
		if stopped then return end
		stopped = true
		
		for _, part in ipairs(originalChar:GetDescendants()) do
			if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
				local isTool = false
				for _, v in part:GetDescendants() do
					if v:IsA("Tool") then
						isTool = true
					end
				end
				if not isTool then
					part.Transparency = 0
				end
			end
		end
		
		local endPos = Vector3.new(endPart.Position.X, HRP.Position.Y, endPart.Position.Z)
		local lookPos = endPart.CFrame.LookVector
		ChangeCamEvent:FireClient(plr, false)
		HRP.CFrame = CFrame.new(endPos, endPos + lookPos)
		HRP.Anchored = false
		
		fakeChar:Destroy()
	end
	
	track.Stopped:Connect(function()
		leaveFromAction()
	end)
	
	task.delay(track.Length + 1, leaveFromAction)
end

local function checkActionZone(ActionModel: Model)
	if not ActionModel then return end
	
	if ActionModel:IsA("Model") then
		if ActionModel:FindFirstChild("StartPart") and ActionModel:FindFirstChild("EndPart") then
			if ActionModel:FindFirstChild("ActionAnim") and ActionModel:FindFirstChild("ActionAnim"):IsA("Animation") then
				local prox = Instance.new("ProximityPrompt")
				local actionName = ActionModel:FindFirstChild("ActionName")
				local actionAnim = ActionModel:FindFirstChild("ActionAnim")
				local startPart = ActionModel:FindFirstChild("StartPart")
				local endPart = ActionModel:FindFirstChild("EndPart")
				local interactSound = ActionModel:FindFirstChildWhichIsA("Sound")
				
				prox.Parent = ActionModel:FindFirstChild("InteractPart") or ActionModel:FindFirstChild("StartPart")
				prox.MaxActivationDistance = GameConfigModule.InteractDistance
				prox.RequiresLineOfSight = true
				prox.Style = Enum.ProximityPromptStyle.Custom
				prox.ActionText = actionName.Value or "Interact"
				
				ContentProvider:PreloadAsync({actionAnim})
				
				if not ActionZones[ActionModel] then
					ActionZones[ActionModel] = prox.Triggered:Connect(function(plr)
						prox.Enabled = false
						task.spawn(connectActionFunc, plr, actionAnim, startPart, endPart, interactSound)
						task.delay(0.3, function() prox.Enabled = true end)
					end)
				end
			end
		end
	end
end

local function removeActionZone(ActionModel: Model)
	if not ActionModel then return end
	if ActionZones[ActionModel] then
		ActionZones[ActionModel]:Disconnect()
		ActionZones[ActionModel] = nil
	end
end

CollectionService:GetInstanceAddedSignal(ActionTAG):Connect(checkActionZone)
CollectionService:GetInstanceRemovedSignal(ActionTAG):Connect(removeActionZone)

for _, v in CollectionService:GetTagged(ActionTAG) do
	checkActionZone(v)
end