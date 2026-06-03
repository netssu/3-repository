local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")

local Player = Players.LocalPlayer
local PlayerGui = Player.PlayerGui

local MainUi = PlayerGui:WaitForChild("TD")
local Frames = MainUi:WaitForChild("Frames")
local WormsInventory = Frames:WaitForChild("Worms")

local Modules = ReplicatedStorage:WaitForChild("Modules")
local StoredData = Modules:WaitForChild("StoredData")
local TowerData = require(StoredData:WaitForChild("TowerData"))
local TowerLevelData = require(StoredData:WaitForChild("TowerLevelData"))
local ConsumableData = require(StoredData:WaitForChild("ConsumableData"))

local PlayerData = Player:WaitForChild("UserData")
local PlayerInventory = PlayerData:WaitForChild("Inventory")
local PlayerHotbar = PlayerData:WaitForChild("Hotbar")
local PlayerConsumables = PlayerData:WaitForChild("Consumables")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local InventoryRemotes = Remotes:WaitForChild("Inventory")
local SellRemote = InventoryRemotes:WaitForChild("Sell")
local UseConsumableRemote = InventoryRemotes:WaitForChild("UseConsumable")

local GuiManager = require(script.Parent.Parent.Managers.GuiManager)

local Handler = {}

local Selected = nil
local SelectedConsumable = nil
local CurrentFilter = ""

local RarityRanks = { Legendary = 5, Epic = 4, Rare = 3, Uncommon = 2, Common = 1 }
local LayoutOrder = { Common = 10, Uncommon = 9, Rare = 8, Epic = 7, Legendary = 6 }

local RarityColor = {
	["Common"] = ColorSequence.new(Color3.fromRGB(238, 235, 255), Color3.fromRGB(57, 56, 70)),
	["Uncommon"] = ColorSequence.new(Color3.fromRGB(199, 255, 213), Color3.fromRGB(23, 70, 19)),
	["Rare"] = ColorSequence.new(Color3.fromRGB(148, 185, 255), Color3.fromRGB(24, 40, 70)),
	["Epic"] = ColorSequence.new(Color3.fromRGB(162, 69, 255), Color3.fromRGB(34, 21, 70)),
	["Legendary"] = ColorSequence.new(Color3.fromRGB(255, 226, 137), Color3.fromRGB(70, 53, 28)),
}

local function isTextObject(obj): boolean
	return obj and (obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox"))
end

local function isImageObject(obj): boolean
	return obj and (obj:IsA("ImageLabel") or obj:IsA("ImageButton"))
end

local function setText(obj, value: string)
	if isTextObject(obj) then
		obj.Text = value
	end
end

local function setImage(obj, imageId)
	if not isImageObject(obj) then
		return
	end

	if imageId == nil or imageId == "" then
		obj.Image = ""
		return
	end

	obj.Image = "rbxassetid://" .. tostring(imageId)
end

local function getDisplayName(unitName: string): string
	return tostring(unitName):gsub("_%d+$", "")
end

local function findByName(root: Instance?, names: { string }, recursive: boolean?, className: string?)
	if not root then
		return nil
	end

	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name, recursive == true)
		if found then
			if not className or found:IsA(className) then
				return found
			end
		end
	end

	return nil
end

local function getModel(itemName: string)
	return ReplicatedStorage:WaitForChild("Storage"):WaitForChild("Towers"):FindFirstChild(itemName)
end

local function getInventorySlot(baseName: string)
	for _, slot in ipairs(PlayerInventory:GetChildren()) do
		if slot:IsA("Folder") then
			local nameVal = slot:FindFirstChild("Name")
			if nameVal and nameVal.Value == baseName then
				return slot
			end
		end
	end
	return nil
end

local function readSlotEntry(baseName: string)
	local slot = getInventorySlot(baseName)
	if not slot then
		return nil
	end

	local function val(name, default)
		local v = slot:FindFirstChild(name)
		return v and v.Value or default
	end

	return {
		Name = val("Name", baseName),
		Level = val("Level", 1),
		EXP = val("EXP", 0),
		Damage = val("Damage", 0),
		Range = val("Range", 0),
		AttackCooldown = val("AttackCooldown", 0),
	}
