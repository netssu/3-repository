-- ExtendedTutorialSteps Module
-- 16-step tutorial redesign
-- Each Phase maps to one BoolValue step in PlayerStats.ExtendedTutorial
-- The client reads these details to drive quest UI + popups

local ExtendedTutorial = {}

--[[
	HOW THE SYSTEM WORKS (summary for future devs)
	------------------------------------------------
	PlayerStats.ExtendedTutorial has BoolValues:
	  FirstStep, SecondStep, ThirdStep, FourthStep, FifthStep
	
	Each step has:
	  .Value         = false  → main goal not yet reached
	  .SubStepComplete (Attribute) = false → sub-goal not yet reached

	The client Heartbeat (ExtendedTutorialSetup) reads this module
	and drives the TipsFrame quest UI accordingly.

	PHASE MAPPING
	─────────────────────────────────────────────────────────────
	FirstStep  main     → Step 1-3   : Welcome popup, teleport to ingredients,
	                                   explain upgrades, collect 1 000 ingredients
	FirstStep  substep  → Step 4-6   : Explain rebirth + multiplier, collect 1 500 ingr.

	SecondStep main     → Step 7-9   : Teleport to pot, explain cooking + pot upgrades,
	                                   collect 1 000 food
	SecondStep substep  → Step 10-12 : Explain food rebirth, collect 45 000 food

	ThirdStep  main     → Step 13    : Popup → buy Farmers Market (50 000 Food)
	ThirdStep  substep  → Step 14    : Explain how to use Farmers Market

	FourthStep main     → Step 15    : Collect 250 000 Cash
	FourthStep substep  → Step 16    : Popup → buy Restaurant (250 000 Cash)
	
	FifthStep is kept as a dummy "completed" marker so the old server
	badge logic still fires cleanly.
	─────────────────────────────────────────────────────────────
]]

