--//Player
local Player = game.Players.LocalPlayer
local character = Player.Character or Player.CharacterAdded:Wait()
local hum = character:WaitForChild("Humanoid") :: Humanoid
local humanoidRootPart = character:WaitForChild("HumanoidRootPart") :: BasePart

--//Sounds
local JumpSoundsFolder = script:FindFirstChild("JumpSounds")

local soundToRemove = humanoidRootPart:WaitForChild("Jumping", 30)
if soundToRemove then
	soundToRemove.Volume = 0
end

hum.Jumping:Connect(function(active)
	if active then
		local randomJumpSound = JumpSoundsFolder:GetChildren()[math.random(1, #JumpSoundsFolder:GetChildren())]
		if randomJumpSound then
			local jumpSoundClone = randomJumpSound:Clone()
			jumpSoundClone.Parent = humanoidRootPart
			jumpSoundClone:Play()
			game.Debris:AddItem(jumpSoundClone, jumpSoundClone.TimeLength + 1)
			wait()
		end
	end
end)