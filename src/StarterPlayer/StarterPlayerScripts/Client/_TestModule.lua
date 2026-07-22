local TestModule = {
	DataLoad = false -- If true, module will only load after the player's data is loaded.
}

function TestModule:Init()
	--print("INITIALIZED:", script.Name)
end

function TestModule:Start()
	--print("STARTED: ", script.Name)
end

return TestModule