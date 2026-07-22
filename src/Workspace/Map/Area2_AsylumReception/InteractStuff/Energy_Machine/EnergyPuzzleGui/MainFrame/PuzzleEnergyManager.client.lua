--//Services
local Rs  =game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local GamePuzzles = Remotes:WaitForChild("gamePuzzles")

--//Player
local Player = game.Players.LocalPlayer

--//UI
local MainFrame = script.Parent
local ButtonsFrame = MainFrame.ButtonsFrame

--//Values
local onPuzzleDebounce = false
local plrSelectedOrder = {}
local currentOrder = {}
local currentLevel = 0
local maxLevel = 5
local blinkSpeed = 0.12

--//Setup
MainFrame.Position = UDim2.fromScale(1, 0)
task.wait(0.5)
Ts:Create(MainFrame, TweenInfo.new(1), {Position = UDim2.fromScale(0, 0)}):Play()

local function playSound(sound: Sound, parent: Instance)
	local snd = sound:Clone()
	snd.Parent = parent and parent or sound.Parent
	snd:Play()
	game.Debris:AddItem(snd, snd.TimeLength + 1)
end

local function cloneTable(t)
	local new = {}
	for i, v in ipairs(t) do
		new[i] = v
	end
	return new
end

local function compareTables(t1, t2)
	if #t1 ~= #t2 then
		return false
	end
	for i = 1, #t1 do
		if t1[i] ~= t2[i] then
			return false
		end
	end
	return true
end

local function alreadyInCurrentOrder(button)
	for _, b in ipairs(currentOrder) do
		if b == button then
			return true
		end
	end
	return false
end

local function addNewInter()
	local newInter
	local buttons = {}
	
	for _, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			table.insert(buttons, v)
		end
	end
	
	repeat
		newInter = buttons[math.random(1, #buttons)]
	until not alreadyInCurrentOrder(newInter)
	table.insert(currentOrder, newInter)
end

local function resetButtons()
	for _, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(163, 162, 165)
		end
	end
end

local function resetPuzzle()
	currentLevel = 0
	onPuzzleDebounce = false
	currentOrder = {}
	plrSelectedOrder = {}
	resetButtons()
	
	task.wait(blinkSpeed)
	playSound(MainFrame.ButtonBip, MainFrame)
	
	for i, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(147, 146, 149)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(blinkSpeed)
	playSound(MainFrame.ButtonBip, MainFrame)
	
	for i, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(147, 146, 149)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(blinkSpeed)
	playSound(MainFrame.ButtonBip, MainFrame)
	
	for i, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(147, 146, 149)
		end
	end
	
	task.wait(blinkSpeed)
	
	for i, v in ButtonsFrame:GetChildren() do
		if v:IsA("TextButton") then
			v.BackgroundColor3 = Color3.fromRGB(78, 77, 79)
		end
	end
	
	task.wait(0.25)
	onPuzzleDebounce = false
end

local function blinkPattern()
	onPuzzleDebounce = true
	
	resetButtons()
	
	task.wait(0.3)
	
	resetButtons()
	
	--//Blink current order
	for _, v in ipairs(currentOrder) do
		local buttonSelected = nil :: TextButton 
		for _, button in ipairs(ButtonsFrame:GetChildren()) do
			local number = button.Name:match("%d+")
			if number and v.Name:find(number, 1, true) then
				buttonSelected = v
				break
			end
		end
		if buttonSelected then
			buttonSelected.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
			playSound(MainFrame.ButtonBip, MainFrame)
			task.wait(0.25)
			--buttonSelected.Color = Color3.fromRGB(78, 77, 79)
		end
		task.wait(0.25)
	end
	
	resetButtons()
	onPuzzleDebounce = false
end

local function startPuzzle()
	resetPuzzle()
	addNewInter()
	blinkPattern()
end

task.wait(1)

startPuzzle()

for i, v in ButtonsFrame:GetChildren() do
	if v:IsA("TextButton") then
		local alreadyClicked = Instance.new("BoolValue", v)
		alreadyClicked.Name = "alreadyClicked"
		alreadyClicked.Value = false
		
		v.Activated:Connect(function(plr)
			if alreadyClicked.Value or onPuzzleDebounce then return end
			
			print("clicking on:", v)
			
			onPuzzleDebounce = true
			alreadyClicked.Value = true
			table.insert(plrSelectedOrder, v)
			
			playSound(MainFrame.ButtonClick, MainFrame)
			v.BackgroundColor3 = Color3.fromRGB(52, 234, 36)
			
			task.wait(0.25)
			
			if compareTables(plrSelectedOrder, currentOrder) then
				currentLevel += 1
				if currentLevel < maxLevel then
					print("adding new integer")
					plrSelectedOrder = {}
					addNewInter()
					
					task.wait(0.2)
					
					resetButtons()
					blinkPattern()
				else -- win
					print("player winning")
					
					task.delay(0.5, function()
						GamePuzzles:FireServer("energyMachine_win")
					end)
					
					Ts:Create(MainFrame, TweenInfo.new(1), {Position = UDim2.fromScale(1, 0)}):Play()
					return
				end
			elseif #plrSelectedOrder >= #currentOrder and not compareTables(plrSelectedOrder, currentOrder) then
				--puzzleIncorrect() -- event
				print("puzzle is incorrect!")
				resetPuzzle()
				
				--//Restart the puzzle automatically
				addNewInter() -- add another button to the sequence
				task.wait(0.5)
				blinkPattern()
			end
			alreadyClicked.Value = false
			onPuzzleDebounce = false
		end)
	end
end