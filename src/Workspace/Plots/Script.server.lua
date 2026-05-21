-- Helper function to compare colors safely
local function IsColorClose(colorA, colorB)
	local r = math.abs(colorA.R - colorB.R)
	local g = math.abs(colorA.G - colorB.G)
	local b = math.abs(colorA.B - colorB.B)
	-- If the total difference is less than a tiny threshold, they match
	return (r + g + b) < 0.01 
end

-- Define your target colors once to keep it clean
local PRIMARY_TARGET_1 = Color3.new(0.533333, 0.329412, 0.152941)
local PRIMARY_TARGET_2 = Color3.new(0.611765, 0.372549, 0.176471)
local SECONDARY_TARGET_1 = Color3.new(0.780392, 0.67451, 0.470588)
local SECONDARY_TARGET_2 = Color3.new(0.737255, 0.607843, 0.364706)
local FURNITURE_TARGET = Color3.new(0.627451, 0.372549, 0.207843)

for i, v in pairs(script.Parent:GetDescendants()) do
	if v:IsA("BasePart") then
		-- 1. Primary Building Check
		if IsColorClose(v.Color, PRIMARY_TARGET_1) or  IsColorClose(v.Color, PRIMARY_TARGET_2) then
			v.Name = "PrimaryBuildingColorPart"	

			-- 2. Secondary Building Check
		elseif IsColorClose(v.Color, SECONDARY_TARGET_1) or IsColorClose(v.Color, SECONDARY_TARGET_2) then
			v.Name = "SecondaryBuildingColorPart"
		end	

		-- 3. Furniture Check (Only if nested deep enough to avoid errors)
		if v.Parent and v.Parent.Parent and v.Parent.Parent.Parent and v.Parent.Parent.Parent.Name == "Furniture" then
			if IsColorClose(v.Color, FURNITURE_TARGET) then
				if v.Parent.Name == "Chair" then
					v.Name = "ChairColorPart"
				elseif string.find(v.Parent.Name, "Table") then
					v.Name = "TableColorPart"
				end
			end
		end
	end
end