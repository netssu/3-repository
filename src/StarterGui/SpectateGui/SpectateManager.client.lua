repeat task.wait() until game.Players.LocalPlayer.Character

--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")
local MarketplaceService = game:GetService("MarketplaceService")

--//Player
local Player = game.Players.LocalPlayer
local Mouse = Player:GetMouse()
local Char = Player.Character
local Hum = Char:WaitForChild("Humanoid") :: Humanoid
local Camera = workspace.CurrentCamera
local PlayerValues = Player:WaitForChild("PlayerValues")
local IsAlive = PlayerValues:WaitForChild("IsAlive") :: BoolValue
local PlayerOnChase = PlayerValues:WaitForChild("OnChase") :: BoolValue

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local LoadCharFunc = Remotes:WaitForChild("LoadChar")
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")
local TeleportLobbyFunc = Remotes:WaitForChild("TeleportLobby")
local AllPlrsDiedEvent = Remotes:WaitForChild("AllPlrsDied")
local JoinPartyFunc = Remotes:WaitForChild("JoinParty")
local PlrDiedEvent = Remotes:WaitForChild("PlrDied")
local PlrJoinedParty = Remotes:WaitForChild("PlrJoinedParty")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))
local BadgesModule = require(ModulesFolder:WaitForChild("Badges"))
local ShopModule = require(ModulesFolder:WaitForChild("ShopModule"))

--//UI
local SpectateFrame = script.Parent.SpectateFrame
local TransitionFrame = script.Parent.TransitionFrame
local NextButton = SpectateFrame.NextButton
local PreviousButton = SpectateFrame.PreviousButton
local ReviveButton = SpectateFrame.ReviveButton
local LobbyButton = SpectateFrame.LobbyButton
local PartyLobbyButton = SpectateFrame.PartyLobbyButton
local PlrNameText = SpectateFrame.PlrName
local TotalFreeRevivesText = SpectateFrame.CurrentRevives

--//Values
local plrsInGame = #game.Players:GetPlayers()
local maxElapsedTime = 60 -- Time that the player have to buy or use a revive
local teleporting = false
local playerDead = false
local canRevive = true
local CurrentIndex = 1
local everyoneDied = false
local CurrentPlayer = Player
local NextIndex = nil
local revived = false
local currentFreeRevives = 0
local plrsInParty = 0
local plrsDied = 0
local onSpectate = false
local ReviveElapsedtime : RBXScriptConnection = nil
local mouseConnection : RBXScriptConnection = nil
local ReviveDeadline = 0
local REVIVE_PRODUCT_ID = ShopModule:GetProduct("Revive").ID

