--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local TeleportLobbyFunc = Remotes:WaitForChild("TeleportLobby")

--//UI
local lobbyButton = script.Parent.LobbyButton

--//Sounds
local clickSound = script.ClickSound

--//Values
local alreadyTeleporting = false

lobbyButton.MouseButton1Click:Connect(function()
	clickSound:Play()
	if not alreadyTeleporting then
		alreadyTeleporting = true
		lobbyButton.Text = "Teleporting..."
		
		local teleported = TeleportLobbyFunc:InvokeServer()
		if not teleported then
			alreadyTeleporting = false
			lobbyButton.Text = "Back to Lobby"
		end
	end
end)