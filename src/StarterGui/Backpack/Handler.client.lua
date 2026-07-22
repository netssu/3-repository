local starterGui = game:GetService("StarterGui")
local replicatedStorage = game:GetService("ReplicatedStorage")
local uis = game:GetService("UserInputService")
local tweenService = game:GetService("TweenService")
starterGui:SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, false)

local gui = script.Parent
local hotbar = gui:WaitForChild("Hotbar")
local preset = hotbar:WaitForChild("Preset")

local player = game:GetService("Players").LocalPlayer
local onCutsceneValue = player:WaitForChild("PlayerValues"):WaitForChild("OnCutscene") :: BoolValue
local camera = workspace.CurrentCamera
local character = player.Character or player.CharacterAdded:Wait()
local humanoid = character:WaitForChild("Humanoid") :: Humanoid
local backpack = player:WaitForChild("Backpack")

local defaultColor = Color3.fromRGB(0,0,0)
local selectedColor = Color3.fromRGB(0, 0, 0)
local canDrop = false

local NumberKeycodes = {
	"One",
	"Two",
	"Three",
	"Four",
	"Five",
	"Six",
	"Seven",
	"Eight",
	"Nine",
	"Zero"
}

function getTools()
	local tools = {}
	
	for _,obj in pairs(character:GetChildren()) do
		if not obj:isA("Tool") then continue end
		table.insert(tools,obj)
	end
	
	for _,obj in pairs(backpack:GetChildren()) do
		if not obj:isA("Tool") then continue end
		table.insert(tools,obj)
	end
	
	return tools
end

function getEquippedTools()
	local tools = {}
	for _,obj in pairs(character:GetChildren()) do
		if not obj:isA("Tool") then continue end
		table.insert(tools,obj)
	end
	return tools
end

function getFrame(tool)
	return hotbar:FindFirstChild(tool.Name)
end

function getToolFromHotbar(i)
	for _,frame in pairs(hotbar:GetChildren()) do
		if frame.LayoutOrder == i then
			return frame
		end
	end
end

local keybindings = {}

function bindToKey(key, action)
	if keybindings[key] then
		keybindings[key]:Disconnect()
	end
	keybindings[key] = uis.InputBegan:Connect(function(input, gameprocessed)
		if not gameprocessed and input.KeyCode == key then
			action()
		end
	end)
end

function unbindKey(key)
	if keybindings[key] then
		keybindings[key]:Disconnect()
		keybindings[key] = nil
	end
end

function equipTool(tool)
	if onCutsceneValue.Value then return end
	if humanoid.Health <= 0 then return end
	
	for _, equipped in pairs(getEquippedTools()) do
		if equipped:GetAttribute("NotUnequippable") then return end
	end
	
	if tool.Parent then
		if tool and tool.Parent ~= character then
			humanoid:UnequipTools()
			humanoid:EquipTool(tool)
		else
			humanoid:UnequipTools()
		end
	end
end

function tween(i,s,p)
	local tween = tweenService:Create(i,TweenInfo.new(s),p)
	tween:Play()
	return tween
end

