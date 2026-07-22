--[[
	ClientRuntime.client.lua by @TinyGecko920

	Initialize the games client components and controllers.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Added = script.Parent:WaitForChild("Client"):WaitForChild("Added")
local GameClient = script.Parent:WaitForChild("Client"):WaitForChild("Game")
local AddedControllers = Added:WaitForChild("Controllers")
local AddedComponents = Added:WaitForChild("Components")
local Components = GameClient:WaitForChild("Components")
local Controllers = GameClient:WaitForChild("Controllers")

local ComponentsTable = {}
local ControllersTable = {}

--[[
	Require components from a folder (any ModuleScript descendant of the folder)

	@param components (Instance) The folder to require descendants from.
]]
local function RequireComponents(components: Instance)
	for _, v: Instance in ipairs(components:GetDescendants()) do
		if v:IsA("ModuleScript") and not table.find(ComponentsTable, v.Name) then
			local st = tick()
			table.insert(ComponentsTable, v.Name)
			require(v)
			--print("Required " .. v.Name .. " (" .. tick() - st .. ")")
		end
	end
end

--[[
	Require services from a folder (ModuleScript's ending in "Controller")

	@param controllers (Instance) The folder to require descendants from.
]]
local function RequireControllers(controllers: Instance)
	for _, v: Instance in ipairs(controllers:GetDescendants()) do
		if v:IsA("ModuleScript") and v.Name:match("Controller$") and not table.find(ControllersTable, v.Name) then
			local st = tick()
			table.insert(ControllersTable, v.Name)
			Knit.CreateController(require(v))
			--print("Required " .. v.Name .. " (" .. tick() - st .. ")")
		end
	end
end

-- Prioritize and load overwritten controllers & components,
-- or added controllers & components which are not part of the framework
-- then load framework controllers & components
RequireControllers(AddedControllers)
RequireControllers(Controllers)

-- Start Knit
Knit.Start()
	:andThen(function()
		print("Knit started on client")
		RequireComponents(AddedComponents)
		RequireComponents(Components)
	end)
	:catch(warn)
