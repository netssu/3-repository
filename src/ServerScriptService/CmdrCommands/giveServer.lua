local AdminState = require(script.Parent.Parent.CmdrService.AdminState)

return function(_, players, itemName)
	local given = 0
	for _, player in players do
		local result = AdminState.giveItem(player, itemName)
		if result == true then
			given += 1
		elseif type(result) == "string" then
			return result
		end
	end
	return ("Gave %q to %d player(s)."):format(itemName, given)
end
