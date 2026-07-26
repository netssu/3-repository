local NoteGuiHandler = {
	DataLoad = false
}

--//Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

--//Remotes
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local OpenNoteEvent = Remotes:WaitForChild("OpenAsylumNote")

--//Player
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

--//Config
local NOTE_GUI_NAME = "NoteGui"
local CLICK_CLOSE_DELAY = 0.25
local handwrittenFontNames = {
	"Kalam",
	"PatrickHand",
	"IndieFlower",
	"Caveat",
}
local connectedCloseButtons = {}

local titleLabelNames = {
	"TitleText",
	"NoteTitle",
	"LetterTitle",
	"Header",
	"Title",
}

local bodyLabelNames = {
	"NoteText",
	"LetterText",
	"MessageText",
	"BodyText",
	"ContentText",
	"Description",
	"InfoText",
	"Message",
	"Content",
	"Body",
	"Info",
	"Text",
}

local closeButtonNames = {
	"CloseButton",
	"LeaveButton",
	"BackButton",
	"ExitButton",
	"Close",
	"Leave",
	"Back",
	"Exit",
}

local currentNoteGui = nil
local noteOpen = false
local openedAt = 0
local previousMouseBehavior = nil
local previousMouseIconEnabled = nil

local function isTextObject(instance)
	return instance and (instance:IsA("TextLabel") or instance:IsA("TextBox"))
end

local function isCloseButton(instance)
	return instance and (instance:IsA("TextButton") or instance:IsA("ImageButton"))
end

local function findTextObjectByNames(root, names, ignoredObject, allowFallback)
	for _, name in ipairs(names) do
		local found = root:FindFirstChild(name, true)
		if isTextObject(found) and found ~= ignoredObject then
			return found
		end
	end

	if not allowFallback then
		return nil
	end

	for _, descendant in ipairs(root:GetDescendants()) do
		if isTextObject(descendant) and descendant ~= ignoredObject then
			return descendant
		end
	end

	return nil
end

local function applyHandwrittenFont(textObject)
	if not isTextObject(textObject) then
		return
	end

	for _, fontName in ipairs(handwrittenFontNames) do
		local success = pcall(function()
			textObject.FontFace = Font.fromName(fontName, Enum.FontWeight.Regular, Enum.FontStyle.Normal)
		end)

		if success then
			break
		end
	end

	textObject.TextWrapped = true
	textObject.RichText = false
end

local function restoreMouse()
	if previousMouseBehavior then
		UserInputService.MouseBehavior = previousMouseBehavior
		previousMouseBehavior = nil
	end

	if previousMouseIconEnabled ~= nil then
		UserInputService.MouseIconEnabled = previousMouseIconEnabled
		previousMouseIconEnabled = nil
	end
end

local function closeNoteGui()
	if not noteOpen then
		return
	end

	noteOpen = false
	restoreMouse()

	if currentNoteGui then
		currentNoteGui.Enabled = false
	end
end

local function connectCloseButtons(noteGui)
	for _, name in ipairs(closeButtonNames) do
		local button = noteGui:FindFirstChild(name, true)
		if isCloseButton(button) and not connectedCloseButtons[button] then
			connectedCloseButtons[button] = button.Activated:Connect(closeNoteGui)
		end
	end

	for _, descendant in ipairs(noteGui:GetDescendants()) do
		if isCloseButton(descendant) and string.find(string.lower(descendant.Name), "close") and not connectedCloseButtons[descendant] then
			connectedCloseButtons[descendant] = descendant.Activated:Connect(closeNoteGui)
		end
	end
end

local function getNoteGui()
	local noteGui = PlayerGui:FindFirstChild(NOTE_GUI_NAME)
	if noteGui and noteGui:IsA("ScreenGui") then
		return noteGui
	end

	noteGui = PlayerGui:WaitForChild(NOTE_GUI_NAME, 10)
	if noteGui and noteGui:IsA("ScreenGui") then
		return noteGui
	end

	warn(`[NoteGuiHandler] PlayerGui.{NOTE_GUI_NAME} was not found.`)
	return nil
end

local function showNote(noteId, title, text)
	local noteGui = getNoteGui()
	if not noteGui then
		return
	end

	local titleLabel = findTextObjectByNames(noteGui, titleLabelNames, nil, false)
	local bodyLabel = findTextObjectByNames(noteGui, bodyLabelNames, titleLabel, true)

	if titleLabel then
		titleLabel.Text = title or `Carta {noteId}`
		applyHandwrittenFont(titleLabel)
	end

	if bodyLabel then
		bodyLabel.Text = text or ""
		applyHandwrittenFont(bodyLabel)
	else
		warn("[NoteGuiHandler] No text label was found inside NoteGui for the note body.")
	end

	connectCloseButtons(noteGui)

	currentNoteGui = noteGui
	previousMouseBehavior = UserInputService.MouseBehavior
	previousMouseIconEnabled = UserInputService.MouseIconEnabled
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	UserInputService.MouseIconEnabled = true

	noteOpen = true
	openedAt = os.clock()
	noteGui.Enabled = true
end

function NoteGuiHandler:Init()
	local noteGui = getNoteGui()
	if noteGui then
		noteGui.Enabled = false
		connectCloseButtons(noteGui)
	end
end

function NoteGuiHandler:Start()
	OpenNoteEvent.OnClientEvent:Connect(showNote)

	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed or not noteOpen then
			return
		end

		if os.clock() - openedAt < CLICK_CLOSE_DELAY then
			return
		end

		if input.KeyCode == Enum.KeyCode.Escape or input.KeyCode == Enum.KeyCode.Backspace or input.KeyCode == Enum.KeyCode.ButtonB then
			closeNoteGui()
		elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			closeNoteGui()
		end
	end)
end

return NoteGuiHandler
