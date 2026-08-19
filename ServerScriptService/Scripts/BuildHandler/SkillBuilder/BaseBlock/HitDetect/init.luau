local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Math = require( ReplicatedStorage.Packages.Math )
local Maid = require( ReplicatedStorage.Packages.Maid )

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 137, 139)
DerivedBlock.icon = "12181404960"
DerivedBlock.description = "Detects when the previous used skill hits a target"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 6;
DerivedBlock.properties = { 
	
	Duration = {
		Order = 3,
		Default = -1,
	};
	Delay = {
		Order = 5,
		Default = 0,
	};
	MaxHits = {
		Order = 7,
		Default = 5,
	};
	--Immediate = {
	--	Order = 10,
	--	Default = true;
	--};
	Cancels = {
		Order = 10;
		Default = false;
	};
	CancelAllOnEnd = {
		Order = 15,
		Default = false;
	};
	Blocked = {
		Order = 20;
		Default = false;
		Grayboxed = true;
	};
	Ragdolled = {
		Order = 30;
		Default = false;
		Grayboxed = true;
	};
	HealthInRange = {
		Order = 35;
		Default = NumberRange.new(0, 20);
		Grayboxed = true;
	};
	HitBranchTo = {
		Order = 40;
		Default = "Branch";
		Grayboxed = true;
		Described = true;
		ValueList = "Branch",
		Filtered = false;
	};
	BranchTo = {
		Order = 50;
		Default = "Branch";
		Grayboxed = true;
		Described = true;
		ValueList = "Branch",
		Filtered = false;
	};

	--IsSubbranch = {
	--	Order = 4;
	--	DisplayName = "Is Sub-Branch";
	--	Default = true;
	--};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:check_for_states(VictimCombat, Result: string): boolean
	if not self.data.Blocked.Gray and Math.XOr(self.values.Blocked, Result == "Blocked" or Result == "Perfect Blocked") then
		return false;
	end;

	if not self.data.Ragdolled.Gray and Math.XOr(self.values.Ragdolled, VictimCombat:GetState("Ragdolled")) then
		return false;
	end;

	if not self.data.HealthInRange.Gray then
		-- Health can be negative for some reason.
		local health = math.max(0, VictimCombat.LuaCharacter.Humanoid.Health);
		local range = self.data.HealthInRange.Value;

		if health < range.Min or health > range.Max then
			return false;
		end;
	end;

	return true;
end;

function DerivedBlock:activate(sequencer, combat)
	local attack = self:get_attack();
	local skill_block = self:get_previous_block_of_type("Skill");
	local data = self.data;
	
	if not skill_block or not skill_block.custom_attack:ThreadAvailable() then
		return;
	end;
	
	local maid = Maid.new();
	local number_of_hits = 0;
	local branch_success = false;
	local cancel_success = false;
	local max_hits = data.MaxHits.Value;
	local duration = data.Duration.Value;
	
	maid:add(skill_block.custom_attack.Thread.OnClosed:Once(function()
		maid:destroy();
		
		if duration < 0 and number_of_hits == 0 and data.CancelAllOnEnd.Value then
			task.defer(function()
				attack:Cancel();
			end);
		end;
	end));
	
	maid:add(skill_block.custom_attack.OnAfflict:Connect(function(VictimLuaPlayer, Properties, Validated, Result)
		if max_hits > 0 and number_of_hits >= max_hits then
			return maid:destroy();
		end;
		
		number_of_hits += 1;
		
		local VictimCombat = VictimLuaPlayer.Character.Combat;
		
		if self:check_for_states(VictimCombat, Result)  then
			if self.values.Delay > 0 then
				task.wait( self.values.Delay );
			end;
			
			if not data.HitBranchTo.Gray then
				local branch = self.sequence_skill:get_branch(self.values.HitBranchTo);
				
				self.sequence_skill:start_hit_branch(branch, VictimCombat);
			end;
			
			if not cancel_success then
				if not branch_success and not data.BranchTo.Gray  then
					branch_success = true;
					sequencer:branch_to(self.values.BranchTo);
				end;
				
				if self.values.Cancels then
					cancel_success = true;
					maid:destroy();
					
					task.defer(function()
						skill_block.custom_attack:SetUncancellable(false);
						skill_block.custom_attack:Cancel();
					end);
				end;
			end;
		end;
	end));
	
	if duration > 0 then
		maid:add(task.delay(duration, function()
			maid:destroy();
			
			if number_of_hits == 0 and data.CancelAllOnEnd.Value then
				attack:Cancel();
			end;
		end))
	end;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;