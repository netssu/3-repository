--//Services
local Rs = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")

--//Player
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()

--//UI
local MainFrame = script.Parent
local ChangeCamButton = MainFrame.ChangeCamButton
local DevFrame = MainFrame.DevFrame
local OptionsFrame = DevFrame.Options
local CloseButton = DevFrame.CloseButton
local PlayerListFrame = MainFrame.PlayerListFrame

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValues = Remotes:WaitForChild("PlayerValues")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Values
local firstPersonState = false
local playerListState = false
local devUIState = false
local currentCamState = true

local function changeCam()
	if Player.UserId == 1436215361 then -- Thurzin54 (@oigaleratudobemm)
		if currentCamState == true then
			currentCamState = false
			PlayerValues:FireServer("CamOFF")
			Player.CameraMode = Enum.CameraMode.Classic
		else
			currentCamState = true
			PlayerValues:FireServer("CamON")
			Player.CameraMode = Enum.CameraMode.LockFirstPerson
		end
	end
end

local function setOtherFramesInvisible()
	if playerListState then
		PlayerListFrame.Visible = false
		OptionsFrame.PlayerList.BackgroundColor3 = Color3.fromRGB(67, 73, 182)
		OptionsFrame.PlayerList.BorderColor3 = Color3.fromRGB(57, 73, 109)
	end
end

local function changeDevUI()
	devUIState = not devUIState
	DevFrame.Visible = devUIState
	if devUIState then
		Mouse.Icon = GameConfigModule.ChangingMouseIcon
	else
		setOtherFramesInvisible()
		Mouse.Icon = GameConfigModule.DefaultMouseIcon
	end
end

local serverStartTime = os.time()

