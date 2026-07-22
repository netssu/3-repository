--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Player
local Player = game.Players.LocalPlayer
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Camera = workspace.CurrentCamera

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local MeleeModule = require(ModulesFolder:FindFirstChild("MeleeModule"))

--//Tool
local Tool = script.Parent
--local HoldAnim = Hum:WaitForChild("Animator"):LoadAnimation(Tool.HoldAnim) :: AnimationTrack
local AttackAnimsFolder = Tool.AttackAnims
local AttackSoundsFolder = Tool.AttackSounds
local HitSoundsFolder = Tool.HitSounds
--HoldAnim:AddTag("itemAnim")

--//VFX
local VFXFolder = Rs:WaitForChild("VFX")

--//Config
local attackRange = 5
local damage = MeleeModule:GetPlrDamage(Player) * 1.4 --40% More Damage
local maxHit = 1
local hitboxSize = Vector3.new(3.1, 3, attackRange)
local attackDelay = 0.45
local debounce = true

--[[Tool.Equipped:Connect(function()
	HoldAnim:Play()
end)

Tool.Unequipped:Connect(function()
	HoldAnim:Stop(0.3)
end)]]

Tool.Activated:Connect(function()
	if not debounce then return end
	debounce = false
	
	local origin, direction = Char.HumanoidRootPart.Position, Camera.CFrame.LookVector * attackRange
	local attackAnim = AttackAnimsFolder:GetChildren()[math.random(1, #AttackAnimsFolder:GetChildren())]
	local attackSound = AttackSoundsFolder:GetChildren()[math.random(1, #AttackSoundsFolder:GetChildren())]
	local hitSound = HitSoundsFolder:GetChildren()[math.random(1, #HitSoundsFolder:GetChildren())]
	
	MeleeModule.Attack(Char, origin, direction, attackAnim, attackSound, hitSound, damage, VFXFolder.BloodSplatter, maxHit, hitboxSize)
	
	task.wait(attackDelay)
	
	debounce = true
end)