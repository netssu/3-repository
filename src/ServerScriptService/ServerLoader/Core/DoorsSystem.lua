local DoorsSystem = {}

function DoorsSystem.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local Ts = game:GetService("TweenService")
	local CollectionService = game:GetService("CollectionService")

	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local GameConfigModule = require(ModulesFolder:FindFirstChild("GameConfigModule"))
	local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))

	--//Values
	local TAG = "Door"
	local Doors = {}

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
			
			--[[if char:FindFirstChild(KeyValue.Value) and correctValue then
				MainDoor:FindFirstChildWhichIsA("ProximityPrompt").ActionText = "Open"
				InventoryModule.DeleteItem(KeyValue.Value)
				DoorModel:FindFirstChild("Locked").Value = false
				DoorModel:FindFirstChild("State").Value = false
				if MainDoor:FindFirstChild("UnlockSound") then
					MainDoor:FindFirstChild("UnlockSound"):Play()
				end
				return
			end]]
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

	local function addDoorModel(obj: Instance)
		local mainDoor = obj:FindFirstChild("MainDoor")
		if not mainDoor then return end
		
		if Doors[obj] then return end
		Doors[obj] = {}
		Doors[obj].Conns = {}
		
		local Prox = Instance.new("ProximityPrompt", mainDoor)
		local State = obj:FindFirstChild("State") :: BoolValue
		local Locked = obj:FindFirstChild("Locked") :: BoolValue
		local HitBox = obj:FindFirstChild("HitBox") :: BasePart
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
			if HitBox then
				Prox.Enabled = false
			end
		else
			Prox.ActionText = "Close"
			changeDoor(obj, true, "noSound")
		end

		if obj:FindFirstChild("Desc") and obj:FindFirstChild("Desc"):IsA("StringValue") then
			Prox.ObjectText = obj:FindFirstChild("Desc").Value
		end

		if Locked.Value then
			Prox.ActionText = "Unlock"
		end

		Doors[obj].Conns[1] = Prox.Triggered:Connect(function(plr)
			local char = plr.Character
			local hum = char:FindFirstChild("Humanoid")
			if DoorDebounce and char and hum and hum.Health > 0 then
				State.Value = not State.Value
				if not Locked.Value then
					if not State.Value then
						Prox.ActionText = "Open"
						if HitBox then
							Prox.Enabled = false
						end
					else
						Prox.ActionText = "Close"
					end
				end
				task.delay(1.25, resetHitBoxDebounce)
				changeDoor(obj, State.Value, Locked.Value, plr)
			end
		end)

		Doors[obj].Conns[2] = Locked.Changed:Connect(function(NewValue)
			if not NewValue then
				if obj:FindFirstChild("Collider") then
					obj:FindFirstChild("Collider").CanCollide = false
				end
				if not State.Value then
					Prox.ActionText = "Open"
				else
					Prox.ActionText = "Close"
				end
			else
				if obj:FindFirstChild("Collider") then
					obj:FindFirstChild("Collider").CanCollide = true
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
								changeDoor(obj, State.Value, Locked.Value)

								task.wait(0.35)

								Prox.Enabled = true
								DoorDebounce = true
							end
						end
					end
				end
			end)
		end
	end
	
	local function removeDoorModel(obj: Instance)
		if Doors[obj] then
			for _, conn in Doors[obj].Conns do
				conn:Disconnect()
			end
			Doors[obj] = nil
		end
	end
	
	CollectionService:GetInstanceAddedSignal(TAG):Connect(addDoorModel)
	CollectionService:GetInstanceRemovedSignal(TAG):Connect(removeDoorModel)
	
	for _, obj in CollectionService:GetTagged(TAG) do
		addDoorModel(obj)
	end
end

return DoorsSystem