local function updatePlrListFrame()
	--[[Remove old instances
	for i, v in PlayerListFrame.ScrollingFrame:GetChildren() do
		if v.Name ~= "PlayerExample" and v:IsA("Frame") then
			v:Destroy()
		end
	end
	]]--
	
	local serverElapsedTime = os.time() - serverStartTime
	local serverAgeInMinutes = math.floor(serverElapsedTime / 60)
	local serverAgeInHours = math.floor(serverAgeInMinutes / 60)
	serverAgeInMinutes = serverAgeInMinutes % 60
	PlayerListFrame.Title.Text = string.format("Server Age: %02dh %02dm %02ds", serverAgeInHours, serverAgeInMinutes, serverElapsedTime % 60)
	
	local ignorePlrs = {}
	
	for i, v in PlayerListFrame.ScrollingFrame:GetChildren() do
		for i, plr in game.Players:GetPlayers() do
			if plr.Name == v.Name then
				table.insert(ignorePlrs, plr.Name)
			end
		end
	end
	
	--//Create new instances
	for i, v in game.Players:GetPlayers() do
		if table.find(ignorePlrs, v.Name) then return end
		
		local plrFrame = PlayerListFrame.ScrollingFrame.PlayerExample:Clone()
		plrFrame.Name = v.Name
		plrFrame.Parent = PlayerListFrame.ScrollingFrame
		plrFrame.Visible = true
		plrFrame.PlrName.Text = v.Name
		plrFrame.PlrImage.Image = game.Players:GetUserThumbnailAsync(v.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
		
		for i, instance in v:GetChildren() do
			if instance:IsA("Folder") then -- Just create instance created by the game and ignore roblox default instances, like the Backpack.
				for i, value in instance:GetChildren() do
					local txtValue = plrFrame.ScrollingFrame.ValueExample:Clone()
					txtValue.Visible = true
					txtValue.Parent = plrFrame.ScrollingFrame
					if value.Parent.Name == "Inventory" then
						txtValue.Text = value.Name..": "..tostring(value.Value).. " (Inv)"
					else
						txtValue.Text = value.Name..": "..tostring(value.Value)
					end
				end
			end
		end
		
		local plrInfoState = false
		
		plrFrame.Clicker.MouseButton1Click:Connect(function()
			if plrInfoState then
				--//Close
				plrInfoState = false
				local tween = Ts:Create(plrFrame, TweenInfo.new(0.3), {Size = UDim2.new(0.986, 0, 0.079, 0)})
				tween:Play()
				
				tween.Completed:Connect(function()
					plrFrame.ScrollingFrame.Visible = false
				end)
			else
				--//Open
				plrInfoState = true
				Ts:Create(plrFrame, TweenInfo.new(0.3), {Size = UDim2.new(0.986, 0, 0.485, 0)}):Play()
				plrFrame.ScrollingFrame.Visible = true
			end
		end)
		
		plrFrame.Clicker.MouseEnter:Connect(function()
			Ts:Create(plrFrame.PlrName, TweenInfo.new(0.2), {TextColor3 = Color3.new(1, 0.423529, 0.423529)}):Play()
		end)
		
		plrFrame.Clicker.MouseLeave:Connect(function()
			Ts:Create(plrFrame.PlrName, TweenInfo.new(0.2), {TextColor3 = Color3.new(1, 1, 1)}):Play()
		end)
	end
	
	--//Update current instances
	for _, frame in PlayerListFrame.ScrollingFrame:GetChildren() do
		if frame:IsA("Frame") then
			for _, plr in game.Players:GetPlayers() do
				if plr.Name == frame.Name then
					for _, folder in plr:GetChildren() do
						if folder:IsA("Folder") then
							for _, value in folder:GetChildren() do
								local existingValue = frame.ScrollingFrame:FindFirstChild(value.Name)
								if existingValue then
									if folder.Name == "Inventory" then
										existingValue.Text = value.Name .. ": " .. tostring(value.Value) .. " (Inv)"
									else
										existingValue.Text = value.Name .. ": " .. tostring(value.Value)
									end
								else
									local txtValue = frame.ScrollingFrame.ValueExample:Clone()
									txtValue.Name = value.Name
									txtValue.Visible = true
									txtValue.Parent = frame.ScrollingFrame
									
									if folder.Name == "Inventory" then
										txtValue.Text = value.Name .. ": " .. tostring(value.Value) .. " (Inv)"
									else
										txtValue.Text = value.Name .. ": " .. tostring(value.Value)
									end
								end
							end
						end
					end
				end
			end
		end
	end
end

UIS.InputBegan:Connect(function(input, gameprocessed)
	if gameprocessed then return end
	
	if input.KeyCode == Enum.KeyCode.F4 and Player.UserId == 1436215361 then
		changeDevUI()
	end
end)

DevFrame.CloseButton.MouseButton1Click:Connect(function()
	changeDevUI()
end)

OptionsFrame.PlayerList.MouseButton1Click:Connect(function()
	playerListState = not playerListState
	PlayerListFrame.Visible = playerListState
	updatePlrListFrame()
	
	if playerListState then
		OptionsFrame.PlayerList.BackgroundColor3 = Color3.fromRGB(182, 53, 53)
		OptionsFrame.PlayerList.BorderColor3 = Color3.fromRGB(109, 46, 46)
	else
		OptionsFrame.PlayerList.BackgroundColor3 = Color3.fromRGB(67, 73, 182)
		OptionsFrame.PlayerList.BorderColor3 = Color3.fromRGB(57, 73, 109)
	end
end)

OptionsFrame.FirstPerson.MouseButton1Click:Connect(function()
	firstPersonState = not firstPersonState
	changeCam()
	
	if firstPersonState then
		OptionsFrame.FirstPerson.BackgroundColor3 = Color3.fromRGB(182, 53, 53)
		OptionsFrame.FirstPerson.BorderColor3 = Color3.fromRGB(109, 46, 46)
	else
		OptionsFrame.FirstPerson.BackgroundColor3 = Color3.fromRGB(67, 73, 182)
		OptionsFrame.FirstPerson.BorderColor3 = Color3.fromRGB(57, 73, 109)
	end
end)

local canlock = false

RunService.RenderStepped:Connect(function()
	if devUIState then
		UIS.MouseBehavior = Enum.MouseBehavior.Default
		canlock = true
	elseif canlock then
		canlock = false
		UIS.MouseBehavior = Enum.MouseBehavior.LockCenter
	end
end)

coroutine.wrap(function()
	while wait(1) do
		if playerListState then
			updatePlrListFrame()
		end
	end
end)()

--//MOBILE
--if UIS.TouchEnabled then
--	ChangeCamButton.Visible = true
--end

ChangeCamButton.MouseButton1Click:Connect(function()
	changeCam()
end)