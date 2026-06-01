local TextChatService = game:GetService("TextChatService")
local Channel = TextChatService:WaitForChild("TextChannels"):WaitForChild("RBXSystem")

-- A smart helper function to wrap any text in RichText tags easily
local function FormatText(text, options)
	if not options then return text end

	local result = text

	-- Handle Bold, Italic, and Underline
	if options.Bold then result = "<b>" .. result .. "</b>" end
	if options.Italic then result = "<i>" .. result .. "</i>" end
	if options.Underline then result = "<u>" .. result .. "</u>" end

	-- Combine Font, Size, and Color into a single <font> tag for cleaner code
	local fontProps = ""
	if options.Color then
		-- Automatically convert Color3 to Hex, or just use the hex string if provided
		local hex = typeof(options.Color) == "Color3" and options.Color:ToHex() or options.Color
		fontProps = fontProps .. ' color="#' .. hex .. '"'
	end
	if options.Size then
		fontProps = fontProps .. ' size="' .. tostring(options.Size) .. '"'
	end
	if options.Font then
		fontProps = fontProps .. ' face="' .. options.Font .. '"'
	end

	if fontProps ~= "" then
		result = string.format("<font%s>%s</font>", fontProps, result)
	end

	return result
end

-- A table of highly customizable messages
local Messages = {
	{
		Tag = "[SYSTEM]",
		TagOptions = { Color = Color3.fromRGB(255, 215, 0), Size = 18, Bold = true,Italic = true },
		Text = " Make Sure to <font color='#00FF00'>Like the Game👍</font>",
		TextOptions = { Color = Color3.fromRGB(255, 255, 255), Size = 18,Bold = true }
	},
	{
		Tag = "[SYSTEM]",
		TagOptions = { Color = Color3.fromRGB(255, 215, 0), Size = 18, Bold = true, Italic = true },
		Text = " Like the Game👍 and Join the Group for a <font color='#00FF00'>Free Gift🎁</font>",
		TextOptions = { Color = Color3.fromRGB(255, 255, 255), Size = 16 }
	},
	{
		Tag = "[TIP]",
		TagOptions = { Color = Color3.fromRGB(100, 150, 255), Size = 18,Bold = true }, 
		Text = " Remember to Fill up Boxes of Food to Sell in the <font color='#FF0000'>Farmers Market!</font>",
		TextOptions = { Color = Color3.fromRGB(255, 255, 255), Size = 16 }
	},
	{
		Tag = "[TIP]",
		TagOptions = { Color = Color3.fromRGB(100, 150, 255), Size = 18,Bold = true }, 
		Text = " Unlock Skills in The Skill Trees To Grow Faster!",
		TextOptions = { Color = Color3.fromRGB(255, 255, 255), Size = 16 }
	},
	{
		Tag = "[SYSTEM]",
		TagOptions = { Color = Color3.fromRGB(255, 0, 0), Size = 18,Bold = true,Italic = true }, 
		Text = " ⚠️Report <font color='#FF0000'>BUGS</font> on the Group.",
		TextOptions = { Color = Color3.fromRGB(255, 255, 255), Size = 16,Bold = true }
	},
	{
		Tag = "[SYSTEM]",
		TagOptions = { Color = Color3.fromRGB(255, 0, 0), Size = 18,Bold = true,Italic = true }, 
		Text = " ‼️Come Back <font color='#FF0000'>TOMORROW</font> For a Free Gift!",
		TextOptions = { Color = Color3.fromRGB(255, 255, 255), Size = 16,Bold = true }
	},
}

-- Broadcasting Loop
task.spawn(function()
	local lastIndex = 0 -- Variable to remember the last message we picked

	while true do
		task.wait(45) -- Wait 10 seconds between messages

		local RandomIndex

		-- Keep picking a random number until it is DIFFERENT from the last one
		repeat
			RandomIndex = math.random(1, #Messages)
		until RandomIndex ~= lastIndex

		-- Update lastIndex so it remembers this new one for the next loop
		lastIndex = RandomIndex

		local PickedMsg = Messages[RandomIndex]

		-- Format the Tag and the Text independently
		local finalTag = FormatText(PickedMsg.Tag, PickedMsg.TagOptions)
		local finalText = FormatText(PickedMsg.Text, PickedMsg.TextOptions)

		-- Combine them and send to chat
		Channel:DisplaySystemMessage(finalTag .. finalText)
	end
end)