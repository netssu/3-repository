local WormsFrame = script.Parent.Parent.Parent
local Scroller

local deadline = os.clock() + 5
repeat
	Scroller = WormsFrame:FindFirstChild("ScrollingFrame", true)
	if Scroller then
		break
	end

	task.wait(0.1)
until os.clock() >= deadline

if not Scroller then
	warn("[Worms Search] Missing ScrollingFrame under " .. WormsFrame:GetFullName())
	return
end

script.Parent.Changed:Connect(function()
	local text = string.lower(script.Parent.Text)

	if text == "" then
		for _, frame in ipairs(Scroller:GetChildren()) do
			if frame:IsA("Frame") then
				frame.Visible = true
			end
		end
	else
		for _, frame in ipairs(Scroller:GetChildren()) do
			if frame:IsA("Frame") then
				local name = string.lower(frame.Name)
				frame.Visible = string.find(name, text) ~= nil
			end
		end
	end
end)
