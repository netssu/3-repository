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
local AttackAnimsFolder = Tool.AttackAnims
local AttackSoundsFolder = Tool.AttackSounds
local HitSoundsFolder = Tool.HitSounds

--//Config
local attackRange = 5.25
local damage = 45
local attackDelay = 0.35
local debounce = true

Tool.Activated:Connect(function()
	if not debounce then return end
	debounce = false
	
	local origin, direction = Char.HumanoidRootPart.Position, Camera.CFrame.LookVector * attackRange
	local attackAnim = AttackAnimsFolder:GetChildren()[math.random(1, #AttackAnimsFolder:GetChildren())]
	local attackSound = AttackSoundsFolder:GetChildren()[math.random(1, #AttackSoundsFolder:GetChildren())]
	local hitSound = HitSoundsFolder:GetChildren()[math.random(1, #HitSoundsFolder:GetChildren())]
	
	MeleeModule.Attack(Char, origin, direction, attackAnim, attackSound, hitSound, damage, Tool.BloodHit3)
	
	task.wait(attackDelay)
	
	debounce = true
end)