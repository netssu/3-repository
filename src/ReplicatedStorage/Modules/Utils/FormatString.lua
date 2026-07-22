local formatString = {}

function formatString:TimeString(totalSeconds: number, removeZeros: boolean)
	local hours = math.floor(totalSeconds / 3600)
	local minutes = math.floor((totalSeconds % 3600) / 60)
	local secs = math.floor(totalSeconds % 60)
	local milliseconds = math.floor((totalSeconds - math.floor(totalSeconds)) * 1000)
	
	if removeZeros then
		if hours <= 0 then
			return string.format("%02d:%02d.%d", minutes, secs, milliseconds)
		else
			return string.format("%d:%02d:%02d.%d", hours, minutes, secs, milliseconds)
		end
	end
	
	local formattedString = string.format("%02d:%02d:%02d.%03d", hours, minutes, secs, milliseconds)
	return formattedString
end

function formatString:ConvertToDHMS(seconds: number)
	local days = math.floor(seconds / 86400)
	seconds = seconds % 86400
	
	local hours = math.floor(seconds / 3600)
	seconds = seconds % 3600
	
	local minutes = math.floor(seconds / 60)
	seconds = seconds % 60
	
	local formattedString = ""
	
	if days > 0 then
		formattedString = formattedString .. days .. "d "
	end
	
	if hours > 0 or days > 0 then
		formattedString = formattedString .. hours .. "h "
	end
	
	if minutes > 0 or hours > 0 or days > 0 then
		formattedString = formattedString .. minutes .. "m "
	end
	
	formattedString = formattedString .. seconds .. "s"
	return formattedString
end

return formatString