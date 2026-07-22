--//Services
local Ts = game:GetService("TweenService")
local Rs = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--//Player
local Player = game.Players.LocalPlayer
local OtherValues = Player:WaitForChild("OtherValues")
local OwnedCharacters = OtherValues:WaitForChild("OwnedCharacters")
local EquipedCharacter = OtherValues:WaitForChild("EquipedCharacter") :: StringValue

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local UpdateChar = Remotes:WaitForChild("UpdateEquipedChar")

--//Characters Stuff
local CharactersFolder = Rs:WaitForChild("GameCharacters")
local LobbyFolder = workspace:WaitForChild("Map"):WaitForChild("LobbyStuff")

--//UI
local MainFrame = script.Parent
local CharactersFrame = MainFrame.CharactersFrame
local CharsSelectionFrame = CharactersFrame.CharacterSelection.CharactersSelector
local CharSpotExample = CharsSelectionFrame.CharSpot_Example
local CharDescFrame = CharactersFrame.CharacterDesc
local itemTextExample = CharDescFrame.ItemsFrame.ItemTextExample

--//Sounds
local SoundsFolder = MainFrame:FindFirstChild("Sounds")
local InteractSound = SoundsFolder:FindFirstChild("InteractSound")
local ClickSound = SoundsFolder:FindFirstChild("ClickSound")
local TransitionEffect = SoundsFolder:FindFirstChild("TransitionEffect")

if not game:IsLoaded() then
	game.Loaded:Wait()
end

--//Values
local CurrentEquipedChar = UpdateChar:InvokeServer("Update") :: string
local DefaultCharactersPos = LobbyFolder:WaitForChild("CharSelector", 30):WaitForChild("HumanoidRootPart", 30)
local blinkConnection: RBXScriptConnection = nil

--//Setup
pcall(function()
	CharSpotExample.Parent = Rs
	itemTextExample.Parent = Rs
	LobbyFolder.CharSelector:Destroy()
	DefaultCharactersPos = DefaultCharactersPos.CFrame
end)

local newChar = CharactersFolder:FindFirstChild(CurrentEquipedChar, true):Clone() :: Model
newChar.Parent = LobbyFolder
newChar.PrimaryPart.CFrame = DefaultCharactersPos
newChar.Name = "CharSelector"

local function clearViewPort(port: ViewportFrame)
	if not port then warn("No ViewportFrame received.") return end
	for i, v in port:GetChildren() do
		if v:IsA("Model") then
			v:Destroy()
		end
	end
end

local function clearItemsFrame()
	for i, v in CharDescFrame.ItemsFrame:GetChildren() do
		if v:IsA("ImageLabel") then
			v:Destroy()
		end
	end
end

local function createBlinkConnection(charModel)
	if blinkConnection then
		blinkConnection:Disconnect()
	end
	
	local idleAnim = charModel:WaitForChild("Humanoid"):WaitForChild("Animator"):LoadAnimation(charModel:WaitForChild("IdleAnim"))
	idleAnim:Play()
	
	local Head = charModel:WaitForChild("Head") :: BasePart
	local face1 = Head:WaitForChild("face")
	local face2 = Head:WaitForChild("face_SemiBlink")
	local face3 = Head:WaitForChild("face_Blink")
	
	local function blink()
		local waitTime = math.random(100, 150)
		face1.Transparency = 1
		face2.Transparency = 0
		face3.Transparency = 1
		task.wait(waitTime/1000/3)
		face1.Transparency = 1
		face2.Transparency = 1
		face3.Transparency = 0
		task.wait(waitTime/1000/3)
		face1.Transparency = 1
		face2.Transparency = 0
		face3.Transparency = 1
		task.wait(waitTime/1000/3)
		face1.Transparency = 0
		face2.Transparency = 1
		face3.Transparency = 1
	end
	
	blinkConnection = coroutine.wrap(function()
		while true do
			task.wait(math.random(3, 4))
			local state = math.random(0, 1)
			if state == 0 then
				blink()
			else
				blink()
				task.wait(0.2)
				blink()
			end
		end
	end)()
end

createBlinkConnection(newChar)

