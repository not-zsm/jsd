local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Instances = require( ReplicatedStorage.Packages.Instances )
local Maid = require( ReplicatedStorage.Packages.Maid )
local Preloading = require( ReplicatedStorage.Modules.Preloading )

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(227, 255, 103)
DerivedBlock.icon = "12662718374"
DerivedBlock.description = "Plays an animation"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 3;
DerivedBlock.properties = {
	Animation = {
		Order = 0,
		Filtered = false;
		ViewingHelper = {
			Type = "Animation",
			Range = "AnimationRange",
			Name = "AnimationName",
		};
	};
	AnimationName = {
		Default = "None";
		Described = true;
		Filtered = false;
		Order = 20;
		ViewingHelper = {
			Type = "ValueList",
			Animation = "Animation";
			Scale = 0.75;
		};
	};
	AnimationRange = {
		Hidden = true,
		Default = NumberRange.new(0, 1)
	};
	Speed = {
		Described = true;
		Order = 30,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 3);
			Increment = 1 / 60,
		},
	};
	FadeIn = {
		Order = 40,
		Default = 0.1,
	};
	FadeOut = {
		Order = 50,
		Default = 0.25,
	},
	Looped = {
		Order = 60;
		Default = false;
	};
	Cancellable = {
		Order = 70;
		Default = true;
	};
	OverwritePrevious = {
		Order = 80;
		Default = true;
	};
	Targeting = {
		Order = 120,
		Default = "Default",
		IsBranchTargeting = true;
		ValueList = { "Default", "User", "Target" };
	};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);

	self.animation_maid = Maid.new();
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:destroy()
	self:set_preloaded(false);
	self.animation_maid:destroy();
	
	BaseBlock.destroy(self);
end

function DerivedBlock:get_animation(): Animation?
	return Instances.find_directory(ReplicatedStorage.Animations, self.values.AnimationName, "/");
end;

function DerivedBlock:cancel()
	if self.values.Cancellable then
		self:stop_animations();
	end;
end;

function DerivedBlock:close()
	if self.values.Cancellable then
		self:stop_looped_animations();
	end;
end;

function DerivedBlock:stop_looped_animations()
	if self.track and self.track.Looped and self.track.IsPlaying then
		self.track:Stop( self.values.FadeOut );
	end;
end;

function DerivedBlock:stop_animations()
	if self.track and self.track.IsPlaying then
		self.track:Stop( self.values.FadeOut );
		self.track = nil;
	end;
	
	self.animation_maid:clean();
end;

function DerivedBlock:set_preloaded(value: boolean)
	local combat = self:get_combat();
	local animation = self:get_animation();
	
	if animation then
		if value then
			Preloading.Add(combat.LuaPlayer.Player, animation)
		else
			Preloading.Remove(combat.LuaPlayer.Player, animation)
		end
	end;
end;

function DerivedBlock:initialise_attack()
	self:set_preloaded(true);
end;

function DerivedBlock:activate(sequencer, combat)
	self:stop_animations();
	
	local animation = self:get_animation();
	
	if self.values.OverwritePrevious then
		local blocks = self:get_previous_blocks_of_type(self.name);
		
		for _, block in blocks do
			block:stop_animations();
		end;
	end;
	
	if animation then
		local range = self.values.AnimationRange;
		local looped = self.values.Looped;
		local speed = self.values.Speed * self.sequence_skill:get_speed_multiplier();
		
		local current_track = combat.LuaCharacter.Animator:LoadAnimation(animation);
		current_track.Priority = Enum.AnimationPriority.Action3;
		current_track.Looped = looped;
		current_track:Play( self.values.FadeIn, 1, speed );
		
		local in_reverse = speed < 0;
		
		if in_reverse then
			current_track.TimePosition = range.Max * current_track.Length;
		else
			current_track.TimePosition = range.Min * current_track.Length;
		end;
		
		self.track = current_track;
		
		self.animation_maid:add(current_track.Stopped:Connect(function()
			if self.track == current_track then
				self:stop_animations();
			end;
		end));
		
		self.animation_maid:add(RunService.PreAnimation:Connect(function(dt)
			-- Wait for animation to load
			if current_track.Length <= 0 then
				return;
			end;
			
			if in_reverse then
				if current_track.TimePosition <= range.Min * current_track.Length then
					if looped then
						current_track.TimePosition = range.Max * current_track.Length;
					else
						self:stop_animations();
					end;
				end;
				
			elseif current_track.TimePosition >= range.Max * current_track.Length then
				if looped then
					current_track.TimePosition = range.Min * current_track.Length;
				else
					self:stop_animations();
				end;
			end;
		end));
	end;
end;

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;