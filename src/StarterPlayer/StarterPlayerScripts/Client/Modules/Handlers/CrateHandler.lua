local Handler = {}

--services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

--player references
local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

--ui references
local MainGui = PlayerGui:WaitForChild("TD")
local Frames = MainGui:WaitForChild("Frames")

--data references
local UserData = Player:WaitForChild("UserData")

--modules
local Modules = ReplicatedStorage:WaitForChild("Modules")
local StoredData = Modules:WaitForChild("StoredData")
local TowerData = require(StoredData:WaitForChild("TowerData"))
local CrateData = require(StoredData:WaitForChild("CrateData"))

--config and assets
local CurrencyConfig = {
	Coins = {Symbol = "$", Color = Color3.fromRGB(255, 213, 0), UseIcon = true},
	Gems = {Symbol = "", Color = Color3.fromRGB(0, 255, 127), UseIcon = false},
	Robux = {Symbol = "R$", Color = Color3.fromRGB(0, 255, 0), UseIcon = false}
}

local RarityOrder = {"Mythic", "Legendary", "Epic", "Rare", "Common"}

--chance templates
local ChanceCommon = script.Template_Common_Chance
local ChanceUncommon = script.Template_Uncommon_Chance
local ChanceRare = script.Template_Rare_Chance
local ChanceEpic = script.Template_Epic_Chance
local ChanceLegendary = script.Template_Legendary_Chance

--returns the appropriate chance template based on rarity
local function getChance(rarity)
	rarity = rarity or "Common"

	if rarity == "Common" then
		return ChanceCommon:Clone()
	elseif rarity == "Uncommon" then
		return ChanceUncommon:Clone()
	elseif rarity == "Rare" then
		return ChanceRare:Clone()
	elseif rarity == "Epic" then
		return ChanceEpic:Clone()
	elseif rarity == "Legendary" or rarity == "Mythic" then
		return ChanceLegendary:Clone()
	end

	warn("Unknown rarity:", rarity)
	return ChanceCommon:Clone()
end

--formats a number with commas
local function formatWithCommas(n)
	return tostring(n):reverse():gsub("%d%d%d", "%1,"):reverse():gsub("^,", "")
end

local function getBannerInfo(bannerName)
	local timestamp = os.time()

	if type(CrateData.GetBanner) == "function" then
		return CrateData.GetBanner(bannerName, timestamp)
	end

	local resolvedBannerName = bannerName
	if type(CrateData.ResolveBannerName) == "function" then
		resolvedBannerName = CrateData.ResolveBannerName(bannerName, timestamp)
	end

	local banners = CrateData.Banners
	return banners and banners[resolvedBannerName], resolvedBannerName
end

local function getUnitsForBanner(bannerName, targetRarity)
	if type(CrateData.GetUnitsForBanner) == "function" then
		return CrateData.GetUnitsForBanner(bannerName, targetRarity, os.time())
	end

	local bannerInfo = getBannerInfo(bannerName)
	local candidates = {}

	if bannerInfo and bannerInfo.UnitPoolByRarity and bannerInfo.UnitPoolByRarity[targetRarity] then
		for _, unitName in ipairs(bannerInfo.UnitPoolByRarity[targetRarity]) do
			table.insert(candidates, unitName)
		end
	elseif type(CrateData.UnitTiers) == "table" then
		for unitName, tier in pairs(CrateData.UnitTiers) do
			if tier == targetRarity then
				table.insert(candidates, unitName)
			end
		end
	end

	table.sort(candidates)
	return candidates
end

