local Loader = {}

function Loader:updateModel(Model, userId)
	Model.Humanoid:ApplyDescription(game.Players:GetHumanoidDescriptionFromUserId(userId))
end

return Loader