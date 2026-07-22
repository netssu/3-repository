local TutorialController = {}

--//Services
local Players = game:GetService("Players")
local Ts = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")
local GuiService = game:GetService("GuiService")

--//Player
local plr = Players.LocalPlayer
local plrGui = plr.PlayerGui

--//Modules
local Modules = Rs:WaitForChild("Modules")
local DataHandler = require(Modules:WaitForChild("DataHandler"))

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local CompletedTutorial = Remotes:WaitForChild("CompletedTutorial")

--//UI
local TutorialGui = plrGui:WaitForChild("TutorialGui")

local FrameTop = TutorialGui:WaitForChild("FrameTop")
local FrameBottom = TutorialGui:WaitForChild("FrameBottom")
local FrameLeft = TutorialGui:WaitForChild("FrameLeft")
local FrameRight = TutorialGui:WaitForChild("FrameRight")

local TutorialTips = TutorialGui:WaitForChild("TutorialTips")

--//Assets
local BeamArrow = script:FindFirstChild("Beam")

--//Constants
local PADDING = 0
local DELAY_TIP = 1.5
local TARGET_TRANSPARENCY = 0.3
local TWEEN_INFO = TweenInfo.new(
	0.35,
	Enum.EasingStyle.Quint,
	Enum.EasingDirection.Out
)

--//Variables
local currentConnection: RBXScriptConnection? = nil
local currentObject: GuiObject? = nil
local sizeConnection: RBXScriptConnection? = nil

--//Frame animation
local function tweenFrame(frame: Frame, props)
	Ts:Create(frame, TWEEN_INFO, props):Play()
end

local function getRelativeRect(gui: GuiObject, root: GuiObject)
	local pos = gui.AbsolutePosition - root.AbsolutePosition
	local size = gui.AbsoluteSize
	
	return pos.X, pos.Y, pos.X + size.X, pos.Y + size.Y
end

local function getBoundingBox(objects: {GuiObject}, root: GuiObject)
	local minX = math.huge
	local minY = math.huge
	local maxX = -math.huge
	local maxY = -math.huge
	
	for _, obj in ipairs(objects) do
		if obj and obj:IsA("GuiObject") then
			local x1, y1, x2, y2 = getRelativeRect(obj, root)
			
			minX = math.min(minX, x1)
			minY = math.min(minY, y1)
			maxX = math.max(maxX, x2)
			maxY = math.max(maxY, y2)
		end
	end
	
	return minX, minY, maxX, maxY
end

local function updateFocus()
	if not currentObject then return end
	
	local objects = typeof(currentObject) == "table" and currentObject or { currentObject }
	local minX, minY, maxX, maxY = getBoundingBox(objects, TutorialGui)
	
	minX -= PADDING
	minY -= PADDING
	maxX += PADDING
	maxY += PADDING
	
	local screenSize = TutorialGui.AbsoluteSize
	
	minX = math.clamp(math.floor(minX), 0, screenSize.X)
	minY = math.clamp(math.floor(minY), 0, screenSize.Y)
	maxX = math.clamp(math.ceil(maxX), 0, screenSize.X)
	maxY = math.clamp(math.ceil(maxY), 0, screenSize.Y)
	
	-- TOP
	tweenFrame(FrameTop, {
		Position = UDim2.fromOffset(0, 0),
		Size = UDim2.fromOffset(screenSize.X, minY),
		BackgroundTransparency = TARGET_TRANSPARENCY
	})
	
	-- BOTTOM
	tweenFrame(FrameBottom, {
		Position = UDim2.fromOffset(0, maxY),
		Size = UDim2.fromOffset(screenSize.X, screenSize.Y - maxY),
		BackgroundTransparency = TARGET_TRANSPARENCY
	})
	
	-- LEFT
	tweenFrame(FrameLeft, {
		Position = UDim2.fromOffset(0, minY),
		Size = UDim2.fromOffset(minX, maxY - minY),
		BackgroundTransparency = TARGET_TRANSPARENCY
	})
	
	-- RIGHT
	tweenFrame(FrameRight, {
		Position = UDim2.fromOffset(maxX, minY),
		Size = UDim2.fromOffset(screenSize.X - maxX, maxY - minY),
		BackgroundTransparency = TARGET_TRANSPARENCY
	})
end

--//Start showing focus on an object
function TutorialController.focusObj(obj)
	if not obj then return end
	currentObject = obj
	
	if sizeConnection then
		sizeConnection:Disconnect()
		sizeConnection = nil
	end
	
	for _, frame in ipairs({FrameTop, FrameBottom, FrameLeft, FrameRight}) do
		frame.Visible = true
	end
	
	updateFocus()
	
	sizeConnection = TutorialGui:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
		updateFocus()
	end)
end

function TutorialController.clearFocus()
	currentObject = nil
	
	if sizeConnection then
		sizeConnection:Disconnect()
		sizeConnection = nil
	end
	
	for _, frame in ipairs({FrameTop, FrameBottom, FrameLeft, FrameRight}) do
		tweenFrame(frame, {
			BackgroundTransparency = 1
		})
	end
end

