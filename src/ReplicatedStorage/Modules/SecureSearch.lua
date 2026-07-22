local SecureSearch = {}

function SecureSearch:GetInstance(stack: Instance, needle: string, recursive: boolean) : Instance?
	if not stack then warn("Incorrect stack:", stack, " needle:", needle) return end
	if not needle then warn("Incorrect needle:", needle, " stack:", stack) return end
	if recursive == nil then recursive = false end
	local success, instance: Instance = pcall(function()
		return stack:FindFirstChild(needle, recursive)
	end)
	if success then
		return instance
	else
		warn("Can't find instance:", needle, " on stack:", stack)
	end
	return nil
end

function SecureSearch:GetInstanceType(stack: Instance, Type: string) : Instance?
	if not stack then warn("Incorrect stack:", stack, " type:", Type) return end
	if not Type then warn("Incorrect type:", Type, " stack:", stack) return end
	local success, instance: Instance = pcall(function()
		return stack:FindFirstChildOfClass(Type)
	end)
	if success then
		return instance
	else
		warn("Can't find instance of type:", Type, " on stack:", stack)
	end
	return nil
end

function SecureSearch:WaitForInstance(stack: Instance, needle: string, timeOut: number?)
	if not stack then warn("Incorrect stack:", stack, " needle:", needle) return end
	if not needle then warn("Incorrect needle:", needle, " stack:", stack) return end
	if timeOut == nil then timeOut = 1 end
	local success, instance: Instance = pcall(function()
		return stack:WaitForChild(needle, timeOut)
	end)
	if success then
		return instance
	else
		warn("Can't get instance:", needle, " on stack:", stack)
	end
	return nil
end

return SecureSearch