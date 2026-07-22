local Sounds = script:FindFirstChild("Sounds")
local lastSound = nil
local currentSound = nil
Sounds.Parent = game:GetService("SoundService")

while wait() do
	if #Sounds:GetChildren() > 1 then
		repeat wait()
			currentSound = Sounds:GetChildren()[math.random(1, #Sounds:GetChildren())]
		until currentSound ~= nil and currentSound ~= lastSound
	else
		currentSound = Sounds:GetChildren()[1]
	end
	currentSound:Play()
	currentSound.Ended:Wait()
	lastSound = currentSound
end