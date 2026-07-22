-- Defining the variables
local CurrentCamera = workspace.CurrentCamera
CurrentCamera.CameraType = "Custom"
CurrentCamera.CameraSubject = script:WaitForChild("CamPart").Value

--CurrentCamera.CFrame = camPart.CFrame -- This attaches the Camera's CFrame to the camPart