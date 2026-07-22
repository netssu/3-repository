local billBoardHandler = {}

function billBoardHandler.Init()
	--//Services
	local Rs = game:GetService("ReplicatedStorage")
	
	--//Remotes
	local Remotes = Rs:FindFirstChild("Remotes")
	local UpdatePlrBillBoard = Remotes:FindFirstChild("UpdatePlrBillBoard")
	
	--//Modules
	local ModulesFolder = Rs:FindFirstChild("Modules")
	local ShopModule = require(ModulesFolder:FindFirstChild("ShopModule"))
	
	--//Stuff
	local plrExampleBillBoard = script:FindFirstChild("BillboardGui")
	
	UpdatePlrBillBoard.OnServerEvent:Connect(function(plr, equipedTitle: string)
		local title
		
		for i, v in ipairs(ShopModule.Items.Titles) do
			if v.Name == equipedTitle then
				title = v.TextStyle:Clone()
				break
			end
		end
		
		local clonedBoard = plrExampleBillBoard:Clone()
		clonedBoard.Enabled = true
		clonedBoard.PlrName.Text = plr.DisplayName
		
		if title then
			title.Parent = clonedBoard
			title.Visible = true
			title.Size = clonedBoard.PlrTitleText.Size
			title:AddTag("PlayerTitle")
			clonedBoard.PlrTitleText.Visible = false
		else
			print("Can't load", plr.Name, "title on BillBoard.")
			clonedBoard.PlrTitleText.Text = "Newbie"
			clonedBoard.PlrTitleText.Font = Enum.Font.Fondamento
		end
		
		local char = plr.Character
		if char then
			local head = char:FindFirstChild("Head")
			if head then
				--//Clear old bill boards
				if head:FindFirstChildWhichIsA("BillboardGui") then
					head:FindFirstChildWhichIsA("BillboardGui"):Destroy()
				end
				clonedBoard.Parent = head
			end
		end
	end)
end

return billBoardHandler