local function getUnitsInRotation(bannerName, targetRarity)
	local bannerInfo = getBannerInfo(bannerName)
	local allUnitsOfRarity = getUnitsForBanner(bannerName, targetRarity)

	if #allUnitsOfRarity == 0 then
		return {}
	end

	if bannerInfo and bannerInfo.DisableHourlyRotation then
		return allUnitsOfRarity
	end

	local currentHour = math.floor(os.time() / 3600)
	local rng = Random.new(currentHour)

	if #allUnitsOfRarity <= 2 then
		return allUnitsOfRarity
	end

	local rotatedUnits = {}
	local available = { table.unpack(allUnitsOfRarity) }

	for _ = 1, 2 do
		if #available == 0 then
			break
		end

		local idx = rng:NextInteger(1, #available)
		table.insert(rotatedUnits, available[idx])
		table.remove(available, idx)
	end

	return rotatedUnits
end

--helper to get the best unit
local function getBestUnitForBanner(bannerName)
	local bannerInfo = getBannerInfo(bannerName)
	if not bannerInfo then return nil end

	for _, rarity in ipairs(RarityOrder) do
		if bannerInfo.Rates[rarity] and bannerInfo.Rates[rarity] > 0 then
			local units = getUnitsInRotation(bannerName, rarity)
			if units and #units > 0 then
				return units[1] 
			end
		end
	end

	return "Scout"
end

local function formatRotationCountdown(secondsRemaining)
	secondsRemaining = math.max(0, math.floor(secondsRemaining or 0))
	local hours = math.floor(secondsRemaining / 3600)
	local minutes = math.floor((secondsRemaining % 3600) / 60)
	local seconds = secondsRemaining % 60
	return string.format("%02d:%02d:%02d", hours, minutes, seconds)
end

local function getSecondsUntilNextTemporaryRotation(timestamp)
	if type(CrateData.GetSecondsUntilNextTemporaryRotation) == "function" then
		return CrateData.GetSecondsUntilNextTemporaryRotation(timestamp)
	end

	return 0
end

local function isSupportedCrateButtonName(buttonName)
	if buttonName == "Temporary" then
		return type(CrateData.ResolveBannerName) == "function" or type(CrateData.GetBanner) == "function"
	end

	return type(CrateData.Banners) == "table" and CrateData.Banners[buttonName] ~= nil
end

local function getResolvedCrateName(crateName)
	local _, resolvedCrateName = getBannerInfo(crateName)
	return resolvedCrateName or crateName
end

local function findFirstNamedDescendant(root, names)
	if not root then
		return nil
	end

	for _, targetName in ipairs(names) do
		local directChild = root:FindFirstChild(targetName)
		if directChild then
			return directChild
		end
	end

	for _, targetName in ipairs(names) do
		local descendant = root:FindFirstChild(targetName, true)
		if descendant then
			return descendant
		end
	end

	return nil
end

local function describeMissingUi(priceText, ownedLabel, crateIcon)
	local missing = {}

	if not priceText then
		table.insert(missing, "Price")
	end

	if not ownedLabel then
		table.insert(missing, "Owned")
	end

	if not crateIcon then
		table.insert(missing, "MainIcon/Icon")
	end

	return table.concat(missing, ", ")
end

local function waitForDescendant(root, name, timeout)
	local deadline = os.clock() + (timeout or 5)

	repeat
		local found = root:FindFirstChild(name, true)
		if found then
			return found
		end

		task.wait(0.1)
	until os.clock() >= deadline

	warn("[CrateHandler] Missing UI object:", name, "under", root:GetFullName())
	return nil
end

-- Function to completely detach a button from GuiManager
local function SanitizeButton(originalButton, parent)
	local clone = originalButton:Clone()

	-- Remove the tag so GuiManager ignores it
	if CollectionService:HasTag(clone, "Button") then
		CollectionService:RemoveTag(clone, "Button")
	end

	clone.Parent = parent
	originalButton:Destroy() -- Kill the old one that GuiManager is tracking

	return clone
end

-- Custom Hover Animation
local function AddHoverEffect(button)
	local originalSize = button.Size

	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.15, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale * 1.075, 0, originalSize.Y.Scale * 1.075, 0)
		}):Play()
	end)

	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
			Size = originalSize
		}):Play()
	end)

	button.MouseButton1Down:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.08, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale * 0.9, 0, originalSize.Y.Scale * 0.9, 0)
		}):Play()
	end)

	button.MouseButton1Up:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale * 1.1, 0, originalSize.Y.Scale * 1.1, 0)
		}):Play()
	end)
end

