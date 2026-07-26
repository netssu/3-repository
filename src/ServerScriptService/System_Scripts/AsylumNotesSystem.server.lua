--//Services
local Debris = game:GetService("Debris")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--//Modules
local ModulesFolder = ReplicatedStorage:WaitForChild("Modules")
local ConfigsFolder = ModulesFolder:WaitForChild("Configs")
local GameConfigModule = require(ModulesFolder:WaitForChild("GameConfigModule"))
local AsylumNotes = require(ConfigsFolder:WaitForChild("AsylumNotes"))

--//Remotes
local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
if not Remotes then
	Remotes = Instance.new("Folder")
	Remotes.Name = "Remotes"
	Remotes.Parent = ReplicatedStorage
end

local OpenNoteEvent = Remotes:FindFirstChild("OpenAsylumNote")
if not OpenNoteEvent then
	OpenNoteEvent = Instance.new("RemoteEvent")
	OpenNoteEvent.Name = "OpenAsylumNote"
	OpenNoteEvent.Parent = Remotes
end

--//Config
local COLLECT_SOUND_ID = "rbxassetid://2217513097"
local TRIGGER_COOLDOWN_SECONDS = 0.75

--//Notes
local NotesFolder = workspace:WaitForChild("Notes", 30)
local debounceByPlayerAndNote = {}

if not NotesFolder then
	warn("[AsylumNotesSystem] workspace.Notes was not found. Notes prompts were not created.")
	return
end

local function getPromptParent(notePart: BasePart)
	return notePart
end

local function playCollectSound(notePart: BasePart)
	local sound = Instance.new("Sound")
	sound.Name = "NoteCollectSound"
	sound.SoundId = COLLECT_SOUND_ID
	sound.Volume = 0.45
	sound.RollOffMode = Enum.RollOffMode.InverseTapered
	sound.RollOffMinDistance = 4
	sound.RollOffMaxDistance = 35
	sound.Parent = notePart
	sound:Play()

	Debris:AddItem(sound, 8)
end

local function canReadNote(player: Player, noteId: number)
	local character = player.Character
	if not character then
		return false
	end

	local humanoid = character:FindFirstChildWhichIsA("Humanoid")
	if not humanoid or humanoid.Health <= 0 then
		return false
	end

	local debounceKey = `{player.UserId}_{noteId}`
	if debounceByPlayerAndNote[debounceKey] then
		return false
	end

	debounceByPlayerAndNote[debounceKey] = true
	task.delay(TRIGGER_COOLDOWN_SECONDS, function()
		debounceByPlayerAndNote[debounceKey] = nil
	end)

	return true
end

local function setupNotePrompt(notePart: BasePart)
	local noteId = tonumber(notePart.Name)
	local noteData = AsylumNotes.Get(noteId)
	if not noteData then
		return
	end

	local promptParent = getPromptParent(notePart)
	local prompt = promptParent:FindFirstChild("NotePrompt")
	if not prompt or not prompt:IsA("ProximityPrompt") then
		prompt = Instance.new("ProximityPrompt")
		prompt.Name = "NotePrompt"
		prompt.Parent = promptParent
	end

	prompt.MaxActivationDistance = GameConfigModule.InteractDistance
	prompt.Style = Enum.ProximityPromptStyle.Custom
	prompt.HoldDuration = 0.2
	prompt.RequiresLineOfSight = false
	prompt.ActionText = "Read"
	prompt.ObjectText = `Letter {noteId}`

	if prompt:GetAttribute("AsylumNoteConnected") then
		return
	end

	prompt:SetAttribute("AsylumNoteConnected", true)
	prompt.Triggered:Connect(function(player)
		if not canReadNote(player, noteId) then
			return
		end

		playCollectSound(notePart)
		OpenNoteEvent:FireClient(player, noteId, noteData.Title, noteData.Text)
	end)
end

local function trySetupNote(child: Instance)
	if child:IsA("BasePart") then
		setupNotePrompt(child)
	end
end

for _, notePart in ipairs(NotesFolder:GetChildren()) do
	trySetupNote(notePart)
end

NotesFolder.ChildAdded:Connect(trySetupNote)