function reorganizeHotbar()
	local currentIndex = 1
	local children = {}
	
	for i, child in hotbar:GetChildren() do
		if child:IsA("Frame") then
			table.insert(children, child)
		end
	end
	
	table.sort(children, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	
	for _, frame in pairs(children) do
		if frame:IsA("GuiObject") and frame.Container.Tool.Value then
			frame.LayoutOrder = currentIndex
			local tool = frame.Container.Tool.Value
			local k = Enum.KeyCode[NumberKeycodes[currentIndex]]
			local oldk = Enum.KeyCode[NumberKeycodes[tonumber(frame.Container.HotbarIndex.Text)]]
			
			--//Remove the old KeyBind
			unbindKey(oldk)
			
			--//Update KeyBinds
			bindToKey(k, function()
				equipTool(tool)
			end)
			
			frame.Container.HotbarIndex.Text = currentIndex
			currentIndex += 1
		end
	end
end

function addHotbarButton(tool)
	local newFrame = preset:Clone()
	local container = newFrame.Container
	newFrame.Name = tool.Name
	
	local availableSlot = 1
	local usedSlots = {}
	for _, frame in pairs(hotbar:GetChildren()) do
		if frame:IsA("GuiObject") and frame.LayoutOrder then
			usedSlots[frame.LayoutOrder] = true
		end
	end
	
	while usedSlots[availableSlot] do
		availableSlot += 1
	end
	
	newFrame.LayoutOrder = availableSlot
	
	container.Tool.Value = tool
	container.Label.Text = tool.Name
	container.HotbarIndex.Text = availableSlot
	
	newFrame.Visible = true
	newFrame.Parent = hotbar
	
	local OnInv = Instance.new("BoolValue", tool)
	OnInv.Name = "OnInv"
	
	local connections = {}
	local onHand = false
	
	local function cleanup()
		for _, c in pairs(connections) do
			c:Disconnect()
		end
		table.clear(connections)
		newFrame:Destroy()
		
		--//Reoganize the hotbar after removing a item
		reorganizeHotbar()
	end
	
	local function c(v)
		table.insert(connections, v)
	end
	
	if tool.TextureId ~= "" then
		container.Label.Visible = false
		container.Icon.Image = tool.TextureId
	end
	
	if tool.ToolTip ~= "" then
		container.ToolTip.Text = tool.ToolTip
		local hovering = false
		
		c(container.MouseEnter:Connect(function()
			hovering = true
			task.wait(0.5)
			if hovering then
				container.ToolTip.Visible = true
			end
		end))
		
		c(container.MouseLeave:Connect(function()
			hovering = false
			container.ToolTip.Visible = false
		end))
	end
	
	--//Set the KeyBind
	local k = Enum.KeyCode[NumberKeycodes[availableSlot]]
	bindToKey(k, function()
		equipTool(tool)
	end)
	
	c(container.Icon.MouseButton1Click:Connect(function()
		equipTool(tool)
	end))
	
	c(tool.Equipped:Connect(function()
		onHand = true
		tween(container, .25, { BackgroundTransparency = 0.3, BackgroundColor3 = selectedColor, Position = UDim2.new(0, 0, 0, -5) })
		tween(container.UIStroke, .25, { Transparency = 0.5 })
	end))
	
	c(tool.Unequipped:Connect(function()
		onHand = false
		tween(container, .25, { BackgroundTransparency = 0.5, BackgroundColor3 = defaultColor, Position = UDim2.new(0, 0, 0, 0) })
		tween(container.UIStroke, .25, { Transparency = 1 })
	end))
	
	uis.InputBegan:Connect(function(input, gameprocessed)
		if gameprocessed then return end
		
		if input.KeyCode == Enum.KeyCode.Q then
			if onHand and canDrop then
				onHand = false
				
				local k = Enum.KeyCode[NumberKeycodes[newFrame.LayoutOrder]]
				unbindKey(k)
				
				cleanup()
				
				if tool:FindFirstChild("OnInv") then
					tool.OnInv:Destroy()
				end
				
				tool.Parent = workspace
			end
		end
	end)

	c(tool.Destroying:Connect(cleanup))
	c(newFrame.Destroying:Connect(cleanup))

	return newFrame
end

function addToInventory(tool)
	--//Check if the item is already on HotBar
	if tool:FindFirstChild("OnInv") then
		return
	end
	
	addHotbarButton(tool)
end

function updateGui(child)
	local objects = hotbar:GetChildren()
	local tools = getTools()
	
	for _,frame in pairs(objects) do
		if not frame:isA("GuiObject") then continue end
		frame.Container.HotbarIndex.Text = frame.LayoutOrder
	end
	
	for _,tool in pairs(tools) do
		if getFrame(tool) then continue end
		addToInventory(tool)
	end
end

function addtionTool(child)
	if child then
		if child:IsA("Tool") then
			if child:FindFirstChild("OnInv") then return end
			addToInventory(child)
		end
	end
end

function CheckInput(input,isTyping)
	local keycode = tostring(input.KeyCode):split(".")[3]
	local callback = keybindings[keycode]
	if not isTyping and callback then
		callback()
	end
end

character.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		addtionTool(child)
	end
end)

backpack.ChildAdded:Connect(function(child)
	if child:IsA("Tool") then
		addtionTool(child)
	end
end)

--//Gamepad compatibility
local function getHotbarFramesSorted()
	local frames = {}
	for _, child in pairs(hotbar:GetChildren()) do
		if child:IsA("GuiObject") and child.Visible then
			table.insert(frames, child)
		end
	end
	
	table.sort(frames, function(a, b)
		return a.LayoutOrder < b.LayoutOrder
	end)
	
	return frames
end

local selectedIndex = nil

local function selectHotbarIndex(index)
	local frames = getHotbarFramesSorted()
	if frames[index] then
		local tool = frames[index].Container.Tool.Value
		if tool then
			equipTool(tool)
			selectedIndex = index
		end
	end
end

local function deselectHotbar()
	humanoid:UnequipTools()
	selectedIndex = nil
end

local function onShoulderInput(direction)
	local frames = getHotbarFramesSorted()
	local count = #frames
	if count == 0 then return end
	
	if selectedIndex == nil then
		if direction == "right" then
			selectHotbarIndex(count)
		else
			selectHotbarIndex(1)
		end
	else
		local newIndex = selectedIndex + (direction == "right" and 1 or -1)
		if newIndex >= 1 and newIndex <= count then
			selectHotbarIndex(newIndex)
		else
			deselectHotbar()
		end
	end
end

--//Gamepad buttons L1/R1 (LeftShoulder / RightShoulder)
uis.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed or onCutsceneValue.Value then return end
	
	if input.KeyCode == Enum.KeyCode.ButtonL1 then
		onShoulderInput("left")
	elseif input.KeyCode == Enum.KeyCode.ButtonR1 then
		onShoulderInput("right")
	end
end)

uis.InputBegan:Connect(CheckInput)

updateGui()