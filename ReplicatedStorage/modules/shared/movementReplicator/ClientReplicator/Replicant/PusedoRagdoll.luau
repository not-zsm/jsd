local replicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Visuals = workspace:WaitForChild("Visuals");

---------------------------------------------------------------------------------

local Packages = replicatedStorage.packages

local Maid = require( Packages.Maid )
local Debounce = require( Packages.Debounce )

local Util = require( replicatedStorage.modules.shared.movementReplicator.Util )

local Types = require( script.Parent.Parent.Types );

---------------------------------------------------------------------------------

local PsuedoRagdoll = {} :: Types.ClassPsuedoRagdoll;
PsuedoRagdoll.__index = PsuedoRagdoll;

---------------------------------------------------------------------------------

function PsuedoRagdoll.new(character: Model)
	local maid = Maid.new();
	
	local self = setmetatable(
		{
			enabled = false;
			debounce = Debounce.new();
			character = character;
			torso = character.Torso;
			root = character.HumanoidRootPart;
			maid = maid;
		}, 
		PsuedoRagdoll);
	
	self:initialise_joints();
	
	return self;
end;

function PsuedoRagdoll:destroy(): ()
	self:disable()
	self.maid:destroy();
end

---------------------------------------------------------------------------------

function PsuedoRagdoll:initialise_joints(): ()
	self.hip_joints = { self.torso["Left Hip"], self.torso["Right Hip"] };
	self.shoulder_joints = { self.torso["Left Shoulder"], self.torso["Right Shoulder"]; };
	self.neck_joint = self.torso["Neck"];
end


function PsuedoRagdoll:disable(): ()
	if not self.enabled then return end;
	
	self.enabled = false;
	self.maid:clean();
end


function PsuedoRagdoll:connect_limb_knocker(info_table): ()
	local limb: BasePart = self.character:FindFirstChild(info_table.limb_name);
	if not limb then return; end;
	
	self.maid:add(limb.Touched:Connect(function(part)
		if not self.debounce:has(limb.Name) then
			self.debounce:add(limb.Name, info_table.debounce or 2);
			
			Util.tween_number(info_table.knock_table[info_table.property], info_table.knock_table[info_table.property] - info_table.value, info_table.tween_info, function(value, last)
				info_table.knock_table[info_table.property] = value;
			end)
		end;
	end))
end


