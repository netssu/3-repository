--[[--~~~ Arsenal Ragdoll Script/Engine by rl905992 ~~~--
			Please give me credit
			if you use this	
--]]

----- do not touch unless if you want to modify some stuff. -----
function createnocollider(p0,p1,parent)
	local nocollide=Instance.new("NoCollisionConstraint")
	nocollide.Part0=p0
	nocollide.Part1=p1
	nocollide.Parent=parent
--	print("Made nocollision with attachments named "..p1.Name.." and "..p1.Name..", which parents are "..p0.Parent.Name.." and "..p1.Parent.Name)
end

function createconstraint_ballsocket(parent,a0,a1, islimitsenabled,upperangle, istwistenabled,twistlimitu,twistlimitl)
	local constraint=Instance.new("BallSocketConstraint")
	constraint.Name=a0.Name.." Joint"
	constraint.Attachment0=a0
	constraint.Attachment1=a1
	constraint.LimitsEnabled=islimitsenabled
		constraint.UpperAngle=upperangle
		constraint.TwistLimitsEnabled=istwistenabled
			constraint.TwistUpperAngle=twistlimitu
			constraint.TwistLowerAngle=twistlimitl
	constraint.Parent=parent
--	print("Made constraint with attachments named "..a0.Name.." and "..a1.Name..", which parents are "..a0.Parent.Name.." and "..a1.Parent.Name)
end

function createconstraint_hinge(parent,a0,a1, islimitsenabled,upperangle,lowerangle)
	local constraint=Instance.new("HingeConstraint")
	constraint.Name=a0.Name.." Joint"
	constraint.Attachment0=a0
	constraint.Attachment1=a1
	constraint.LimitsEnabled=islimitsenabled
		constraint.UpperAngle=upperangle
		constraint.LowerAngle=lowerangle
	constraint.Parent=parent
--	print("Made constraint with attachments named "..a0.Name.." and "..a1.Name..", which parents are "..a0.Parent.Name.." and "..a1.Parent.Name)
end
function getAttachment0(attachmentName)
	for _,child in next,script.Parent:GetChildren() do
		local attachment = child:FindFirstChild(attachmentName)
		if attachment then
			return attachment
		end
	end
end

function ragdoll()

local char=script.Parent
local hum=script.Parent.Humanoid

local hed = script.Parent.Head
local utor = script.Parent.UpperTorso
local ltor = script.Parent.LowerTorso

local luarm = script.Parent.LeftUpperArm
local llarm = script.Parent.LeftLowerArm
local lh = script.Parent.LeftHand

local ruarm = script.Parent.RightUpperArm
local rlarm = script.Parent.RightLowerArm
local rh = script.Parent.RightHand

local luleg = script.Parent.LeftUpperLeg
local llleg = script.Parent.LeftLowerLeg
local lf = script.Parent.LeftFoot

local ruleg = script.Parent.RightUpperLeg
local rlleg = script.Parent.RightLowerLeg
local rf = script.Parent.RightFoot

local bodyparts={hed,utor,ltor,ruarm,luarm,rlarm,llarm,rh,lh,rf,lf,ruleg,luleg,rlleg,llleg,rf,lf}

--[GeneralGBLue's stuff I had to do lol. THIS WAS A REAL TORTURE ok...]--
local head = script.Parent.Head
local leftlowerarm = script.Parent["LeftLowerArm"]
local leftupperarm = script.Parent["LeftUpperArm"]
local lefthand = script.Parent["LeftHand"]
local leftlowerleg = script.Parent["LeftLowerLeg"]
local leftupperleg = script.Parent["LeftUpperLeg"]
local leftfoot = script.Parent["LeftFoot"]
local rightlowerleg = script.Parent["RightLowerLeg"]
local rightupperleg = script.Parent["RightUpperLeg"]
local rightfoot = script.Parent["RightFoot"]
local rightlowerarm = script.Parent["RightLowerArm"]
local rightupperarm = script.Parent["RightUpperArm"]
local righthand = script.Parent["RightHand"]
local uppertorso = script.Parent.UpperTorso
local lowertorso = script.Parent.LowerTorso
--[Setup dood...]--
--[5 BallIDK things in total I gotta do.]--
--[REAL Part I gotta do for this R15 Ragdoll, to oughta work mahn B)]--
	local LOWERTORSO1 = Instance.new("BallSocketConstraint")
	LOWERTORSO1.Parent = lowertorso
	LOWERTORSO1.Attachment0 = lowertorso.LeftHipRigAttachment
	LOWERTORSO1.Attachment1 = leftupperleg.LeftHipRigAttachment
	LOWERTORSO1.Enabled = true
	LOWERTORSO1.LimitsEnabled = true
	LOWERTORSO1.TwistLimitsEnabled = true
	LOWERTORSO1.TwistUpperAngle = 45
	LOWERTORSO1.TwistLowerAngle = -45
	LOWERTORSO1.UpperAngle = 15
	
	local LOWERTORSO2 = Instance.new("BallSocketConstraint")
	LOWERTORSO2.Parent = lowertorso
	LOWERTORSO2.Attachment0 = lowertorso.RightHipRigAttachment
	LOWERTORSO2.Attachment1 = rightupperleg.RightHipRigAttachment
	LOWERTORSO2.LimitsEnabled = true
	LOWERTORSO2.TwistLimitsEnabled = true
	LOWERTORSO2.TwistUpperAngle = 45
	LOWERTORSO2.TwistLowerAngle = -45
	LOWERTORSO2.UpperAngle = 15
