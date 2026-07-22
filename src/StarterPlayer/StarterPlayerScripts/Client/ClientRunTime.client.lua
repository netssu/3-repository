--[[
	ClientRunTime.lua by @Thurzin54
	
	Little framework for new scripts.
	All new work should be made here in the client folder.
	
	"_TestModule" is a template module for when creating new modules in this simple framework.
	
	Modules can require another modules with security inside of the :Start function in the module.
	Modules can have a "DataLoad" value, if true, will only initialize / start after data is loaded.
]]

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local DataLoaded = Remotes:WaitForChild("PlrDataLoaded")

local ClientFolder = script.Parent

--[[
	@param dataModules (boolean?) | If true, will only load modules that need data loaded before initializing / starting,
	if false, will only load modules that don't need data loaded before initializing / starting.
	
	Load modules in this framework.
]]
local function setupModules(dataModules: boolean?)
	local function getModule(module: ModuleScript): ModuleScript?
		local success, result = pcall(function()
			return require(module)
		end)
		if not success then
			warn(`Error while loading {module.Name}: {result}`)
			return nil
		end
		return result
	end
	
	local modulesFramework = {}
	
	--//load all modules
	for _, module in ClientFolder:GetDescendants() do
		if module:IsA("ModuleScript") then
			local newModule = getModule(module)
			if module then
				modulesFramework[module.Name] = newModule
			end
		end
	end
	
	--//initialize all modules
	for moduleName, module in modulesFramework do
		if dataModules and not module.DataLoad then
			continue
		elseif not dataModules and module.DataLoad then
			continue
		end
		if typeof(module.Init) == "function" then
			local success, result = pcall(function()
				module:Init()
			end)
			if not success then
				warn(`Error while initializing {moduleName}: {result}`)
			end
		end
	end
	
	--//start all modules
	for moduleName, module in modulesFramework do
		if dataModules and not module.DataLoad then
			continue
		elseif not dataModules and module.DataLoad then
			continue
		end
		if typeof(module.Start) == "function" then
			local success, result = pcall(function()
				module:Start()
			end)
			if not success then
				warn(`Error while starting {moduleName}: {result}`)
			end
		end
	end
end

setupModules(false)

DataLoaded.OnClientEvent:Connect(function()
	--warn("DATA LOADED. LOADING MODULES THAT NEED PLAYER DATA LOADED.")
	setupModules(true)
end)