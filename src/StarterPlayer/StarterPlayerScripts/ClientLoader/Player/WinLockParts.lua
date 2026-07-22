local winLockParts = {
	Name = "WinLockParts"
}

function winLockParts.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local CollectionService = game:GetService("CollectionService")
	
	--//Remotes
	local Remotes = Rs:WaitForChild("Remotes")
	local ClientMessage = Remotes:WaitForChild("ClientMessage")
	
	--//Player
	local Player = game.Players.LocalPlayer
	
	--//Values
	local TAG = "WinLock"
	local lockParts = {}
	
	local function addWinLockPart(obj: Instance)
		if lockParts[obj] then return end -- already exists
		if not obj:IsA("BasePart") then return end
		
		local surfaceGui = obj:FindFirstChildWhichIsA("SurfaceGui")
		local mainFrame = surfaceGui and surfaceGui:FindFirstChild("MainFrame")
		local winText = mainFrame and mainFrame:FindFirstChild("WinText") :: TextLabel
		
		local winsValue = obj:GetAttribute("RequiredWins") or 1 --if don't find, set to the default value
		if winsValue <= 0 then winsValue = 1 end -- normalize the required wins
		
		if winText then
			if winsValue > 1 then
				winText.Text = `{winsValue} Wins to Unlock`
			else
				winText.Text = `{winsValue} Win to Unlock`
			end
		end
		
		local function checkIfEnabled(plrTouch: boolean)
			local leaderstats = Player:FindFirstChild("leaderstats")
			local wins = leaderstats and leaderstats:FindFirstChild("Wins")
			
			if wins and wins.Value >= winsValue then
				if plrTouch then
					ClientMessage:Fire("Zone Unlocked.")
				end
				obj.CanCollide = false
				lockParts[obj]:Disconnect()
				lockParts[obj] = nil
				obj:Destroy()
			else
				if plrTouch then
					ClientMessage:Fire("You don't have enough wins!")
				end
			end
		end
		
		local debounce = true
		
		lockParts[obj] = obj.Touched:Connect(function(hit)
			if not hit or not hit.Parent then return end
			local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
			
			if plr and plr.UserId == Player.UserId and debounce then
				debounce = false
				checkIfEnabled(true)
				task.wait(1)
				debounce = true
			end
		end)
		
		checkIfEnabled() -- When player joins, check if the player already has enough wins
	end
	
	local function removeWinLockPart(obj: Instance)
		if lockParts[obj] then
			lockParts[obj]:Disconnect()
			lockParts[obj] = nil
			obj:Destroy()
		end
	end
	
	CollectionService:GetInstanceAddedSignal(TAG):Connect(addWinLockPart)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(removeWinLockPart)
	
	for _, v in CollectionService:GetTagged(TAG) do
		addWinLockPart(v)
	end
end

return winLockParts