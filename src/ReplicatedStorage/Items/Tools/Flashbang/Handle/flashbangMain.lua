local flashbangMain = {}

--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Tool
local Handle = script.Parent

--//Animations
local throwAnim = Handle.ThrowAnim
local enemyStunAnim = Handle.EnemyStunAnim

--//Modules
local Modules = Rs:WaitForChild("Modules")
local InventoryModule = require(Modules:WaitForChild("InventoryModule"))

--//Config
local range = 65

function flashbangMain.Init(plr: Player, targetPos: Vector3)
	local flashbangModel = Handle
	flashbangModel.Anchored = false
	
	local direction = (targetPos - flashbangModel.Position).Unit
	local velocity = direction * 75
	
	flashbangModel.CFrame = CFrame.lookAt(flashbangModel.Position, targetPos)
	flashbangModel.AssemblyLinearVelocity = velocity
	flashbangModel.throwSound:Play()
	
	flashbangModel.Parent = workspace
	flashbangModel:SetNetworkOwner(plr)
	flashbangModel.Flashbang.CanCollide = true
	
	InventoryModule.RemoveItem(plr, "Flashbang")
	
	local function playSound(sound: Sound)
		local snd = sound:Clone()
		snd.Parent = sound.Parent
		snd:Play()
		game.Debris:AddItem(snd, 5)
	end
	
	local hitSndDebounce = false
	local cTouch: RBXScriptConnection = nil
	
	cTouch = flashbangModel.Flashbang.Touched:Connect(function(hit)
		if not hitSndDebounce then
			hitSndDebounce = true
			playSound(flashbangModel.hitSound)
			task.wait(math.random(10, 170) / 1000)
			hitSndDebounce = false
		end
	end)
	
	--//Play the throw animation
	local char = plr.Character
	local hum = char and char:FindFirstChild("Humanoid") :: Humanoid
	local animator = hum and hum:FindFirstChildWhichIsA("Animator")
	if animator then
		local anim = animator:LoadAnimation(throwAnim)
		anim.Priority = Enum.AnimationPriority.Action4
		anim:Play()
	end
	
	task.wait(3)
	
	--//Flashbang explosion
	local light = Instance.new("PointLight")
	light.Color = Color3.new(1, 1, 1)
	light.Brightness = 100
	light.Range = 100
	light.Parent = flashbangModel
	
	local tween = Ts:Create(light, TweenInfo.new(0.25), {Brightness = 0, Range = 8})
	tween:Play()
	
	flashbangModel.explodeSound:Play()
	cTouch:Disconnect()
	
	local explosionArea = Instance.new("Part")
	explosionArea.Parent = workspace
	explosionArea.Anchored = true
	explosionArea.CanCollide = false
	explosionArea.Transparency = 1
	explosionArea.Size = Vector3.new(range, range, range)
	explosionArea.CFrame = flashbangModel.CFrame
	
	explosionArea.Touched:Connect(function(hit)
		if not hit or not hit.Parent then return end
		
		local hum = hit.Parent:FindFirstChild("Humanoid") :: Humanoid
		if not hum or hum:GetAttribute("Monster") == true then return end
		
		local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
		if plr then
			--try to stun the player (event)
			return
		end
		
		local enemyRoot = hit.Parent:FindFirstChild("HumanoidRootPart") :: Part
		if not enemyRoot then return end
		
		enemyRoot.Anchored = true
		
		local animator = hum:FindFirstChildWhichIsA("Animator")
		local anim = nil :: Animation
		local randomTime = math.random(30, 50) / 10
		
		if animator then
			anim = animator:LoadAnimation(enemyStunAnim)
			anim.Priority = Enum.AnimationPriority.Action4
			
			for i, v in animator:GetPlayingAnimationTracks() do
				v:Stop()
			end
			
			anim:Play()
			anim:AdjustSpeed(math.random(11, 18)/10)
			
			local tries = 0
			repeat task.wait()
				tries += 1
			until anim.IsPlaying or tries >= 10
			
			task.delay(randomTime, function()
				anim:Stop()
				enemyRoot.Anchored = false
			end)
		else
			task.delay(randomTime, function()
				enemyRoot.Anchored = false
			end)
		end
	end)
	
	task.delay(0.2, function()
		explosionArea:Destroy()
	end)
	
	for i, v in flashbangModel:GetDescendants() do
		if v:IsA("BasePart") then
			v.Transparency = 1
			v.Anchored = true
			v.CanCollide = false
		end
	end
	
	task.delay(5, function()
		flashbangModel:Destroy()
	end)
end

return flashbangMain