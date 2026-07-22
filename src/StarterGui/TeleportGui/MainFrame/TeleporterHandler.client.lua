--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local teleporterEvent = Remotes:WaitForChild("TeleporterEvent")
local warnTeleportEvent = Remotes:WaitForChild("WarnTeleportEvent")

--//Player
local camera = workspace.CurrentCamera

--//UI
local teleportFrame = script.Parent.TeleportFrame
local leaveButton = script.Parent.LeaveButton
local warnText = script.Parent.WarnText

--//Sounds
local clickSound = script.Parent.ClickSound
local selectSound = script.Parent.SelectSound

--//Values
local textDebounce = true
local debounce = false
local onTeleportGui = false
local lastCamPos = nil

--//Setup
teleportFrame.Visible = false

local function ChangeTeleportGui(state: boolean)
	if state then
		onTeleportGui = true
		teleportFrame.Visible = true
		Ts:Create(teleportFrame, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
		task.wait(1)
		if not onTeleportGui then
			textDebounce = true
			return
		end
		Ts:Create(teleportFrame.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position = UDim2.new(0.259, 0, 0.313, 0)}):Play()
	else
		onTeleportGui = false
		Ts:Create(teleportFrame.TextLabel, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {Position = UDim2.new(0.259, 0, 1, 0)}):Play()
		task.wait(1)
		Ts:Create(teleportFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
		task.wait(0.5)
		teleportFrame.Visible = false
	end
end

leaveButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	if debounce and not onTeleportGui then
		debounce = false
		
		leaveButton.Visible = false
		game.Players.LocalPlayer.PlayerGui.MenuGui.Enabled = true
		teleporterEvent:FireServer() --leave from teleporter
		camera.CameraType = Enum.CameraType.Custom
	end
end)

leaveButton.MouseEnter:Connect(function()
	selectSound:Play()
	Ts:Create(leaveButton, TweenInfo.new(0.3), {TextColor3 = Color3.new(1, 0.188235, 0.188235)})
end)

leaveButton.MouseLeave:Connect(function()
	Ts:Create(leaveButton, TweenInfo.new(0.3), {TextColor3 = Color3.new(1, 1, 1)})
end)

teleporterEvent.OnClientEvent:Connect(function(CamChange: boolean, CamPos: CFrame)
	if CamChange == true then
		debounce = true
		leaveButton.Visible = true
		game.Players.LocalPlayer.PlayerGui.MenuGui.Enabled = false
		
		if CamPos then
			camera.CameraType = Enum.CameraType.Scriptable
			Ts:Create(camera, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {CFrame = CamPos}):Play()
		end
	elseif CamChange == "Teleport" then
		ChangeTeleportGui(true)
	elseif CamChange == "errTeleport" then
		camera.CameraType = Enum.CameraType.Custom
		leaveButton.Visible = false
		game.Players.LocalPlayer.PlayerGui.MenuGui.Enabled = true
		debounce = false
		onTeleportGui = false
		ChangeTeleportGui(false)
	end
end)

local function ShowText(text: string)
	local showText = warnText:Clone()
	showText.Parent = script.Parent
	showText.Text = text
	showText.TextTransparency = 1
	
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0.272, 0, 0.812, 0)}):Play()
	
	task.wait(1.5)
	
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(0.272, 0, 0.862, 0)}):Play()
	
	game.Debris:AddItem(showText, 1)
end

warnTeleportEvent.OnClientEvent:Connect(function(Text: string)
	if Text and textDebounce then
		textDebounce = false
		ShowText(Text)
		textDebounce = true
	end
end)