--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local PlayerValuesEvent = Remotes:WaitForChild("PlayerValues")

--//Player
local Plr = game.Players.LocalPlayer

--//Safe Parts
local Map = workspace:WaitForChild("Map")
local SafeAreasFolder = Map:WaitForChild("SafeAreas")

local function updateSafesAreas()
	for i, SafeArea: BasePart in SafeAreasFolder:GetChildren() do
		if SafeArea:HasTag("SafeArea") then
			if not SafeArea:HasTag("MarkedSafeArea") then
				SafeArea:AddTag("MarkedSafeArea")
				
				SafeArea.Touched:Connect(function(hit)
					if not hit.Parent then return end
					if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
						local player = game.Players:GetPlayerFromCharacter(hit.Parent)
						if player and player == Plr and hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 and hit.Name == "HumanoidRootPart" then
							PlayerValuesEvent:FireServer("SafeON")
						end
					end
				end)
				
				SafeArea.TouchEnded:Connect(function(hit)
					if not hit.Parent then return end
					if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
						local player = game.Players:GetPlayerFromCharacter(hit.Parent)
						if player and player == Plr and hit.Name == "HumanoidRootPart" then
							PlayerValuesEvent:FireServer("SafeOFF")
						end
					end
				end)
			end
		end
	end
end

SafeAreasFolder.ChildAdded:Connect(function(child)
	updateSafesAreas()
end)

if not game:IsLoaded() then
	game.Loaded:Wait()
end

updateSafesAreas()