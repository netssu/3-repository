local dollMain = {}

function dollMain.Init(plr, dollCFrame)
	--//Services
	local SoundService = game:GetService("SoundService")
	local Rs = game:GetService("ReplicatedStorage")
	local Ts = game:GetService("TweenService")
	local ServerStorage = game:GetService("ServerStorage")
	
	--//Modules
	local Modules = Rs:WaitForChild("Modules")
	local Utils = Modules:WaitForChild("Utils")
	local SoundPlayer = require(Utils:FindFirstChild("SoundPlayer"))
	local InventoryModules = require(Modules:WaitForChild("InventoryModule"))
	
	local Assets = ServerStorage:FindFirstChild("Assets")
	local CursedVFX = Assets:FindFirstChild("Cursed_VFX")
	local DollModel = script.Parent
	local newCursedDoll = DollModel:Clone()
	
	for _, v in newCursedDoll:GetChildren() do
		if v:IsA("WeldConstraint") or v:IsA("Weld") then
			v:Destroy()
		end
	end
	
	newCursedDoll.CFrame = dollCFrame
	newCursedDoll.Parent = workspace
	newCursedDoll.Anchored = false
	newCursedDoll.CanCollide = true
	newCursedDoll:SetAttribute("Enabled", true)
	InventoryModules.RemoveItem(plr, "Cursed Doll")
	
	repeat task.wait() until newCursedDoll.AssemblyLinearVelocity.Magnitude <= 0.01
	
	newCursedDoll.Anchored = true
	
	SoundPlayer:PlaySound(SoundService.Effects.CursedDollWhisper, newCursedDoll) --apply whisper sound
	for _, v in CursedVFX:GetChildren() do
		local effect = v:Clone()
		effect.Parent = newCursedDoll
		effect.Enabled = true
	end
	
	task.wait(10) -- Doll curse duration
	
	local tween = Ts:Create(newCursedDoll, TweenInfo.new(5), {Transparency = 1})
	newCursedDoll.CanCollide = false
	
	for _, v in newCursedDoll:GetChildren() do
		if v:IsA("ParticleEmitter") then
			v.Enabled = false
		end
	end
	
	tween:Play()
	tween.Completed:Wait()
	newCursedDoll:Destroy()
end

return dollMain