end

local function computeTowerStats(towerName: string, entry: table)
	local towerInfo = TowerData[towerName]
	if not towerInfo or not towerInfo.BaseStats then
		return nil
	end

	local baseDamage = towerInfo.BaseStats.Damage or 0
	local baseRange = towerInfo.BaseStats.Range or 0
	local baseCooldown = towerInfo.BaseStats.AttackCooldown or 1

	return TowerLevelData.computeStats(
		baseDamage,
		baseRange,
		baseCooldown,
		entry.Level,
		entry.Damage,
		entry.Range,
		entry.AttackCooldown
	)
end

local function checkEquipped(unitName: string): boolean
	local targetBase = getDisplayName(unitName)

	for _, slot in ipairs(PlayerHotbar:GetChildren()) do
		if slot:IsA("StringValue") then
			if slot.Value == unitName then
				return true
			end

			if slot.Value ~= "" and getDisplayName(slot.Value) == targetBase then
				return true
			end
		end
	end

	return false
end

local function getWormsUi()
	local wormsBg = WormsInventory:FindFirstChild("WormsBG") or WormsInventory

	local itemFrame = wormsBg:FindFirstChild("ItemFR")
		or WormsInventory:FindFirstChild("ItemFrame")
		or WormsInventory:FindFirstChild("ItemFR", true)

	local itemOptions = itemFrame and (itemFrame:FindFirstChild("ItemOptionBG") or itemFrame) or nil

	local wormListFr = wormsBg:FindFirstChild("WormListFR") or WormsInventory:FindFirstChild("WormListFR", true)
	local wormListBg = wormListFr and (wormListFr:FindFirstChild("WormListBG") or wormListFr) or nil
	local wormListScrolling = wormListBg
		and (wormListBg:FindFirstChild("GridScrollingFrame")
			or wormListBg:FindFirstChild("ScrollingFrame")
			or wormListBg:FindFirstChild("GridScrollingFrame", true)
			or wormListBg:FindFirstChild("ScrollingFrame", true))
		or WormsInventory:FindFirstChild("ScrollingFrame")

	local consumablesBg = WormsInventory:FindFirstChild("ConsumablesBG")
		or WormsInventory:FindFirstChild("Consumables", true)
	local consumablesListFr = consumablesBg
		and (consumablesBg:FindFirstChild("ConsumableListFR")
			or consumablesBg:FindFirstChild("Consumables")
			or consumablesBg)
		or nil
	local consumablesScrolling = consumablesListFr
		and (consumablesListFr:FindFirstChild("GridScrollingFrame")
			or consumablesListFr:FindFirstChild("ScrollingFrame")
			or consumablesListFr:FindFirstChild("GridScrollingFrame", true)
			or consumablesListFr:FindFirstChild("ScrollingFrame", true))
		or WormsInventory:FindFirstChild("Consumables", true)
			and WormsInventory:FindFirstChild("Consumables", true):FindFirstChild("ScrollingFrame")

	local searchBox = findByName(WormsInventory, { "SearchTBX", "SearchTextBox", "SearchBox" }, true, "TextBox")
	local searchButton = findByName(WormsInventory, { "Search" }, true, "GuiButton")

	local countLabels = {}
	local oldCount = WormsInventory:FindFirstChild("Count", true)
	if oldCount then
		local oldCountLabel = oldCount:FindFirstChild("Count")
		if isTextObject(oldCountLabel) then
			table.insert(countLabels, oldCountLabel)
		end
	end

	local storageBg = WormsInventory:FindFirstChild("StorageBG", true)
	if storageBg then
		local fallback = nil
		for _, desc in ipairs(storageBg:GetDescendants()) do
			if isTextObject(desc) and (desc.Name == "WormsTX" or desc.Name == "Count") then
				local txt = string.lower(desc.Text or "")
				if txt:find("/") or txt:find("%d") then
					table.insert(countLabels, desc)
				elseif not fallback then
					fallback = desc
				end
			end
		end

		if #countLabels == 0 and fallback then
			table.insert(countLabels, fallback)
		end
	end

	local equipButton = itemOptions and findByName(itemOptions, { "Equipp", "Equip", "EquipBT" }, true, "GuiButton") or nil
	local unequipSelectionButton = itemOptions
		and findByName(itemOptions, { "Unequipp", "Unequip", "UnequipBT" }, true, "GuiButton")
		or nil
	local sellButton = findByName(WormsInventory, { "Sell", "SellBT" }, true, "GuiButton")
	local equipAllButton = findByName(WormsInventory, { "Best", "BestBT", "EquipAll", "EquipAllBT" }, true, "GuiButton")

	local unequipButtons = {}
	for _, d in ipairs(WormsInventory:GetDescendants()) do
		if d:IsA("GuiButton") and (d.Name == "Unequip" or d.Name == "UnequipBT") then
			table.insert(unequipButtons, d)
		end
	end

	local openCratesButtons = {}
	for _, d in ipairs(WormsInventory:GetDescendants()) do
		if d:IsA("GuiButton") and (d.Name == "OpenCrates" or d.Name == "OpenCratesBT") then
			table.insert(openCratesButtons, d)
		end
	end

	local damageFrame = itemOptions and itemOptions:FindFirstChild("Damage") or nil
	local rangeFrame = itemOptions and itemOptions:FindFirstChild("Range") or nil
	local rateFrame = itemOptions and itemOptions:FindFirstChild("Rate") or nil
	local levelFrame = itemOptions and itemOptions:FindFirstChild("Level") or nil

	if not damageFrame and itemFrame then
		damageFrame = itemFrame:FindFirstChild("Damage")
	end
	if not rangeFrame and itemFrame then
		rangeFrame = itemFrame:FindFirstChild("Range")
	end
	if not rateFrame and itemFrame then
		rateFrame = itemFrame:FindFirstChild("Rate")
	end
	if not levelFrame and itemFrame then
		levelFrame = itemFrame:FindFirstChild("Level")
	end

	local levelBarBg = levelFrame and levelFrame:FindFirstChild("BarBG")
	local levelBarFill = levelBarBg and levelBarBg:FindFirstChild("BarBT")
	local levelStat = levelFrame and levelFrame:FindFirstChild("Stat")

	local nameLabel = itemOptions and findByName(itemOptions, { "NameWormsTX", "WormName", "WormNameTX" }, true)
	local imageLabel = itemOptions and findByName(itemOptions, { "ImageTower", "ItemImage", "MainIcon" }, true)
	if not imageLabel then
		local itemBg = itemOptions and findByName(itemOptions, { "ItemBG" }, true)
		imageLabel = itemBg and (itemBg:FindFirstChild("ImageTower") or findByName(itemBg, { "ImageTower" }, true))
	end

	return {
		WormsBG = wormsBg,
		ItemFrame = itemFrame,
		ItemOptions = itemOptions,
		InventoryScrolling = wormListScrolling,
		ConsumablesScrolling = consumablesScrolling,
		SearchBox = searchBox,
		SearchButton = searchButton,
		CountLabels = countLabels,
		EquipButton = equipButton,
		UnequipSelectionButton = unequipSelectionButton,
		SellButton = sellButton,
		EquipAllButton = equipAllButton,
		UnequipButtons = unequipButtons,
		OpenCratesButtons = openCratesButtons,
		DamageFrame = damageFrame,
		RangeFrame = rangeFrame,
		RateFrame = rateFrame,
		LevelFrame = levelFrame,
		LevelBarFill = levelBarFill,
		LevelStat = levelStat,
		NameLabel = nameLabel,
		ImageLabel = imageLabel,
	}
