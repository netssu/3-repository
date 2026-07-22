--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local updatePlrBillBoard = Remotes:FindFirstChild("UpdatePlrBillBoard")
local plrDataLoaded = Remotes:FindFirstChild("PlrDataLoaded")

--//Player
local Player = game.Players.LocalPlayer
local PlrSettings = Player:WaitForChild("PlrSettings")
local PlrTitles = PlrSettings:WaitForChild("PlrTitles") :: BoolValue

--//Stuff
local equipedTitle = Player:WaitForChild("OtherValues"):WaitForChild("EquipedTitle") :: StringValue

local function changeBillBoardsVisibility()
	if not PlrTitles.Value then
		for _, plr in game.Players:GetPlayers() do
			local char = plr.Character
			if char and char:FindFirstChild("Head") then
				local plrBillBoard = char.Head:FindFirstChildWhichIsA("BillboardGui") :: BillboardGui
				if plrBillBoard then
					local titleText = plrBillBoard:FindFirstChild("PlrTitleText")
					if titleText then
						titleText.Visible = false
					end
				end
			end
		end
	end
end

local function createPlrBillBoard()
	updatePlrBillBoard:FireServer(equipedTitle.Value)
	changeBillBoardsVisibility()
end

plrDataLoaded.OnClientEvent:Connect(function()
	createPlrBillBoard()
end)

equipedTitle:GetPropertyChangedSignal("Value"):Connect(function()
	createPlrBillBoard()
end)

createPlrBillBoard()