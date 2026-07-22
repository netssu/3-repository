--!strict
local XmasEventController = {}

--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

--//Modules
local Modules = Rs:WaitForChild("Modules")
local Configs = Modules:WaitForChild("Configs")
local EventsModule = require(Configs.Events)
local DataHandler = require(Modules.DataHandler)

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local CheckEvent = Remotes:WaitForChild("CheckEvent")

--//Player
local plr = Players.LocalPlayer
local plrGui = plr.PlayerGui
local camera = workspace.CurrentCamera

--//Assets
local XmasEventFolder = workspace:WaitForChild("Xmas_Event")
local Elf_NPC = XmasEventFolder:WaitForChild("Elf_NPC")
local InteractProx = Elf_NPC:WaitForChild("HumanoidRootPart"):WaitForChild("ProximityPrompt")
local DialogCamPart = XmasEventFolder:WaitForChild("DialogCamPart")

--//Constants
local elfDialog = {
	"Hello! Welcome to the Christmas Event!",
	"I’ve hidden 15 Elf Plushies around the asylum. When you start playing, look for them and bring each one back to me.",
	"If you manage to find all of them, I'll reward you with a special, exclusive character!",
}

function XmasEventController.Init()
	local MenuGui = plrGui:WaitForChild("MenuGui")
	local XmasEventFrame = MenuGui.InGameFrame.XmasEventFrame
	local DialogFrame = MenuGui.InGameFrame.DialogFrame
	local speakerText = DialogFrame.TitleText
	local contentDialogText = DialogFrame.ContentText
	local skipDialogText = DialogFrame.SkipText
	local skipButton = DialogFrame.SkipButton
	
	local main_bottomButtons = MenuGui.InGameFrame.ButtonsFrame
	local main_leftButtons = MenuGui.InGameFrame.LButtonsFrame
	
	local defaultXmasFrameSize = XmasEventFrame.Size
	XmasEventFrame.Size = UDim2.new(0, 0, 0, 0)
	
	local function openEventFrame()
		XmasEventFrame.Visible = true
		Ts:Create(XmasEventFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = defaultXmasFrameSize}):Play()
	end
	
	local function changeDialog(state: boolean)
		if state then
			main_leftButtons.Visible = false
			main_bottomButtons.Visible = false
			
			speakerText.Text = "Elf"
			speakerText.UIStroke.Transparency = 1
			speakerText.TextTransparency = 1
			contentDialogText.Text = ""
			DialogFrame.Transparency = 1
			DialogFrame.Visible = true
			
			Ts:Create(speakerText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
			Ts:Create(speakerText.UIStroke, TweenInfo.new(0.3), {Transparency = 0}):Play()
			Ts:Create(DialogFrame, TweenInfo.new(0.3), {BackgroundTransparency = 0.2}):Play()
		else
			Ts:Create(contentDialogText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
			Ts:Create(speakerText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
			Ts:Create(speakerText.UIStroke, TweenInfo.new(0.3), {Transparency = 1}):Play()
			Ts:Create(skipDialogText, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
			
			task.wait(0.3)
			
			Ts:Create(DialogFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
			main_leftButtons.Visible = true
			main_bottomButtons.Visible = true
		end
	end
	
	local skipWriting = false
	local nextDialog = false
	local finishedWriting = false
	
	skipButton.MouseButton1Click:Connect(function()
		if not skipWriting and not finishedWriting then
			skipWriting = true
		else
			nextDialog = true
		end
	end)
	
	local function talkDialog(text: string)
		skipWriting = false
		nextDialog = false
		finishedWriting = false
		skipDialogText.TextTransparency = 1
		contentDialogText.Text = ""
		contentDialogText.TextTransparency = 0
		
		for i = 1, #text do
			contentDialogText.Text = text:sub(1, i)
			if not skipWriting then
				task.wait(0.03)
			end
		end
		
		finishedWriting = true
		Ts:Create(skipDialogText, TweenInfo.new(0.3), {TextTransparency = 0}):Play()
		
		repeat task.wait() until nextDialog == true
	end
	
	local plrOnDialog = false
	
	local function startDialog()
		changeDialog(true)
		task.wait(0.5)
		
		for _, dialogTxt in elfDialog do
			talkDialog(dialogTxt)
		end
		
		changeDialog(false)
		plrOnDialog = false
		camera.CameraType = Enum.CameraType.Custom
		InteractProx.Enabled = true
		
		task.wait(0.5)
		
		openEventFrame()
	end
	
	local function updatePlushiesCount()
		local plrData = DataHandler:GetProfileData(plr)
		if not plrData then
			return
		end
		
		local totalPlushies = 0
		if plrData.Events.Xmas_2025.Plushies then
			for _, v in plrData.Events.Xmas_2025.Plushies do
				totalPlushies += 1
			end
		end
		
		XmasEventFrame.CollectedAmount.Text = totalPlushies .. "/15"
	end
	
	InteractProx.Triggered:Connect(function(plr)
		if plrOnDialog then return end
		plrOnDialog = true
		InteractProx.Enabled = false
		camera.CameraType = Enum.CameraType.Scriptable
		Ts:Create(camera, TweenInfo.new(0.7, Enum.EasingStyle.Sine), {CFrame = DialogCamPart.CFrame}):Play()
		updatePlushiesCount()
		startDialog()
	end)
	
	XmasEventFrame.ClaimButton.MouseButton1Click:Connect(function()
		local claimedReward = CheckEvent:InvokeServer("Xmas_2025", true)
		if claimedReward then
			--reward claimed YAY!
		else
			game:GetService("SoundService").Effects.IncorrectSound:Play()
		end
	end)
	
	--//Event timer
	coroutine.wrap(function()
		while task.wait(1) do
			XmasEventFrame.EventTimer.Text = EventsModule:CalculateTimeLeft("Xmas_2025")
		end
	end)()
end

return XmasEventController