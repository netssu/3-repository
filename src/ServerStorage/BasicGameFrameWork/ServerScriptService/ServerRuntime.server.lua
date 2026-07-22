--[[
	ServerRunime.server.lua by @TinyGecko920
	Edited by @Thurzin54

	Initialize the games server components and services.
]]

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

local Packages = ReplicatedStorage.Packages
local Knit = require(Packages.Knit)

local Server = ServerScriptService:WaitForChild("Server")
local Services = Server:WaitForChild("Services")
local Components = Server:WaitForChild("Components")

for _, v in ipairs(Services:GetDescendants()) do
	if v:IsA("ModuleScript") and v.Name:match("Service$") then
		Knit.CreateService(require(v))
	end
end

for _, v in ipairs(Components:GetDescendants()) do
	if v:IsA("ModuleScript") then
		require(v)
	end
end

-- Start Knit
Knit.Start():andThen(function()
	print("Knit started on server")
end):catch(warn)
