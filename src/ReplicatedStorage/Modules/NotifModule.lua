local SS = game:GetService("ServerStorage")
local RS = game:GetService("ReplicatedStorage")
local TS = game:GetService("TweenService")
local CS = game:GetService("CollectionService")
local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")
local HTTPs = game:GetService("HttpService")
local Players = game:GetService("Players")

local NotifModule = {}
	function NotifModule.Notify(plr:Player,Text:string)
		task.spawn(function()
		local NotifText = RS:WaitForChild("UIAssets").NotifText:Clone()
		NotifText.Parent = plr.PlayerGui:WaitForChild("HUD").Notifications.List
		NotifText.Text = Text
		Debris:AddItem(NotifText,4)
		NotifText.UIScale.Scale = 0
		local Tween = TS:Create(NotifText.UIScale,TweenInfo.new(0.45,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Scale = 1})
		Tween:Play()
		local NotifSFX = RS:WaitForChild("Assets").SFX.NotifSound:Clone()
		NotifSFX.Parent = plr.Character:WaitForChild("HumanoidRootPart")
		NotifSFX:Play()
		Debris:AddItem(NotifSFX,1)

		Tween.Completed:Wait()
		task.wait(2)
		local Tween2 = TS:Create(NotifText.UIScale,TweenInfo.new(1.25,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Scale = 0})
		Tween2:Play()
		TS:Create(NotifText,TweenInfo.new(1,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{TextTransparency = 1})
		Tween2.Completed:Once(function()
			NotifText:Destroy()
		end)	
		end)
	end
	
function NotifModule.ItemNotify(plr:Player,IconImageID,Text:string)
	task.spawn(function()
		local NotifText = RS:WaitForChild("UIAssets").ItemNotif:Clone()
		NotifText.Parent = plr.PlayerGui:WaitForChild("HUD").Notifications.List
		NotifText.IconNotifText.Text = Text
		Debris:AddItem(NotifText,6)
		NotifText.UIScale.Scale = 0
		NotifText.IconNotifText.ItemIcon.Image = IconImageID
		local Tween = TS:Create(NotifText.UIScale,TweenInfo.new(0.45,Enum.EasingStyle.Elastic,Enum.EasingDirection.Out,0,false,0),{Scale = 1})
		Tween:Play()
		local NotifSFX = RS:WaitForChild("Assets").SFX.ItemNotifSound:Clone()
		NotifSFX.Parent = plr.Character:WaitForChild("HumanoidRootPart")
		NotifSFX:Play()
		Debris:AddItem(NotifSFX,1.25)

		Tween.Completed:Wait()
		task.wait(4)
		local Tween2 = TS:Create(NotifText.UIScale,TweenInfo.new(1.25,Enum.EasingStyle.Back,Enum.EasingDirection.In,0,false,0),{Scale = 0})
		Tween2:Play()
		Tween2.Completed:Once(function()
			NotifText:Destroy()
		end)	
	end)
	
end
	
return NotifModule
