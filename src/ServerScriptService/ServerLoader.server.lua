--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local ModulesHandler = require(ModulesFolder:FindFirstChild("ModulesHandlerLoader"))

ModulesHandler.LoadModules(script)