end

local UI = getWormsUi()

local function setStat(frame, value)
	if not frame then
		return
	end

	local stat = frame:FindFirstChild("Stat")
	if stat and isTextObject(stat) then
		stat.Text = tostring(value)
		return
	end

	if isTextObject(frame) then
		frame.Text = tostring(value)
	end
end

local function setCountText(text: string)
	for _, label in ipairs(UI.CountLabels or {}) do
		setText(label, text)
	end
end

local function setEquipButtonState(equipped: boolean)
	local equipButton = UI.EquipButton
	local unequipButton = UI.UnequipSelectionButton
	if not equipButton and not unequipButton then
		return
	end

	if equipButton and unequipButton then
		equipButton.Visible = not equipped
		unequipButton.Visible = equipped
		return
	end

	if not equipButton then
		return
	end

	local textObj = findByName(equipButton, { "MainText", "EquipTX", "UnequipTX", "TextLabel" }, true)
	local targetText = equipped and "Unequip" or "Equip"

	if textObj then
		setText(textObj, targetText)
	elseif equipButton:IsA("TextButton") then
		equipButton.Text = targetText
	end

	local stroke = findByName(equipButton, { "UIStroke" }, true, "UIStroke")
	local textStroke = textObj and textObj:FindFirstChild("UIStroke")
	if textStroke and not textStroke:IsA("UIStroke") then
		textStroke = nil
	end

	if equipped then
		if isImageObject(equipButton) then
			equipButton.ImageColor3 = Color3.fromRGB(255, 28, 51)
		end
		if stroke then
			stroke.Color = Color3.fromRGB(58, 1, 2)
		end
		if textStroke then
			textStroke.Color = Color3.fromRGB(58, 1, 2)
		end
	else
		if isImageObject(equipButton) then
			equipButton.ImageColor3 = Color3.fromRGB(81, 255, 0)
		end
		if stroke then
			stroke.Color = Color3.fromRGB(33, 58, 0)
		end
		if textStroke then
			textStroke.Color = Color3.fromRGB(33, 58, 0)
		end
	end
