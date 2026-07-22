--!strict
--[[
	TestComponent.Lua by @Thurzin54
	
	Class: BasePart
]]

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Packages = ReplicatedStorage.Packages
local Component = require(Packages.Component)
local Knit = require(Packages.Knit)
local Trove = require(Packages.Trove)

local TestComponent = Component.new({
	Tag = "TestComponent",
	Ancestors = { workspace }, -- where to start searching for the component by the given tag
	Extensions = {},
})

function TestComponent:Construct()
	self._trove = Trove.new()
end

TestComponent.Started:Connect(function(component)
	--code here
end)

TestComponent.Stopped:Connect(function(component)
	component._trove:Destroy()
end)

return TestComponent