--[Alright, thats all the lower torso ball socket constraints i finished.]--
	local UPPERTORSO1 = Instance.new("HingeConstraint")
	UPPERTORSO1.Parent = uppertorso
	UPPERTORSO1.Attachment0 = lowertorso.WaistRigAttachment
	UPPERTORSO1.Attachment1 = uppertorso.WaistRigAttachment
	UPPERTORSO1.Enabled = true
	UPPERTORSO1.LimitsEnabled = true
	UPPERTORSO1.UpperAngle = -45
	UPPERTORSO1.LowerAngle = 0
	
	local UPPERTORSO2 = Instance.new("BallSocketConstraint")
	UPPERTORSO2.Parent = uppertorso
	UPPERTORSO2.Attachment0 = uppertorso.LeftShoulderRigAttachment
	UPPERTORSO2.Attachment1 = leftupperarm.LeftShoulderRigAttachment
	UPPERTORSO2.Enabled = true
	UPPERTORSO2.LimitsEnabled = true
	UPPERTORSO2.TwistLimitsEnabled = true
	UPPERTORSO2.TwistUpperAngle = 140
	UPPERTORSO2.TwistLowerAngle = -140
	UPPERTORSO2.UpperAngle = 25
	
	local UPPERTORSO3 = Instance.new("BallSocketConstraint")
	UPPERTORSO3.Parent = uppertorso
	UPPERTORSO3.Attachment0 = uppertorso.RightShoulderRigAttachment
	UPPERTORSO3.Attachment1 = rightupperarm.RightShoulderRigAttachment
	UPPERTORSO3.Enabled = true
	UPPERTORSO3.LimitsEnabled = true
	UPPERTORSO3.TwistLimitsEnabled = true
	UPPERTORSO3.TwistUpperAngle = 140
	UPPERTORSO3.TwistLowerAngle = -140
	UPPERTORSO3.UpperAngle = 25
	--[End for UpperTorso. Woo...]--
	local HEAD = Instance.new("BallSocketConstraint")
	HEAD.Parent = head
	HEAD.Attachment0 = head.NeckRigAttachment
	HEAD.Attachment1 = uppertorso.NeckRigAttachment
	HEAD.Enabled = true
	HEAD.LimitsEnabled = true
	HEAD.UpperAngle = 35
	HEAD.TwistLimitsEnabled=true
	HEAD.TwistUpperAngle= 35
	HEAD.TwistLowerAngle= -35
	--[Seriously XD]--
	local LOWLEG = Instance.new("HingeConstraint")
	LOWLEG.Parent = leftlowerleg
	LOWLEG.Attachment0 = leftlowerleg.LeftKneeRigAttachment
	LOWLEG.Attachment1 = leftupperleg.LeftKneeRigAttachment
	LOWLEG.Enabled = true
	LOWLEG.LimitsEnabled = true
	LOWLEG.LowerAngle = 90
	LOWLEG.UpperAngle = 0
	local LOWLEG2 = Instance.new("HingeConstraint")
	LOWLEG2.Parent = rightlowerleg
	LOWLEG2.Attachment0 = rightlowerleg.RightKneeRigAttachment
	LOWLEG2.Attachment1 = rightupperleg.RightKneeRigAttachment
	LOWLEG2.Enabled = true
	LOWLEG2.LimitsEnabled = true
	LOWLEG2.LowerAngle = 90
	LOWLEG2.UpperAngle = 0
	local LOWARM = Instance.new("HingeConstraint")
	LOWARM.Parent = leftlowerarm
	LOWARM.Attachment0 = leftlowerarm.LeftElbowRigAttachment
	LOWARM.Attachment1 = leftupperarm.LeftElbowRigAttachment
	LOWARM.Enabled = true
	LOWARM.LimitsEnabled = true
	LOWARM.LowerAngle = -160
	LOWARM.UpperAngle = 0
	local LOWARM2 = Instance.new("HingeConstraint")
	LOWARM2.Parent = rightlowerarm
	LOWARM2.Attachment0 = rightlowerarm.RightElbowRigAttachment
	LOWARM2.Attachment1 = rightupperarm.RightElbowRigAttachment
	LOWARM2.Enabled = true
	LOWARM2.LimitsEnabled = true
	LOWARM2.LowerAngle = -160
	LOWARM2.UpperAngle = 0
	local FOOT = Instance.new("HingeConstraint")
	FOOT.Parent = leftfoot
	FOOT.Attachment0 = leftfoot.LeftAnkleRigAttachment
	FOOT.Attachment1 = leftlowerleg.LeftAnkleRigAttachment
	FOOT.Enabled = true
	FOOT.LimitsEnabled = true
	FOOT.LowerAngle = 25
	FOOT.UpperAngle = 25
	local FOOT2 = Instance.new("HingeConstraint")
	FOOT2.Parent = rightfoot
	FOOT2.Attachment0 = rightfoot.RightAnkleRigAttachment
	FOOT2.Attachment1 = rightlowerleg.RightAnkleRigAttachment
	FOOT2.Enabled = true
	FOOT2.LimitsEnabled = true
	FOOT2.LowerAngle = 25
	FOOT2.UpperAngle = 25
	local HAND = Instance.new("HingeConstraint")
	HAND.Parent = lefthand
	HAND.Attachment0 = lefthand.LeftWristRigAttachment
	HAND.Attachment1 = leftlowerarm.LeftWristRigAttachment
	HAND.Enabled = true
	HAND.LimitsEnabled = true
	HAND.LowerAngle = 25
	HAND.UpperAngle = 25
	local HAND2 = Instance.new("HingeConstraint")
	HAND2.Parent = righthand
	HAND2.Attachment0 = righthand.RightWristRigAttachment
	HAND2.Attachment1 = rightlowerarm.RightWristRigAttachment
	HAND2.Enabled = true
	HAND2.LimitsEnabled = true
	HAND2.LowerAngle = 25
	HAND2.UpperAngle = 25
	
	

