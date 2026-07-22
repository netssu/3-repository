--|| SERVICES ||--
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")

--|| MODULES ||--
local GlobalFunctions = require(script.GlobalFunctions)
local StarterData = require(script.StarterData)
local Properties = require(script.Properties)

local module = {}
local cachedTable = {}

local Datastore = DataStoreService:GetDataStore(Properties.datastore)

function module:output(msg)
	if Properties.prints then
		print("[DATASTORE]: "..msg)
	end
end

function module:startData(Player)
	--> create logs for player, purpose is to cache
	cachedTable[Player] = {
		data = {},
		lastSave = os.clock(),
		dataLoaded = false,
	}
	
	module:loadData(Player)
end

function module:endData(Player)
	module:saveData(Player)
	if cachedTable[Player] then
		cachedTable[Player] = nil
	end
end

function module:loadNewData(tbl, obj)
	if typeof(obj) == "Instance" and obj:IsA("Folder") then
		for index, value in pairs(tbl) do
			if not obj:FindFirstChild(index) then
				if typeof(value) == "table" then
					local newFolder = Instance.new("Folder")
					newFolder.Name = index
					newFolder.Parent = obj
					module:createInstances(value, newFolder)
				else
					local newValue = Instance.new( GlobalFunctions.getObjFromValue(value) )
					newValue.Value = value
					newValue.Name = index
					newValue.Parent = obj
				end
			elseif obj:FindFirstChild(index) then
				if typeof(value) == "table" then
					--> We want to repeat what we just did
					module:loadNewData(value, obj[index])
				else 
					-- Don't do anything in this case
				end
			end
		end
	elseif typeof(obj) == "table" then
		for index, value in pairs(tbl) do
			if not obj[index] then
				if typeof(value) == "table" then
					obj[index] = GlobalFunctions.deepTableCopy(value)
				else
					obj[index] = value	
				end	
			else
				if typeof(value) == "table" then
					module:loadNewData(value, obj[index])	
				end
			end
		end
	end
end

function module:saveData(Player)
	
	--> Conditions
	if not Properties.save 
	or (not Properties.studioSave and RunService:IsStudio()) then
		module:output("Could not SAVE "..Player.Name.."'s data due to properties being set to false \n[save]: "..tostring(Properties.save).."\n[studioSave]: "..tostring(Properties.studioSave))
		return 
	end
	
	if not cachedTable[Player] or not cachedTable[Player].dataLoaded or not cachedTable[Player].data then
		module:output("Could not SAVE "..Player.Name.."'s data due to their data not being loaded yet.")
	end
	
	--> Load in all the instance data before saving it:
	local playerc = Player:GetChildren()
	for i = 1, #playerc do
		--> If the object is a folder and we have data on it then
		if StarterData[playerc[i].Name] 
			and playerc[i]:IsA("Folder") 
			and StarterData[playerc[i].Name].createInstance then
			--> Get the data from the folders
			cachedTable[Player].data[playerc[i].Name] = module:getInstanceTree(playerc[i])
		end
	end
	
	--> saving
	local userId, playerData = Player.UserId, GlobalFunctions.deepTableCopy(cachedTable[Player].data)
	local suc, err, att = nil, nil, 0
	coroutine.resume(coroutine.create(function()
		repeat
			att = att + 1
			suc, err = pcall(function()
				Datastore:UpdateAsync(userId, function(olddata)
					return playerData
				end)
			end)
			task.wait(1)
		until suc or att >= Properties.retries do end
		
		if not suc then
			module:output("An error has occured while trying to save "..userId.."'s data; "..err)
		elseif suc then
			if cachedTable[Player] then
				cachedTable[Player].lastSave = os.clock()
			end	
			module:output("Saved "..userId.."'s data with no errors!")
		end
	end))
end

