--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local MoneyEarnEvent = Remotes:FindFirstChild("MoneyEarn")

--//UI
local MainFrame = script.Parent
local CoinsSpawnFrame = MainFrame.CoinsSpawnFrame
local CoinsFrame_Example = CoinsSpawnFrame.CoinsEarnExample_Frame

--//Sounds
local CoinsSound = script:FindFirstChild("CoinSound")

--//Setup
CoinsFrame_Example.Parent = Rs

local function animCoin(amount: number)
	local newCoins = CoinsFrame_Example:Clone()
	newCoins.Parent = CoinsSpawnFrame
	newCoins.Visible = true
	newCoins.Position = UDim2.fromScale(math.random(0, 100)/100, math.random(0, 100)/100)
	newCoins.TextLabel.Text = "+"..amount.." Coins"
	
	CoinsSound:Play()
	local newPos = UDim2.fromScale(newCoins.Position.X.Scale, newCoins.Position.Y.Scale - 0.3)
	Ts:Create(newCoins, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), {Position = newPos}):Play()
	
	task.wait(1.5)
	
	Ts:Create(newCoins, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Size = UDim2.fromScale(0, 0)}):Play()
	task.wait(0.2)
	newCoins.Visible = false
	
	game.Debris:AddItem(newCoins, 3)
end

MoneyEarnEvent.OnClientEvent:Connect(function(amount: number)
	animCoin(amount)
end)