local BadgesModule = {}

--[[
	Badge Instance Example:
	
	{ -- [Badge Name Here] Badge
		Id = 0000000000;
		Name = "Badge Name Here"; -- Badge name to be able to find a specify badge
		Reward = {["Character"] = "CharName"; ["Coins"] = "Amount"};
		Enabled = true; -- Determines if will show this badge in UI
		Order = 1 -- Order to be shown in the UI
	};
	
	Difficulty Params:
	
	Diff = { Name = "Easy"; -- DiffName to be able to get the diffColor
			Order = 1 -- Diff order ([1] = Easy; [2] = Medium; ...)
		
		-- Badges instances...
	}
]]

--//Services
local BadgeService = game:GetService("BadgeService")
local RunService = game:GetService("RunService")
local Rs = game:GetService("ReplicatedStorage")

--//Remotes
local Remotes = Rs:WaitForChild("Remotes")
local AwardBadgeEvent = Remotes:FindFirstChild("AwardBadge")

BadgesModule.Badges = {
	Easy = { Name = "Easy"; Order = 1;
		{ -- [Welcome] Badge
			Id = 1166468301518262;
			Name = "Welcome";
			Reward = {};
			Enabled = true;
			Order = 1
		};
		{ -- [Entered The Asylum] Badge
			Id = 2134608999289443;
			Name = "Entered The Asylum";
			Reward = {};
			Enabled = true;
			Order = 2
		};
		{ -- [Open a Door] Badge
			Id = 132446137312447;
			Name = "Opened a Door";
			Reward = {};
			Enabled = true;
			Order = 3
		};
		{ -- [Die For the First Time] Badge
			Id = 2846192345853149;
			Name = "Die First Time";
			Reward = {};
			Enabled = true;
			Order = 4
		};
		{ -- [Die For Bob] Badge
			Id = 2683184029304448;
			Name = "Bob-a-Scare";
			Reward = {};
			Enabled = true;
			Order = 5
		};
		{ -- [Failed to Open the Chest] Badge
			Id = 4099739490720033;
			Name = "Failed Chest";
			Reward = {};
			Enabled = true;
			Order = 6
		};
	};
	Medium = { Name = "Medium"; Order = 2;
		{ -- [Die of from staircase] Badge
			Id = 4313571320212925;
			Name = "Die Staircase";
			Reward = {["Coins"] = 5};
			Enabled = true;
			Order = 1
		};
		{ -- [Opened the Chest] Badge
			Id = 1605108115167480;
			Name = "Opened Chest";
			Reward = {["Coins"] = 10};
			Enabled = true;
			Order = 2
		};
		{ -- [Eletrocuted - try to pass by energized cables] Badge
			Id = 3853741826275249;
			Name = "Eletrocuted";
			Reward = {};
			Enabled = true;
			Order = 3
		};
	};
	Hard = { Name = "Hard"; Order = 3;
		{ -- [Resolve Pressure Puzzle] Badge
			Id = 3933127634155752;
			Name = "Right Pressure";
			Reward = {["Coins"] = 40};
			Enabled = true;
			Order = 1
		};
		{ -- [Resolve eletricity puzzle] Badge
			Id = 3130187004042732;
			Name = "Cut the Power";
			Reward = {["Coins"] = 30};
			Enabled = true;
			Order = 2
		};
		{ -- [Restore Asylum Energy] Badge
			Id = 2410255130654007;
			Name = "Restore Energy";
			Reward = {["Coins"] = 50};
			Enabled = true;
			Order = 3
		}
	};
	Extreme = { Name = "Extreme"; Order = 4;
		{ -- [The Killer] Badge
			Id = 2248056575025161;
			Name = "The Killer";
			Reward = {["Coins"] = 80};
			Enabled = true;
			Order = 1
		};
		{ -- [Fully Focused] Badge
			Id = 1991837489650142;
			Name = "Focused";
			Reward = {["Coins"] = 50};
			Enabled = true;
			Order = 2
		};
	};
	Insane = { Name = "Insane"; Order = 5;
		{ -- [Escape Chapter 1] Badge
			Id = 573847208725039;
			Name = "Escape Chapter 1";
			Reward = {["Coins"] = 100};
			Enabled = true;
			Order = 1
		}
	};
	Exclusive = { Name = "Exclusive"; Order = 6;
		{ -- [Pre-Alpha Tester] Badge
			Id = 4399038034878585;
			Name = "Alpha Tester";
			Reward = {};
			Enabled = true;
			Order = 1
		};
		{ -- [Join in the game Group] Badge
			Id = 428089155703396;
			Name = "Join Group";
			Reward = {};
			Enabled = true;
			Order = 2
		};
		{ -- [Met Owner (rose)] Badge
			Id = 4152196096227201;
			Name = "Met Owner";
			Reward = {};
			Enabled = true;
			Order = 3
		};
		{ -- [Met Dev (thurzin54)] Badge
			Id = 4297371863889834;
			Name = "Met Thurzin";
			Reward = {};
			Enabled = true;
			Order = 4
		};
		{ -- [Met Dev (yungbasco)] Badge
			Id = 1543172126775829;
			Name = "Met yungbasco";
			Reward = {};
			Enabled = true;
			Order = 5
		};
		{ -- [Met Dev (overkillexo)] Badge
			Id = 769700173827495;
			Name = "Met overkillexo";
			Reward = {};
			Enabled = true;
			Order = 6
		};
	};
	
	}

BadgesModule.DiffColors = {
	["Easy"] = {MainColor = Color3.fromRGB(44, 107, 23); SecondaryColor = Color3.fromRGB(31, 71, 15)};
	["Medium"] = {MainColor = Color3.fromRGB(191, 169, 46); SecondaryColor = Color3.fromRGB(143, 110, 31)};
	["Hard"] = {MainColor = Color3.fromRGB(148, 26, 26); SecondaryColor = Color3.fromRGB(104, 18, 18)};
	["Extreme"] = {MainColor = Color3.fromRGB(93, 21, 140); SecondaryColor = Color3.fromRGB(77, 18, 117)};
	["Insane"] = {MainColor = Color3.fromRGB(38, 35, 59); SecondaryColor = Color3.fromRGB(23, 21, 36)};
	["Exclusive"] = {MainColor = Color3.fromRGB(67, 104, 127); SecondaryColor = Color3.fromRGB(51, 81, 98)}
};

function BadgesModule:FindBadge(badgeName: string)
	for i, badgeTable in pairs(BadgesModule.Badges) do
		for i, badge in ipairs(badgeTable) do
			if typeof(badge) == "table" then
				if badge.Name == badgeName and badge.Enabled then
					return badge
				end
			end
		end
	end
	return nil
end

function BadgesModule:GiveBadge(plr: Player, badgeId: number)
	if not plr or not badgeId then return warn("Can't give badge, Id or Plr is nil:", plr, "|", badgeId) end
	if RunService:IsClient() then
		AwardBadgeEvent:FireServer(badgeId)
		return
	end
	pcall(function()
		if not BadgeService:UserHasBadgeAsync(plr.UserId, badgeId) then
			local success, result = pcall(function()
				return BadgeService:AwardBadge(plr.UserId, badgeId)
			end)
			if not success then
				warn("Can't give badge", badgeId, "to", plr.Name, result)
			end
		end
	end)
end
return BadgesModule