ExtendedTutorial.Steps = {

	-- ══════════════════════════════════════════════════════════
	-- FIRST STEP
	-- Main  : collect 1 000 ingredients
	-- Sub   : collect 1 500 ingredients (after learning rebirth + multi)
	-- ══════════════════════════════════════════════════════════
	FirstStep = {
		-- Quest bar (main goal)
		Description    = "Collect 1,000 Ingredients!",
		Tip            = "Walk over the ingredients on the floor to collect them. Upgrade 'Ingredients Per Collect' and 'Spawn Speed' on the boards nearby!",
		Currency       = "Ingredients",
		Icon           = "rbxassetid://71158302190765",
		ValueGoal      = 1000,

		-- Quest bar (sub goal – shown after main is done)
		SubStep        = "Now collect 1,500 Ingredients!",
		SubStepCurrency = "Ingredients",
		SubStepIcon    = "rbxassetid://71158302190765",
		SubStepValueGoal = 1500,          -- single-currency check

		-- Shown for 10 s after sub completes before moving on
		EndingTip      = "Great! Now head to the Cooking Pot to turn your Ingredients into Food!",

		-- ── Inline popup scripts (read by the client, not the quest bar) ──
		-- The client fires these at the moments described below.
		-- They are just data – the client controls timing.
		Popups = {
			-- Fired immediately when TutorialRemote "StartTutorial" arrives
			Welcome = {
				{
					text  = "Welcome to the cooking game!",
					color = {255, 230, 80},
					scale = 0.48,
					posY  = 0.38,
					wait  = 3.0,
				},
				{
					text  = "Your goal: collect Ingredients,\ncook in the Big Pot and earn Money!",
					color = {255, 255, 255},
					scale = 0.52,
					posY  = 0.42,
					wait  = 4.0,
				},
				{
					text  = "Spend your Money on Upgrades\nto grow faster and faster!",
					color = {180, 255, 180},
					scale = 0.50,
					posY  = 0.42,
					wait  = 3.5,
				},
			},
			-- Fired when player enters the ingredient zone
			InZone = {
				{
					text  = "Great! Stay here and collect the Ingredients!\nThey disappear when you touch them.",
					color = {100, 255, 150},
					scale = 0.46,
					posY  = 0.30,
					wait  = 4.0,
				},
				{
					text  = "Check the BOARDS around you:\nBuy upgrades to collect faster!",
					color = {255, 220, 80},
					scale = 0.48,
					posY  = 0.32,
					wait  = 3.5,
				},
			},
			-- Fired when main goal (1 000) is reached
			MainDone = {
				{
					text  = "1,000 Ingredients collected!\nNow learn how to REBIRTH.",
					color = {255, 230, 80},
					scale = 0.50,
					posY  = 0.40,
					wait  = 3.5,
				},
				{
					text  = "REBIRTH: spend Ingredients\nto earn Rebirths and reset your speed!",
					color = {255, 255, 255},
					scale = 0.52,
					posY  = 0.42,
					wait  = 4.0,
				},
				{
					text  = "Use the 'Rebirth' board in the Ingredient area.\nMore Rebirths = more bonuses!",
					color = {100, 220, 255},
					scale = 0.48,
					posY  = 0.38,
					wait  = 4.0,
				},
				{
					text  = "Now buy the MULTIPLIER!\n'Multiply Ingredients Per Collect' board.",
					color = {180, 255, 180},
					scale = 0.48,
					posY  = 0.40,
					wait  = 4.0,
				},
			},
		},

		-- Beam targets (client uses PrimaryPart or first Part of model)
		BeamTargets = {
			IngredientZone  = "workspace.Map.CenterPoint.IngredientCollection",
			RebirthBoard    = "workspace.Map.CenterPoint.IngredientCollection.UpgradeBoards.RebirthForIngredients",
			MultiBoard      = "workspace.Map.CenterPoint.IngredientCollection.UpgradeBoards.MultiplyIngredientsPerCollect",
		},
	},

	-- ══════════════════════════════════════════════════════════
	-- SECOND STEP
	-- Main  : cook 1 000 food
	-- Sub   : cook 45 000 food (after learning food rebirth)
	-- ══════════════════════════════════════════════════════════
	SecondStep = {
		Description    = "Cook 1,000 Food at the Cooking Pot!",
		Tip            = "Walk to the Big Cooking Pot and stand near it. Your Ingredients will be cooked automatically! Upgrade 'Food Per Ingredients' and 'Cooking Speed'.",
		Currency       = "Food",
		Icon           = "rbxassetid://102577198031611",
		ValueGoal      = 1000,

		SubStep        = "Cook 45,000 Food!",
		SubStepCurrency = "Food",
		SubStepIcon    = "rbxassetid://102577198031611",
		SubStepValueGoal = 45000,

		EndingTip      = "Incredible! Now you have enough Food to unlock the Farmers Market!",

		Popups = {
			-- Fired when arriving near the pot (after teleport)
			AtPot = {
				{
					text  = "This is the BIG POT!\nStay close to it to cook Ingredients.",
					color = {255, 180, 60},
					scale = 0.50,
					posY  = 0.38,
					wait  = 3.5,
				},
				{
					text  = "Upgrade 'Food Per Ingredients' and 'Cooking Speed'\nat the boards around the Pot!",
					color = {255, 255, 255},
					scale = 0.50,
					posY  = 0.40,
					wait  = 4.0,
				},
			},
			-- Fired when main goal (1 000 food) is reached
			MainDone = {
				{
					text  = "1,000 Food cooked!\nNow learn the Food REBIRTH.",
					color = {255, 230, 80},
					scale = 0.50,
					posY  = 0.40,
					wait  = 3.5,
				},
				{
					text  = "FOOD REBIRTH: use the 'Rebirth' board\nnear the Pot to earn Food bonuses!",
					color = {100, 220, 255},
					scale = 0.50,
					posY  = 0.40,
					wait  = 4.5,
				},
				{
					text  = "Now cook 45,000 Food!\nUpgrade your stats to get there fast.",
					color = {180, 255, 180},
					scale = 0.48,
					posY  = 0.40,
					wait  = 3.5,
				},
			},
		},

		BeamTargets = {
			CookingPot   = "workspace.Map.CenterPoint.FoodCollection.CookingPot.Pot",
			RebirthBoard = "workspace.Map.CenterPoint.FoodCollection.UpgradeBoards.RebirthsForFood",
		},
	},

	-- ══════════════════════════════════════════════════════════
	-- THIRD STEP
	-- Main  : unlock Farmers Market (needs 50 000 Food in SkillTree)
	-- Sub   : learn how to use Farmers Market
	-- ══════════════════════════════════════════════════════════
	ThirdStep = {
		Description    = "Unlock the Farmers Market! (50,000 Food)",
		Tip            = "Go to the Skill Tree area and step on 'Unlock Farmers Market'. It costs 50,000 Food!",
		Currency       = "Food",
		Icon           = "rbxassetid://102577198031611",
		ValueGoal      = 50000,           -- checked against Food value

		SubStep        = "Learn to use the Farmers Market!",
		SubStepCurrency = "Food",
		SubStepIcon    = "rbxassetid://102577198031611",
		SubStepValueGoal = 50000,         -- already met once market unlocked

		EndingTip      = "The Farmers Market gives you powerful multipliers! Use your Food and Ingredients wisely.",

		Popups = {
			-- Fired when Food >= 50 000 (prompt to go unlock)
			CanUnlock = {
				{
					text  = "You have enough Food!\nGo to the SKILL TREE and buy 'Unlock Farmers Market'.",
					color = {255, 230, 80},
					scale = 0.52,
					posY  = 0.40,
					wait  = 4.5,
				},
			},
			-- Fired when UnlockFarmersMarket BoolValue flips true
			Unlocked = {
				{
					text  = "FARMERS MARKET UNLOCKED!\nHere you buy powerful multipliers.",
					color = {255, 230, 80},
					scale = 0.54,
					posY  = 0.40,
					wait  = 4.0,
				},
				{
					text  = "Step on the Skill Tree nodes to unlock\nIngredient, Food, Cash buffs and more!",
					color = {255, 255, 255},
					scale = 0.50,
					posY  = 0.42,
					wait  = 4.5,
				},
			},
		},

		BeamTargets = {
			SkillTreeFM = "workspace.Map.SkillTrees.FarmersMarketSkillTree",
		},
	},

	-- ══════════════════════════════════════════════════════════
	-- FOURTH STEP
	-- Main  : earn 250 000 Cash
	-- Sub   : unlock Restaurant (250 000 Cash in SkillTree)
	-- ══════════════════════════════════════════════════════════
	FourthStep = {
		Description    = "Earn 250,000 Cash!",
		Tip            = "Sell your Food at the Farmers Market to earn Cash. Upgrade your stats to earn faster!",
		Currency       = "Cash",
		Icon           = "rbxassetid://86766178919624",
		ValueGoal      = 250000,

		SubStep        = "Unlock Your Restaurant! (250,000 Cash)",
		SubStepCurrency = "Cash",
		SubStepIcon    = "rbxassetid://86766178919624",
		SubStepValueGoal = 250000,

		EndingTip      = "Your Restaurant is open! Keep growing your numbers to HUGE amounts!",

		Popups = {
			-- Fired when Cash >= 250 000
			CanUnlock = {
				{
					text  = "You have 250,000 Cash!\nGo to your Plot and unlock the RESTAURANT.",
					color = {255, 230, 80},
					scale = 0.52,
					posY  = 0.40,
					wait  = 4.5,
				},
			},
			-- Fired when UnlockRestaurant BoolValue flips true
			Unlocked = {
				{
					text  = "RESTAURANT UNLOCKED!\nHere you multiply your Cash even faster.",
					color = {255, 230, 80},
					scale = 0.54,
					posY  = 0.40,
					wait  = 4.0,
				},
				{
					text  = "Keep upgrading your stats\nand become the greatest chef!",
					color = {180, 255, 180},
					scale = 0.50,
					posY  = 0.42,
					wait  = 3.5,
				},
			},
		},

		BeamTargets = {
			RestaurantSkillTree = "PlayerPlot.RestaurantSkillTree",  -- resolved at runtime
		},
	},

	-- ══════════════════════════════════════════════════════════
	-- FIFTH STEP  (dummy completion marker)
	-- Used only so the server badge logic has a FifthStep to mark.
	-- ══════════════════════════════════════════════════════════
	FifthStep = {
		Description    = "You finished the Tutorial!",
		Tip            = "Keep growing your numbers!",
		Currency       = "Cash",
		Icon           = "rbxassetid://86766178919624",
		ValueGoal      = 0,
		SubStep        = "Tutorial Complete!",
		SubStepCurrency = "Cash",
		SubStepIcon    = "rbxassetid://86766178919624",
		SubStepValueGoal = 0,
		EndingTip      = "Run Your Restaurant and grow to HUGE Numbers!",
		Popups         = {},
		BeamTargets    = {},
	},
}

return ExtendedTutorial