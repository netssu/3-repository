--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local ContentProvider = game:GetService("ContentProvider")
local CollectionService = game:GetService("CollectionService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlrDialog = Remotes:WaitForChild("PlrDialog")

--//Interact Stuff
local Map = workspace:WaitForChild("Map")
local InteractParts = Map:WaitForChild("InteractParts")
local HintParts = InteractParts:WaitForChild("HintParts")

--//UI
local MainFrame = script.Parent
local DialogFrame = MainFrame.DialogFrame
local DialogText_Example = DialogFrame.DialogText_Example
local HintFrame = MainFrame.HintFrame
local HintTitle = HintFrame.InfoTitle
local HintDesc = HintFrame.InfoText
local HintClose = HintFrame.CloseText

--//Values
local TAG = "HintPart" -- tag of the hint parts
local partsHints = {}
local showedObjectivesMouseHint = false

ContentProvider:PreloadAsync({HintFrame.BgImage.Image})

-- Play a specified sound.
local function playSound(sound: Sound)
	local snd = sound:Clone()
	snd.Parent = MainFrame
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 5)
end

-- Show a dialog text on player screen.
local function showDialog(text: string, duration: number, sound: boolean)
	local dialogText = DialogText_Example:Clone()
	dialogText.Size = UDim2.new(0, 0)
	dialogText.Text = text
	dialogText.Visible = true
	dialogText.Parent = DialogFrame
	
	if sound then
		playSound(script:FindFirstChild("DialogSound"))
	else
		playSound(script:FindFirstChild("DialogSound2"))
	end
	
	local function unshowText()
		Ts:Create(dialogText, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
		game.Debris:AddItem(dialogText, 1)
	end
	
	Ts:Create(dialogText, TweenInfo.new(0.2), {Size = DialogText_Example.Size, TextTransparency = 0}):Play()
	task.delay(duration + 2, unshowText)
end

-- Show a hint on player screen.
local function showHint(text: string)
	HintFrame.BackgroundTransparency = 1
	HintFrame.BgImage.ImageTransparency = 1
	HintTitle.TextTransparency = 1
	HintDesc.TextTransparency = 1
	HintClose.TextTransparency = 1
	
	local posDescText = HintDesc.Position
	HintDesc.Position = UDim2.fromScale(HintDesc.Position.X.Scale, HintDesc.Position.Y.Scale + 0.015)
	
	HintDesc.Text = text and text or "Take care with the shadows..."
	HintFrame.Visible = true
	
	playSound(script:FindFirstChild("ShowTipSound"))
	Ts:Create(HintFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0.6}):Play()
	Ts:Create(HintFrame.BgImage, TweenInfo.new(0.5), {ImageTransparency = 0}):Play()
	task.wait(0.5)
	Ts:Create(HintTitle, TweenInfo.new(0.2), {TextTransparency = 0}):Play()
	task.wait(0.1)
	Ts:Create(HintDesc, TweenInfo.new(0.2, Enum.EasingStyle.Sine), {Position = posDescText}):Play()
	Ts:Create(HintDesc, TweenInfo.new(0.1), {TextTransparency = 0}):Play()
	
	task.delay(1.5, function()
		Ts:Create(HintClose, TweenInfo.new(0.3), {TextTransparency = 0.6}):Play()
	end)
	task.wait(2.2) -- min show time
	
	UIS.InputBegan:Wait()
	
	Ts:Create(HintTitle, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
	Ts:Create(HintDesc, TweenInfo.new(0.2), {TextTransparency = 1}):Play()
	Ts:Create(HintClose, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
	
	Ts:Create(HintFrame, TweenInfo.new(0.2), {BackgroundTransparency = 1}):Play()
	Ts:Create(HintFrame.BgImage, TweenInfo.new(0.5), {ImageTransparency = 1}):Play()
	playSound(script:FindFirstChild("UnshowTipSound"))
end

local function addObjectivesMouseHint(text: string): string
	if showedObjectivesMouseHint or not UIS.KeyboardEnabled then return text end

	local normalizedText = string.lower(text)
	if string.find(normalizedText, "objective", 1, true) and string.find(normalizedText, "tab", 1, true) then
		showedObjectivesMouseHint = true
		return text .. "\n\nPress V to unlock your mouse."
	end

	return text
end

local function addHintPart(obj: Instance)
	if obj:IsA("BasePart") and obj:FindFirstChild("CrossDevices") and obj:FindFirstChild("Hint") then
		local CrossDevices = obj:FindFirstChild("CrossDevices") :: BoolValue
		local HintFolder = obj:FindFirstChild("Hint") :: Folder
		
		local activated = false
		
		if partsHints[obj] then return end
		
		partsHints[obj] = obj.Touched:Connect(function(hit)
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			if not player or player.UserId ~= game.Players.LocalPlayer.UserId then return end
			
			if activated then return end
			activated = true
			
			local playerSettings = player:WaitForChild("PlrSettings")
			local gameTips = playerSettings:WaitForChild("GameTips")
			
			if gameTips then
				if not gameTips.Value then return end
			end
			
			if CrossDevices.Value then -- If the message is diffrent for each device
				if UIS.TouchEnabled then
					showHint(HintFolder:FindFirstChild("MobileHint").Value)
				elseif UIS.KeyboardEnabled then
					showHint(addObjectivesMouseHint(HintFolder:FindFirstChild("PCHint").Value))
				elseif UIS.GamepadEnabled then
					showHint(HintFolder:FindFirstChild("ConsoleHint").Value)
				end
			else
				showHint(HintFolder:FindFirstChild("Hint").Value)
			end
		end)
	end
end

local function removeHintPart(obj: Instance)
	if partsHints[obj] then
		partsHints[obj]:Disconnect()
		partsHints[obj] = nil
	end
end

CollectionService:GetInstanceAddedSignal(TAG):Connect(addHintPart)
CollectionService:GetInstanceRemovedSignal(TAG):Connect(removeHintPart)

for _, v in CollectionService:GetTagged(TAG) do
	addHintPart(v)
end

PlrDialog.OnClientEvent:Connect(function(dialog: {}, SimpleText: string, sound2: boolean)
	if not dialog then
		if typeof(SimpleText) == "string" then
			if sound2 then
				showDialog(SimpleText, 0, true, false)
			else
				showDialog(SimpleText, 0, true)
			end
		end
		return
	end
	
	for i, v in ipairs(dialog) do
		showDialog(v.Text, v.Duration, true)
		task.wait(v.Duration)
	end
	--[[Dialog structure:
	local dialog = {
		Text1 = {
			Text = "blablabla",
			Duration = 3
		},
		Text2 = {
			Text = "blablabla",
			Duration = 3
		},
	}
	]]
end)
