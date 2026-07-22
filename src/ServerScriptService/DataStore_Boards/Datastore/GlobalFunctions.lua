--|| SERVICES ||--
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

--|| LOCALISE ||--
local random = Random
local Pairs = pairs
local Script = script
local Require = require
local Int = Instance
local Pcall = pcall
local TypeOf = typeof

local suffixes = {"K", "M", "B", "T", "Q", "Qu", "S", "Se", "O", "N", "D"}
local randomSeed = random.new()

local module = {
	deepTableCopy = function(Table)
		local newTable = {}
		
		local function copy(ParentTable, OriginalTable)
			for i, v in Pairs(OriginalTable) do
				if typeof(v) == "table" then
					ParentTable[i] = {}
					copy(ParentTable[i], v)
				else
					ParentTable[i] = v
				end
			end
		end
		
		copy(newTable, Table)
		return newTable
	end,
	screenShake = function(hum, intensity, shake, drag)
		coroutine.wrap(function()
			for i = 1, shake do
				local x,y,z = randomSeed:NextNumber()*intensity, randomSeed:NextNumber()*intensity, randomSeed:NextNumber()*intensity
				local shakeTween = TweenService:Create(hum, TweenInfo.new(0.125, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out, 0, true), {CameraOffset = Vector3.new(x,y,z)})
				shakeTween:Play()
				shakeTween:Destroy()
				wait(drag)
			end
			local Return = TweenService:Create(hum, TweenInfo.new(0.1, Enum.EasingStyle.Linear), {CameraOffset = Vector3.new(0,0,0)})
			Return:Play()
			Return:Destroy()
		end)()
	end,
	toSuffixString = function(n)
		for i = #suffixes, 1, -1 do
			local v = math.pow(10, i * 3)
			if n >= v then
				return ("%.0f"):format(n / v) .. suffixes[i]
			end
		end
		return tostring(n)
	end,
	isAlive = function(Model)
		if Model and Model.PrimaryPart
		and Model:FindFirstChild("Humanoid")
		and Model.Humanoid:IsDescendantOf(game.Workspace)
		and Model.Humanoid.Health > 0 then
			return true
		end
		return false
	end,
	createVisualRay = function(startPos, endPos)
		local beam = Int.new("Part")
	    beam.Anchored = true
	    beam.Locked = true
	    beam.CanCollide = false
		beam.Parent = game.Workspace.Visuals or game.Workspace
	    
	    local distance = (startPos - endPos).Magnitude
	    beam.Size = Vector3.new(0.3, 0.3, distance)
	    beam.CFrame = CFrame.new(startPos, endPos)*CFrame.new(0, 0, -distance / 2)
	end,
	rng = function(min, max, num)
		if num == 1 then -- whole
			return math.random(min,max)
		elseif num == 2 then -- decimals
			return math.random(min,max) * math.random()
		end	
	end,
	toHMS = function(s)
		return ("%02i:%02i:%02i"):format(s/60^2, s/60%60, s%60)
	end,
	getPlayerPlatform = function()
    	if (GuiService:IsTenFootInterface()) then
        	return "Console"
    	elseif (UserInputService.TouchEnabled and not UserInputService.MouseEnabled) then
        	return "Mobile"
	    else
       		return "Desktop"
    	end
	end,
	getObjFromValue = function(value)
		if TypeOf(value) == "number" then
			return "NumberValue"
		elseif TypeOf(value) == "boolean" then
			return "BoolValue"
		elseif TypeOf(value) == "string" then
			return "StringValue"
		end
	end,
}

function module:getSquareGrid(mainCFrame,x,y)
	local hSizex, hSizey = 4,5
	local splitx, splity = 1 + math.floor(x/hSizex), 1 + math.floor(y/hSizey)
	local studPerPointX = x / splitx
	local studPerPointY = y / splity
	
	--> A table and starting cframe
	local startCFrame = mainCFrame * CFrame.new(-x/2 -studPerPointX/2 ,-y/2 -studPerPointY/2,0)
	local points = {mainCFrame}
	
	for x = 1, splitx do
		for y = 1, splity do
			points[#points + 1] = startCFrame * CFrame.new(studPerPointX*x, studPerPointY*y,0)
		end
	end
	return points
end

function module:createProjectileHitbox(data, fun)
	local startCFrame = data.startCFrame
	local velocity = data.velocity
	local check = data.check
	local lifetime = data.lifetime
	local showRays = data.showRays
	local multiHit = data.multiHit
	local direction = data.direction
	local ignoreList = data.ignoreList
	local waitTime = lifetime / check
	local pSpeed = waitTime * velocity
	
	if typeof(startCFrame) == "CFrame" then
		startCFrame = {startCFrame}
	end
	
	coroutine.resume(coroutine.create(function()
		local detected = false
		for _ = 1, check do
			for i = 1, #startCFrame do
				local endCFrame = startCFrame[i] * CFrame.new(1*direction[1]*pSpeed,1*direction[2]*pSpeed,1*direction[3]*pSpeed)
				local startPos = startCFrame[i].Position
				local endPos = endCFrame.Position
				local ray = Ray.new(startPos, (endPos - startPos).Unit * pSpeed)
				local hit, pos = game.Workspace:FindPartOnRayWithIgnoreList(ray,ignoreList)
				if data.showRays then
					module.createVisualRay(startPos, endPos)
				end
				if hit then
					detected = true
					fun(hit, pos)
					break
				end
				startCFrame[i] = endCFrame
			end
			if not multiHit and detected then
				break
			end
			wait(waitTime)
		end
	end))
end

module.convertToDashedNumber = function(number)
	number = tostring(number or 0)
	local t = {}
	while #number > 0 do
		table.insert(t, 1, string.sub(number, -3, -1))
		number = string.sub(number, 1, -4)
	end
	
	return table.concat(t,",")
end

module.compareTables = function(table1, table2)
	--> Loops through table1
	for i, v in Pairs(table1) do
		-- If the value is a table
		if TypeOf(v) == "table" then
			-- Compare table2's index with this table (comparing both subtables)
			if not table2[i] or TypeOf(table2[i]) ~= "table" or not module.compareTables(table2[i], v) then
				--> If it's not the same then the tables aren't equal
				return false
			end 
		--> If the value is not a table
		else
			--> If the value isn't equal to the index of table2	
			if v ~= table2[i] then
				--> It's not the same
				return false
			end
		end
	end
		
	--> Loops through table2
	for i, v in Pairs(table2) do
		-- If the value is a table
		if TypeOf(v) == "table" then
			-- Compare table1's index with this table (comparing both subtables)
			if not table1[i] or TypeOf(table1[i]) ~= "table" or not module.compareTables(table1[i], v) then
				--> If it's not the same then the tables aren't equal
				return false
			end 
		--> If the value is not a table
		else
			--> If the value isn't equal to the index of table2	
			if v ~= table1[i] then
				--> It's not the same
				return false
			end
		end
	end
	--> If all the other conditions don't get triggered it's the same
	return true
end

module.getValidEntities = function(int, whitelist, startPos, range)
	local entities = int:GetChildren()
	local validTargets = {}
	for i = 1, #entities do
		if not whitelist[entities[i]] and entities[i] and entities[i]:FindFirstChild"HumanoidRootPart" and entities[i]:FindFirstChild("Humanoid") then
			local distance = (startPos - entities[i].HumanoidRootPart.Position).Magnitude
			if distance <= range then
				validTargets[#validTargets + 1] = entities[i]
			end
		end
	end
	return validTargets
end

return module
