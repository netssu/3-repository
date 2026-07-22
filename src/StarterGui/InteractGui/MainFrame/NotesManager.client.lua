--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local UIS = game:GetService("UserInputService")

--//Player
local Player = game.Players.LocalPlayer
local Camera = workspace.CurrentCamera
local Char = Player.Character or Player.CharacterAdded:Wait()
local Hum = Char:WaitForChild("Humanoid")

--//UI
local MainFrame = script.Parent
local NotesFrame = MainFrame.NotesFrame
local BackgroundImage = NotesFrame.Background
local InfoText = NotesFrame.InfoText
local TitleText = NotesFrame.Title
local HintText = NotesFrame.HintText

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))

--//Notes Stuff
local Map = workspace:WaitForChild("Map")
local NotesFolder = Map:WaitForChild("Notes")
local PaperNotes = {}
local OnTransition = false
local Dying = false

local function changeNote(PaperNote: BasePart, state: boolean, title: string, info: string)
	if state then
		if not PaperNote then return end
		local Observer = PaperNote:FindFirstChild("Observer") :: BasePart
		
		InfoText.Text = info
		TitleText.Text = title
		Camera.CameraType = Enum.CameraType.Scriptable
		OnTransition = true
		
		if PaperNote:FindFirstChild("OpenSound") then
			PaperNote:FindFirstChild("OpenSound"):Play()
		end
		
		local camTween = Ts:Create(Camera, TweenInfo.new(0.5, Enum.EasingStyle.Quad), {CFrame = Observer.CFrame})
		camTween:Play()
		
		camTween.Completed:Connect(function()
			if Dying then return end
			
			local backgroundTween = Ts:Create(BackgroundImage, TweenInfo.new(0.5), {ImageTransparency = 0.4})
			backgroundTween:Play()
			
			backgroundTween.Completed:Connect(function()
				if Dying then return end
				Ts:Create(InfoText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
				Ts:Create(TitleText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
				Ts:Create(HintText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
				task.wait(0.35)
				OnTransition = false
			end)
		end)
	else
		if PaperNote then
			if PaperNote:FindFirstChild("CloseSound") then
				PaperNote:FindFirstChild("CloseSound"):Play()
			end
		end
		Camera.CameraType = Enum.CameraType.Custom
		BackgroundImage.ImageTransparency = 1
		InfoText.TextTransparency = 1
		TitleText.TextTransparency = 1
		HintText.TextTransparency = 1
	end
end

local function loadPaperNotes()
	for i, v: BasePart in ipairs(PaperNotes) do
		if not v:HasTag("markedPaperNote") then
			v:AddTag("markedPaperNote")
			
			local MainFrame = v:WaitForChild("SurfaceGui"):WaitForChild("MainFrame")
			local TitleText = MainFrame:WaitForChild("Title") :: TextLabel
			local InfoTextNote = MainFrame:WaitForChild("Info") :: TextLabel
			
			local currentState = false
			local prox = Instance.new("ProximityPrompt", v)
			local highlight = Instance.new("Highlight", v)
			
			prox.RequiresLineOfSight = false
			prox.MaxActivationDistance = GameConfigModule.InteractDistance
			prox.Style = Enum.ProximityPromptStyle.Custom
			prox.ActionText = "Read"
			prox.ObjectText = "Note"
			
			highlight.DepthMode = Enum.HighlightDepthMode.Occluded
			highlight.OutlineTransparency = 1
			highlight.FillTransparency = 1
			
			prox.PromptShown:Connect(function()
				Ts:Create(highlight, TweenInfo.new(0.2), {OutlineTransparency = 0.2}):Play()
			end)
			
			prox.PromptHidden:Connect(function()
				Ts:Create(highlight, TweenInfo.new(0.2), {OutlineTransparency = 1}):Play()
			end)
			
			prox.Triggered:Connect(function(plr)
				if not (plr == Player) then return end
				if OnTransition then return end
				if currentState then
					currentState = false
					changeNote(v, currentState)
				else
					prox.Enabled = false
					currentState = true
					changeNote(v, currentState, TitleText.Text, InfoTextNote.Text)
				end
			end)
			
			UIS.InputBegan:Connect(function(input, gameprocessed)
				if gameprocessed then return end
				if OnTransition then return end
				if not currentState then return end
				
				if input.UserInputType == Enum.UserInputType.Touch or input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Gamepad1 or input.UserInputType == Enum.UserInputType.Gamepad2 then
					prox.Enabled = true
					currentState = false
					changeNote(false)
				end
			end)
		end
	end
end

Hum.Died:Connect(function()
	Dying = true
	Camera.CameraType = Enum.CameraType.Custom
	changeNote(false)
	--//Get the new player character and humanoid
	Char = Player.Character or Player.CharacterAdded:Wait()
	Hum = Char:WaitForChild("Humanoid")
	Dying = false
end)

NotesFolder.ChildAdded:Connect(function(child)
	if child:HasTag("PaperNote") and child:FindFirstChild("Observer") then
		table.insert(PaperNotes, child)
	end
	loadPaperNotes()
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

for i, v in NotesFolder:GetChildren() do
	if v:HasTag("PaperNote") and v:FindFirstChild("Observer") then
		table.insert(PaperNotes, v)
	end
end

loadPaperNotes()