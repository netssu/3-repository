local Ts = game:GetService("TweenService")

local textLabel = script.Parent
local colors = {
	Color3.fromRGB(255, 255, 255),
	Color3.fromRGB(0, 0, 0)
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
		
		task.wait(1.5)
	end
end
changeColor()