--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local MoneyEarnEvent = Remotes:FindFirstChild("MoneyEarn")

MoneyEarnEvent.OnServerEvent:Connect(function(plr, amount)
	local plrCoins = plr:FindFirstChild("leaderstats"):FindFirstChild("Coins")
	plrCoins.Value += amount -- update plr coins amount
	MoneyEarnEvent:FireClient(plr, amount) -- show animation in client
end)