--------------------------------------------------------
---------- Version 2.0 ---------------------------------
---------- Released 8/17/2017 --------------------------
---------- Written by orange451 ------------------------
--------------------------------------------------------

local Character = script.parent

local function wait(TimeToWait)
	if TimeToWait ~= nil then
		local TotalTime = 0
		TotalTime = TotalTime + game:GetService("RunService").Heartbeat:wait()
		while TotalTime < TimeToWait do
			TotalTime = TotalTime + game:GetService("RunService").Heartbeat:wait()
		end
	else
		game:GetService("RunService").Heartbeat:wait()
	end
end

local function waitFor( directory, name ) 
	while ( directory == nil or (name ~= nil and directory:FindFirstChild(name) == nil) ) do
		wait();
	end
	if ( name == nil ) then
		return directory;
	else
		return directory:FindFirstChild(name);
	end
end

local function getCharacter()
	return script.Parent;
end


local function getHumanoid()
	return waitFor( getCharacter(), "Humanoid" );
end

local function getNearestPlayer( position )
	local Players = game.Players:GetChildren();
	local dist = math.huge;
	local ret = nil;
	for i=1,#Players do
		local Player = Players[i];
		local Character = Player.Character;
		if ( Character ~= nil ) then
			local Root = Character:FindFirstChild("HumanoidRootPart");
			if ( Root ~= nil ) then
				local t = (position - Root.Position).magnitude;
				if ( t < dist ) then
					dist = t;
					ret = Player;
				end
			end
		end
	end
	
	return ret;
end