function PsuedoRagdoll:enable(): ()
	if self.enabled then return end;
	
	self.enabled = true;
	self.maid:clean();
	self.debounce:reset();
	
	local bounce = 0;
	local elapsed = 0;
	local flail_value = 1;
	local hipps = { right = 0, left = 0 };
	local knocks = { head = 1, right = 0, left = 0 };
	
	local linear = script.LinearVelocity:Clone();
	self.maid:add(linear)
	
	linear.Attachment0 = self.root.RootAttachment;
	linear.Parent = self.root
	
	self:connect_limb_knocker({
		limb_name = "Right Arm";
		property = "right";
		tween_info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, true);
		knock_table = knocks;
		value = 1;
	});

	self:connect_limb_knocker({
		limb_name = "Left Arm";
		property = "left";
		tween_info = TweenInfo.new(0.25, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, true);
		knock_table = knocks;
		value = 0.5;
	});

	self:connect_limb_knocker({
		limb_name = "Left Leg";
		property = "left";
		tween_info = TweenInfo.new(0.28, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, true);
		knock_table = hipps;
		value = -1;
	});

	self:connect_limb_knocker({
		limb_name = "Right Leg";
		property = "right";
		tween_info = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, 0, true);
		knock_table = hipps;
		value = 1;
	});
	
	local info = TweenInfo.new(0.5, Enum.EasingStyle.Cubic, Enum.EasingDirection.Out);
	local linear_info = TweenInfo.new(0.15);
	local linear_goal = {VectorVelocity = script.LinearVelocity.VectorVelocity, MaxAxesForce = script.LinearVelocity.MaxAxesForce};
	
	local function impact_react(part: BasePart)
		if not part:IsDescendantOf(Visuals) and not self.debounce:has("impact") then
			self.debounce:add("impact", 3);
			
			Util.tween_number(flail_value, 0, TweenInfo.new(0.5, Enum.EasingStyle.Cubic), function(value)
				flail_value = value;
			end)

			if self.character.HumanoidRootPart.CFrame.LookVector:Dot(Vector3.yAxis) < 0 then
				knocks.head = 1;
			else
				knocks.head = -1;
			end

			Util.tween_number(bounce, bounce + 3, info, function(value, last)
				bounce += value - last
			end)

			linear.VectorVelocity = Vector3.yAxis * 100;
			linear.MaxAxesForce = Vector3.new(0, 10_000, 0);

			TweenService:Create(linear, linear_info, linear_goal):Play();
		end;
	end
	
	self.debounce:add("impact", 0.25);
	self.maid:add(self.character.Humanoid.Touched:Connect(impact_react))
	
	-- Holy moly!!!!!! This is so ugly!!!!!!!
	self.maid:add(RunService.PreSimulation:Connect(function(dt)
		elapsed += dt;
		bounce = math.max(0, bounce - dt * 4);
		
		local new_cframe: CFrame = self.root.CFrame;
		
		-- Some time control variables...
		local rebounce = bounce * knocks.head;
		local interpolation_alpha = math.clamp(elapsed * 3, 0, 1);
		local target_magnitude = math.clamp(10 - elapsed * 12, 0, 10);
		local curve_sine = math.sin(elapsed * 8) * target_magnitude;
		
		local head_sine1 = math.sin(elapsed * 10) * flail_value;
		local head_sine2 = math.sin(elapsed * 8) * flail_value * 0.5;
		local head_sine3 = math.cos(elapsed * 5) * flail_value * 0.5;
		
		-- Animate the hips (Right Leg, Left Leg)
		for index, hip in self.hip_joints do
			local axis = 3 - index * 2;
			local knock_value = hipps[if index == 1 then "left" else "right"];
			
			hip.Transform = hip.Transform:Lerp( 
				CFrame.Angles(
					math.rad(-target_magnitude * 3 - 5) - knock_value * 0.2 * axis - head_sine1 * 0.2 - flail_value * 0.1, 
					math.rad(12) * axis + knock_value * 0.5, 
					math.rad(target_magnitude * 3) + rebounce / 2 * axis + head_sine2
				), interpolation_alpha ) 
		end
		
		-- Animate the shoulders (Right Arm, Left Arm)
		for index, shoulder in self.shoulder_joints do
			local axis = 3 - index * 2;
			local knock_value = knocks[if index == 1 then "left" else "right"];
			
			shoulder.Transform = shoulder.Transform:Lerp(
				CFrame.new(-flail_value * 0.4 * axis, 0, flail_value * 0.1 + 0.5) *
				CFrame.Angles(
					math.rad(-5 - index * 21) + head_sine2 - 1, 
						math.rad(index * 10 * axis) - head_sine2 + flail_value * axis * 0.5 + head_sine3, 
					math.rad((-7 + target_magnitude * 4 + curve_sine * 3) * axis + (index - 1) * 19) - knock_value * 0.5 + rebounce / 2 * axis - head_sine1 * 0.5 - flail_value * 1 * axis
				), interpolation_alpha);
		end
		
		-- Animate the neck
		self.neck_joint.Transform = self.neck_joint.Transform:Lerp(
			CFrame.Angles(
				math.rad(5) - bounce / 5 + head_sine3 * 0.25,  
				math.rad(15 + curve_sine * 4) + head_sine1 * 0.2, 
				0.2 + rebounce / 5
			), interpolation_alpha);
	end))
end


function PsuedoRagdoll:set_enabled(value: boolean): ()
	if value then
		self:enable();
	else
		self:disable();
	end
end

---------------------------------------------------------------------------------

table.freeze(PsuedoRagdoll);

return PsuedoRagdoll;