end

local ConsumableHoverTip: TextLabel? = nil

local function ensureConsumableHoverTip(): TextLabel
	if ConsumableHoverTip and ConsumableHoverTip.Parent then
		return ConsumableHoverTip
	end

	local tip = Instance.new("TextLabel")
	tip.Name = "ConsumableHoverTip"
	tip.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	tip.BackgroundTransparency = 0.1
	tip.TextColor3 = Color3.fromRGB(255, 255, 255)
	tip.TextStrokeTransparency = 0.5
	tip.TextXAlignment = Enum.TextXAlignment.Left
	tip.TextYAlignment = Enum.TextYAlignment.Center
	tip.Font = Enum.Font.GothamSemibold
	tip.TextSize = 13
	tip.ZIndex = 500
	tip.Visible = false
	tip.Parent = MainUi

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = tip

	ConsumableHoverTip = tip
	return tip
end

local function hideConsumableHover()
	local tip = ensureConsumableHoverTip()
	tip.Visible = false
end

local function showConsumableHover(hoverTarget: GuiObject, text: string)
	local tip = ensureConsumableHoverTip()
	local content = text ~= "" and text or "No buff info"
	tip.Text = "  " .. content .. "  "

	local textBounds = TextService:GetTextSize(tip.Text, tip.TextSize, tip.Font, Vector2.new(260, 500))
	local width = math.clamp(textBounds.X + 18, 90, 280)
	local height = math.max(26, textBounds.Y + 10)
	tip.Size = UDim2.fromOffset(width, height)

	local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(1920, 1080)
	local x = hoverTarget.AbsolutePosition.X + hoverTarget.AbsoluteSize.X + 8
	local y = hoverTarget.AbsolutePosition.Y + (hoverTarget.AbsoluteSize.Y / 2) - (height / 2)

	if x + width > viewport.X - 6 then
		x = hoverTarget.AbsolutePosition.X - width - 8
	end

	if y < 6 then
		y = 6
	elseif y + height > viewport.Y - 6 then
		y = viewport.Y - height - 6
	end

	tip.Position = UDim2.fromOffset(math.floor(x), math.floor(y))
	tip.Visible = true
end

local function updateLevelBar(entry: table)
	local level = entry.Level or 1
	local exp = entry.EXP or 0

	setStat(UI.LevelStat, level)

	if UI.LevelBarFill then
		local needed = TowerLevelData.expToNextLevel(level)
		local ratio = (needed == math.huge) and 1 or math.clamp(exp / math.max(needed, 1), 0, 1)
		UI.LevelBarFill.Size = UDim2.new(ratio, 0, UI.LevelBarFill.Size.Y.Scale, UI.LevelBarFill.Size.Y.Offset)
	end