local function makeTipVisible(tipFrame: Frame)
	for _, v in TutorialTips:GetChildren() do
		v.Visible = false
	end
	if tipFrame then
		tipFrame.Visible = true
	end
end

function TutorialController.Init()
	task.wait(2) -- delay to start the tutorial if is the first time of the player playing
	
	local plrData = DataHandler:GetProfileData(plr)
	if not plrData or not plrData.FirstTime then return end -- player already played the game before
	
	local MenuFrame = plrGui.MenuGui.MainFrame
	local GameFrame = plrGui.MenuGui.InGameFrame
	local ButtonsFrame = GameFrame.ButtonsFrame
	local LeftButtonsFrame = GameFrame.LButtonsFrame
	
	ButtonsFrame.CharactersButton.Visible = false
	
	--[[
	TutorialController.focusObj({
		ButtonsFrame.ShopButton,
		ButtonsFrame.PlrInfoButton,
		ButtonsFrame.InventoryButton,
		ButtonsFrame.CharactersButton,
		ButtonsFrame.BadgesButton
	})
	
	task.wait(4)
	]]
	
	--//Shop tip
	TutorialController.focusObj(ButtonsFrame.ShopButton)
	makeTipVisible(TutorialTips.Tip1)
	ButtonsFrame.ShopButton.MouseButton1Click:Wait()
	makeTipVisible() -- will hide all tips
	TutorialController.clearFocus()
	
	task.wait(DELAY_TIP)
	
	--//Inventory Tip
	TutorialController.focusObj(ButtonsFrame.InventoryButton)
	makeTipVisible(TutorialTips.Tip2)
	ButtonsFrame.InventoryButton.MouseButton1Click:Wait()
	makeTipVisible()
	TutorialController.clearFocus()
	
	task.wait(0.5)
	
	--//Inventory tip sessions
	TutorialController.focusObj(GameFrame.InventoryFrame.OptionsFrame)
	makeTipVisible(TutorialTips.Tip3)
	
	task.wait(DELAY_TIP + 1.5)
	
	--//Badges tip
	TutorialController.focusObj(ButtonsFrame.BadgesButton)
	makeTipVisible(TutorialTips.Tip4)
	ButtonsFrame.BadgesButton.MouseButton1Click:Wait()
	makeTipVisible()
	TutorialController.clearFocus()
	
	task.wait(DELAY_TIP)
	
	--//Stats tip
	TutorialController.focusObj(ButtonsFrame.PlrInfoButton)
	makeTipVisible(TutorialTips.Tip5)
	ButtonsFrame.PlrInfoButton.MouseButton1Click:Wait()
	makeTipVisible()
	TutorialController.clearFocus()
	
	task.wait(DELAY_TIP)
	
	--//Characters tip
	ButtonsFrame.CharactersButton.Visible = true
	TutorialController.focusObj(ButtonsFrame.CharactersButton)
	makeTipVisible(TutorialTips.Tip6)
	ButtonsFrame.CharactersButton.MouseButton1Click:Wait()
	makeTipVisible()
	TutorialController.clearFocus()
	
	task.wait(DELAY_TIP)
	
	TutorialController.focusObj(MenuFrame.CharactersFrame.CharacterSelection)
	makeTipVisible(TutorialTips.Tip7)
	
	local canContinue = false
	
	for _, frame in MenuFrame.CharactersFrame.CharacterSelection.CharactersSelector:GetChildren() do
		if frame:IsA("Frame") then
			local EquipButton = frame:FindFirstChild("EquipButton") :: TextButton
			EquipButton.MouseButton1Click:Connect(function()
				if EquipButton.Text == "Equip" then
					canContinue = true
				end
			end)
		end
	end
	
	repeat task.wait() until canContinue
	
	TutorialController.focusObj(MenuFrame.CharactersFrame.Back)
	makeTipVisible(TutorialTips.Tip8)
	MenuFrame.CharactersFrame.Back.MouseButton1Click:Wait()
	makeTipVisible()
	TutorialController.clearFocus()
	
	--//Beam effect to direct players to the teleporters and play a match
	local TeleporterModel = workspace:WaitForChild("Map"):WaitForChild("GameTeleporters"):WaitForChild("TeleporterModel_1")
	local FinishPart = TeleporterModel:WaitForChild("Gate")
	local StartPart = plr.Character and plr.Character:FindFirstChild("HumanoidRootPart")
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Parent = StartPart
	
	local attachment2 = Instance.new("Attachment")
	attachment2.Parent = FinishPart
	
	task.delay(1, function()
		makeTipVisible(TutorialTips.TipTeleporter)
	end)
	
	local teleporterConnection: RBXScriptConnection = nil
	
	if StartPart then
		local beam = BeamArrow:Clone()
		beam.Parent = plr.Character
		beam.Attachment0 = attachment2
		beam.Attachment1 = attachment1
		
		teleporterConnection = FinishPart.Touched:Connect(function(hit)
			if hit.Parent == plr.Character then
				beam:Destroy()
				makeTipVisible()
				
				if teleporterConnection then
					teleporterConnection:Disconnect()
					teleporterConnection = nil
				end
			end
		end)
	end
	
	CompletedTutorial:FireServer()
end

return TutorialController