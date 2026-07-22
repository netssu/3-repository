--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local updatePlrBillBoard = Remotes:FindFirstChild("UpdatePlrBillBoard")

--//Player
local Player = game.Players.LocalPlayer

--//Stuff
local equipedTitle = Player:WaitForChild("OtherValues"):WaitForChild("EquipedTitle") :: StringValue

local function createPlrBillBoard()
	updatePlrBillBoard:FireServer(equipedTitle.Value)
end

createPlrBillBoard()

equipedTitle:GetPropertyChangedSignal("Value"):Connect(function()
	createPlrBillBoard()
end)