end

local function applyPreviewRarity(unitName: string)
	local itemFrame = UI.ItemFrame
	if not itemFrame then
		return
	end

	local towerModel = getModel(unitName)
	if not towerModel then
		return
	end

	local rarity = towerModel:GetAttribute("Rarity")
	local color = RarityColor[rarity]
	if not color then
		return
	end

	local gradient = itemFrame:FindFirstChild("UIGradient")
	if gradient and gradient:IsA("UIGradient") then
		gradient.Color = color
	end

	local stroke = itemFrame:FindFirstChild("UIStroke")
	local strokeGradient = stroke and stroke:FindFirstChild("UIGradient")
	if strokeGradient and strokeGradient:IsA("UIGradient") then
		strokeGradient.Color = color
	end
end

local function updatePreview(unitName: string)
	local towerInfo = TowerData[unitName]
	if not towerInfo then
		return
	end

	Selected = unitName

	setEquipButtonState(checkEquipped(unitName))

	if UI.ItemFrame and UI.ItemFrame:IsA("GuiObject") then
		UI.ItemFrame.Visible = true
	end

	applyPreviewRarity(unitName)
	setText(UI.NameLabel, getDisplayName(unitName))
	setImage(UI.ImageLabel, towerInfo.ImageId)

	local baseName = getDisplayName(unitName)
	local entry = readSlotEntry(baseName)

	if entry then
		local stats = computeTowerStats(unitName, entry)
		if stats then
			setStat(UI.DamageFrame, stats.Damage)
			setStat(UI.RangeFrame, stats.Range)
			setStat(UI.RateFrame, stats.AttackCooldown)
		end
		updateLevelBar(entry)
	else
		local baseStats = towerInfo.BaseStats
		setStat(UI.DamageFrame, baseStats and baseStats.Damage or "-")
		setStat(UI.RangeFrame, baseStats and baseStats.Range or "-")
		setStat(UI.RateFrame, baseStats and baseStats.AttackCooldown or "-")
		if UI.LevelBarFill then
			UI.LevelBarFill.Size = UDim2.new(0, 0, UI.LevelBarFill.Size.Y.Scale, UI.LevelBarFill.Size.Y.Offset)
		end
	end
end

local function clearContainer(container: Instance?, templateInstance: Instance?)
	if not container then
		return
	end

	for _, child in ipairs(container:GetChildren()) do
		if child == templateInstance then
			continue
		end

		if child:IsA("UIListLayout")
			or child:IsA("UIGridLayout")
			or child:IsA("UIPadding")
			or child:IsA("UIAspectRatioConstraint")
			or child:IsA("UISizeConstraint")
			or child:IsA("UICorner")
			or child:IsA("UIStroke")
		then
			continue
		end

		if child.Name == "OpenCrates" or child.Name == "OpenCratesBT" then
			continue
		end

		child:Destroy()
	end
end

local function getWormTemplate(rarity: string?)
	local scrolling = UI.InventoryScrolling
	if not scrolling then
		return nil
	end

	local template = scrolling:FindFirstChild("WormBT")
		or scrolling:FindFirstChild("Example")
		or scrolling:FindFirstChild("Template")

	if template then
		return template
	end

	if rarity then
		local byRarity = script:FindFirstChild("Template_" .. rarity)
		if byRarity then
			return byRarity
		end
	end

	return script:FindFirstChild("Template_Common")
end

local function getConsumableTemplate()
	local scrolling = UI.ConsumablesScrolling
	if not scrolling then
		return nil
	end

	return scrolling:FindFirstChild("ConsumableBT")
		or scrolling:FindFirstChild("Example")
		or scrolling:FindFirstChild("Template")
		or script:FindFirstChild("Template_Common")
end

local function getClickable(root: Instance?): GuiButton?
	if not root then
		return nil
	end

	if root:IsA("GuiButton") then
		return root
	end

	local direct = root:FindFirstChildOfClass("GuiButton")
	if direct then
		return direct
	end

	for _, desc in ipairs(root:GetDescendants()) do
		if desc:IsA("GuiButton") then
			return desc
		end
	end

	return nil
