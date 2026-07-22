local BackgroundMusic = {}

function BackgroundMusic.Init()
	local Sounds = script:FindFirstChild("Sounds")
	local lastSound = nil
	local currentSound = nil
	Sounds.Parent = game:GetService("SoundService")
	
	coroutine.wrap(function()
		while task.wait() do
			if #Sounds:GetChildren() > 1 then
				repeat task.wait()
					currentSound = Sounds:GetChildren()[math.random(1, #Sounds:GetChildren())]
				until currentSound ~= nil and currentSound ~= lastSound
			else
				currentSound = Sounds:GetChildren()[1]
			end
			currentSound:Play()
			currentSound.Ended:Wait()
			lastSound = currentSound
		end
	end)()
	
	local ParallelSounds = script:FindFirstChild("ParallelSounds")
	local parallelSound = nil :: Sound
	local lastParallelSound = nil
	ParallelSounds.Parent = game:GetService("SoundService")
	
	--//Parallel sounds
	--[[
	coroutine.wrap(function()
		while task.wait() do
			if #ParallelSounds:GetChildren() > 1 then
				repeat task.wait()
					parallelSound = ParallelSounds:GetChildren()[math.random(1, #ParallelSounds:GetChildren())]
				until parallelSound ~= nil and parallelSound ~= lastParallelSound
			else
				parallelSound = ParallelSounds:GetChildren()[1]
			end
			if parallelSound then
				parallelSound:Play()
				parallelSound.Ended:Wait()
				lastParallelSound = parallelSound
			end
		end
	end)()]]
end

return BackgroundMusic