local function makeTransition(Type: number)
	if Type == 1 then --Slow transition
		Ts:Create(TransitionFrame, TweenInfo.new(1), {BackgroundTransparency = 0}):Play()
		task.wait(2)
		Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 1}):Play()
	elseif Type == 2 then --Normal transition
		Ts:Create(TransitionFrame, TweenInfo.new(0.7), {BackgroundTransparency = 0}):Play()
		task.wait(1.5)
		Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	elseif Type == 3 then --Fast transition
		Ts:Create(TransitionFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play()
		task.wait(1)
		Ts:Create(TransitionFrame, TweenInfo.new(0.3), {BackgroundTransparency = 1}):Play()
	end
end

-- Make all ScreenGuis (except this gui and cutscene gui) to invisible or visible. 
local function changeGuis(state: boolean)
	if state then
		for i, v in script.Parent.Parent:GetChildren() do
			if v ~= script.Parent and v.Name ~= "CutsceneGui" then
				if v:IsA("ScreenGui") then
					v.Enabled = true
				end
			end
		end
	else
		for i, v in script.Parent.Parent:GetChildren() do
			if v ~= script.Parent and v.Name ~= "CutsceneGui" then
				if v:IsA("ScreenGui") then
					v.Enabled = false
				end
			end
		end
	end
end

local function getCurrentPlrList() : {Player}
	local PlayersList = {}
	
	for i, plr in game.Players:GetPlayers() do
		if plr:FindFirstChild("PlayerValues") then
			local IsAlive = plr:FindFirstChild("PlayerValues"):FindFirstChild("IsAlive") :: BoolValue
			if IsAlive then
				if IsAlive.Value then
					table.insert(PlayersList, plr)
				else
					continue
				end
			end
		end
	end
	
	return PlayersList
end

local function spectatePlayer()
	if CurrentPlayer and CurrentPlayer.Character then
		Player.CameraMode = Enum.CameraMode.Classic
		Player.CameraMinZoomDistance = 6
		Camera.CameraSubject = CurrentPlayer.Character:FindFirstChildOfClass("Humanoid")
		PlrNameText.Text = CurrentPlayer.Name
	else
		warn("Can't spectate: ", CurrentPlayer)
	end
end

local function spectateNextPlayer()
	local PlayersList = getCurrentPlrList()
	NextIndex = CurrentIndex + 1
	
	if NextIndex > #PlayersList then
		NextIndex = 1
	end
	
	CurrentIndex = NextIndex
	CurrentPlayer = PlayersList[CurrentIndex]
	
	makeTransition(3)
	spectatePlayer()
end

local function spectatePreviousPlayer()
	local PlayersList = getCurrentPlrList()
	NextIndex = CurrentIndex - 1
	
	if NextIndex < 1 then
		NextIndex = #PlayersList
	end
	
	CurrentIndex = NextIndex
	CurrentPlayer = PlayersList[CurrentIndex]
	
	makeTransition(3)
	spectatePlayer()
end

NextButton.MouseButton1Click:Connect(function()
	spectateNextPlayer()
end)

PreviousButton.MouseButton1Click:Connect(function()
	spectatePreviousPlayer()
end)

ReviveButton.MouseButton1Click:Connect(function()
	plrsInGame = #game.Players:GetPlayers()
	if PlayerOnChase and PlayerOnChase.Value then
		ReviveButton.TextLabel.Text = "Can't revive now."
		return
	end
	if everyoneDied and not (plrsInGame <= 1) then return end
	if canRevive and not teleporting then
		local IsAlive = PlayerValues:WaitForChild("IsAlive") :: BoolValue
		if IsAlive then
			if not IsAlive.Value then
				canRevive = false
				if currentFreeRevives >= 1 then
					print("using free revive")
					LoadCharFunc:InvokeServer("use")
				else
					print("buying revive")
					LoadCharFunc:InvokeServer("buy")
				end
			end
		end
	end
end)

local PurchaseFinishedConnection = MarketplaceService.PromptProductPurchaseFinished:Connect(function(UserId, ProductId, WasPurchased)
	if UserId ~= Player.UserId or ProductId ~= REVIVE_PRODUCT_ID or WasPurchased then return end
	if playerDead and not teleporting and os.clock() < ReviveDeadline then
		canRevive = true
	end
end)

script.Destroying:Connect(function()
	PurchaseFinishedConnection:Disconnect()
end)

LobbyButton.MouseButton1Click:Connect(function()
	if not teleporting then
		teleporting = true
		LobbyButton.TextLabel.Text = "Teleporting..."
		local teleported = TeleportLobbyFunc:InvokeServer()
		if not teleported then
			LobbyButton.TextLabel.Text = "Back to Lobby"
		end
	end
end)

PartyLobbyButton.MouseButton1Click:Connect(function()
	if not teleporting and everyoneDied then
		local joinParty = JoinPartyFunc:InvokeServer()
		if joinParty == true then
			plrsInGame = #game.Players:GetPlayers()
			PartyLobbyButton.TextLabel.Text = `Play Again ({plrsInParty}/{plrsInGame})`
		end
	end
end)

PlrJoinedParty.OnClientEvent:Connect(function()
	plrsInParty += 1
	plrsInGame = #game.Players:GetPlayers()
	--PartyLobbyButton.Visible = true
	PartyLobbyButton.TextLabel.Text = `Play Again ({plrsInParty}/{plrsInGame})`
end)

AllPlrsDiedEvent.OnClientEvent:Connect(function()
	print("All players died.")
	--everyoneDied = true
	--// Disabled to fix bugs
end)

PlrDiedEvent.OnClientEvent:Connect(function(event, leavingParty)
	if event and leavingParty then
		plrsDied -= 1
		plrsInParty -= 1
		plrsInGame = #game.Players:GetPlayers()
		PartyLobbyButton.TextLabel.Text = `Play Again ({plrsInParty}/{plrsInGame})`
		return
	elseif event and not leavingParty then
		plrsDied -= 1
		plrsInGame = #game.Players:GetPlayers()
		PartyLobbyButton.TextLabel.Text = `Play Again ({plrsInParty}/{plrsInGame})`
		return
	end
	plrsDied += 1
	plrsInGame = #game.Players:GetPlayers()
	if plrsDied == plrsInGame then
		--everyoneDied = true
		--PartyLobbyButton.Visible = true
		--PartyLobbyButton.TextLabel.Text = `Play Again ({plrsInParty}/{plrsInGame})`
	end
end)

local function disableCam(state: boolean)
	if state then
		PlayerValuesEvent:FireServer("CamOFF")
		Player.CameraMode = Enum.CameraMode.Classic
	else
		PlayerValuesEvent:FireServer("CamON")
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
	end
end

local function activeSpectate()
	local badge = BadgesModule:FindBadge("Exterminated")
	BadgesModule:GiveBadge(Player, badge.Id)
	plrsInGame = #game.Players:GetPlayers()
	PlrDiedEvent:FireServer()
	
	task.wait(1)
	
	makeTransition(2)
	disableCam(true)
	changeGuis(false)
	spectatePlayer()
	Mouse.Icon = GameConfigModule.ChangingMouseIcon
	
	if (mouseConnection) then
		mouseConnection:Disconnect()
	end
	
	PlayerValuesEvent:FireServer("CamOFF")
	
	mouseConnection = game:GetService("RunService").Heartbeat:Connect(function()
		Player.CameraMode = Enum.CameraMode.Classic
		Player.CameraMinZoomDistance = 6
		game:GetService("UserInputService").MouseBehavior = Enum.MouseBehavior.Default
	end)
	
	if (ReviveElapsedtime) then
		ReviveElapsedtime:Disconnect()
		ReviveElapsedtime = nil
	end
	
	local alivePlrs = getCurrentPlrList()
	everyoneDied = false
	ReviveDeadline = os.clock() + maxElapsedTime
	if not everyoneDied or #alivePlrs > 0 or plrsInGame <= 1 then
		ReviveElapsedtime = coroutine.wrap(function()
			local waitTime = maxElapsedTime
			while true do
				task.wait(1)
				
				if revived then
					ReviveButton.TextLabel.Text = `Revive ({maxElapsedTime})`
					revived = false
					break
				end
				
				waitTime -= 1
				ReviveButton.TextLabel.Text = `Revive ({waitTime})`
				
				--[[if everyoneDied then
					ReviveButton.TextLabel.Text = "Everyone died..."
					break
				end]]
				
				if waitTime <= 0 then
					canRevive = false
					break
				end
			end
		end)()
	elseif everyoneDied or #alivePlrs <= 0 then
		--PartyLobbyButton.Visible = true
		ReviveButton.TextLabel.Text = "Everyone died..."
	end
	
	if plrsInGame <= 1 then
		--PartyLobbyButton.Visible = true
	end
	
	local OtherValues = Player:WaitForChild("OtherValues")
	local FreeRevives = OtherValues:WaitForChild("FreeRevives") :: IntValue
	if FreeRevives then
		TotalFreeRevivesText.Text = `You have a total of {FreeRevives.Value} revives.`
		currentFreeRevives = FreeRevives.Value
	end
	
	SpectateFrame.Visible = true
end

local function checkIfEveryoneDead()
	local PlayersAlive = getCurrentPlrList()
	if #PlayersAlive <= 0 then
		everyoneDied = true
	else
		everyoneDied = false
	end
end

local function loadSpectateMain()
	Char = Player.Character or Player.CharacterAdded:Wait()
	Hum = Char:WaitForChild("Humanoid")
	
	Hum.Died:Connect(function()
		if playerDead then return end
		onSpectate = true
		playerDead = true
		checkIfEveryoneDead()
		print(Player.Name.." died.")
		
		activeSpectate()
	end)
end

loadSpectateMain()

IsAlive:GetPropertyChangedSignal("Value"):Connect(function()
	if IsAlive.Value then
		revived = true
		canRevive = false
		ReviveDeadline = 0
		playerDead = false
		everyoneDied = false
		
		if (ReviveElapsedtime) then
			ReviveElapsedtime:Disconnect()
		end
		if (mouseConnection) then
			mouseConnection:Disconnect()
		end
		
		SpectateFrame.Visible = false
		changeGuis(true)
		Mouse.Icon = GameConfigModule.DefaultMouseIcon
		disableCam(false)
		Player.CameraMode = Enum.CameraMode.LockFirstPerson
		
		task.delay(1, function()
			canRevive = true
			loadSpectateMain()
		end)
	else
		task.wait(0.1)
		if not onSpectate and not playerDead then
			checkIfEveryoneDead()
			activeSpectate()
		end
	end
end)

Player.CharacterAdded:Connect(function(char)
	loadSpectateMain()
	Camera.CameraSubject = char:WaitForChild("Humanoid")
end)