end

local function updateInventory()
	local scrolling = UI.InventoryScrolling
	if not scrolling then
		return
	end

	local templateKeep = getWormTemplate(nil)
	if templateKeep and templateKeep:IsA("GuiObject") then
		templateKeep.Visible = false
	end
	clearContainer(scrolling, templateKeep)

	local allItems = {}
	local totalOwned = 0

	for _, slot in ipairs(PlayerInventory:GetChildren()) do
		if not slot:IsA("Folder") then
			continue
		end

		local nameVal = slot:FindFirstChild("Name")
		if not nameVal then
			continue
		end

		local unitName = nameVal.Value
		local towerInfo = TowerData[unitName]
		if not towerInfo then
			continue
		end

		totalOwned += 1

		if CurrentFilter ~= "" then
			local display = string.lower(getDisplayName(unitName))
			if not string.find(display, CurrentFilter, 1, true) then
				continue
			end
		end

		table.insert(allItems, {
			Name = unitName,
			DisplayName = getDisplayName(unitName),
			Info = towerInfo,
			IsEquipped = checkEquipped(unitName),
		})
	end

	setCountText(tostring(totalOwned) .. "/100")

	table.sort(allItems, function(a, b)
		if a.IsEquipped ~= b.IsEquipped then
			return a.IsEquipped
		end

		local towerA = getModel(a.Name)
		local towerB = getModel(b.Name)
		local rarA = RarityRanks[towerA and towerA:GetAttribute("Rarity")] or 0
		local rarB = RarityRanks[towerB and towerB:GetAttribute("Rarity")] or 0

		if rarA ~= rarB then
			return rarA > rarB
		end

		return a.DisplayName < b.DisplayName
	end)

	for _, itemData in ipairs(allItems) do
		local towerModel = getModel(itemData.Name)
		local rarity = towerModel and towerModel:GetAttribute("Rarity") or "Common"
		local template = getWormTemplate(rarity)
		if not template then
			continue
		end

		local clone = template:Clone()
		clone.Name = itemData.Name
		clone.Visible = true
		clone.Parent = scrolling
		clone.LayoutOrder = LayoutOrder[rarity] or 10

		local holder = clone:FindFirstChild("Holder", true)
		if holder and holder:IsA("GuiObject") then
			holder.Visible = true
		end

		local imageObj = findByName(clone, { "ItemImage", "Worm_Icon", "MainIcon", "Icon" }, true)
		local nameObj = findByName(clone, { "WormNameTX", "WormName", "NameTX" }, true)
		local priceObj = findByName(clone, { "PriceTX", "Price", "Cost" }, true)
		local equippedMarker = findByName(clone, { "Equipp", "Equiped", "Equipped" }, true)

		setImage(imageObj, itemData.Info.ImageId)
		setText(nameObj, itemData.DisplayName)
		setText(priceObj, "$" .. tostring(itemData.Info.Price))

		if equippedMarker and equippedMarker:IsA("GuiObject") then
			equippedMarker.Visible = itemData.IsEquipped
		end

		local clickable = getClickable(clone)
		if clickable then
			clickable.Activated:Connect(function()
				updatePreview(itemData.Name)
			end)
		end
	end
end

local function formatConsumableDescription(info): string
	local effect = info.Effect
	if not effect then
		return ""
	end

	local effectTypeLabel = {
		XP = "XP",
		Damage = "Damage",
		Range = "Range",
		AttackCooldown = "Cooldown",
		Cooldown = "Cooldown",
		Level = "Level",
	}

	local value = effect.Value or 0
	local sign = value > 0 and "+" or ""
	local kind = effectTypeLabel[effect.Type] or tostring(effect.Type)
	return string.format("%s%s %s", sign, tostring(value), kind)
end

