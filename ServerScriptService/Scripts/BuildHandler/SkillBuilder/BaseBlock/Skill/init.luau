local Debris = game:GetService("Debris")
local RunService = game:GetService("RunService")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);

local SMALL_WEIGHT = 0.001;

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 80, 80)
DerivedBlock.icon = "7485051715";
DerivedBlock.description = "Triggers a skill from the game"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 2;
DerivedBlock.primary_view = "Skill";
DerivedBlock.properties = {
	Skill = {
		Described = true;
		Order = 10,
		Default = "Soundwave Punch",
		Filtered = false;
		ViewingHelper = {
			Type = "ValueList",
			Getter = "Skills",
			Scale = 0.8;
		};
	};
	Speed = {
		Order = 20;
		Default = 1;
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	DamageMultiplier = {
		Order = 30;
		Default = 1;
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	RagdollMultiplier = {
		Order = 40;
		Default = 1;
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	KnockbackMultiplier = {
		Order = 50;
		Default = 1;
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	StunMultiplier = {
		Order = 55;
		Default = 1;
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	HitboxMultiplier = {
		Order = 60;
		Default = Vector3.one;
	};
	HitboxOffset = {
		Order = 65,
		Default = Vector3.zero;
	};
	Animated = {
		Order = 70,
		Default = false;
		Described = true;
	};
	VisualScripts = {
		Order = 80,
		Default = true;
	};
	SoundEffects = {
		Order = 85,
		Default = true;
	};
	Concurrent = {
		Order = 90;
		Default = true;
	};
	Finishers = {
		Order = 100;
		Default = true;
	};
	CancelPrevious = {
		Described = true;
		Order = 110;
		Default = true;
	};
	AutoVariants = {
		NewSection = "Variants",
		DisplayName = "Auto-Variants",
		Order = 120;
		Default = false;
	};
	ForceVariant = {
		Order = 130;
		Default = false;
	};
	ForceSpecialVariant = {
		Order = 140;
		Default = false;
	};
	Blockable = {
		Order = 150;
		Default = false;
		Grayboxed = true;
	};
	HitsRagdoll = {
		Order = 151;
		Default = false;
		Grayboxed = true;
	};
	M1Reset = {
		DisplayName = "M1 Reset",
		Order = 152;
		Default = 0;
		Grayboxed = true;
	};
	Cancellable = {
		NewSection = "State",
		Order = 160;
		Default = false;
		Grayboxed = true;
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:set_attack(custom_attack)
	self.custom_attack = custom_attack;
	
	custom_attack.CooldownEnabled = false;
	custom_attack.TryToCancelMoves = false; -- Needs to false to prevent cancelling the Custom Master attack
	
	local base_afflict = custom_attack.Afflict;
	
	function custom_attack.Afflict(_, VictimLuaPlayer, Properties, ...)
		if not self.data.HitsRagdoll.Gray then
			Properties.DontHitRagdolled = not self.data.HitsRagdoll.Value;
		end;
		
		if not self.data.Blockable.Gray then
			Properties.DontCheckBlock = not self.data.Blockable.Value;
		end;
		
		return base_afflict(custom_attack, VictimLuaPlayer, Properties, ...);
	end;
end;

local function mask_windup_fix(self)
	local thread = self.custom_attack.Thread;

	if thread.Closed then
		return; -- Already cancelled
	end
	
	local target_speed = self.values.Speed * self.sequence_skill:get_speed_multiplier();
	
	local function update_animations(windup: AnimationTrack, keep_animated: boolean)
		if not keep_animated and not self.values.Animated then
			if windup.WeightTarget ~= SMALL_WEIGHT then
				windup:AdjustWeight( SMALL_WEIGHT, 0 );
			end;
		end;
	end;
	
	local connection = RunService.PreAnimation:Connect(function(dt)
		for _, animation in self.custom_attack.Animations do
			update_animations(animation, false);
		end;

		for _, animation in self.custom_attack.VictimAnimations do
			update_animations(animation, true);
		end;
	end);
	
	thread.OnClosed:Once(function()
		connection:Disconnect();
	end);
	
	self.custom_attack:SetSpeedMultiplier( target_speed );
end;

local function activate_attack(self)
	local combat = self:get_combat();
	local data = self:get_values();
	
	-- Incase the block is running (IE from a loop)
	--self:cancel();
	
	self.custom_attack.FinisherEnabled = data.Finishers;
	self.custom_attack.DamageMultiplier = data.DamageMultiplier * self.sequence_skill.values.DamageMultiplier;
	self.custom_attack.RagdollMultiplier = data.RagdollMultiplier  * self.sequence_skill.values.RagdollMultiplier;
	self.custom_attack.KnockbackMultiplier = data.KnockbackMultiplier  * self.sequence_skill.values.KnockbackMultiplier;
	self.custom_attack.StunMultiplier = data.StunMultiplier;
	
	self.custom_attack.HitboxMultiplier = data.HitboxMultiplier;
	self.custom_attack.HitboxOffset = data.HitboxOffset;
	
	self.custom_attack.VariantsEnabled = data.AutoVariants;
	self.custom_attack.VisualEffectsEnabled = data.VisualScripts;
	self.custom_attack.SoundEffectsEnabled = data.SoundEffects;
	
	self.custom_attack.ForceVariant = data.ForceVariant;
	self.custom_attack.ForceSpecialVariant = data.ForceSpecialVariant;
	
	if not self.data.Cancellable.Gray then
		self.custom_attack.Uncancellable = not data.Cancellable;
	end;
	
	if not self.data.M1Reset.Gray then
		local M1 = self.combat:GetFirstAttack("M1");
		
		if M1 then
			M1.ResetTime = time() - data.M1Reset;
		end;
	end;
	
	self.custom_attack:UpdateAirVariantChecking(combat.Actions.ClientSentExtra);
	
	if self.custom_attack.Name == "Lapse Pull" then
		task.spawn(self.custom_attack.ConditionToActivate, self.custom_attack);
	end;
	
	self.custom_attack:Trigger();
	
	task.defer( mask_windup_fix, self );
end;

function DerivedBlock:cancel()
	if self.custom_attack then
		self.custom_attack:SetUncancellable(false);
		self.custom_attack:Cancel();
	end;
end;

function DerivedBlock:close()
	if not self.values.Concurrent then
		self:cancel();
	end;
end;

function DerivedBlock:activate(sequencer, combat)
	if not self.values.Speed then
		self.values.Speed = 1;
	end;
	
	if self.custom_attack then
		if self.values.Concurrent then
			task.spawn( activate_attack, self );
		else
			local success, result = pcall( activate_attack, self );
			
			if not success then
				warn("Custom Skill Error:", result);
			end;
			
			if self.custom_attack.Thread then
				self.custom_attack.Thread.OnClosed:Wait();
			end;
		end
	end;
	
	if self.values.CancelPrevious then
		local block = self:get_previous_block_of_type(self.name);
		
		if block then
			block:cancel();
		end;
	end;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;