--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = Rs:WaitForChild("Modules")
local AbbModule = require(ModulesFolder:WaitForChild("AbbreviationModule"))
local DataHandlerModule = require(ModulesFolder:WaitForChild("DataHandler"))

local Utils = ModulesFolder:WaitForChild("Utils")
local FormatString = require(Utils:WaitForChild("FormatString"))

--//Player
local Player = game.Players.LocalPlayer
local PlrLeaderstats = Player:WaitForChild("leaderstats", 30)
local PlrOtherValues = Player:WaitForChild("OtherValues", 30)

--//UI
local StatsFrame = script.Parent:FindFirstChild("StatsFrame")
local StatsList = StatsFrame.StatsList
local PlrIcon = StatsFrame.PlrIcon
local PlrName = StatsFrame.PlrName

local SpeedrunFrame = StatsFrame.Parent.SpeedrunFrame
local ChaptersList = SpeedrunFrame.ChaptersList

local thumbCache = {}

local function setupStatsUI()
	if not PlrLeaderstats then return end
	
	local wins = PlrLeaderstats:FindFirstChild("Wins")
	local coins = PlrLeaderstats:FindFirstChild("Coins")
	local kills = PlrLeaderstats:FindFirstChild("Kills")
	local equipedChar = PlrOtherValues:FindFirstChild("EquipedCharacter")
	
	local timePlayed = PlrOtherValues:FindFirstChild("TimePlayed")
	local deaths = PlrOtherValues:FindFirstChild("Deaths")
	
	if not thumbCache[Player] then
		thumbCache[Player] = game.Players:GetUserThumbnailAsync(Player.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size420x420)
	end
	PlrIcon.Image = thumbCache[Player]
	PlrName.Text = "@"..Player.Name
	
	local plrData = DataHandlerModule:GetProfileData(Player)
	if plrData and plrData["Speedruns"] then
		for runName, runTime in plrData["Speedruns"] do
			local chapterFrame = ChaptersList:FindFirstChild(runName.."Frame")
			if chapterFrame then -- Ex: Chapter1Frame
				local timeLabel = chapterFrame:FindFirstChild("SpeedrunTime") :: TextLabel
				if timeLabel then
					timeLabel.Text = "Personal Best: "..FormatString:TimeString(runTime)
				end
			end
		end
	end
	
	if wins then
		StatsList.Wins.ValueText.Text = tostring(wins.Value)
	end
	if coins then
		StatsList.Coins.ValueText.Text = tostring(coins.Value)
	end
	if kills then
		StatsList.Kills.ValueText.Text = tostring(kills.Value)
	end
	if equipedChar then
		StatsList.CurrentChar.ValueText.Text = equipedChar.Value
	end
	if timePlayed then
		local timeInHours = AbbModule.abbreviate(timePlayed.Value / 3600)
		StatsList.TimePlayed.ValueText.Text = tostring(timeInHours).."h"
	end
	if deaths then
		StatsList.TimesDied.ValueText.Text = tostring(deaths.Value)
	end
end

coroutine.wrap(function()
	while true do
		setupStatsUI()
		task.wait(10)
	end
end)()