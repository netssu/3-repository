--SERVICES
local RS = game:GetService("ReplicatedStorage")
local CS = game:GetService("CollectionService")
local TS = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")

--REFERENCES
local Player = Players.LocalPlayer
local SkillTreeRem = RS:WaitForChild("Remotes").SkillTreeRemote

local Plots = workspace:WaitForChild("Plots")
local SkillTreeDict = require(RS:WaitForChild("Modules").SkillTreeDict)

local Character = Player.Character or Player.CharacterAdded:Wait()
repeat task.wait(5) until Player:FindFirstChild("PlayerInfo") and Character:FindFirstChild("ToolFolder")

local PlayerStats = Player:WaitForChild("PlayerStats")
local Upgrades = PlayerStats:WaitForChild("Upgrades")
local FarmersMarketSkillTree = PlayerStats:WaitForChild("FarmersMarketSkillTree")
local RestaurantSkillTree = PlayerStats:WaitForChild("RestaurantSkillTree")
local PlayerInfo = Player:WaitForChild("PlayerInfo")
local PlayerSpotVal = PlayerInfo:WaitForChild("PlayerSpot")

-- [[ WAIT FOR PLOT ASSIGNMENT ]]
if PlayerSpotVal.Value == "None" or PlayerSpotVal.Value == "" then
	PlayerSpotVal:GetPropertyChangedSignal("Value"):Wait()
end

local PlayerPlot = Plots:WaitForChild(PlayerSpotVal.Value)

-- [[ NUMBER FORMATTER ]]
local names = {"K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dd", "Ud", "Dd", "Td", "Qad", "Qid", 
	"Sxd", "Spd", "Ocd", "Nod", "Vg", "Uvg", "Dvg", "Tvg", "Qavg", "Qivg", "Sxvg", "Spvg", "Ocvg"}