local function updateConsumables()
	local scrolling = UI.ConsumablesScrolling
	if not scrolling then
		return
	end

	local templateKeep = getConsumableTemplate()
	if templateKeep and templateKeep:IsA("GuiObject") then
		templateKeep.Visible = false
	end
	clearContainer(scrolling, templateKeep)
	SelectedConsumable = nil

	for _, item in ipairs(PlayerConsumables:GetChildren()) do
		if not item:IsA("StringValue") then
			continue
		end

		local consumableInfo = ConsumableData[item.Value]
		if not consumableInfo then
			continue
		end

		local template = getConsumableTemplate()
		if not template then
			continue
		end

		local clone = template:Clone()
		clone.Name = item.Name
		clone.Visible = true
		clone.Parent = scrolling

		local holder = clone:FindFirstChild("Holder", true)
		if holder and holder:IsA("GuiObject") then
			holder.Visible = true
		end

		local imageObj = findByName(clone, { "ItemImage", "Worm_Icon", "MainIcon", "Icon" }, true)
		local nameObj = findByName(clone, { "WormNameTX", "WormName", "NameTX" }, true)
		local descObj = findByName(clone, { "Description", "Desc", "BuffTX", "Price" }, true)
		local marker = findByName(clone, { "Equipp", "Equiped", "Equipped", "Selected" }, true)

		setImage(imageObj, consumableInfo.ImageId)
		setText(nameObj, item.Value)
		setText(descObj, formatConsumableDescription(consumableInfo))

		if holder and descObj and descObj.Name == "Price" then
			for _, child in ipairs(holder:GetChildren()) do
				if child:IsA("GuiObject") and child ~= descObj then
					child.Visible = false
				end
			end
		end

		if marker and marker:IsA("GuiObject") then
			marker.Visible = false
		end

		local clickable = getClickable(clone)
		if clickable then
			local consumableName = item.Value
			local hoverText = formatConsumableDescription(consumableInfo)

			clickable.Activated:Connect(function()
				if not Selected then
					return
				end

				for _, child in ipairs(scrolling:GetChildren()) do
					if child == templateKeep then
						continue
					end
					local selectedMarker = findByName(child, { "Equipp", "Equiped", "Equipped", "Selected" }, true)
					if selectedMarker and selectedMarker:IsA("GuiObject") then
						selectedMarker.Visible = false
					end
				end

				if marker and marker:IsA("GuiObject") then
					marker.Visible = true
				end

				SelectedConsumable = consumableName
				UseConsumableRemote:FireServer(Selected, consumableName)
			end)

			if clickable:IsA("GuiObject") then
				clickable.MouseEnter:Connect(function()
					showConsumableHover(clickable, hoverText)
				end)

				clickable.MouseLeave:Connect(function()
					hideConsumableHover()
				end)

				clickable.AncestryChanged:Connect(function(_, parent)
					if not parent then
						hideConsumableHover()
					end
				end)
			end
		end
	end
end

local function watchInventorySlot(slot: Folder)
	for _, valueObj in ipairs(slot:GetChildren()) do
		if valueObj:IsA("ValueBase") then
			valueObj.Changed:Connect(function()
				local nameVal = slot:FindFirstChild("Name")
				if nameVal and Selected and getDisplayName(nameVal.Value) == getDisplayName(Selected) then
					updatePreview(Selected)
				end
			end)
		end
	end
end

local function connectOpenCratesButtons()
	for _, button in ipairs(UI.OpenCratesButtons or {}) do
		button.Activated:Connect(function()
			local targetFrame = button:GetAttribute("FrameName")
			if targetFrame and targetFrame ~= "" then
				GuiManager.ToggleUi(targetFrame)
			else
				GuiManager.ToggleUi("Crates")
			end
		end)
	end
end

local function connectSearch()
	if not UI.SearchBox then
		return
	end

	local function refreshFromSearch()
		CurrentFilter = string.lower(UI.SearchBox.Text or "")
		updateInventory()
	end

	UI.SearchBox:GetPropertyChangedSignal("Text"):Connect(refreshFromSearch)
	UI.SearchBox.FocusLost:Connect(refreshFromSearch)

	if UI.SearchButton then
		UI.SearchButton.Activated:Connect(refreshFromSearch)
	end

	refreshFromSearch()
end

