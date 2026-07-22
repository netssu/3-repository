--[[
	TestService.lua by @Thurzin54
	
	system desc.
]]

--//Services
local Rs = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

--//Modules
local Knit = require(Rs.Packages.Knit)

local TestService = {
	Name = "TestService",
	Client = {}
}

function TestService.KnitInit()
	--print("test service initialized.")
end

function TestService.KnitStart()
	--print("test service started.")
end

return TestService