--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Player
local Plr = game.Players.LocalPlayer

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local ClientMessage = Remotes:WaitForChild("ClientMessage")
local RewardWarnEvent = Remotes:WaitForChild("RewardWarnEvent")

local function showNotification(text: string)
	if not text then warn("Incorrect text value.") return end
	
	local showText = script.Parent.MainFrame.WarnText:Clone()
	showText.Parent = script.Parent
	showText.Text = text
	showText.TextTransparency = 1
	script.Parent.GroupRewardsManager.SelectSound:Play()
	
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 0}):Play()
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {Position = UDim2.new(0.272, 0, 0.812, 0)}):Play()
	
	task.wait(1.7)
	
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out), {TextTransparency = 1}):Play()
	Ts:Create(showText, TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.In), {Position = UDim2.new(0.272, 0, 0.862, 0)}):Play()
	
	game.Debris:AddItem(showText, 1)
end

ClientMessage.Event:Connect(function(message: string)
	showNotification(message)
end)

--//Map
local MapFolder = workspace:WaitForChild("Map")
local InteractStuff = MapFolder:WaitForChild("InteractStuff", 10)
local InteractPart = InteractStuff:WaitForChild("SewageInteract", 10)
local SewagePrompt = nil
if InteractPart then
	SewagePrompt = InteractPart:WaitForChild("ProximityPrompt", 10)
end

--//Values
local debounce = false
local delayTime = 2
local TimeOut = 10
local lastMessage = nil
local randomScaryMessages = {
	"Something is wrong here...",
	"Better take care.",
	"Something is in the shadows...",
	"Weird noises came from here."
}

if not SewagePrompt then return end

SewagePrompt.Triggered:Connect(function(plr)
	if debounce then return end
	debounce = true
	
	local message = nil
	local currentTime = 0
	
	repeat task.wait()
		message = randomScaryMessages[math.random(1, #randomScaryMessages)]
		currentTime += 1
	until message ~= lastMessage or currentTime >= TimeOut
	
	showNotification(message)
	
	task.wait(delayTime)
	
	debounce = false
end)

RewardWarnEvent.OnClientEvent:Connect(function(reward, amount, itemName)
	if reward == "FreeRevives" then
		showNotification("+"..amount.." Free Revives!")
	elseif reward == "Title" then
		showNotification("New Title Unlocked! [" .. itemName .. "]")
	elseif reward == "Perk" then
		showNotification("+"..amount.." "..itemName)
	elseif reward == "Character" then
		showNotification("New Character Unlocked! [" .. itemName .. "]")
	end
end)