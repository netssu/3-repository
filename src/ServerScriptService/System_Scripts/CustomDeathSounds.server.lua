--//Sounds
local DeathSoundsFolder = script:FindFirstChild("DeathSounds")

game.Players.PlayerAdded:Connect(function(Player)
	Player.CharacterAdded:Connect(function(Char)
		local Hum = Char:WaitForChild("Humanoid") :: Humanoid
		local defaultDeathSound = Char:WaitForChild("HumanoidRootPart"):WaitForChild("Died", 30) :: Sound
		if defaultDeathSound then
			defaultDeathSound:Destroy()
		end
		
		Hum.Died:Connect(function()
			local sound = DeathSoundsFolder:GetChildren()[math.random(1, #DeathSoundsFolder:GetChildren())]:Clone()
			sound.Parent = Char:WaitForChild("HumanoidRootPart")
			sound.Name = "Jumping"
		end)
	end)
end)