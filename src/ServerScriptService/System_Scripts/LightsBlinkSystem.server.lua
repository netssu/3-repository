--//Blinking Lights Stuff
local Map = workspace:FindFirstChild("Map")
local BlinkLights = Map:FindFirstChild("BlinkingLights")

--//Values
local LightsBlink = {}

local function loadLightsBlink()
	for i, v: Model in ipairs(LightsBlink) do
		if not v:HasTag("MarkedBlinkLight") then
			v:AddTag("MarkedBlinkLight")
			local BasePart = v.PrimaryPart
			local BlinkSound = v:FindFirstChildWhichIsA("Sound")
			local Blinking = v:FindFirstChild("Blinking") :: BoolValue
			local Working = v:FindFirstChild("Working") :: BoolValue
			local LightPart = v:FindFirstChild("LightPart") :: BasePart
			
			if not LightPart then return end
			
			local DefaultLightPartColor = LightPart.Color
			local DefaultLightPartMaterial = LightPart.Material
			
			local lights = {}
			for i, light in v:GetDescendants() do
				if light:IsA("SpotLight") or light:IsA("PointLight") or light:IsA("SurfaceLight") then
					table.insert(lights, light)
				end
			end
			
			local function playSound(sound: Sound)
				local snd = sound:Clone()
				snd.Parent = BasePart
				snd:Play()
				game.Debris:AddItem(snd, snd.TimeLength + 1)
			end
			
			local function changeLight(state: boolean)
				if state then
					LightPart.Material = DefaultLightPartMaterial
					LightPart.Color = DefaultLightPartColor
				else
					LightPart.Color = Color3.new(0.333333, 0.345098, 0.356863)
					LightPart.Material = Enum.Material.Glacier
					for i, light in ipairs(lights) do
						light.Enabled = false
					end
				end
			end
			
			coroutine.wrap(function()
				while true do
					task.wait(0.1)
					if Blinking.Value and Working.Value then
						for i, light in ipairs(lights) do
							light.Enabled = true
						end
						changeLight(true)
						task.wait(math.random(0.5, 1))
						playSound(BlinkSound)
						changeLight(false)
					elseif not Working.Value then
						changeLight(false)
					end
				end
			end)()
		end
	end
end

BlinkLights.ChildAdded:Connect(function(child)
	if child:IsA("Model") and child:HasTag("BlinkLight") and child.PrimaryPart then
		table.insert(LightsBlink, child)
	end
	loadLightsBlink()
end)

task.wait(3) -- Delay to don't bug

for i, v in BlinkLights:GetChildren() do
	if v:IsA("Model") and v:HasTag("BlinkLight") and v.PrimaryPart then
		table.insert(LightsBlink, v)
	end
end

loadLightsBlink()