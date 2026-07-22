--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local DialogModule = require(ModulesFolder:FindFirstChild("PlayerDialogModule"))

--//Asylum Reception Stuff
local Map = workspace:FindFirstChild("Map")
local AsylumReceptionFolder = Map:FindFirstChild("Area2_AsylumReception")
local InteractStuff = AsylumReceptionFolder:FindFirstChild("InteractStuff")

--//Npc's
local DeadGuyFalling = InteractStuff:FindFirstChild("DeadGuyFalling")

local guyFallingDebounce = true
local DeadGuyFall = AsylumReceptionFolder.NPCs:FindFirstChild("Dead_Patient_Elevator")
local FallAnim = DeadGuyFall:FindFirstChild("FallingAnim")
local npcAnimator = DeadGuyFall:FindFirstChild("Humanoid"):FindFirstChild("Animator")
local animFall = npcAnimator:LoadAnimation(FallAnim)
animFall:Play()
animFall:AdjustSpeed(0)
animFall.TimePosition = 0.01

DeadGuyFalling.Touched:Connect(function(hit)
	if hit.Parent:FindFirstChildWhichIsA("Humanoid") then
		if hit.Parent:FindFirstChildWhichIsA("Humanoid").Health > 0 then
			local plr = game.Players:GetPlayerFromCharacter(hit.Parent)
			if plr and guyFallingDebounce then
				guyFallingDebounce = false
				
				animFall:AdjustSpeed(0.5)
				
				animFall.KeyframeReached:Connect(function(keyFrame)
					if keyFrame == "APPEAR" then
						DeadGuyFalling:FindFirstChild("IntenseSound"):Play()
					end
				end)
				
				task.wait(3.7)
				
				DialogModule.Dialog(false, plr, nil, "This place just keeps getting worse...")
			end
		end
	end
end)