local function changeChar(charName: string)
	if LobbyFolder:FindFirstChild("CharSelector") then
		LobbyFolder:FindFirstChild("CharSelector"):Destroy()
		local newChar = CharactersFolder:FindFirstChild(charName, true):Clone()
		newChar.Parent = LobbyFolder
		newChar.PrimaryPart.CFrame = DefaultCharactersPos
		newChar.Name = "CharSelector"
		createBlinkConnection(newChar)
	end
end

local function updateDescFrame(config: ModuleScript)
	if not config then warn("No config [Module Script] received.") return end
	CharDescFrame.Title.Text = config.Name
	CharDescFrame.Desc.Text = config.Desc
	CharDescFrame.StatsFrame.Strengh.valueText.Text = config.Damage
	CharDescFrame.StatsFrame.Health.valueText.Text = config.Health
	CharDescFrame.StatsFrame.Speed.valueText.Text = config.RunSpeed
	CharDescFrame.StatsFrame.Jump.valueText.Text = config.Jump
	
	clearItemsFrame()
	
	for i, v in pairs(config.StarterItems) do
		local newText = itemTextExample:Clone()
		newText.Parent = CharDescFrame.ItemsFrame
		newText.AmountTX.Text = tostring(v)
		newText.ItemNameTX.Text = "x "..tostring(i)
	end
end

local function SetupCharsSelectionUI()
	for i, v in CharactersFolder:GetDescendants() do
		if v:IsA("Model") then
			if v:FindFirstChildWhichIsA("ModuleScript") then
				local config = require(v:FindFirstChildWhichIsA("ModuleScript"))
				local spotFrame = CharSpotExample:Clone()
				local clonedModel = v:Clone()
				local oldModelPos = spotFrame.ViewportFrame:FindFirstChildWhichIsA("Model").PrimaryPart.CFrame
				local camera = Instance.new("Camera")
				camera.Parent = spotFrame.ViewportFrame
				spotFrame.Parent = CharsSelectionFrame
				spotFrame.ViewportFrame.CurrentCamera = camera
				spotFrame.CharName.Text = v.Name
				spotFrame.LayoutOrder = config.Order
				spotFrame.Name = v.Name
				
				clearViewPort(spotFrame.ViewportFrame)
				
				clonedModel.Parent = spotFrame.ViewportFrame
				clonedModel.PrimaryPart.CFrame = oldModelPos
				camera.CFrame = CFrame.new(Vector3.new(0, 4.5, -4), oldModelPos.Position)
				
				if CurrentEquipedChar == v.Name then
					updateDescFrame(config)
					spotFrame.EquipButton.Text = "Equipped"
					spotFrame.EquipButton.StateText.Text = "Equipped"
					spotFrame.EquipButton.TextColor3 = Color3.fromRGB(203, 39, 39)
				else
					if not OwnedCharacters:FindFirstChild(v.Name) and config.Limited then
						spotFrame.EquipButton.Text = "Locked"
						spotFrame.EquipButton.StateText.Text = "Locked"
						spotFrame.EquipButton.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
						spotFrame.EquipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
						spotFrame.EquipButton.UIStrokeText.Color = Color3.fromRGB(0, 0, 0)
						spotFrame.EquipButton.UIStroke.Color = Color3.fromRGB(29, 29, 29)
					elseif not OwnedCharacters:FindFirstChild(v.Name) and config.RobuxId then
						local passInfo = nil
						
						pcall(function()
							passInfo = MarketplaceService:GetProductInfo(config.RobuxId, Enum.InfoType.GamePass)
						end)
						
						if passInfo then
							spotFrame.EquipButton.Text = "R$ "..passInfo.PriceInRobux
							spotFrame.EquipButton.StateText.Text = "R$ " ..passInfo.PriceInRobux
							spotFrame.EquipButton.TextColor3 = Color3.fromRGB(59, 255, 15)
						else
							spotFrame.EquipButton.Text = "Locked"
							spotFrame.EquipButton.StateText.Text = "Locked"
							spotFrame.EquipButton.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
							spotFrame.EquipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
							spotFrame.EquipButton.UIStrokeText.Color = Color3.fromRGB(0, 0, 0)
							spotFrame.EquipButton.UIStroke.Color = Color3.fromRGB(29, 29, 29)
						end
					end
				end
				
				task.wait()
			end
		end
	end
end