--handles all crate ui functionality
local function HandleCrateUI()
	task.spawn(function()

		--ui references
		local CrateFrame = Frames:WaitForChild("Crates")
		local CrateHolder = CrateFrame:FindFirstChild("Holder") or waitForDescendant(CrateFrame, "Holder", 5)
		local PreviewContainer = (CrateHolder and CrateHolder:FindFirstChild("ItemFrame")) or waitForDescendant(CrateFrame, "ItemFrame", 5)
		if not PreviewContainer then
			return
		end

		local ChancesFrame = PreviewContainer:FindFirstChild("ChancesFrame") or waitForDescendant(PreviewContainer, "ChancesFrame", 5)
		if not ChancesFrame then
			return
		end

		--remove layout constraints to prevent button jumping
		for _, child in ipairs(PreviewContainer:GetChildren()) do
			if child:IsA("UIListLayout") or child:IsA("UIGridLayout") then
				child:Destroy()
			end
		end

		--preview elements
		local PreviewTitle = PreviewContainer:FindFirstChild("CrateName") or waitForDescendant(PreviewContainer, "CrateName", 5)
		local OpenButtonOriginal = PreviewContainer:FindFirstChild("Open") or waitForDescendant(PreviewContainer, "Open", 5)
		local PurchaseButtonOriginal = PreviewContainer:FindFirstChild("Buy") or waitForDescendant(PreviewContainer, "Buy", 5)
		local ChancesButtonOriginal = PreviewContainer:FindFirstChild("Chances") or waitForDescendant(PreviewContainer, "Chances", 5)
		if not PreviewTitle or not OpenButtonOriginal or not PurchaseButtonOriginal or not ChancesButtonOriginal then
			return
		end

		-- REPLACE BUTTONS TO KILL GUIMANAGER CONFLICT
		local ChancesButton = SanitizeButton(ChancesButtonOriginal, PreviewContainer)
		AddHoverEffect(ChancesButton)

		local OpenButton = OpenButtonOriginal
		local PurchaseButton = PurchaseButtonOriginal

		local AmountFrame = (CrateHolder and CrateHolder:FindFirstChild("Amount")) or CrateFrame:FindFirstChild("Amount", true)
		local PriceText = findFirstNamedDescendant(AmountFrame, {"Price"})
			or findFirstNamedDescendant(PurchaseButton, {"Price"})
			or findFirstNamedDescendant(CrateHolder, {"Price"})
			or findFirstNamedDescendant(CrateFrame, {"Price"})
		local PriceIcon = findFirstNamedDescendant(AmountFrame, {"Icon"})
		local OwnedAmountLabel = findFirstNamedDescendant(CrateHolder, {"Owned"})
			or findFirstNamedDescendant(OpenButton, {"Owned"})
		local ItemBG = PreviewContainer:FindFirstChild("ItemBG") or PreviewContainer:FindFirstChild("ItemBG", true)
		local CrateIcon = findFirstNamedDescendant(ItemBG, {"MainIcon", "MainIon", "Icon"})
			or findFirstNamedDescendant(PreviewContainer, {"MainIcon", "MainIon"})
		if not PriceText or not OwnedAmountLabel or not CrateIcon then
			warn("[CrateHandler] Missing required preview labels/icons under:", PreviewContainer:GetFullName(), "missing:", describeMissingUi(PriceText, OwnedAmountLabel, CrateIcon))
			return
		end

		--scripted ui elements

		--timer label
		local TimerLabel = Instance.new("TextLabel")
		TimerLabel.Name = "ResetTimer"
		TimerLabel.Size = UDim2.new(1, 0, 0, 35)
		TimerLabel.Position = UDim2.new(0, 0, 0.12, 0) 
		TimerLabel.BackgroundTransparency = 1
		TimerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		TimerLabel.TextStrokeTransparency = 0
		TimerLabel.Font = Enum.Font.GothamBlack 
		TimerLabel.TextSize = 32
		TimerLabel.ZIndex = 100 
		TimerLabel.Parent = PreviewContainer

		--chances button positioning setup
		-- ZINDEX 302: O botão ? tem que estar ACIMA da lista (que será 300)
		--ChancesButton.ZIndex = 302 

		--pity label
		local PityLabel = Instance.new("TextLabel")
		PityLabel.Name = "PityCounter"
		PityLabel.Size = UDim2.new(1, 0, 0, 20)
		PityLabel.Position = UDim2.new(0, 0, 0.65, 0) 
		PityLabel.BackgroundTransparency = 1
		PityLabel.TextColor3 = Color3.fromRGB(255, 85, 127)
		PityLabel.TextStrokeTransparency = 0
		PityLabel.Font = Enum.Font.GothamBlack
		PityLabel.TextSize = 16
		PityLabel.ZIndex = 100 
		PityLabel.Parent = PreviewContainer

		--state
		local SelectedCrate = "Normal"

		--crate icon assets
		local CrateIcons = {
			Normal = "rbxassetid://79132028062877",
			Steel = "rbxassetid://78854786317873",
			Golden = "rbxassetid://77544826310708",
			Diamond = "rbxassetid://139414131564390",
			["Basic Weapon Crate"] = "rbxassetid://79132028062877",
			["Explosive Crate"] = "rbxassetid://77544826310708",
			["Utility Crate"] = "rbxassetid://78854786317873",
			["Legendary Arsenal Crate"] = "rbxassetid://77544826310708",
			["Event Crate"] = "rbxassetid://139414131564390",
			["Mythic Mayhem Crate"] = "rbxassetid://139414131564390",
		}

		local function applyPriceLabel(targetLabel, bannerInfo, useCurrencyColor)
			if not targetLabel then
				return
			end

			if bannerInfo then
				local currencyData = CurrencyConfig[bannerInfo.Currency] or CurrencyConfig.Coins
				if bannerInfo.Currency == "Gems" then
					targetLabel.Text = currencyData.Symbol .. " " .. formatWithCommas(bannerInfo.Price)
				else
					targetLabel.Text = currencyData.Symbol .. formatWithCommas(bannerInfo.Price)
				end

				if useCurrencyColor then
					targetLabel.TextColor3 = currencyData.Color
				else
					targetLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			else
				targetLabel.Text = "N/A"
			end
		end

		--update preview function
		local function updatePreview(hideItemFrame)
			local BannerInfo, ResolvedCrateName = getBannerInfo(SelectedCrate)
			ResolvedCrateName = ResolvedCrateName or SelectedCrate

			--toggle visibility
			if not hideItemFrame then
				PreviewContainer.Visible = true
			else
				ChancesFrame.Visible = false
			end

			--update labels
			PreviewTitle.Text = BannerInfo and BannerInfo.DisplayName or ResolvedCrateName
			TimerLabel.Visible = SelectedCrate == "Temporary"
			TimerLabel.Text = TimerLabel.Visible and ("ROTATES IN " .. formatRotationCountdown(getSecondsUntilNextTemporaryRotation(os.time()))) or ""

			--update pity
			local pityFolder = UserData:FindFirstChild("BannerPity")
			local currentPity = 0
			if pityFolder and pityFolder:FindFirstChild(ResolvedCrateName) then
				currentPity = pityFolder[ResolvedCrateName].Value
			end
			local threshold = BannerInfo and BannerInfo.PityThreshold or 50
			PityLabel.Text = "PITY: " .. currentPity .. " / " .. threshold

			--update icon
			if CrateIcons[ResolvedCrateName] then
				CrateIcon.Image = CrateIcons[ResolvedCrateName]
			end

			--update owned amount
			local CratesFolder = UserData:FindFirstChild("Crates")
			local ownedAmount = 0
			if CratesFolder and CratesFolder:FindFirstChild(ResolvedCrateName) then
				ownedAmount = CratesFolder[ResolvedCrateName].Value
			end

			OwnedAmountLabel.Visible = true
			OwnedAmountLabel.Text = "Owned: " .. ownedAmount
			OpenButton.Visible = true 
			if PriceIcon then
				PriceIcon.Visible = false
			end

			--update price
			applyPriceLabel(PriceText, BannerInfo, true)
			if BannerInfo then
				local currencyData = CurrencyConfig[BannerInfo.Currency] or CurrencyConfig.Coins
				if PriceIcon then
					PriceIcon.Visible = currencyData.UseIcon
				end
			else
				PriceText.Text = "???"
			end
		end

		--setup crate buttons (REMOVED VIEWPORT LOGIC AS REQUESTED)
		for _, Button in ipairs(CrateFrame:GetDescendants()) do
			if not Button:IsA("GuiButton") or not isSupportedCrateButtonName(Button.Name) then continue end

			local ButtonPriceText = findFirstNamedDescendant(Button, {"Price"})

			local BannerInfo = getBannerInfo(Button.Name)
			applyPriceLabel(ButtonPriceText, BannerInfo, BannerInfo and BannerInfo.Currency == "Gems")

			Button.Activated:Connect(function()
				SelectedCrate = Button.Name
				ChancesFrame.Visible = false
				updatePreview()
			end)

			-- REMOVIDO: MouseEnter/MouseLeave do Viewport (O "segundo glossário")
		end

		--visible signal
		CrateFrame:GetPropertyChangedSignal("Visible"):Connect(function()
			if CrateFrame.Visible then
				SelectedCrate = "Normal"
				ChancesFrame.Visible = false
				updatePreview(false)
			end
		end)

		updatePreview(false)

		--chances hover
		ChancesButton.MouseEnter:Connect(function()
			ChancesFrame.Visible = true
			-- ZINDEX 300: Glossário acima de tudo, menos do botão ?
			ChancesFrame.ZIndex = 300 

			for _, Frame in ipairs(ChancesFrame:GetChildren()) do
				if Frame:IsA("ImageButton") then
					Frame:Destroy()
				end
			end

			if not SelectedCrate then return end
			local BannerInfo = getBannerInfo(SelectedCrate)
			if not BannerInfo then return end

			local Rates = BannerInfo.Rates

			for _, RarityName in ipairs(RarityOrder) do
				local RateValue = Rates[RarityName]

				if RateValue and RateValue > 0 then

					local activeUnits = getUnitsInRotation(SelectedCrate, RarityName)

					if #activeUnits == 0 then continue end

					for _, unitName in ipairs(activeUnits) do
						local NewEntry = getChance(RarityName)
						NewEntry.Parent = ChancesFrame
						NewEntry.Visible = true

						NewEntry.Size = UDim2.new(1, 0, 0, 50) 
						-- ZINDEX 301: Itens da lista acima do fundo da lista
						NewEntry.ZIndex = 301

						local individualChance = (RateValue / 100) / #activeUnits

						NewEntry.Chance.Text = string.format("%.2f%%", individualChance)
						NewEntry.WormName.Text = unitName 

						-- Setar ZIndex dos textos e imagens
						NewEntry.Chance.ZIndex = 301
						NewEntry.WormName.ZIndex = 301

						if TowerData[unitName] and TowerData[unitName].ImageId then
							NewEntry.Worm_Icon.Visible = true
							NewEntry.Worm_Icon.Image = "rbxassetid://" .. TowerData[unitName].ImageId
							NewEntry.Worm_Icon.ZIndex = 301
						else
							NewEntry.Worm_Icon.Visible = false
						end
					end
				end
			end
		end)

		ChancesButton.MouseLeave:Connect(function()
			ChancesFrame.Visible = false
		end)

		--open handler
		OpenButton.Activated:Connect(function()
			ReplicatedStorage.Remotes.Game.Unbox:FireServer(getResolvedCrateName(SelectedCrate))
			updatePreview()
		end)

		--buy handler
		PurchaseButton.Activated:Connect(function()
			local CratesFolder = UserData:FindFirstChild("Crates")
			if not CratesFolder then return end

			local ResolvedCrateName = getResolvedCrateName(SelectedCrate)
			local BannerInfo = getBannerInfo(SelectedCrate)
			if not BannerInfo then return end

			local Crate = CratesFolder:FindFirstChild(ResolvedCrateName)
			local oldAmount = Crate and Crate.Value or 0

			if BannerInfo.Currency == "Robux" then
				if SelectedCrate == "Diamond" then
					MarketplaceService:PromptProductPurchase(Player, 3449816999)
				end
			else
				ReplicatedStorage.Remotes.Game.PurchaseBox:FireServer(ResolvedCrateName)
			end

			task.spawn(function()
				local timeout = 5
				local startTime = tick()
				local found = false

				repeat
					task.wait(0.1)
					Crate = CratesFolder:FindFirstChild(ResolvedCrateName)
					if Crate and Crate.Value > oldAmount then
						found = true
					end
				until found or (tick() - startTime > timeout)

				if found then
					ReplicatedStorage.Remotes.Game.Unbox:FireServer(ResolvedCrateName)
					updatePreview()
				end
			end)
		end)
	end)
end

--initialize
HandleCrateUI()

return Handler