local RootLimbData = {
	{
		["WeldTo"]			= "LowerTorso",
		["WeldRoot"]		= "HumanoidRootPart",
		["AttachmentName"]	= "Root",
		["NeedsCollider"]	= true,
		["UpperAngle"]		= 10
	},
	{
		["WeldTo"]			= "UpperTorso",
		["WeldRoot"]		= "LowerTorso",
		["AttachmentName"]	= "Waist",
		["ColliderOffset"]	= CFrame.new(0, 0, 0),
		["UpperAngle"]		= 10
	},
	{
		["WeldTo"]			= "Head",
		["WeldRoot"]		= "UpperTorso",
		["AttachmentName"]	= "Neck",
		["ColliderOffset"]	= CFrame.new(0, 0, 0),--CFrame.new(0, 1, 0),
	},
	{
		["WeldTo"]			= "LeftUpperLeg",
		["WeldRoot"]		= "LowerTorso",
		["AttachmentName"]	= "LeftHip",
		["ColliderOffset"]	= CFrame.new(0, -0.5, 0)
	},
	{
		["WeldTo"]			= "RightUpperLeg",
		["WeldRoot"]		= "LowerTorso",
		["AttachmentName"]	= "RightHip",
		["ColliderOffset"]	= CFrame.new(0, -0.5, 0)
	},
	{
		["WeldTo"]			= "RightLowerLeg",
		["WeldRoot"]		= "RightUpperLeg",
		["AttachmentName"]	= "RightKnee",
		["ColliderOffset"]	= CFrame.new(0, -0.5, 0)
	},
	{
		["WeldTo"]			= "LeftLowerLeg",
		["WeldRoot"]		= "LeftUpperLeg",
		["AttachmentName"]	= "LeftKnee",
		["ColliderOffset"]	= CFrame.new(-0.05, -0.5, 0)
	},
	{
		["WeldTo"]			= "RightUpperArm",
		["WeldRoot"]		= "UpperTorso",
		["AttachmentName"]	= "RightShoulder",
		["ColliderOffset"]	= CFrame.new(0.05, 0.45, 0.15),
	},
	{
		["WeldTo"]			= "LeftUpperArm",
		["WeldRoot"]		= "UpperTorso",
		["AttachmentName"]	= "LeftShoulder",
		["ColliderOffset"]	= CFrame.new(0, 0.45, 0.15),
	},
	{
		["WeldTo"]			= "LeftLowerArm",
		["WeldRoot"]		= "LeftUpperArm",
		["AttachmentName"]	= "LeftElbow",
		["ColliderOffset"]	= CFrame.new(0, 0.125, 0),
		["UpperAngle"]		= 7
	},
	{
		["WeldTo"]			= "RightLowerArm",
		["WeldRoot"]		= "RightUpperArm",
		["AttachmentName"]	= "RightElbow",
		["ColliderOffset"]	= CFrame.new(0, 0.125, 0),
		["UpperAngle"]		= 7
	},
	{
		["WeldTo"]			= "RightHand",
		["WeldRoot"]		= "RightLowerArm",
		["AttachmentName"]	= "RightWrist",
		["ColliderOffset"]	= CFrame.new(0, 0.125, 0),
		["UpperAngle"]		= 7
	},
	{
		["WeldTo"]			= "LeftHand",
		["WeldRoot"]		= "LeftLowerArm",
		["AttachmentName"]	= "LeftWrist",
		["ColliderOffset"]	= CFrame.new(0, 0.125, 0),
		["UpperAngle"]		= 7
	},
	{
		["WeldTo"]			= "LeftFoot",
		["WeldRoot"]		= "LeftLowerLeg",
		["AttachmentName"]	= "LeftAnkle",
		["NeedsCollider"]	= false,
		["UpperAngle"]		= 7
	},
	{
		["WeldTo"]			= "RightFoot",
		["WeldRoot"]		= "RightLowerLeg",
		["AttachmentName"]	= "RightAnkle",
		["NeedsCollider"]	= false,
		["UpperAngle"]		= 7
	},
}

local RootPart = nil;
local MotorList = {};
local GlueList = {};
local ColliderList = {};

	

	--print("Ragdolling");
	local Character = getCharacter();
	local Humanoid = getHumanoid();
	local HumanoidRoot = script.Parent:FindFirstChild("HumanoidRootPart");
	if ( HumanoidRoot == nil ) then
		print("Cannot create ragdoll");
		return;
	end
	local Position = script.Parent.HumanoidRootPart.Position;
	Humanoid.PlatformStand = true;
	
	-- Handle death specific ragdoll. Will Clone you, then destroy you.
	local RagDollModel = Character;
	if (Humanoid.Health <= 0) then
		Character:FindFirstChild("HumanoidRootPart"):Destroy();
		Character.Archivable = true;
		RagDollModel = Character:Clone();
		
		local t = RagDollModel:GetChildren();
		for i=1,#t do
			local t2 = t[i];
			if ( t2:IsA("Script") or t2:IsA("LocalScript") ) then
				t2:Destroy()
			elseif (t2:IsA("BasePart")) then
				t2.CanCollide = false -- to avoid collision bugs
			end
		end
		
		spawn(function()
			local nsc = script.CamAttach:clone()
			nsc.CamPart.Value = RagDollModel.Head
			nsc.Disabled = false
			nsc.Parent = Character
		end)
		
		RagDollModel.Humanoid.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None;
		RagDollModel.Humanoid.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff;
		RagDollModel.Humanoid.MaxHealth = 0;
		RagDollModel.Humanoid.Health = 0;
		RagDollModel.Name="RagDoll"
		RagDollModel.Parent = workspace;
		
		local RagDollPointer = Instance.new("ObjectValue");
		RagDollPointer.Value = RagDollModel;
		RagDollPointer.Name = "RagDoll";
		RagDollPointer.Parent = Character;
		
