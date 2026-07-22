local dialogModule = {}

--//Services
local Rs = game:GetService("ReplicatedStorage")
local PlrDialog = Rs:WaitForChild("Remotes"):WaitForChild("PlrDialog")

dialogModule.Dialog = function(AllPlrs: boolean, Player, DialogFolder: Folder?, SimpleText: string, sound2: boolean?)
	if not DialogFolder then
		if AllPlrs then
			PlrDialog:FireAllClients(false, SimpleText, sound2)
		else
			PlrDialog:FireClient(Player, false, SimpleText, sound2)
		end
		return
	end
	
	local dialog = {}
	
	for i, v in DialogFolder:GetChildren() do
		local text = {
			["Text"] = v.Text.Value,
			["Duration"] = v.Duration.Value
		}
		table.insert(dialog, tonumber(v.Name), text)
	end
	
	if AllPlrs then
		PlrDialog:FireAllClients(dialog)
	else
		PlrDialog:FireClient(Player, dialog)
	end
end

return dialogModule