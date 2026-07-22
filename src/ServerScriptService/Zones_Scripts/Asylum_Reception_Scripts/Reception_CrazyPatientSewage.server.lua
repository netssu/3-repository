--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Crazy patient
local NPCsFolder = AsylumReceptionFolder:FindFirstChild("NPCs")
local CrazyPatient = NPCsFolder:FindFirstChild("Crazy_Patient")
local InteractAnim = CrazyPatient:FindFirstChild("InteractAnim")
local HumCrazyPatient = CrazyPatient:FindFirstChild("Humanoid")
local animInteract = HumCrazyPatient.Animator:LoadAnimation(InteractAnim)
local PatientTrigger = InteractStuff:FindFirstChild("CrazyPatientTrigger")
animInteract.Priority = Enum.AnimationPriority.Action2

--//Values
local Triggered = false

PatientTrigger.Touched:Connect(function(hit)
	if hit.Parent and hit.Parent:FindFirstChild("Humanoid") then
		local player = game.Players:GetPlayerFromCharacter(hit.Parent)
		if player and not Triggered and hit.Parent:FindFirstChild("Humanoid").Health > 0 then
			Triggered = true
			animInteract:Play()
			repeat wait() until animInteract.Length > 0
			CrazyPatient.HumanoidRootPart.IntenseSound:Play()
			animInteract.KeyframeReached:Connect(function(keyname)
				if keyname == "BARS" then
					CrazyPatient.HumanoidRootPart.BarsSound:Play()
				elseif keyname == "GASP" then
					CrazyPatient.HumanoidRootPart.GaspSound:Play()
				elseif keyname == "LAUGH" then
					CrazyPatient.HumanoidRootPart.LaughSound:Play()
				elseif keyname == "STOP" then
					animInteract:AdjustSpeed(0)
				end
			end)
		end
	end
end)