game.Debris:AddItem(RagDollModel, 30);
	
	-- Reglue The Character
	for i=1,#RootLimbData do
		local limbData = RootLimbData[i];
		local partName = limbData["WeldTo"];
		local weldName = limbData["WeldRoot"];
		local PartTo = RagDollModel:FindFirstChild(partName);
		local WeldTo = RagDollModel:FindFirstChild(weldName);
		
		if ( PartTo ~= nil and WeldTo ~= nil ) then
			-- Create New Constraint
			
			-- Destroy the motor attaching it
			local Motor = PartTo:FindFirstChildOfClass("Motor6D");
			if ( Motor ~= nil ) then
				if ( Humanoid.Health <= 0 ) then
					Motor:Destroy();
				else
					MotorList[#MotorList+1] = { PartTo, Motor };
					Motor.Parent = nil;
				end
			end
			
			-- Create Collider
			local needsCollider = limbData["NeedsCollider"];
			if ( needsCollider == nil ) then
				needsCollider = true;
			end
			if ( needsCollider ) then
				local B = Instance.new("Part");
				B.Material = "Plastic"
				B.CanCollide = true;
				B.TopSurface = 0;
				B.BottomSurface = 0;
				B.formFactor = "Symmetric";
				B.Size = Vector3.new(0.4,0.4,0.4);
				B.Name="Collider"
				B.Transparency = 1;
				B.BrickColor = BrickColor.Red();
				B.Shape="Ball"
				B.Parent = RagDollModel;
				local W = Instance.new("Weld");
				W.Part0 = PartTo;
				W.Part1 = B;
				W.C0 = limbData["ColliderOffset"];
				W.Parent = PartTo;
				B.Velocity=PartTo.Velocity
				B.RotVelocity=PartTo.RotVelocity
				ColliderList[#ColliderList+1] = B;
				local c = RagDollModel:GetChildren()
				for i = 1,#c do
					if c[i].Name==B.Name and (c[i]:IsA("BasePart") or c[i]:IsA("MeshPart")) then
					end
				end
			end
		end
	end

	-- Destroy Root Part
	local root = Character:FindFirstChild("HumanoidRootPart");
	if ( root ~= nil ) then
		RootPart = root;
		if ( Humanoid.Health <= 0 ) then
			RootPart:Destroy();
		else
			RootPart.Parent = nil;
		end
	end
	
	local ff = Instance.new("ForceField",RagDollModel)
	ff.Visible=false	
	
	-- Delete all my parts if we made a new ragdoll
	if ( RagDollModel ~= Character ) then
		print("Deleting character");
		local children = Character:GetChildren();
		for i=1,#children do
			local child = children[i];
			if ( child:IsA("BasePart") or child:IsA("Accessory") or child:IsA("ForceField") ) and not (child.Name == "sndPart") then
				child:Destroy();
			elseif child.ClassName=="Tool" then
				child:Destroy()
			end
		end
	end

	if RagDollModel then
		--print("Deleting tools");
		local children = RagDollModel:GetChildren();
		for i=1,#children do
			local child = children[i];
			if ( child.ClassName=="Tool" ) then
				child:Destroy()
			end
		end
	end
	
	end
		local face = RagDollModel.Head:FindFirstChild("face")
		if face and face ~= nil then
			face.Texture = "http://www.roblox.com/asset/?id=3318783462"
		end

	local r = RagDollModel:GetChildren()
	for i = 1,#r do
		if r[i]:IsA("BasePart") or r[i]:IsA("MeshPart") then
		r[i]:SetNetworkOwner(nil)
		end
	end
		
RagDollModel.Humanoid.PlatformStand=true
-- Wait for torso (assume everything else will load at the same time)
waitFor( getCharacter(), "UpperTorso" );

--
end

script.Parent.Humanoid.Died:Connect(ragdoll)