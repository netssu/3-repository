--//Services
local Rs = game:GetService("ReplicatedStorage")
local Ts = game:GetService("TweenService")

--//Doors Stuff
local Map = workspace:FindFirstChild("Map")
local DoorsFolder = Map.Doors

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))
local InventoryModule = require(ModulesFolder:FindFirstChild("InventoryModule"))
local BadgesModule = require(ModulesFolder:FindFirstChild("Badges"))

--//Values
local Doors = {}

DoorsFolder.ChildAdded:Connect(function(child)
	if child:HasTag("Door") and child:IsA("Model") then
		if child:FindFirstChild("Hinge") and child:FindFirstChild("MainDoor") then
			table.insert(Doors, child)
			loadDoorsFunc()
		end
	end
end)

task.wait(3) -- Delay to don't bug

for i, v in DoorsFolder:GetChildren() do
	if v:HasTag("Door") and v:IsA("Model") then
		if v:FindFirstChild("Hinge") and v:FindFirstChild("MainDoor") then
			table.insert(Doors, v)
		end
	end
end

local function changeDoor(DoorModel: Model, state: boolean, locked: boolean, plr: Player)
	local Hinge = DoorModel:FindFirstChild("Hinge") :: BasePart
	local OpenedPos = DoorModel:FindFirstChild("OpenedPos") :: BasePart
	local ClosedPos = DoorModel:FindFirstChild("ClosedPos") :: BasePart
	local MainDoor = DoorModel:FindFirstChild("MainDoor") :: BasePart

	if locked == true and DoorModel:FindFirstChild("KeyName") then
		local KeyValue = DoorModel:FindFirstChild("KeyName") :: StringValue
		local char = plr.Character
		local correctValue = true

		if KeyValue.Value == "" or KeyValue .Value == " " then correctValue = false end

		if char:FindFirstChild(KeyValue.Value) and correctValue then
			MainDoor:FindFirstChildWhichIsA("ProximityPrompt").ActionText = "Open"
			InventoryModule.DeleteItem(KeyValue.Value)
			DoorModel:FindFirstChild("Locked").Value = false
			DoorModel:FindFirstChild("State").Value = false
			if MainDoor:FindFirstChild("UnlockSound") then
				MainDoor:FindFirstChild("UnlockSound"):Play()
			end
			return
		end
	end

	if locked == true then
		if DoorModel:FindFirstChild("Collider") then
			DoorModel:FindFirstChild("Collider").CanCollide = true
		end

		if plr then
			DialogModule.Dialog(false, plr, nil, "I need a key to open this door.")
		end

		Ts:Create(Hinge, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), {CFrame = OpenedPos.CFrame}):Play()
		task.wait(0.001)
		Ts:Create(Hinge, TweenInfo.new(0.15, Enum.EasingStyle.Cubic), {CFrame = ClosedPos.CFrame}):Play()
		if MainDoor:FindFirstChild("LockedSound") then
			MainDoor:FindFirstChild("LockedSound"):Play()
		end
		task.wait(0.2)
		return
	end

	if DoorModel:FindFirstChild("Collider") then
		DoorModel:FindFirstChild("Collider").CanCollide = false
	end

	if state then
		Ts:Create(Hinge, TweenInfo.new(0.4, Enum.EasingStyle.Cubic), {CFrame = OpenedPos.CFrame}):Play()
		if MainDoor:FindFirstChild("OpenSound") and not (locked == "noSound") then
			MainDoor:FindFirstChild("OpenSound"):Play()
		end
		task.wait(0.4)
	else
		Ts:Create(Hinge, TweenInfo.new(0.3, Enum.EasingStyle.Cubic), {CFrame = ClosedPos.CFrame}):Play()
		if MainDoor:FindFirstChild("CloseSound") then
			MainDoor:FindFirstChild("CloseSound"):Play()
		end
		task.wait(0.3)
	end
end

function loadDoorsFunc()
	for i, v: Model in ipairs(Doors) do
		if v:HasTag("markedDoor") then return end
		v:AddTag("markedDoor")

		local Prox = Instance.new("ProximityPrompt", v:FindFirstChild("MainDoor"))
		local State = v:FindFirstChild("State") :: BoolValue
		local Locked = v:FindFirstChild("Locked") :: BoolValue
		local HitBox = v:FindFirstChild("HitBox") :: BasePart
		local DoorDebounce = true
		local HitBoxDebounce = true
		Prox.Style = Enum.ProximityPromptStyle.Custom
		Prox.MaxActivationDistance = GameConfigModule.InteractDistance
		Prox.RequiresLineOfSight = false
		Prox.HoldDuration = 0.15

		local function resetHitBoxDebounce()
			HitBoxDebounce = true
		end

		if not State.Value then
			Prox.ActionText = "Open"
		else
			Prox.ActionText = "Close"
			changeDoor(v, true, "noSound")
		end

		if v:FindFirstChild("Desc") and v:FindFirstChild("Desc"):IsA("StringValue") then
			Prox.ObjectText = v:FindFirstChild("Desc").Value
		end

		if Locked.Value then
			Prox.ActionText = "Unlock"
		end

		Prox.Triggered:Connect(function(plr)
			local char = plr.Character
			local hum = char:FindFirstChild("Humanoid")
			if DoorDebounce and char and hum and hum.Health > 0 then
				State.Value = not State.Value
				if not Locked.Value then
					if not State.Value then
						Prox.ActionText = "Open"
					else
						Prox.ActionText = "Close"
					end
				end
				task.delay(1.25, resetHitBoxDebounce)
				changeDoor(v, State.Value, Locked.Value, plr)
				local badge = BadgesModule:FindBadge("Opened a Door")
				BadgesModule:GiveBadge(plr, badge.Id)
				
				-- what is this for? this was bugging the doors making it collidable even when its opened
				--[[
				for a, b in v:GetDescendants() do
					if b:IsA("BasePart") then
						b.CanCollide = not b.CanCollide
					end
				end]]
			end
		end)

		Locked.Changed:Connect(function(NewValue)
			if not NewValue then
				if v:FindFirstChild("Collider") then
					v:FindFirstChild("Collider").CanCollide = false
				end
				if not State.Value then
					Prox.ActionText = "Open"
				else
					Prox.ActionText = "Close"
				end
			else
				if v:FindFirstChild("Collider") then
					v:FindFirstChild("Collider").CanCollide = true
				end
				Prox.ActionText = "Unlock"
			end
		end)

		if HitBox then
			HitBox.Touched:Connect(function(hit)
				if not hit or not hit.Parent then return end
				if hit.Parent:FindFirstChild("Humanoid") and hit.Parent:FindFirstChild("Humanoid").Health > 0 then
					if DoorDebounce and HitBoxDebounce then
						if not Locked.Value then
							if not State.Value then
								State.Value = true
								DoorDebounce = false
								HitBoxDebounce = false
								changeDoor(v, State.Value, Locked.Value)

								task.wait(0.35)

								Prox.Enabled = true
								DoorDebounce = true

								local plr = game.Players:GetPlayerFromCharacter(hit.Parent)

								if plr then
									local badge = BadgesModule:FindBadge("Opened a Door")
									BadgesModule:GiveBadge(plr, badge.Id)
								end
							end
						end
					end
				end
			end)
		end
	end
end

loadDoorsFunc()
