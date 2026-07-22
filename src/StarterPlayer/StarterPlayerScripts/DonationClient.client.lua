task.wait(1)

local Settings = require(workspace.DonationBoard.Settings)
local MarketplaceService = game:GetService("MarketplaceService")
local player = game.Players.LocalPlayer
local DonateAnnouncement = game.ReplicatedStorage.DonateAnnouncement
local MonthlyStatue = workspace.DonationBoard.MonthlyStatue:GetChildren()
local AllTimeStatue = workspace.DonationBoard.AllTimeStatue:GetChildren()
local donationdata = player:WaitForChild('DonationData')

local function aberviate(num)
	local decAcc = 2
	if num < 1000 then
		return num
	else
		local number = math.floor(num)
		local abreviations = {
			[3] = "K",
			[6] = "M",
			[9] = "B",
			[12] = "T",
			[15] = "Qa"
		}
		local show = #tostring(number) % 3
		if show == 0 then
			show = 3
		end
		local trueLength = #tostring(number) - show
		if abreviations[trueLength] then
			number = tostring(number)
			return string.sub(number,1,show)..".".. string.sub(number,show + 1,show+decAcc) ..   abreviations[trueLength]
		else
			return num
		end
	end
end


workspace.DonationBoard.DonateBoard.SurfaceGui.Frame.ClientDonation.Text = aberviate(donationdata.MonthlyTotalDonation.Value)
donationdata.MonthlyTotalDonation.Changed:Connect(function()
	if workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.MonthlyBoard.Visible then
		workspace.DonationBoard.DonateBoard.SurfaceGui.Frame.ClientDonation.Text = aberviate(donationdata.MonthlyTotalDonation.Value)
	end
end)
donationdata.TotalDonation.Changed:Connect(function()
	if workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.AllTimeBoard.Visible then
		workspace.DonationBoard.DonateBoard.SurfaceGui.Frame.ClientDonation.Text = aberviate(donationdata.MonthlyTotalDonation.Value)
	end
end)

for _,Option in pairs(Settings.DonateButton) do
	Option.Button.MouseButton1Click:Connect(function()
		MarketplaceService:PromptProductPurchase(player,Option.Id)
	end)
end

for _,statue in pairs(MonthlyStatue) do
	statue.Parent = workspace.DonationBoard
end

for _,statue in pairs(AllTimeStatue) do
	statue.Parent = game.ReplicatedStorage
end

Settings.AllTimeButton.MouseButton1Click:Connect(function()
	Settings.AllTimeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	Settings.MonthlyButton.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
	workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.AllTimeBoard.Visible = true
	workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.MonthlyBoard.Visible = false
	workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.MainTitle.Text = "all time donation"
	workspace.DonationBoard.DonateBoard.SurfaceGui.Frame.ClientDonation.Text = aberviate(donationdata.TotalDonation.Value)
	
	for _,statue in pairs(MonthlyStatue) do
		statue.Parent = game.ReplicatedStorage
	end
	
	for _,statue in pairs(AllTimeStatue) do
		statue.Parent = workspace.DonationBoard
	end
end)

Settings.MonthlyButton.MouseButton1Click:Connect(function()
	Settings.MonthlyButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	Settings.AllTimeButton.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
	workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.AllTimeBoard.Visible = false
	workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.MonthlyBoard.Visible = true
	workspace.DonationBoard.DonationLeaderboard.SurfaceGui.Frame.MainTitle.Text = os.date("%B"):lower().."'s donation"
	workspace.DonationBoard.DonateBoard.SurfaceGui.Frame.ClientDonation.Text = aberviate(donationdata.MonthlyTotalDonation.Value)
	
	for _,statue in pairs(MonthlyStatue) do
		statue.Parent = workspace.DonationBoard
	end

	for _,statue in pairs(AllTimeStatue) do
		statue.Parent = game.ReplicatedStorage
	end
end)

DonateAnnouncement.OnClientEvent:Connect(function(donator,amount)
	game.StarterGui:SetCore("ChatMakeSystemMessage",{
		Text = donator.." just donated "..aberviate(amount).." R$!", 
		Color = Color3.fromRGB(0, 255, 0)
		,Font = Enum.Font.SourceSansBold, 
		FontSize = Enum.FontSize.Size8
	})
end)