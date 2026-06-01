local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid: Humanoid = Character:WaitForChild("Humanoid")
local RootPart: Part = Character:WaitForChild("HumanoidRootPart")

Humanoid.Died:Connect(function()
	Character = Player.Character or Player.CharacterAdded:Wait()
	Humanoid = Character:WaitForChild("Humanoid")
	RootPart = Character:WaitForChild("HumanoidRootPart")
end)

RunService:BindToRenderStep("FollowHead", Enum.RenderPriority.Camera.Value + 1, function(DeltaTime: number)
	if not Character or (Humanoid:GetState() == Enum.HumanoidStateType.Dead) then
		return
	end

	local Head: Part = Character:WaitForChild("Head")
	local ObjectSpace = RootPart.CFrame:ToObjectSpace(Head.CFrame)
	Humanoid.CameraOffset = Humanoid.CameraOffset:Lerp(ObjectSpace.Position - Vector3.new(0, 1.5, 0), DeltaTime * 10)
end)
