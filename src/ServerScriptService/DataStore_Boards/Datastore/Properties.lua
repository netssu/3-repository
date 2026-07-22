local module = {
	save = true,
	studioSave = true,
	autoSave = true,
	safeSave = true,
	autoSaveInterval = 60, -- keep at 60 or higher
	
	load = true,
	studioLoad = true,
	
	retries = 10, -- For saving / loading
	yieldTimeout = 10, -- for GetData
	prints = false, -- for printing status
	datastore = "SmortGuy1-1"
}

return module
