local groupid = 35529401
local rankid = 4

game.Players.PlayerAdded:Connect(function(player)
	task.wait(3)
	if player:IsInGroup(groupid) and player:GetRankInGroup(groupid) >= rankid then
		local othervalues = player:WaitForChild("OtherValues")
		local freerevives = othervalues:WaitForChild("FreeRevives") :: IntValue
		
		freerevives.Value = 100
	end
end)