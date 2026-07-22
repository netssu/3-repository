local Notification = {}

function Notification.Init()
	local remote: RemoteEvent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes", 30):WaitForChild("Notification", 30)

	remote.OnClientEvent:Connect(function(notif)
		game:GetService("StarterGui"):SetCore("SendNotification", {
			Title = notif.Title,
			Text = notif.Text,
			Duration = notif.Duration,
			Icon = notif.Icon
		})
	end)
end

return Notification