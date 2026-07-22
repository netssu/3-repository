local Clicker = script.Parent
local Ts = game:GetService("TweenService")

Clicker.MouseEnter:Connect(function()
	Ts:Create(Clicker, TweenInfo.new(0.25), {BackgroundTransparency = 0.9}):Play()
end)

Clicker.MouseLeave:Connect(function()
	Ts:Create(Clicker, TweenInfo.new(0.25), {BackgroundTransparency = 1}):Play()
end)