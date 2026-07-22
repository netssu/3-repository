local formatString = {}

function formatString:TimeString(totalSeconds: number)
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local secs = math.floor(totalSeconds % 60)
	local milliseconds = math.floor((totalSeconds - math.floor(totalSeconds)) * 1000)
	
	local formattedString = string.format("%02d:%02d:%02d.%03d", hours, minutes, secs, milliseconds)
	return formattedString
end

return formatString