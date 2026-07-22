local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")

local AnnouncementEvent = ReplicatedStorage:WaitForChild("GlobalAnnouncementEvent")
local player = Players.LocalPlayer

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "AnnouncementGui"
screenGui.ResetOnSpawn = false
screenGui.Parent = player:WaitForChild("PlayerGui")

local container = Instance.new("Frame")
container.Size = UDim2.new(1, 0, 1, 0)
container.BackgroundTransparency = 1
container.Parent = screenGui

local messageDuration = 6
local spacing = 0.09
local startingY = 0.15 -- moved slightly higher on screen
local activeMessages = {}

local function createAnnouncement(displayName, prefix, message)
	local messageIndex = #activeMessages + 1
	local yPos = startingY + (messageIndex - 1) * spacing

	local holder = Instance.new("Frame")
	holder.Size = UDim2.new(0.6, 0, 0.07, 0)
	holder.Position = UDim2.new(0.5, 0, yPos, 0)
	holder.AnchorPoint = Vector2.new(0.5, 0)
	holder.BackgroundTransparency = 1
	holder.Parent = container

	local bg = Instance.new("Frame")
	bg.Size = UDim2.new(1, 0, 1, 0)
	bg.BackgroundColor3 = Color3.new(0, 0, 0)
	bg.BackgroundTransparency = 1
	bg.Parent = holder

	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(Color3.fromRGB(0, 0, 0))
	gradient.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1),
		NumberSequenceKeypoint.new(0.1, 0),
		NumberSequenceKeypoint.new(0.9, 0),
		NumberSequenceKeypoint.new(1, 1),
	})
	gradient.Parent = bg

	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, -20, 1, 0)
	label.BackgroundTransparency = 1
	label.TextColor3 = Color3.fromRGB(255, 255, 255)
	label.TextStrokeTransparency = 0
	label.Font = Enum.Font.Cartoon
	label.TextSize = 24
	label.TextScaled = true
	label.TextWrapped = true
	label.TextXAlignment = Enum.TextXAlignment.Center
	label.TextYAlignment = Enum.TextYAlignment.Center
	label.TextTransparency = 1
	label.RichText = true
	label.Parent = holder

	label.Text = string.format("%s%s: %s", displayName, prefix or "", message)

	holder.Size = UDim2.new(0, label.TextBounds.X + 40, 0.07, 0)

	table.insert(activeMessages, holder)

	TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
	TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 0}):Play()

	task.delay(messageDuration, function()
		local fadeBg = TweenService:Create(bg, TweenInfo.new(0.5), {BackgroundTransparency = 1})
		local fadeText = TweenService:Create(label, TweenInfo.new(0.5), {TextTransparency = 1})
		fadeBg:Play()
		fadeText:Play()
		fadeText.Completed:Wait()

		local indexToRemove = table.find(activeMessages, holder)
		if indexToRemove then
			table.remove(activeMessages, indexToRemove)
			holder:Destroy()
			for i = indexToRemove, #activeMessages do
				local targetY = startingY + (i - 1) * spacing
				TweenService:Create(activeMessages[i], TweenInfo.new(0.3), {
					Position = UDim2.new(0.5, 0, targetY, 0)
				}):Play()
			end
		end
	end)
end

AnnouncementEvent.OnClientEvent:Connect(function(data)
	if typeof(data) == "table" and data.displayName and data.message then
		createAnnouncement(data.displayName, data.prefix, data.message)
	end
end)