function module:loadData(Player)
	if not Properties.load
	or (not Properties.studioLoad and RunService:IsStudio()) then
		module:output("Could not LOAD "..Player.Name.."'s data due to properties being set to false \n[load]: "..tostring(Properties.load).."\n[studioLoad]: "..tostring(Properties.studioLoad))
	end
	
	local userId = Player.UserId
	local suc, err, att, data = nil, nil, 0, nil
	coroutine.resume(coroutine.create(function()
		repeat 
			att = att + 1		
			if Player then
				suc, err = pcall(function()
					data = Datastore:GetAsync(userId)
				end)
			end
		until suc or att >= Properties.retries do end
		
		if not suc then
			module:output("An error has occured while trying to load "..userId.."'s data; "..err)
			Player:Kick("[DATASTORE]: We were unable to retrive you're data; please try again later.")
		elseif suc then
			--> If player has data
			if data then
				module:output("Data was detected for "..userId.."; loading it")
				
				--> Load in data from them instances
				for index, plrData in next, data do
					if StarterData[index] and StarterData[index].createInstance then
						local folder = Instance.new("Folder")
						folder.Name = index
						folder.Parent = Player
						module:createInstances(plrData, folder)
					end
				end
				--> Load in any new things from starterData
				for index, info in next, StarterData do
					--> If you wish to create instances
					if info.createInstance then
						if Player:FindFirstChild(index) then
							module:loadNewData(info.data, Player[index])
						else
							local newFolder = Instance.new("Folder")
							newFolder.Name = index
							newFolder.Parent = Player
							module:createInstances(info.data, newFolder)	
						end
					else
						if not data[index] then
							data[index] = {}
						end
						module:loadNewData(info.data, data[index])
					end	
				end
				cachedTable[Player].data = data -- cache the data
			else
				module:output("There was no data for "..userId.." available; loading in new data")
				--> Let's load in the default data
				for dataCategory, data in next, StarterData do
					cachedTable[Player][dataCategory] = GlobalFunctions.deepTableCopy(data.data)
					if data.createInstance then
						local newFolder = Instance.new("Folder")
						newFolder.Name = dataCategory
						newFolder.Parent = Player
						module:createInstances(data.data, newFolder)
					end
				end	
			end
			
			cachedTable[Player].dataLoaded = true -- signal we have loaded out data
		end
	end))
end

function module:getData(Player)
	--> Yields to wait for loaded data
	local yieldTime = os.clock()
	while not cachedTable[Player] or not cachedTable[Player].dataLoaded do
		RunService.Stepped:Wait()
		if os.clock() - yieldTime >= Properties.yieldTimeout then
			module:output(Player.Name.."'s getData callback has timed out: "..(os.clock() - yieldTime))
			return nil
		end
	end
	return cachedTable[Player].data
end

function module:createInstances(tbl, p)
	--> Loop through table
	for index, value in next, tbl do
		if typeof(value) == "table" then
			local newFolder = Instance.new("Folder")
			newFolder.Name = index
			newFolder.Parent = p
			module:createInstances(value, newFolder)
		else
			local newInstance = Instance.new(GlobalFunctions.getObjFromValue(value))
			newInstance.Name = index
			newInstance.Value = value
			newInstance.Parent = p 
		end
	end
end

function module:getInstanceTree(int)
	local newTable = {}
	local intChildren = int:GetChildren()
	for i = 1, #intChildren do
		if intChildren[i]:IsA("Folder") then
			newTable[intChildren[i].Name] = module:getInstanceTree(intChildren[i])
		else
			newTable[intChildren[i].Name] = intChildren[i].Value
		end
	end
	return newTable
end

if Properties.autoSave then
	coroutine.resume(coroutine.create(function()
		while true do
			for Player, Data in next, cachedTable do
				if Data.dataLoaded and os.clock() - Data.lastSave >= Properties.autoSaveInterval then
					Data.lastSave = os.clock() -- Reset the timer
					--> Save data in new thread incase of errors; this doesn't break datastore
					coroutine.resume(coroutine.create(function()
						module:saveData(Player) -- save the data
					end))
				end
			end
			task.wait(1)
		end
	end))
end

if Properties.safeSave then
	game:BindToClose(function()
		for Player, Data in next, cachedTable do
			Data.lastSave = os.clock()
			--> new thread		
			coroutine.resume(coroutine.create(function()
				module:saveData(Player)			
			end))
			Player:Kick("[Datastore]: Game is shutting down possibly for an update; please hold still as we secure your data")
		end
	end)
end

return module
