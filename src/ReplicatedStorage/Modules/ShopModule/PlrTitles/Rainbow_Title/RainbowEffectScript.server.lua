local Ts = game:GetService("TweenService")

local textLabel = script.Parent
local colors = {
	Color3.fromRGB(255, 0, 0), -- Red
	Color3.fromRGB(0, 0, 255), -- Blue
	Color3.fromRGB(0, 255, 0), -- Green
	Color3.fromRGB(26, 255, 133), -- Cyan
	Color3.fromRGB(255, 79, 173), -- Pink
	Color3.fromRGB(193, 0, 207), -- Purple
}

local function changeColor()
	local currentIndex = 1
	while true do
		local currentColor = colors[currentIndex]
		
		local nextIndex = currentIndex + 1
		if nextIndex > #colors then
			nextIndex = 1
		end
		
		local nextColor = colors[nextIndex]
		local tweenInfo = TweenInfo.new(1, Enum.EasingStyle.Linear)
		local tween = Ts:Create(textLabel, tweenInfo, {TextColor3 = nextColor})
		tween:Play()
		currentIndex = nextIndex
		
		task.wait(1)
	end
end
changeColor()