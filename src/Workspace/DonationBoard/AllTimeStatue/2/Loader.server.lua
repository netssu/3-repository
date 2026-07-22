local Model = script.Parent
local Config = Model.Configuration
local userId = Config.userId.Value

local Loader

if Config.AutoUpdateLoader.Value then
	Loader = require(10599737239)
else
	Loader = require(script.MainModule)
end


-------------------------------------------------------------------------------------

Loader:updateModel(Model, Config.userId.Value)

if Config.AutoUpdateCharacter.Value then
	while wait(Config.AutoUpdateCharacter.Delay.Value) do
		Loader:updateModel(Model, Config.userId.Value)
	end
end