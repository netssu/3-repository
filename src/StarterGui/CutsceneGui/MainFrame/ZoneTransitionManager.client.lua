--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local ZoneTransitionFunc = Remotes:WaitForChild("ZoneTransition")

--//UI
local MainFrame = script.Parent
local TransitionFrame = MainFrame.Transition
local ZoneLoadFrame = MainFrame.ZoneLoadFrame
local LoopText = ZoneLoadFrame.LoopText
local TipText = ZoneLoadFrame.TipText

--//Teleport Stuff
local Map = workspace:WaitForChild("Map")
local TeleportZones = Map:WaitForChild("TeleportZones")

--//Values
local lastTip = nil
local Tips = {
	"If you hear something strange, hide.",
	"Share your resources with others players.",
	"Explore and interact with the scenery to get more items!",
	"Be careful when entering unfamiliar areas.",
	"Be careful not to get cornered!"
}

-- Make all ScreenGuis (except this gui) to invisible or visible. 
local function changeGuis(state: boolean)
	if state then
		for i, v in script.Parent.Parent.Parent:GetChildren() do
			if v ~= script.Parent.Parent then
				if v:IsA("ScreenGui") then
					v.Enabled = true
				end
			end
		end
	else
		for i, v in script.Parent.Parent.Parent:GetChildren() do
			if v ~= script.Parent.Parent then
				if v:IsA("ScreenGui") then
					v.Enabled = false
				end
			end
		end
	end
end

local function enableTransition(AreaTitle: string)
	local textLoadAnim : RBXScriptConnection = nil
	local tipsAnim : RBXScriptConnection = nil
	
	textLoadAnim = coroutine.wrap(function()
		while true do
			LoopText.Text = "Loading."
			task.wait(0.5)
			LoopText.Text = "Loading.."
			task.wait(0.5)
			LoopText.Text = "Loading..."
			task.wait(0.5)
		end
	end)()
	
	tipsAnim = coroutine.wrap(function()
		while true do
			Ts:Create(TipText, TweenInfo.new(0.4), {TextTransparency = 0}):Play()
			
			local currentTip = Tips[math.random(1, #Tips)]
			if currentTip == lastTip then
				repeat task.wait()
					currentTip = Tips[math.random(1, #Tips)]
				until currentTip ~= lastTip
			end
			
			TipText.Text = currentTip
			task.wait(3.5)
			Ts:Create(TipText, TweenInfo.new(0.4), {TextTransparency = 1}):Play()
			task.wait(0.5)
		end
	end)()
	
	Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	
	if typeof(AreaTitle) == "string" then
		ZoneLoadFrame.ZoneTitle.Text = AreaTitle
	else
		ZoneLoadFrame.ZoneTitle.Text = "Unknow Zone"
	end
	
	task.wait(1)
	
	changeGuis(false)
	ZoneLoadFrame.Visible = true
	Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	
	task.wait(math.random(8, 10))
	
	Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
	
	task.wait(1)
	
	if (textLoadAnim) then
		textLoadAnim:Disconnect()
	end
	if (tipsAnim) then
		tipsAnim:Disconnect()
	end
	
	changeGuis(true)
	ZoneLoadFrame.Visible = false
	Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
end

ZoneTransitionFunc.OnClientInvoke = function(ZoneName: string)
	if not ZoneName then return true end
	
	local ZoneFolder = TeleportZones:FindFirstChild(ZoneName)
	local AreaTitle = ZoneFolder:FindFirstChild("Title") :: StringValue
	
	if AreaTitle then
		task.spawn(enableTransition, AreaTitle.Value)
	else
		task.spawn(enableTransition)
	end
	
	return true -- Send to the server that teleported successfully
end