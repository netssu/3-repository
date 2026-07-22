function toggleLight(toggle)
	script.Parent.PointLight.Enabled,script.Parent.SpotLight.Enabled = toggle,toggle
end

while task.wait(1) do
	local toNum = Random.new():NextNumber(1,4)
	
	for i = 1,toNum,1 do
		task.wait(.1)
		
		toggleLight(false)
		
		script.Parent.Material = "Glass"
		task.wait(.1)
		
		toggleLight(true)
		
		script.Parent.Material = "Neon"
	end
end