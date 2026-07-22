local AdminState = require(script.Parent.Parent.CmdrService.AdminState)

return function(_, players, enabled)
	for _, player in players do
		AdminState.setGodMode(player, enabled)
	end
	return ("God mode %s for %d player(s)."):format(enabled and "enabled" or "disabled", #players)
end
