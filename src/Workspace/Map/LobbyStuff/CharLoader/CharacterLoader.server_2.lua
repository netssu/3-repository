local Players = game.Players
local CharModel = script.Parent
local IdleAnim = script:FindFirstChild("IdleAnimation")
local IDToLoad = script:FindFirstChild("ID")
local HumDescription = Players:GetHumanoidDescriptionFromUserId(IDToLoad.Value)
local Humanoid = CharModel:FindFirstChildWhichIsA("Humanoid")
local animIdle = Humanoid.Animator:LoadAnimation(IdleAnim)
local PlrName = Players:GetNameFromUserIdAsync(IDToLoad.Value)
local BillBoard = CharModel.BillboardGui
BillBoard.Frame.PlrName.Text = "@"..PlrName
CharModel.Name = PlrName
Humanoid:ApplyDescription(HumDescription)

repeat wait()
	animIdle:Play()
until animIdle.IsPlaying