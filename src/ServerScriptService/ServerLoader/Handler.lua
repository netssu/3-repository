--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local Modules = Rs:FindFirstChild("Modules")
local ModulesHandler = require(Modules:FindFirstChild("ModulesHandlerLoader"))

return ModulesHandler.CollectModules(script)