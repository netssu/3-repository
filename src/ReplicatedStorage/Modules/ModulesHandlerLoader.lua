--!nonstrict

--//Module By: @oigaleratudobemm (Thurzin54) | 25/05/2025

--[[Example Usage:

1. ServerLoader[Script]
	| Class Module or a Folder
		| Modules With .Init() Function.

2. ClientLoader[LocalScript]
	| Class Module or a Folder
		| Modules With .Init() Function.
		
-------------[//]----------------[//]-------------

	Default Class Module Script:

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local ModulesHandler = require(Modules:FindFirstChild("ModulesHandlerLoader"))

return ModulesHandler.CollectModules(script)

-------------[//]----------------[//]-------------

	Default Loader Scripts [Server-Client]:

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local ModulesHandler = require(ModulesFolder:FindFirstChild("ModulesHandlerLoader"))

ModulesHandler.LoadModules(script)

]]

--//Services
local RunService = game:GetService("RunService")

local ModulesHandler = {}

type ModuleList = { ModuleScript }
type Side = Script | LocalScript
type ModuleClass = ModuleScript | Folder

--[[
	This function get a list of Modules on a table and Initialize them
	@param modulesList { ModuleScript } -- A table with ModuleScript instances
]]
function ModulesHandler.SecureRequire(modulesList: ModuleList)
	for _, module in ipairs(modulesList) do
		local success, result = pcall(function()
			return require(module)
		end)
		if success then
			if typeof(result) == "table" and typeof(result.Init) == "function" then
				if typeof(result.Enabled) == "boolean" and not result.Enabled then
					local moduleName = result.Name or result
					print(tostring(moduleName), "are current disabled.")
					continue
				end
				task.spawn(function()
					local loaded, errmsg = pcall(function()
						result.Init()
					end)
					if not loaded then
						warn("Failed to Init: ", module.Name)
						error("Error: "..errmsg)
					end
				end)
			end
		else
			warn("Can't load", module, "result:", result)
		end
	end
end

--[[
	This function get a Loader Script and load all Classes inside of him.
	@param service Instance --  Loader script instance.
]]
function ModulesHandler.LoadModules(service: Side)
	if not service then warn("No service to load.") return end
	local side = RunService:IsServer() and "Server" or "Client"
	
	print("---------------------")
	print("//Loading ".. side .." Modules . . .")
	print("---------------------")
	
	local classTable = service:GetChildren()
	
	--//Make modules with higher priority load first due to dependencies on other modules
	table.sort(classTable, function(a, b)
		local priorityA = a:GetAttribute("Priority") or 0
		local priorityB = b:GetAttribute("Priority") or 0
		return priorityA > priorityB
	end)
	
	for _, class in ipairs(classTable) do
		if class:IsA("Folder") then
			local moduleLists = ModulesHandler.CollectModules(class)
			if moduleLists then ModulesHandler.SecureRequire(moduleLists) end
			continue
		end
		
		task.spawn(function()
			local success, result = pcall(function()
				return require(class)--()
			end)
			if success then
				ModulesHandler.SecureRequire(result)
			else
				warn("Can't load Module Class:", class.Name)
				error("Result: "..result)
			end
		end)
	end
	
	print("---------------------")
	print("//".. side .." Modules Loaded!")
	print("---------------------")
end

--[[
	This function get all Modules inside of a Table or ModuleScript and group then in one table
	@param class ModuleScript | Folder -- ModuleScript or a Folder with Modules.
	@return classModules { ModuleScript } -- A table with Modules
]]
function ModulesHandler.CollectModules(class: ModuleClass)
	if not class or (not class:IsA("ModuleScript") and not class:IsA("Folder")) then
		warn("Incorrect class received, expected Folder or ModuleScript. ::", class)
		return
	end
	
	local classModules = {}
	
	for _, v in ipairs(class:GetChildren()) do
		if v:IsA("ModuleScript") then
			table.insert(classModules, v)
		end
	end
	
	return classModules
end

return ModulesHandler