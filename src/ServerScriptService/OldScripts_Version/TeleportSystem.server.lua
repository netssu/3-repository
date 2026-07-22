--//Services
local Rs = game:GetService("ReplicatedStorage")
local TeleportService = game:GetService("TeleportService")

--//Events
local Remotes = Rs:FindFirstChild("Remotes")
local teleportEvent = Remotes:FindFirstChild("TeleporterEvent")
local warnTeleportEvent = Remotes:FindFirstChild("WarnTeleportEvent")

--//Teleporters
local Map = workspace:FindFirstChild("Map")
local GameTeleporters = Map:FindFirstChild("GameTeleporters")

--//Values
local Teleporters = {}

--//Get all teleportes in game
for i, v in GameTeleporters:GetChildren() do
	if v:HasTag("Teleporter") then
		table.insert(Teleporters, v)
	end
end

--//Create a function for every teleporter in game
for i, teleporter in ipairs(Teleporters) do
	--//Model
	local TeleporterModel = teleporter
	local camPart = TeleporterModel:FindFirstChild("Cam") :: BasePart
	local gate = TeleporterModel:FindFirstChild("Gate") :: BasePart
	local leavePart = TeleporterModel:FindFirstChild("LeavePart") :: BasePart
	local spawnPart = TeleporterModel:FindFirstChild("SpawnPart") :: BasePart
	local ScreenGui = gate:FindFirstChild("Screen") :: SurfaceGui
	local PlayerGui = gate:FindFirstChild("PlayersGui"):FindFirstChild("Players") :: SurfaceGui
	local PlayerFrame_Example = PlayerGui:FindFirstChild("PlayerFrame_Example") :: Frame
	local Configuration = TeleporterModel:FindFirstChild("Configuration")
	
	--//Config
	local maxPlayers = Configuration:GetAttribute("MaxPlayers")
	local waitTime = Configuration:GetAttribute("SessionTime")
	local placeID = Configuration:GetAttribute("PlaceID")
	local resetTime = Configuration:GetAttribute("ResetTime")
	
	--//Others
	local plrsOnDebounce = {}
	local currentPlrs = {}
	local status = "waiting"
	local timeToWait = waitTime
	
	--//Pre-Set
	ScreenGui.MainFrame.Players.Text = "Players: " .. #currentPlrs .. "/" .. maxPlayers
	PlayerFrame_Example.Parent = Rs
	
	local function UpdatePlrList(clear: boolean?)
		if clear then
			for i, v in PlayerGui:GetChildren() do
				if v:IsA("Frame") then
					v:Destroy()
				end
			end
			return
		end
		
		local plrListByName = {}
		for i, plr in ipairs(currentPlrs) do
			table.insert(plrListByName, plr.Name)
		end
		
		--//Reset List
		for i, v in PlayerGui:GetChildren() do
			if v:IsA("Frame") and not table.find(plrListByName, v.Name) then
				v:Destroy()
			end
		end
		
		--//Create new list
		for i, plr in ipairs(currentPlrs) do
			if not PlayerGui:FindFirstChild(plr.Name) then
				local PlayerFrame = PlayerFrame_Example:Clone()
				PlayerFrame.Name = plr.Name
				PlayerFrame.Visible = true
				PlayerFrame.Icon.Image = game.Players:GetUserThumbnailAsync(plr.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
				PlayerFrame.Parent = PlayerGui
			end
		end
	end
	
	local function UpdateUI()
		ScreenGui.MainFrame.Players.Text = "Players: " .. #currentPlrs .. "/" .. maxPlayers
		ScreenGui.MainFrame.Status.Text = "Starting in: " .. timeToWait
		UpdatePlrList()
		if status == "waiting" then
			ScreenGui.MainFrame.Status.TextColor3 = Color3.new(1, 1, 1)
		else
			ScreenGui.MainFrame.Status.Text = "Teleporting"
			ScreenGui.MainFrame.Status.TextColor3 = Color3.new(1, 0.188235, 0.188235)
		end
	end
	
	local function JoinPlr(Player: Player)
		if Player then
			if #currentPlrs < maxPlayers and status == "waiting" then
				table.insert(currentPlrs, Player)
				UpdateUI()
				
				local Char = Player.Character
				
				Char.HumanoidRootPart.Anchored = true
				Char.HumanoidRootPart.CFrame = spawnPart.CFrame
				Char.HumanoidRootPart.Anchored = false
				teleportEvent:FireClient(Player, true, camPart.CFrame)
				return
			end
			warnTeleportEvent:FireClient(Player, "Can't join in this Lobby") --fire server to warn that its not possible to join in this teleport
			return
		end
		return
	end
	
	local function removePlrsOnDebounce(Player: Player)
		if Player then
			for i, v in ipairs(plrsOnDebounce) do
				if v == Player then
					table.remove(plrsOnDebounce, i)
				end
			end
		else
			table.clear(plrsOnDebounce)
		end
	end
	
	local function LeavePlr(Player: Player, removingFromTable: boolean)
		if Player then
			for i, v in ipairs(currentPlrs) do
				if v == Player then
					local Char = Player.Character
					
					Char.HumanoidRootPart.Anchored = true
					Char.HumanoidRootPart.CFrame = leavePart.CFrame
					Char.HumanoidRootPart.Anchored = false
					
					table.insert(plrsOnDebounce, Player)
					table.remove(currentPlrs, i)
					UpdateUI()
					task.delay(1, removePlrsOnDebounce, Player)
				end
			end
		elseif removingFromTable then
			if #currentPlrs > 0 then
				for _, v in ipairs(currentPlrs) do
					local playerchar = v.Character
					playerchar.HumanoidRootPart.Anchored = true
					playerchar.HumanoidRootPart.CFrame = leavePart.CFrame
					playerchar.HumanoidRootPart.Anchored = false
					table.insert(plrsOnDebounce, Player)
					task.delay(1, removePlrsOnDebounce)
				end
			end
		end
	end
	
	local function TeleportsPlrs()
		status = "teleporting"
		UpdateUI()
		
		local TeleportData = {
			["TotalPlayers"] = #currentPlrs
		}
		
		for _, v in ipairs(currentPlrs) do --show teleport gui
			teleportEvent:FireClient(v, "Teleport")
		end
		
		if placeID == "0" or placeID == "" then
			warn("Incorrect placeID, check the correct ID.")
		end
		
		local success, errmsg = pcall(function()
			local code = TeleportService:ReserveServer(tonumber(placeID))
			TeleportService:TeleportToPrivateServer(tonumber(placeID), code, currentPlrs, nil, TeleportData)
		end)
		if not success then
			warn("Cannot teleport, error: " .. errmsg)
			LeavePlr(nil, true)
			UpdateUI()
			UpdatePlrList(true)
			ScreenGui.MainFrame.Status.Text = "Reseting"
			timeToWait = waitTime
			
			for _, v in ipairs(currentPlrs) do
				teleportEvent:FireClient(v, "errTeleport")
				warnTeleportEvent:FireClient(v, "Cannot teleport, try again later.")
			end
		end
		
		task.wait(resetTime)
		
		if #currentPlrs > 0 then
			currentPlrs = {}
			status = "waiting"
			UpdateUI()
			return
		end
		
		status = "waiting"
		UpdateUI()
	end
	
	gate.Touched:Connect(function(hit)
		if hit.Parent:FindFirstChild("Humanoid") and hit.Parent:FindFirstChild("Humanoid").Health > 0 then
			local player = game.Players:GetPlayerFromCharacter(hit.Parent)
			local onTable = false
			
			--//Check if the player is already on teleporter
			for i, v in ipairs(currentPlrs) do
				if v == player then
					onTable = true
				end
			end
			
			--//Check if the player is on debounce
			for i, v in ipairs(plrsOnDebounce) do
				if v == player then
					onTable = true
				end
			end
			
			if player and not onTable then
				JoinPlr(player)
			end
		end
	end)
	
	teleportEvent.OnServerEvent:Connect(function(Player)
		LeavePlr(Player, false)
	end)
	
	local textState = 1
	
	coroutine.wrap(function()
		while true do
			if #currentPlrs == 0 then
				if textState == 1 then
					textState = 2
					ScreenGui.MainFrame.Status.Text = "Waiting for Players."
				elseif textState == 2 then
					textState = 3
					ScreenGui.MainFrame.Status.Text = "Waiting for Players.."
				elseif textState == 3 then
					textState = 1
					ScreenGui.MainFrame.Status.Text = "Waiting for Players..."
				end
			end
			task.wait(1)
		end
	end)()
	
	coroutine.wrap(function()
		while task.wait() do
			if #currentPlrs > 0 then
				timeToWait = waitTime
				for i=1, waitTime do
					if #currentPlrs == 0 then
						timeToWait = waitTime
						break
					end
					task.wait(1)
					timeToWait -= 1
					if #currentPlrs == 0 then
						timeToWait = waitTime
						break
					end
					UpdateUI()
				end
				if #currentPlrs > 0 then
					TeleportsPlrs()
				end
			end
		end
	end)()
end