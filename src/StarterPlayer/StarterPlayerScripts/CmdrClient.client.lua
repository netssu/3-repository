local ReplicatedStorage = game:GetService("ReplicatedStorage")

print("[Cmdr] Client loader started")

local cmdrClient = ReplicatedStorage:FindFirstChild("CmdrClient")
if not cmdrClient then
	warn("[Cmdr] Client is waiting for ReplicatedStorage.CmdrClient")
	cmdrClient = ReplicatedStorage:WaitForChild("CmdrClient")
end
print("[Cmdr] Client found:", cmdrClient:GetFullName())

if cmdrClient:GetAttribute("CmdrCommandsReady") ~= true then
	print("[Cmdr] Client is waiting for server command registration")
	cmdrClient:GetAttributeChangedSignal("CmdrCommandsReady"):Wait()
end
print("[Cmdr] Client received all server commands")

local ok, CmdrOrError = pcall(require, cmdrClient)
if not ok then
	warn("[Cmdr] Client failed to require CmdrClient:", CmdrOrError)
	return
end

local Cmdr = CmdrOrError
Cmdr:SetPlaceName("Horror Outbreak: Chapter 1")
Cmdr:SetActivationKeys({ Enum.KeyCode.F2 })
print("[Cmdr] Client ready; F2 is registered")
