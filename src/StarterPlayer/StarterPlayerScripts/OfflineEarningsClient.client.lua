--SERVICES
local RS = game:GetService("ReplicatedStorage")
local MS = game:GetService("MarketplaceService")
local TS = game:GetService("TweenService")
local Players = game:GetService("Players")

--REFERENCES
local Player = Players.LocalPlayer
local OfflineEarningsRem = RS:WaitForChild("Remotes"):WaitForChild("OfflineEarningsRem")
local NotifModule = require(RS:WaitForChild("Modules").NotifModule)

-- Number Formatter
local names = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc"}
local Nums = {}
for i = 1, #names do table.insert(Nums, 1000^i) end
local function FrmtNum(x)
	local function roundToDecimals(num, decimals)
		local formatString = string.format("%%.%df", decimals)
		return tonumber(string.format(formatString, num))
	end
	local ab = math.abs(x)
	local p = math.min(math.floor(math.log10(ab)/3), #names)
	if ab < 1000 then return roundToDecimals(x, 2) end 
	local num = roundToDecimals(ab / Nums[p], 2)
	return num * math.sign(x) .. names[p]
end

repeat task.wait(1) until Player:FindFirstChild("PlayerInfo") and Player.Character:FindFirstChild("ToolFolder")

-- [[ UI REFERENCES ]]
local PlayerGui = Player:WaitForChild("PlayerGui")
local HUD = PlayerGui:WaitForChild("HUD")
-- Make sure this matches where you actually put the UI frame in StarterGui!
local OfflineUI = HUD:WaitForChild("OfflineReward") 
local StatsFrame = OfflineUI:WaitForChild("Stats")

local DOUBLE_PRODUCT_ID = 3591446724

-- Variables to hold current base earnings
local currentIng = 0
local currentCash = 0
local currentGF = 0

-- [[ HOVER EFFECTS ]]
OfflineUI.DoubleEarnings.MouseEnter:Connect(function()
	if currentCash > 0 then StatsFrame.Cash.CashAmount.Text = "+" .. FrmtNum(currentCash * 2) end
	if currentGF > 0 then StatsFrame["Gourmet Food"]["Gourmet FoodAmount"].Text = "+" .. FrmtNum(currentGF * 2) end
	if currentIng > 0 then StatsFrame.Ingredients.IngredientsAmount.Text = "+" .. FrmtNum(currentIng * 2) end

	-- Make text turn green to indicate a boost
	StatsFrame.Cash.CashAmount.TextColor3 = Color3.fromRGB(85, 255, 0)
	StatsFrame["Gourmet Food"]["Gourmet FoodAmount"].TextColor3 = Color3.fromRGB(85, 255, 0)
	StatsFrame.Ingredients.IngredientsAmount.TextColor3 = Color3.fromRGB(85, 255, 0)
end)

OfflineUI.DoubleEarnings.MouseLeave:Connect(function()
	if currentCash > 0 then StatsFrame.Cash.CashAmount.Text = "+" .. FrmtNum(currentCash) end
	if currentGF > 0 then StatsFrame["Gourmet Food"]["Gourmet FoodAmount"].Text = "+" .. FrmtNum(currentGF) end
	if currentIng > 0 then StatsFrame.Ingredients.IngredientsAmount.Text = "+" .. FrmtNum(currentIng) end

	-- Revert to white
	StatsFrame.Cash.CashAmount.TextColor3 = Color3.fromRGB(255, 255, 255)
	StatsFrame["Gourmet Food"]["Gourmet FoodAmount"].TextColor3 = Color3.fromRGB(255, 255, 255)
	StatsFrame.Ingredients.IngredientsAmount.TextColor3 = Color3.fromRGB(255, 255, 255)
end)

-- [[ BUTTON CLICKS ]]
OfflineUI.CollectEarnings.MouseButton1Click:Connect(function()
	OfflineEarningsRem:FireServer("StandardClaim")
end)

OfflineUI.DoubleEarnings.MouseButton1Click:Connect(function()
	MS:PromptProductPurchase(Player, DOUBLE_PRODUCT_ID)
end)

OfflineUI.Close.MouseButton1Click:Connect(function()
	local Tween = TS:Create(OfflineUI, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 1.5)})
	Tween:Play()
	Tween.Completed:Once(function() OfflineUI.Visible = false end)
end)

-- [[ SERVER LISTENER ]]
OfflineEarningsRem.OnClientEvent:Connect(function(Action, Data)
	if Action == "OpenUI" then
		currentIng = Data.Ing
		currentCash = Data.Cash
		currentGF = Data.GF

		-- Setup UI
		if currentCash > 0 then
			StatsFrame.Cash.Visible = true
			StatsFrame.Cash.CashAmount.Text = "+" .. FrmtNum(currentCash)
		else StatsFrame.Cash.Visible = false end

		if currentGF > 0 then
			StatsFrame["Gourmet Food"].Visible = true
			StatsFrame["Gourmet Food"]["Gourmet FoodAmount"].Text = "+" .. FrmtNum(currentGF)
		else StatsFrame["Gourmet Food"].Visible = false end

		if currentIng > 0 then
			StatsFrame.Ingredients.Visible = true
			StatsFrame.Ingredients.IngredientsAmount.Text = "+" .. FrmtNum(currentIng)
		else StatsFrame.Ingredients.Visible = false end

		-- Pop Up Animation
		OfflineUI.Position = UDim2.fromScale(0.5, -0.5)
		OfflineUI.Visible = true
		TS:Create(OfflineUI, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {Position = UDim2.fromScale(0.5, 0.5)}):Play()

	elseif Action == "StandardSuccess" or Action == "DoubledSuccess" then
		-- Close Menu
		local Tween = TS:Create(OfflineUI, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Position = UDim2.fromScale(0.5, 1.5)})
		Tween:Play()
		Tween.Completed:Once(function() OfflineUI.Visible = false end)

		-- Play Sound
		local ChaChing = RS:WaitForChild("Assets").SFX:FindFirstChild("ChaChing")
		if ChaChing then
			local snd = Instance.new("Sound", Player.Character and Player.Character.PrimaryPart or workspace)
			snd.SoundId = ChaChing.SoundId
			snd.Volume = 0.5
			snd:Play()
			game.Debris:AddItem(snd, 2)
		end

		-- Send Notifications
		if Data.Ing > 0 then NotifModule.Notify(Player, "Offline: +" .. FrmtNum(Data.Ing) .. " Ingredients!") end
		task.wait(0.2)
		if Data.Cash > 0 then NotifModule.Notify(Player, "Offline: +" .. FrmtNum(Data.Cash) .. " Cash!") end
		task.wait(0.2)
		if Data.GF > 0 then NotifModule.Notify(Player, "Offline: +" .. FrmtNum(Data.GF) .. " Gourmet Food!") end
	end
end)