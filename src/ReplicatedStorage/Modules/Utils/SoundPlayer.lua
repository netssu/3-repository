local SoundPlayer = {}

function SoundPlayer:PlaySound(sound: Sound, parent: Instance?)
	if not sound then return end
	local snd = sound:Clone()
	snd.Parent = parent or game:GetService("SoundService")
	snd:Play()
	snd.Ended:Connect(function()
		snd:Destroy()
	end)
end

return SoundPlayer