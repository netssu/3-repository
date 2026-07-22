local UIController = {}

function UIController.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	local Players = game:GetService("Players")
	local SoundService = game:GetService("SoundService")
	local Ts = game:GetService("TweenService")
	
	--//Modules
	local ModulesFolder = Rs:WaitForChild("Modules")
	local Packages = Rs:WaitForChild("Packages")
	local SoundPlayer = require(ModulesFolder.Utils.SoundPlayer)
	local Trove = require(Packages.Trove)
	local Component = require(Packages.Component)
	
	--//Player
	local plr = Players.LocalPlayer
	local plrGui = plr.PlayerGui
	local MenuGui = plrGui:WaitForChild("MenuGui")
	
	-------------------------------------
	--// Interact Buttons
	-------------------------------------
	local InteractButton = Component.new({
		Tag = "InteractButton",
		Ancestors = { plrGui }, -- where to start searching for the component by the given tag
		Extensions = {},
	})
	
	function InteractButton:Construct()
		self._trove = Trove.new()
	end
	
	InteractButton.Started:Connect(function(component)
		local button = component.Instance :: GuiButton
		
		assert(button:IsA("GuiButton"),
			"[UIController] Expected GuiButton, got:",
			button,
			"(InteractButton)"
		)
		
		local defaultSize = button.Size
		local ChangeImgColor = button:GetAttribute("ChangeImgColor")
		
		button.MouseEnter:Connect(function()
			SoundPlayer:PlaySound(SoundService.Effects.InteractSound)
			local newSize = UDim2.new(defaultSize.X.Scale * 1.18, 0, defaultSize.Y.Scale * 1.18, 0)
			Ts:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = newSize}):Play()
			if ChangeImgColor and button:IsA("ImageButton") then
				Ts:Create(button, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(255, 0, 0)}):Play()
			end
		end)
		
		button.MouseLeave:Connect(function()
			Ts:Create(button, TweenInfo.new(0.3, Enum.EasingStyle.Back), {Size = defaultSize}):Play()
			if ChangeImgColor and button:IsA("ImageButton") then
				Ts:Create(button, TweenInfo.new(0.3), {ImageColor3 = Color3.fromRGB(255, 255, 255)}):Play()
			end
		end)
		
		button.MouseButton1Click:Connect(function()
			SoundPlayer:PlaySound(SoundService.Effects.ClickSound)
			Ts:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back), {Size = defaultSize}):Play()
		end)
	end)
	
	InteractButton.Stopped:Connect(function(component)
		component._trove:Destroy()
	end)
	
	
	-------------------------------------
	--// Change Frames Visibility Buttons
	-------------------------------------
	local ChangeFrame = Component.new({
		Tag = "ChangeFrame",
		Ancestors = { plrGui }, -- where to start searching for the component by the given tag
		Extensions = {},
	})
	
	function ChangeFrame:Construct()
		self._trove = Trove.new()
	end
	
	local openedFrame = nil
	
	ChangeFrame.Started:Connect(function(component)
		local button = component.Instance :: GuiButton
		
		assert(button:IsA("GuiButton"),
			"[UIController] Expected GuiButton, got:",
			button,
			"(ChangeFrame)"
		)
		
		local frameOpen = button:GetAttribute("Frame")
		local selectedFrame = MenuGui:FindFirstChild("InGameFrame"):FindFirstChild(frameOpen) :: Frame
		local defaultSize = selectedFrame.Size
		
		local beingClose = {}
		local beingOpen = {}
		
		local function closeFrame(frame: Frame)
			Ts:Create(frame, TweenInfo.new(0.35, Enum.EasingStyle.Back, Enum.EasingDirection.In), {Size = UDim2.new(0, 0, 0, 0)}):Play()
			task.wait(0.35)
			frame.Visible = false
		end
		
		if selectedFrame then
			button.MouseButton1Click:Connect(function()
				print("Changing Frame:", selectedFrame)
				if selectedFrame.Visible then -- close
					if beingOpen[selectedFrame] then return end
					if beingClose[selectedFrame] then return end
					
					beingClose[selectedFrame] = true
					closeFrame(selectedFrame)
					
					if openedFrame == selectedFrame then
						openedFrame = nil
					end
					
					beingClose[selectedFrame] = false
				else -- open
					if beingClose[selectedFrame] then return end
					if beingOpen[selectedFrame] then return end
					
					if openedFrame then
						task.spawn(closeFrame, openedFrame)
					end
					
					beingOpen[selectedFrame] = true
					
					openedFrame = selectedFrame
					selectedFrame.Size = UDim2.new(0, 0, 0, 0)
					selectedFrame.Visible = true
					Ts:Create(selectedFrame, TweenInfo.new(0.35, Enum.EasingStyle.Back), {Size = defaultSize}):Play()
					
					task.wait(0.35)
					
					beingOpen[selectedFrame] = false
				end
			end)
		end
	end)
	
	ChangeFrame.Stopped:Connect(function(component)
		component._trove:Destroy()
	end)
end

return UIController
