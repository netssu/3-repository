--//Services
local UIS = game:GetService("UserInputService")

--//UI
local MainFrame = script.Parent

--//Sounds
local ClickSound = script:FindFirstChild("ClickSound")

local function updateUIVisibility(inputType: Enum.UserInputType)
	if inputType == Enum.UserInputType.Touch then
		MainFrame.Visible = true
	elseif inputType == Enum.UserInputType.Keyboard then
		MainFrame.Visible = false
	end
end

local function connectButtonSounds()
	for _, button in pairs(MainFrame:GetChildren()) do
		if button:IsA("ImageButton") or button:IsA("TextButton") then
			button.MouseButton1Click:Connect(function()
				if ClickSound then
					ClickSound:Play()
				end
			end)
		end
	end
end

if UIS.TouchEnabled then
	MainFrame.Visible = true
else
	MainFrame.Visible = false
end

connectButtonSounds()
updateUIVisibility()

UIS.LastInputTypeChanged:Connect(function(inputType)
	updateUIVisibility(inputType)
end)