--//Script used to make the bandage work//--

--//Services
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local ChangePlrLifeEvent = Remotes:FindFirstChild("ChangePlrLife")

--//Values
local plrsDebounce = {}

ChangePlrLifeEvent.OnServerEvent:Connect(function(plr, amount, item)
	if not plrsDebounce[plr] then
		plrsDebounce[plr] = true
		
		local char = plr.Character
		local hum = char:WaitForChild("Humanoid") :: Humanoid
		
		hum.Health += amount
		
		if item == "bandage" then
			coroutine.wrap(function()
				local continue = true
				local amount = 0
				local maxAmount = 12
				while continue and amount <= maxAmount do
					if hum.Health >= 100 then
						continue = false
					end
					hum.Health += math.random(1, 2)
					amount += 1
					wait(0.5)
				end
			end)
		end
		
		wait()
		plrsDebounce[plr] = nil
	end
end)