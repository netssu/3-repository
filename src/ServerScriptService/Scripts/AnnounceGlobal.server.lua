local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local MessagingService = game:GetService("MessagingService")
local HttpService = game:GetService("HttpService")
local SoundService = game:GetService("SoundService")

local AnnouncementEvent = ReplicatedStorage:WaitForChild("GlobalAnnouncementEvent")

-- Sound effect setup
local SOUND_ID = "rbxassetid://17208361335"

local function playAnnouncementSFX()
	local sound = Instance.new("Sound")
	sound.SoundId = SOUND_ID
	sound.Volume = 0.65
	sound.PlayOnRemove = false
	sound.Looped = false
	sound.Parent = SoundService
	sound:Play()
	game:GetService("Debris"):AddItem(sound, 6)
end

local Admins = {
	["AimbotJokers"] = true, 
	["oigaleratudobemm"] = true, -- Replace with your username
}

local seen = {}
local function isDuplicate(id)
	if seen[id] then return true end
	seen[id] = tick()

	for msgId, t in pairs(seen) do
		if tick() - t > 30 then
			seen[msgId] = nil
		end
	end
	return false
end

local function handleAnnouncement(player, command, text)
	if not Admins[player.Name] then return end
	command = command:lower()

	if command == "/globalannounce" then
		local data = {
			id = HttpService:GenerateGUID(false),
			displayName = player.DisplayName,
			prefix = "  ",
			message = text,
		}

		local success, err = pcall(function()
			MessagingService:PublishAsync("GlobalAnnouncementChannel", data)
		end)
		if not success then
			warn("[Global Announcement] Failed:", err)
		end

		if not isDuplicate(data.id) then
			AnnouncementEvent:FireAllClients(data)
			playAnnouncementSFX()
		end

	elseif command == "/serverannounce" then
		AnnouncementEvent:FireAllClients({
			displayName = player.DisplayName,
			prefix = "  ",
			message = text,
		})
		playAnnouncementSFX()
	end
end

Players.PlayerAdded:Connect(function(player)
	player.Chatted:Connect(function(msg)
		local command, text = msg:match("^(%S+)%s+(.*)")
		if command and text then
			handleAnnouncement(player, command, text)
		end
	end)
end)

for _, player in ipairs(Players:GetPlayers()) do
	player.Chatted:Connect(function(msg)
		local command, text = msg:match("^(%S+)%s+(.*)")
		if command and text then
			handleAnnouncement(player, command, text)
		end
	end)
end

pcall(function()
	MessagingService:SubscribeAsync("GlobalAnnouncementChannel", function(message)
		local data = message.Data
		if typeof(data) == "table" and data.id and not isDuplicate(data.id) then
			AnnouncementEvent:FireAllClients(data)
			playAnnouncementSFX()
		end
	end)
end)