local function connectCoreButtons()
	local debounce = false
	local connectedButtons = {}

	local function requestEquipToggle()
		if not Selected or debounce then
			return
		end

		debounce = true
		InventoryRemotes.Equip:FireServer(Selected)
		task.wait(0.12)
		updatePreview(Selected)
		updateInventory()
		task.delay(0.25, function()
			debounce = false
		end)
	end

	local function connectEquipButton(button: GuiButton?)
		if not button or connectedButtons[button] then
			return
		end

		connectedButtons[button] = true
		button.Activated:Connect(requestEquipToggle)
	end

	connectEquipButton(UI.EquipButton)
	connectEquipButton(UI.UnequipSelectionButton)

	if UI.SellButton then
		UI.SellButton.Activated:Connect(function()
			if not Selected then
				return
			end
			InventoryRemotes.Sell:FireServer(Selected)
			task.wait(0.2)
			updateInventory()
		end)
	end

	if UI.EquipAllButton then
		UI.EquipAllButton.Activated:Connect(function()
			local bestUnit = nil
			local bestRank = 0

			for _, slot in ipairs(PlayerInventory:GetChildren()) do
				if not slot:IsA("Folder") then
					continue
				end

				local nameVal = slot:FindFirstChild("Name")
				if not nameVal then
					continue
				end

				local unitName = nameVal.Value
				local towerModel = getModel(unitName)
				local rarity = towerModel and towerModel:GetAttribute("Rarity")
				local rank = RarityRanks[rarity] or 0

				if rank > bestRank then
					bestRank = rank
					bestUnit = unitName
				end
			end

			if bestUnit then
				InventoryRemotes.Equip:FireServer(bestUnit)
				task.spawn(function()
					task.wait(0.1)
					updatePreview(bestUnit)
					updateInventory()
				end)
			end
		end)
	end

	for _, button in ipairs(UI.UnequipButtons or {}) do
		button.Activated:Connect(function()
			InventoryRemotes.UnequipAll:FireServer()
			task.wait(0.1)
			if Selected then
				updatePreview(Selected)
			end
			updateInventory()
		end)
	end
end

for _, slot in ipairs(PlayerInventory:GetChildren()) do
	if slot:IsA("Folder") then
		watchInventorySlot(slot)
	end
end

PlayerInventory.ChildAdded:Connect(function(slot)
	if slot:IsA("Folder") then
		watchInventorySlot(slot)
		updateInventory()
	end
end)

PlayerInventory.ChildRemoved:Connect(function()
	updateInventory()
	if Selected and UI.ItemFrame and UI.ItemFrame:IsA("GuiObject") then
		UI.ItemFrame.Visible = false
		Selected = nil
	end
end)

for _, slot in ipairs(PlayerHotbar:GetChildren()) do
	if slot:IsA("StringValue") then
		slot.Changed:Connect(function()
			updateInventory()
			if Selected then
				updatePreview(Selected)
			end
		end)
	end
end

PlayerHotbar.ChildAdded:Connect(function(slot)
	if slot:IsA("StringValue") then
		slot.Changed:Connect(function()
			updateInventory()
			if Selected then
				updatePreview(Selected)
			end
		end)
	end
end)

PlayerConsumables.ChildAdded:Connect(function()
	updateConsumables()
end)

PlayerConsumables.ChildRemoved:Connect(function()
	updateConsumables()
	if Selected then
		updatePreview(Selected)
	end
end)

SellRemote.OnClientEvent:Connect(function()
	if UI.ItemFrame and UI.ItemFrame:IsA("GuiObject") then
		UI.ItemFrame.Visible = false
	end
	hideConsumableHover()
end)

WormsInventory:GetPropertyChangedSignal("Visible"):Connect(function()
	if WormsInventory.Visible then
		updateInventory()
		updateConsumables()
	else
		hideConsumableHover()
	end
end)

connectCoreButtons()
connectOpenCratesButtons()
connectSearch()

updateInventory()
updateConsumables()

if UI.ItemFrame and UI.ItemFrame:IsA("GuiObject") then
	UI.ItemFrame.Visible = false
end

return Handler
