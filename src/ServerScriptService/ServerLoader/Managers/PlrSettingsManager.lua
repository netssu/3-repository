local plrSettingsManager = {}

function plrSettingsManager.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Modules
	local DataManager = require(game:GetService("ServerScriptService").Data.DataManager)
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local UpdatePlrSettingsEvent = Remotes:FindFirstChild("UpdatePlrSettings")
	
	UpdatePlrSettingsEvent.OnServerEvent:Connect(function(plr, setting: string, value)
		if setting and value ~= nil then
			local plrSettings = plr:FindFirstChild("PlrSettings") :: Folder
			if not plrSettings then return end
			
			DataManager.UpdateSetting(plr, setting, value)
		end
	end)
end

return plrSettingsManager