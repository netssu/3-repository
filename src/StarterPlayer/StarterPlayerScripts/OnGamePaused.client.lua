--//Services
local Ts = game:GetService("TweenService")
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local GuiService = game:GetService("GuiService")

--//Player
local plr = Players.LocalPlayer

--//Values
local defaultBlur = Lighting.Blur.Size
local newBlur = 24
local currentTween: Tween = nil
local defaultSaturation = Lighting.ColorCorrection.Saturation
local newSaturation = -1
local satTween: Tween = nil

GuiService.MenuOpened:Connect(function()
	if currentTween then
		currentTween:Cancel()
	end
	if satTween then
		satTween:Cancel()
	end
	satTween = Ts:Create(Lighting.ColorCorrection, TweenInfo.new(0.3), {Saturation = newSaturation})
	satTween:Play()
	currentTween = Ts:Create(Lighting.Blur, TweenInfo.new(1), {Size = newBlur})
	currentTween:Play()
end)

GuiService.MenuClosed:Connect(function()
	if currentTween then
		currentTween:Cancel()
	end
	if satTween then
		satTween:Cancel()
	end
	satTween = Ts:Create(Lighting.ColorCorrection, TweenInfo.new(0.3), {Saturation = defaultSaturation})
	satTween:Play()
	currentTween = Ts:Create(Lighting.Blur, TweenInfo.new(0.3), {Size = defaultBlur})
	currentTween:Play()
end)