local Nums = {}
for i = 1, #names do table.insert(Nums, 1000^i) end
local function FrmtNum(x: number, decimalPlaces: number)
	local function roundToDecimals(num, decimalPlaces)
		local formatString = string.format("%%.%df", decimalPlaces)
		return tonumber(string.format(formatString, num))
	end
	local ab = math.abs(x)
	local p = math.min(math.floor(math.log10(ab)/3), #names)
	if ab < 1000 then return roundToDecimals(x, decimalPlaces) end 
	local num = roundToDecimals(ab / Nums[p], decimalPlaces)
	return num * math.sign(x) .. names[p]
end

-- [[ DESTROY OTHER PLOTS' SKILL TREES LOCALLY ]]
for _, plot in pairs(Plots:GetChildren()) do
	if plot:IsA("Folder") or plot:IsA("Model") then
		if plot.Name ~= PlayerPlot.Name then
			local otherSkillTree = plot:FindFirstChild("RestaurantSkillTree", true)
			if otherSkillTree then
				otherSkillTree:Destroy()
			end
		end
	end
end

-- =======================================================
-- [[ CORE VISIBILITY LOGIC (NO RACE CONDITIONS) ]]
-- =======================================================
local function SyncVisibility(SkillPadsFolder, StatsFolder)
	if not SkillPadsFolder then return end

	-- 1. HIDE EVERYTHING EXCEPT THE SEED
	for _, v in pairs(SkillPadsFolder:GetDescendants()) do
		if v:IsA("BasePart") then
			if v.Parent.Name == "Seed" or (v.Parent.Parent and v.Parent.Parent.Name == "Seed") then
				v.Transparency = 0
				v.CanCollide = true
				v.CanQuery = true
				v.CanTouch = true
				local sg = v:FindFirstChildWhichIsA("SurfaceGui")
				if sg then sg.Enabled = true end
			else
				v.Transparency = 1
				v.CanCollide = false
				v.CanQuery = false
				v.CanTouch = false
				local sg = v:FindFirstChildWhichIsA("SurfaceGui")
				if sg then sg.Enabled = false end
			end
		end
	end

	-- 2. LOOP ONLY TRUE STATS & SHOW THEIR PATHS
	for _, stat in pairs(StatsFolder:GetChildren()) do
		if stat:IsA("BoolValue") and stat.Value == true then
			local SkillPad = SkillPadsFolder:FindFirstChild(stat.Name, true)
			if SkillPad then
				local ownerFolder = SkillPad.Parent
				if ownerFolder then
					for _, v in pairs(SkillPadsFolder:GetDescendants()) do
						if v:IsA("BasePart") then
							local ownerAttr = v:GetAttribute("Owner")
							local parentOwnerAttr = v.Parent and v.Parent:GetAttribute("Owner")

							if ownerAttr == ownerFolder.Name or parentOwnerAttr == ownerFolder.Name then
								v.Transparency = 0
								v.CanCollide = true
								v.CanQuery = true
								v.CanTouch = true
								local sg = v:FindFirstChildWhichIsA("SurfaceGui")
								if sg then sg.Enabled = true end
							end
						end
					end
				end
			end
		end
	end
end

local function SyncUI(SkillPadsFolder, StatsFolder, DictType)
	if not SkillPadsFolder then return end

	for _, stat in pairs(StatsFolder:GetChildren()) do
		if stat:IsA("BoolValue") then
			local SkillPad = SkillPadsFolder:FindFirstChild(stat.Name, true)
			if SkillPad then
				local SurfaceGui = SkillPad:FindFirstChild("SurfaceGui") and SkillPad.SurfaceGui:FindFirstChild("UpgradeFrame")
				if SurfaceGui then
					if stat.Value == true then
						SurfaceGui.Cost.Text = "UNLOCKED!"
						SurfaceGui.Cost.Size = UDim2.fromScale(0.975,0.25)
						SurfaceGui.Cost.Position = UDim2.fromScale(0.5,0.85)
						if SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient") then
							SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient").Enabled = false
						end
						SurfaceGui.Cost.TextColor3 = Color3.new(1, 0, 0)
						if SurfaceGui:FindFirstChild("CostTitle") then SurfaceGui.CostTitle.Visible = false end
						if SkillPad:FindFirstChild("Unlocked") then SkillPad.Unlocked.Value = true end
					else
						local SkillData = SkillTreeDict[DictType][stat.Name]
						if SkillData then
							SurfaceGui.Cost.Text = FrmtNum(SkillData.Cost,2) .." "..SkillData.Currency
							SurfaceGui.Cost.Size = UDim2.fromScale(0.975,0.15)
							SurfaceGui.Cost.Position = UDim2.fromScale(0.5,0.9)
							if SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient") then
								SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient").Enabled = true
							end
							SurfaceGui.Cost.TextColor3 = Color3.new(1, 1, 1)
							if SurfaceGui:FindFirstChild("CostTitle") then SurfaceGui.CostTitle.Visible = true end
							if SkillPad:FindFirstChild("Unlocked") then SkillPad.Unlocked.Value = false end
						end
					end
				end
			end
		end
	end
end

local function RefreshAllTrees()
	local FMPads = workspace.Map.SkillTrees:FindFirstChild("FarmersMarketSkillTree")
	local RestPads = PlayerPlot:FindFirstChild("RestaurantSkillTree")

	SyncVisibility(FMPads, FarmersMarketSkillTree)
	SyncUI(FMPads, FarmersMarketSkillTree, "FarmersMarketSkillTree")

	SyncVisibility(RestPads, RestaurantSkillTree)
	SyncUI(RestPads, RestaurantSkillTree, "RestaurantSkillTree")
end

-- [[ INITIALIZE & CONNECT ]] --
RefreshAllTrees()

for _, stat in pairs(FarmersMarketSkillTree:GetChildren()) do
	if stat:IsA("BoolValue") then
		stat:GetPropertyChangedSignal("Value"):Connect(RefreshAllTrees)
	end
end

for _, stat in pairs(RestaurantSkillTree:GetChildren()) do
	if stat:IsA("BoolValue") then
		stat:GetPropertyChangedSignal("Value"):Connect(RefreshAllTrees)
	end
end

-- [[ SETUP UI TAGS ]] --
for i,SkillTreePad in pairs(CS:GetTagged("SkillTreePad")) do
	if SkillTreePad:IsA("BasePart") then
		local SkillName = SkillTreePad.Name
		local SkillTreeType = SkillTreePad.Parent.Parent.Name
		local SkillData = SkillTreeDict[SkillTreeType][SkillName]

		if SkillData then
			local SurfaceGui = SkillTreePad.SurfaceGui.UpgradeFrame

			if not SurfaceGui.Cost:FindFirstChild(SkillData.Currency.."Gradient") then
				if SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient") then
					SurfaceGui.Cost:FindFirstChildWhichIsA("UIGradient"):Destroy()
				end
				local CurrencyGradient = RS:WaitForChild("UIAssets")[SkillData.Currency.."Gradient"]:Clone()
				CurrencyGradient.Name = SkillData.Currency.."Gradient"
				CurrencyGradient.Parent = SurfaceGui.Cost
			end

			SurfaceGui.SkillDescription.Text = SkillData.Description

			if SkillData.ValueType == "Variable" and not SurfaceGui:FindFirstChild("CostTitle") then
				local CurrentValue = Instance.new("TextLabel")
				CurrentValue.Name = "CostTitle"
				CurrentValue.Parent = SurfaceGui
				CurrentValue.BackgroundTransparency = 1
				CurrentValue.TextScaled = true
				CurrentValue.Font = Enum.Font.FredokaOne
				CurrentValue.Text = "Current: x1.0"
				CurrentValue.Size = UDim2.fromScale(0.9,0.125)
				CurrentValue.Position = UDim2.fromScale(0.5,0.6)
				CurrentValue.AnchorPoint = Vector2.new(0.5,0.5)
				CurrentValue.TextColor3 = Color3.new(0.145098, 0.647059, 0.882353)

				SurfaceGui.SkillDescription.Position = UDim2.fromScale(0.5,0.28)
				SurfaceGui.SkillDescription.Size = UDim2.fromScale(0.975,0.55)
			end
		end
	end
end

-- [[ ANIMATIONS ]] --
SkillTreeRem.OnClientEvent:Connect(function(Action,SkillPad:BasePart)
	if Action == "Success" and SkillPad then
		SkillPad.Material = "Neon"
		local Tween = TS:Create(SkillPad,TweenInfo.new(0.3,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,true,0),{Transparency = 0.75,Size = SkillPad.Size * 1.3, Color = Color3.new(1, 1, 1)})
		Tween:Play()
		Tween.Completed:Once(function() SkillPad.Material = "Plastic" end)
	elseif Action == "Decline" and SkillPad then
		SkillPad.Material = "Neon"
		local Tween = TS:Create(SkillPad,TweenInfo.new(0.3,Enum.EasingStyle.Cubic,Enum.EasingDirection.Out,0,true,0),{Transparency = 0.75,Size = SkillPad.Size * 1.3, Color = Color3.new(1, 0, 0)})
		Tween:Play()
		Tween.Completed:Once(function() SkillPad.Material = "Plastic" end)
	end
end)