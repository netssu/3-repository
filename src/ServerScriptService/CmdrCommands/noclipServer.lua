local AdminState = require(script.Parent.Parent.CmdrService.AdminState)

return function(_, players, enabled)
	for _, player in players do
		AdminState.setNoclip(player, enabled)
	end
	return ("Noclip %s for %d player(s)."):format(enabled and "enabled" or "disabled", #players)
end
