--//Services
local Rs = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

--//Modules
local ModulesFolder = Rs:FindFirstChild("Modules")
local ShopModule = require(ModulesFolder.ShopModule)
local PushRagdollModule = require(ModulesFolder.PushRagdoll)
local SoundPlayer = require(ModulesFolder.Utils.SoundPlayer)
local InventoryModule = require(Rs.Modules.InventoryModule)

--//Remotes
local Remotes = Rs:FindFirstChild("Remotes")
local loadPlrCharBind = Remotes:FindFirstChild("LoadPlrCharBind")
local ProductJumpscareEvent = Remotes:FindFirstChild("ProductJumpscare")

MarketplaceService.ProcessReceipt = function(receiptInfo)
	local player = game.Players:GetPlayerByUserId(receiptInfo.PlayerId)
	local productId = receiptInfo.ProductId
	
	if not player then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	if productId == 2815366790 then -- Revive product
		--player:LoadCharacter()
		
		local PlayerValues = player:WaitForChild("PlayerValues")
		if PlayerValues then
			local IsAlive = PlayerValues:FindFirstChild("IsAlive") :: BoolValue
			if IsAlive then
				IsAlive.Value = true
			end
		end
		
		--loadPlrSelectedChar(player)
		loadPlrCharBind:Fire(player)
	elseif productId == 3384093042 then -- push plrs product
		local selectedPushPlr = player:WaitForChild("PlayerValues"):WaitForChild("SelectedPushPlayer")
		
		if selectedPushPlr and selectedPushPlr.Value then
			local pushPlr = game.Players:GetPlayerByUserId(tonumber(selectedPushPlr.Value))
			if pushPlr then
				local charRoot = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart
				local lookVector = charRoot and charRoot.CFrame.LookVector
				
				task.spawn(function()
					PushRagdollModule.enabledRagdoll(pushPlr, lookVector)
				end)
				
				SoundPlayer:PlaySound(game.SoundService.Effects.PunchEffect, charRoot)
				
				task.delay(math.random(3, 5), function()
					PushRagdollModule.disabledRagdoll(pushPlr)
				end)
			end
		end
	elseif productId == 3435647011 then -- jumpscare everyone product
		task.wait(2)
		for i, plr in game.Players:GetPlayers() do
			local PatientModel = workspace.Map.JumpscareBoxes.PatientScare.Patient_Enemy_Var1
			local SoundsFolder = PatientModel.Sounds
			ProductJumpscareEvent:FireClient(plr, PatientModel, SoundsFolder.ScreamSound, PatientModel.CamPart, 129728063187402, SoundsFolder.HitSound)
		end
	elseif productId == 3382855969 then -- base ball bat tool product
		InventoryModule.AddItem(player, "Baseball Bat")
	else
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end