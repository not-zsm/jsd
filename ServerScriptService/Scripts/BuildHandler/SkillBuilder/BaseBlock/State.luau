local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Maid = require( ReplicatedStorage.Packages.Maid )
local Utility = require( ReplicatedStorage.Modules.Shared.Utilities.Utility )

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(0, 235, 47)
DerivedBlock.icon = "17546229322"
DerivedBlock.description = "Change how the skill behaves"
DerivedBlock.order = 8;
DerivedBlock.properties = {
	UndoWhenFinished = {
		Order = -1;
		Default = true;
	};
	Attacking = {
		Order = 1,
		Default = true,
		Described = true;
		Grayboxed = true;
	};
	Cancellable = {
		Order = 2,
		Default = true,
		Described = true;
		Grayboxed = true;
	};
	LockCamera = {
		Order = 3,
		Default = true;
		Described = true;
		Grayboxed = true;
	};
	MultiplyWalkSpeed = {
		Order = 4,
		Default = 1,
		Described = true;
		Grayboxed = true;
	};
	DivideWalkSpeed = {
		Order = 5,
		Default = 1,
		Described = true;
		Grayboxed = true;
	};
	StunDuration = {
		Order = 6,
		Default = 1,
		Described = true;
		Grayboxed = true;
	};
	Damage = {
		Order = 7,
		Default = 10,
		Described = true;
		Grayboxed = true;
	};
	IFrames = {
		DisplayName = "IFrames";
		Order = 9,
		Default = "BackdashIFrames",
		Grayboxed = true;
		Described = true;
		ValueList = {
			"RemoveAll",
			"BackdashIFrames",
			"GrabIFrames",
			"HitboxImmunity",
		};
	};
	Targeting = {
		Order = 10,
		Default = "Default",
		IsBranchTargeting = true;
		ValueList = { "Default", "User", "Target" };
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	self.revert_maid = Maid.new();
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:add_to_revert(callback)
	if self.values.UndoWhenFinished then
		self.revert_maid:add(callback);
	end;
end;

function DerivedBlock:cancel()
	self.revert_maid:clean();
end;

function DerivedBlock:activate(sequencer, combat)
	local attack = self.sequence_skill.attack;
	local data = self:get_values();
	local normal_combat = self:get_combat();
	
	if not self.data.Cancellable.Gray then
		attack:SetUncancellable(not data.Cancellable);
	end;
	
	if not self.data.LockCamera.Gray then
		local humanoid = combat.LuaCharacter.Humanoid;
		
		if data.LockCamera then
			local camera_lock = Utility.StopAutoRotate(humanoid, "sbcl") -- skill builder cam lock
			
			self:add_to_revert(function()
				camera_lock:Destroy();
			end);
		else
			for _, camera_lock in humanoid:GetChildren() do
				if camera_lock:HasTag("sbcl") then
					camera_lock:Destroy();
					break;
				end;
			end;
		end;
	end;
	
	if not self.data.Attacking.Gray then
		combat:StackState("Attacking", data.Attacking);
		
		self:add_to_revert(function()
			combat:StackState("Attacking", false);
		end);
	end;
	
	if not self.data.Damage.Gray then
		normal_combat:DealDamage(combat.LuaPlayer, data.Damage);
	end;
	
	if not self.data.StunDuration.Gray then
		combat:Stun(data.StunDuration);
	end;
	
	if not self.data.MultiplyWalkSpeed.Gray then
		combat:TimesSpeed( data.MultiplyWalkSpeed );
		
		self:add_to_revert(function()
			combat:DivideSpeed( data.MultiplyWalkSpeed );
		end)
	end;
	
	if not self.data.DivideWalkSpeed.Gray then
		combat:DivideSpeed( data.DivideWalkSpeed );
		
		self:add_to_revert(function()
			combat:TimesSpeed( data.DivideWalkSpeed );
		end)
	end;
	
	if not self.data.IFrames.Gray and table.find(DerivedBlock.properties.IFrames.ValueList, data.IFrames) then
		if data.IFrames == "RemoveAll" then
			for _, state in DerivedBlock.properties.IFrames.ValueList do
				combat:StackState(state, false);
			end;
		else
			combat:StackState(data.IFrames, true);

			self:add_to_revert(function()
				combat:StackState(data.IFrames, false);
			end)
		end;
	end
end;

function DerivedBlock:destroy()
	self.revert_maid:destroy();
	
	BaseBlock.destroy(self);
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;