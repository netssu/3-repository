local module = {}
local suffixes = {
	"K", "M", "B", "T", "Qa", "Qi", "SX", 
	"Sp", "Oc", "No", "Dc", "UD", "DD", "TD", 
	"QaD", "QnD", "SxD", "SpD", "OcD", "NnD", "Vi", 
	"UVg", "DVg", "TVg", "QaVg", "QiVg", "SxVg", "SpVg", 
	"OcVg", "NoVg", "TG", "Qag", "Qig", "G", "Sxg",
	"Spg", "Ocg", "Nog", "Ci", "UCe", "DCe", "TCe", 
	"QaCe", "QiCe", "SxCe", "SpCe", "OtCe", "NvCe"
}

function module.abbreviate(number)
	if number < 1000 then
		if number == math.floor(number) then
			return tostring(number)
		else
			return string.format("%.1f", number) --1 = 0.5, 2 = 0.53...
		end
	end
	
	local exponent = math.floor(math.log10(number) / 3)
	local abbreviatedNumber = math.floor(number / 1000 ^ exponent * 100) / 100
	
	if exponent > #suffixes then
		return tostring(number)
	end
	
	return string.format("%.2f%s", abbreviatedNumber, suffixes[exponent])
end

return module