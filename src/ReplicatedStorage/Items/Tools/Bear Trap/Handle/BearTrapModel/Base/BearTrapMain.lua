local bearTrapMain = {}

function bearTrapMain.Init(plr, trapModelCFrame)
	--//Services
	local RunService = game:GetService("RunService")
	local Rs = game:GetService("ReplicatedStorage")
	local Ts = game:GetService("TweenService")
	local SoundService = game:GetService("SoundService")
	
	--//Modules
	local Modules = Rs:WaitForChild("Modules")
	local Utils = Modules:WaitForChild("Utils")
	local SoundPlayer = require(Utils:FindFirstChild("SoundPlayer"))
	local InventoryModules = require(Modules:WaitForChild("InventoryModule"))
	
	--//Bear Trap Stuff
	local trapModel = script.Parent.Parent
	local newTrapModel = trapModel:Clone()
	
	for _, v in newTrapModel:GetDescendants() do
		if v:IsA("Weld") or v:IsA("WeldConstraint") then
			if v:GetAttribute("ignore") then continue end
			v:Destroy()
		elseif v:IsA("BasePart") then
			v.Anchored = false
			v.CanCollide = true
		end
	end
	
	newTrapModel.Parent = workspace
	newTrapModel:PivotTo(trapModelCFrame)
	InventoryModules.RemoveItem(plr, "Bear Trap")
	
	repeat task.wait() until newTrapModel.PrimaryPart.AssemblyLinearVelocity.Magnitude <= 0.01
	
	for _, v in newTrapModel:GetDescendants() do
		if v:IsA("BasePart") then
			v.Anchored = true
		end
	end
	
	local activatedTrap = false
	local connection: RBXScriptConnection = nil
	local rightTrigger = newTrapModel.RightTrigger
	local leftTrigger = newTrapModel.LeftTrigger
	
	connection = newTrapModel.PrimaryPart.Touched:Connect(function(hit)
		if not hit or not hit.Parent then return end
		if activatedTrap then return end
		
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		if plr then return end -- only work for game enemies
		
		local hum = hit.Parent:FindFirstChildWhichIsA("Humanoid")
		if not hum then return end
		
		local rootPart = hit.Parent:FindFirstChild("HumanoidRootPart") :: BasePart
		if not rootPart then return end
		
		activatedTrap = true
		SoundPlayer:PlaySound(SoundService.Effects.BearTrap, newTrapModel.PrimaryPart)
		rootPart.Anchored = true
		if not hit.Parent:HasTag("Monster") then
			hum.Health *= 0.8 -- -20% health
		end
		
		local rightCloseCFAngle = CFrame.Angles(0, 0, math.rad(-90))
		local leftCloseCFAngle = CFrame.Angles(0, 0, math.rad(90))
		
		local rightCloseCFrame = rightTrigger.CFrame * rightCloseCFAngle
		local leftCloseCFrame = leftTrigger.CFrame * leftCloseCFAngle
		
		local rightTween = Ts:Create(rightTrigger, TweenInfo.new(0.3, Enum.EasingStyle.Back), {CFrame = rightCloseCFrame})
		local leftTween = Ts:Create(leftTrigger, TweenInfo.new(0.3, Enum.EasingStyle.Back), {CFrame = leftCloseCFrame})

		rightTween:Play()
		leftTween:Play()
		
		task.delay(5, function()
			rootPart.Anchored = false
			if connection then
				connection:Disconnect()
				connection = nil
			end
			for _, v in newTrapModel:GetDescendants() do
				if v:IsA("BasePart") then
					Ts:Create(v, TweenInfo.new(0.5), {Transparency = 1}):Play()
					game.Debris:AddItem(v, 5)
				end
			end
		end)
	end)
end

return bearTrapMain