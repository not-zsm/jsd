local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Math = require( ReplicatedStorage.Packages.Math )

-------------------------------------------------------------------------

local FPS60 = 1 / 60;

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(255, 159, 25)
DerivedBlock.icon = "86084882582277"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.description = "Loop a set of blocks until a condition is met"
DerivedBlock.order = 7;
DerivedBlock.properties = { 
	
	Previous = {
		Order = 10;
		Default = 1;
		Described = true,
	};
	MaxLoops = {
		Order = 20,
		Default = 3,
		Described = true,
	};
	MinLoops = {
		Order = 21,
		Default = 0,
		Described = true,
	};
	--Mode = {
	--	Order = 25,
	--	Default = "AND";
	--	ValueList = {"AND", "OR"};
	--};
	ImmediateExit = {
		Order = 26,
		Default = true;
	};
	UntilPressedAgain = {
		Order = 30,
		Default = false,
		Grayboxed = true;
	};
	UntilTimeElapsed = {
		Order = 40,
		Default = 1,
		Grayboxed = true;
	};
	UntilAwakeningInRange = {
		Order = 50,
		Default = NumberRange.new(50, 100),
		Grayboxed = true;
	};
	UntilHealthInRange = {
		Order = 60,
		Default = NumberRange.new(100, 100),
		Grayboxed = true;
	};
	--UntilSkillsEnded = {
	--	Order = 60,
	--	Default = false,
	--	Grayboxed = true;
	--};
};

function DerivedBlock.new(...)
	local self = setmetatable(BaseBlock.new(...), DerivedBlock);
	
	self.loops = 0;
	self.has_looped = false;
	self.stop_loop_flag = false;
	self.stop_loop_flag_min = false;
	self.last_loop = -math.huge;
	
	self.loop_maid = self.maid:limb();
	
	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:cancel()
	self.loops = 0;
	self.has_looped = false;
	self.stop_loop_flag = false;
	self.stop_loop_flag_min = false;
	
	self.loop_maid:clean();
end

function DerivedBlock:activate(sequencer, combat)
	local attack = self:get_attack();
	local last_loop = self.last_loop;
	local current_loop = os.clock();
	
	self.loops += 1;
	self.last_loop = current_loop;
	
	if self.stop_loop_flag_min and ( self.loops > self.values.MinLoops ) then
		return self:cancel();
	end;
	
	if self.stop_loop_flag or ( self.values.MaxLoops > 0 and self.loops > self.values.MaxLoops ) then
		return self:cancel();
	end;
	
	-- Prevents script timeouts
	if current_loop - last_loop <= FPS60 then
		task.wait();
	end;
	
	if not self.has_looped then
		self.has_looped = true;
		self.loop_maid:clean();
		
		local function stop_loop()
			-- Loop block cannot exit immediately if MinLoops has not been reached
			if self.loops > self.values.MinLoops then
				--self:cancel();
				self.stop_loop_flag = true;
				
				if self.values.ImmediateExit and sequencer.thread then
					sequencer:branch_to(self.branch, self.position + 1);
				end;
			else
				self.stop_loop_flag_min = true;
			end;
		end;
		
		if not self.data.UntilPressedAgain.Gray then
			self.loop_maid:add(attack.OnVariant:Connect(stop_loop));
		end;
		
		if not self.data.UntilTimeElapsed.Gray then
			self.loop_maid:add(task.delay(self.values.UntilTimeElapsed, stop_loop))
		end;
		
		if not self.data.UntilAwakeningInRange.Gray then
			local function check_awakening()
				local value = attack.CurrentUltimate.Value;
				local range = self.values.UntilAwakeningInRange;

				if value >= range.Min and value <= range.Max then
					stop_loop();
				end;
			end;
			
			self.loop_maid:add(attack.CurrentUltimate.OnUltimateValueChanged:Connect(check_awakening))
			check_awakening();
		end;
		
		if not self.data.UntilHealthInRange.Gray then
			local humanoid: Humanoid = combat.Character.Humanoid;
			
			local function check_health(health: number)
				local range = self.values.UntilHealthInRange;

				if health >= range.Min and health <= range.Max then
					stop_loop();
				end;
			end
			
			self.loop_maid:add(humanoid.HealthChanged:Connect(check_health));
			check_health(humanoid.Health);
		end
	end;
	
	if not self.stop_loop_flag then
		return -self.values.Previous;
	end;
end;

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;