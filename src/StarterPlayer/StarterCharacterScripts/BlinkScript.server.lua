local Head = script.Parent.Head :: BasePart
local Hum = script.Parent:FindFirstChildWhichIsA("Humanoid")
local alive = true
local loopConnection: RBXScriptConnection = nil

function blink()
	if not alive then return end
	if not Head:FindFirstChild("face") or not Head:FindFirstChild("face_SemiBlink") or not Head:FindFirstChild("face_blink") then return end
	
	local waitTime = math.random(100, 150)
	Head.face.Transparency = 1
	Head.face_SemiBlink.Transparency = 0
	Head.face_Blink.Transparency = 1
	task.wait(waitTime/1000/3)
	if not alive then return end
	Head.face.Transparency = 1
	Head.face_SemiBlink.Transparency = 1
	Head.face_Blink.Transparency = 0
	task.wait(waitTime/1000/3)
	if not alive then return end
	Head.face.Transparency = 1
	Head.face_SemiBlink.Transparency = 0
	Head.face_Blink.Transparency = 1
	task.wait(waitTime/1000/3)
	if not alive then return end
	Head.face.Transparency = 0
	Head.face_SemiBlink.Transparency = 1
	Head.face_Blink.Transparency = 1
end

Hum.Died:Connect(function()
	alive = false
	if (loopConnection) then
		loopConnection:Disconnect()
		loopConnection = nil
	end
	task.delay(1, function()
		local face1 = Head:FindFirstChild("face")
		local face2 = Head:FindFirstChild("face_SemiBlink")
		local face3 = Head:FindFirstChild("face_Blink")
		if face1 then
			Head.face.Transparency = 1
		end
		if face2 then
			Head.face_SemiBlink.Transparency = 1
		end
		if face3 then
			Head.face_Blink.Transparency = 0
		end
	end)
end)

loopConnection = coroutine.wrap(function()
	while alive do
		task.wait(math.random(3, 4))
		if not alive then break end
		local state = math.random(0, 1)
		if state == 0 then
			blink()
		else
			blink()
			task.wait(0.2)
			if not alive then break end
			blink()
		end
	end
end)()