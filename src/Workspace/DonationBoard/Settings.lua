local DonateBoard = script.Parent:WaitForChild("DonateBoard")
local DonateFrame = DonateBoard.SurfaceGui.Frame
local LeaderboardFrame = script.Parent.DonationLeaderboard.SurfaceGui.Frame
local List = DonateFrame.List

local module = {
	DonateButton = {
		Robux5 = {
			Id = 3437261123,
			Amount = 5,
			Button = List.Robux5.Purchase,
		},
		
		Robux25 = {
			Id = 3437261293,
			Amount = 25,
			Button = List.Robux25.Purchase,
		},
		
		Robux100 = {
			Id = 3311857267,
			Amount = 100,
			Button = List.Robux100.Purchase,
		},
		
		Robux500 = {
			Id = 3311856159,
			Amount = 500,
			Button = List.Robux500.Purchase,
		},
		
		Robux2500 = {
			Id = 3311856972,
			Amount = 2500,
			Button = List.Robux2500.Purchase,
		},
		
		Robux10000 = {
			Id = 3245885655,
			Amount = 10000,
			Button = List.Robux10000.Purchase,
		},
		
		Robux10 = {
			Id = 3311859330,
			Amount = 10,
			Button = List.Robux10.Purchase,
		},
		
		Robux50 = {
			Id = 3442008500,
			Amount = 50,
			Button = List.Robux50.Purchase,
		},
		
		Robux200 = {
			Id = 3442008578,
			Amount = 200,
			Button = List.Robux200.Purchase,
		},
		
		Robux1000 = {
			Id = 3442008717,
			Amount = 1000,
			Button = List.Robux1000.Purchase,
		},
		
		Robux5000 = {
			Id = 3442008821,
			Amount = 5000,
			Button = List.Robux5000.Purchase,
		},
		
		Robux25000 = {
			Id = 3442008978,
			Amount = 25000,
			Button = List.Robux25000.Purchase,
		},
	},
	
	RanksColor = {
		[1] = Color3.fromRGB(255, 217, 0),
		[2] = Color3.fromRGB(143, 143, 143),
		[3] = Color3.fromRGB(255, 124, 137),
		["Default"] = Color3.fromRGB(61, 61, 61),
	},
	
	RefreshRate = 60,
	
	MonthlyButton = LeaderboardFrame.Monthly,
	AllTimeButton = LeaderboardFrame.AllTime,
}

return module