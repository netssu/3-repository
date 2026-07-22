local Model = script.Parent
local Config = Model.Configuration
local Loader = require(script.MainModule)

-------------------------------------------------------------------------------------

Loader:updateModel(Model, Config.userId.Value)

while task.wait(Config.AutoUpdateCharacter.Delay.Value) do
	local name = "Unknown"
	pcall(function()
		name = game.Players:GetNameFromUserIdAsync(Config.userId.Value)
	end)
	Model.Tags.Container.pName.Text = name
	Loader:updateModel(Model, Config.userId.Value)
end