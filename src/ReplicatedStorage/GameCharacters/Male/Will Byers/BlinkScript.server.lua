local Head = script.Parent.Head

function blink()
	local waitTime = math.random(100, 150)
	Head.face.Transparency = 1
	Head.face_SemiBlink.Transparency = 0
	Head.face_Blink.Transparency = 1
	task.wait(waitTime/1000/3)
	Head.face.Transparency = 1
	Head.face_SemiBlink.Transparency = 1
	Head.face_Blink.Transparency = 0
	task.wait(waitTime/1000/3)
	Head.face.Transparency = 1
	Head.face_SemiBlink.Transparency = 0
	Head.face_Blink.Transparency = 1
	task.wait(waitTime/1000/3)
	Head.face.Transparency = 0
	Head.face_SemiBlink.Transparency = 1
	Head.face_Blink.Transparency = 1
end

while true do
	task.wait(math.random(3, 4))
	local state = math.random(0, 1)
	if state == 0 then
		blink()
	else
		blink()
		task.wait(0.2)
		blink()
	end
end