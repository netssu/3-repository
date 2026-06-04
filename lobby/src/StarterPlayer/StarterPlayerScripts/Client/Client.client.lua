-- // services

local Players = game:GetService("Players")

-- // replicate first

local LoadingScreen = require(script.Parent.ReplicateFirst:WaitForChild("LoadingScreen", 5))

-- // variables

local Player = Players.LocalPlayer
local PlayerGui = Player and Player:WaitForChild("PlayerGui", 5)
local MainGui = PlayerGui and PlayerGui:WaitForChild("TD", 5)
local LoadingGui = PlayerGui and PlayerGui:WaitForChild("Loading", 5)

-- // helpers

local function addAssetId(bucket, seen, value)
	if typeof(value) ~= "string" or value == "" or seen[value] then
		return
	end

	seen[value] = true
	table.insert(bucket, value)
end

local function collectAssetsFrom(root: Instance, bucket, seen)
	for _, descendant in ipairs(root:GetDescendants()) do
		if descendant:IsA("ImageLabel") or descendant:IsA("ImageButton") then
			addAssetId(bucket, seen, descendant.Image)
		elseif descendant:IsA("Decal") or descendant:IsA("Texture") then
			addAssetId(bucket, seen, descendant.Texture)
		elseif descendant:IsA("Sound") then
			addAssetId(bucket, seen, descendant.SoundId)
		elseif descendant:IsA("MeshPart") then
			addAssetId(bucket, seen, descendant.TextureID)
		elseif descendant:IsA("SpecialMesh") then
			addAssetId(bucket, seen, descendant.TextureId)
		elseif descendant:IsA("ParticleEmitter") or descendant:IsA("Trail") then
			addAssetId(bucket, seen, descendant.Texture)
		elseif descendant:IsA("Animation") then
			addAssetId(bucket, seen, descendant.AnimationId)
		end
	end
end

local function collectPreloadAssets(): {string}
	local assets = {}
	local seen = {}

	if LoadingGui then
		collectAssetsFrom(LoadingGui, assets, seen)
	end

	if MainGui then
		collectAssetsFrom(MainGui, assets, seen)
	end

	return assets
end

local function getClientModules(): {ModuleScript}
	local modules = {}

	for _, module in ipairs(script.Parent.Modules:GetDescendants()) do
		if module:IsA("ModuleScript") and not module.Parent:IsA("ModuleScript") then
			table.insert(modules, module)
		end
	end

	return modules
end

local function preloadClientAssets()
	local assets = collectPreloadAssets()
	if #assets == 0 then
		LoadingScreen.SetProgress(0.9, "LOADING GAME...", false)
		return
	end

	LoadingScreen.PreloadAssets(assets, {
		label = "LOADING GAME...",
		startProgress = 0,
		endProgress = 0.9,
		showPercent = false,
	})
end

local function loadModules()
	local modules = getClientModules()
	local totalModules = #modules

	if totalModules == 0 then
		return
	end

	LoadingScreen.SetProgress(0.9, "STARTING GAME...", false)

	for index, module in ipairs(modules) do
		local success, err = pcall(function()
			require(module)
		end)

		if not success then
			warn("Failed to load module:", module.Name, "-", err)
		end

		local moduleProgress = 0.9 + ((index / totalModules) * 0.1)
		LoadingScreen.SetProgress(moduleProgress, "STARTING GAME...", false)
	end
end

-- // code

preloadClientAssets()
loadModules()

print("Client loaded all modules.")

LoadingScreen.Finish("LOADING GAME...")
LoadingScreen.Hide()