local function updateCharsUI()
	for i, v in CharsSelectionFrame:GetChildren() do
		if v:IsA("Frame") then
			if v.CharName.Text == CurrentEquipedChar then
				v.EquipButton.Text = "Equipped"
				v.EquipButton.StateText.Text = "Equipped"
				v.EquipButton.TextColor3 = Color3.fromRGB(203, 39, 39)
				v.EquipButton.UIStrokeText.Color = Color3.fromRGB(130, 100, 39)
				v.EquipButton.UIStroke.Color = Color3.fromRGB(130, 100, 39)
			else
				if OwnedCharacters:FindFirstChild(v.CharName.Text) then
					v.EquipButton.Text = "Equip"
					v.EquipButton.StateText.Text = "Equip"
					v.EquipButton.BackgroundColor3 = Color3.fromRGB(255, 219, 76)
					v.EquipButton.TextColor3 = Color3.fromRGB(138, 249, 255)
					v.EquipButton.UIStrokeText.Color = Color3.fromRGB(130, 100, 39)
					v.EquipButton.UIStroke.Color = Color3.fromRGB(130, 100, 39)
				else
					local charModel = CharactersFolder:FindFirstChild(v.CharName.Text, true)
					local config = require(charModel:FindFirstChildWhichIsA("ModuleScript"))
					if not config.Limited then
						v.EquipButton.Text = "$"..config.Price
						v.EquipButton.StateText.Text = "$"..config.Price
						if config.RobuxId then
							local passInfo = nil
							pcall(function()
								passInfo = MarketplaceService:GetProductInfo(config.RobuxId, Enum.InfoType.GamePass)
							end)
							if passInfo then
								v.EquipButton.Text = "R$ "..passInfo.PriceInRobux
								v.EquipButton.StateText.Text = "R$ "..passInfo.PriceInRobux
								v.EquipButton.TextColor3 = Color3.fromRGB(59, 255, 15)
							else
								v.EquipButton.Text = "Locked"
								v.EquipButton.StateText.Text = "Locked"
								v.EquipButton.BackgroundColor3 = Color3.fromRGB(113, 113, 113)
								v.EquipButton.TextColor3 = Color3.fromRGB(255, 255, 255)
								v.EquipButton.UIStrokeText.Color = Color3.fromRGB(0, 0, 0)
								v.EquipButton.UIStroke.Color = Color3.fromRGB(29, 29, 29)
							end
						end
					end
				end
			end
		end
	end
end

SetupCharsSelectionUI()

local function connectCharsFunc()
	for i, v in CharsSelectionFrame:GetChildren() do
		if v:IsA("Frame") then
			v.EquipButton.MouseButton1Click:Connect(function()
				ClickSound:Play()
				local config = require(CharactersFolder:FindFirstChild(v.CharName.Text, true):FindFirstChildWhichIsA("ModuleScript"))
				
				if v.EquipButton.Text == "Equip" then
					local equiped = UpdateChar:InvokeServer("Equip", v.CharName.Text)
					if equiped then
						print("equipped character:", v.CharName.Text)
						changeChar(v.CharName.Text)
						CurrentEquipedChar = v.CharName.Text
						updateCharsUI()
						updateDescFrame(config)
					end
				elseif v.EquipButton.Text ~= "Equipped" then
					if config.Limited then return end
					
					local robuxCharacter = v.EquipButton.Text:match("R")
					if robuxCharacter then
						local success, errmsg = pcall(function()
							MarketplaceService:PromptGamePassPurchase(Player, config.RobuxId)
						end)
						if not success then
							warn("Can't prompt character gamepass purchase. Error:", errmsg)
						end
						return
					end
					
					local purchaseChar = UpdateChar:InvokeServer("Buy", v.CharName.Text)
					if purchaseChar then
						SoundsFolder.PurchaseSound:Play()
						updateCharsUI()
					else
						SoundsFolder.IncorrectSound:Play()
					end
				end
			end)
			
			v.Clicker.MouseButton1Click:Connect(function()
				ClickSound:Play()
				local config = require(CharactersFolder:FindFirstChild(v.CharName.Text, true):FindFirstChildWhichIsA("ModuleScript"))
				updateDescFrame(config)
				changeChar(v.CharName.Text)
				updateDescFrame(config)
			end)
		end
	end
	
	OwnedCharacters.ChildAdded:Connect(function(child)
		updateCharsUI()
	end)
end

connectCharsFunc()
updateCharsUI()