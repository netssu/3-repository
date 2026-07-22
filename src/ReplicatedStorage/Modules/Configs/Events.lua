local Events = {
	Xmas_2025 = {
		EndDate = os.time({
			year = 2026,
			month = 1,
			day = 1,
			hour = 0,
			min = 0,
			sec = 0,
		})
	}
}

--//Services
local Rs = game:GetService("ReplicatedStorage")
local FormatString = require(Rs:WaitForChild("Modules"):WaitForChild("Utils").FormatString)

function Events:CalculateTimeLeft(eventName: string): string | boolean
	local event = self[eventName]
	if not event then return end
	
	local timeLeft = event.EndDate - os.time()
	local formatedString = FormatString:ConvertToDHMS(timeLeft)
	
	local eventEnded = timeLeft <= 0
	
	return formatedString, eventEnded
end

return Events