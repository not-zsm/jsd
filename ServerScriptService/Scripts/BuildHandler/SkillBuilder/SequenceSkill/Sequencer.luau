local Thread = require( "./Thread" );

local MAX_PREVIOUS_BLOCKS_TRACE = 256;

local Sequencer = {};
Sequencer.__index = Sequencer;

function Sequencer.new(SequenceSkill)
	local self = setmetatable(
		{
			sequence_skill = SequenceSkill;
			
			current_branch = nil;
			target_branch = nil;
			
			next_block_index = 0,
			previous_block_pointer = 0;
			previous_block_size = 0;
			previous_block_stack = {};
			
			thread = nil;
			callback = nil;
		}, 
		Sequencer);
	
	return self;
end;

function Sequencer:start(callback, branch)
	assert(branch, "No branch was provided");
	assert(callback, "No callback was provided");
	
	self:stop();
	
	self.thread = Thread.new(function(branch, ...)
		self:jump_to(branch, ...);
		
		if self.thread then
			self.thread:close();
			self.thread = nil;
		end;
	end);
	
	self.thread.closed:Once(function()
		self.thread = nil;
		self.target_branch = nil;
	end);
	
	self.callback = callback;
	self.thread:start(branch);
end;

function Sequencer:get_previous_blocks(from_block)
	local stack = self.previous_block_stack;
	local pointer = self.previous_block_pointer;
	local blocks = table.create(#stack);

	if from_block then
		pointer = table.find( stack, from_block );
	end;

	if pointer and pointer > 0  then
		for point = pointer, math.max(pointer - #stack, 1), -1 do
			table.insert(blocks, stack[point]);
		end;

		for point = MAX_PREVIOUS_BLOCKS_TRACE, math.max(pointer, MAX_PREVIOUS_BLOCKS_TRACE - (#stack - pointer)) + 1, -1 do
			table.insert(blocks, stack[point]);
		end;

		return blocks;
	end;

	return blocks;
end;

function Sequencer:branch_to(branch_name: string, index: number?)
	if not self.thread then
		local builder = self.sequence_skill:get_builder();
		
		if builder then
			builder:push_notification("warning", "[Skill Debug] Unable to branch: custom skill has ended", 10);
			builder:push_notification("info", "Try placing a wait block with a long enough time at the end of your skill", 10);
		end;
		
		return;
	end;
	
	local branch = self.sequence_skill:get_branch(branch_name);

	if branch then
		self.next_block_index = math.max(0, index or 0);
		
		if self.next_block_index > #branch.blocks then
			return;
		end;
		
		if self.thread:is_running() then
			-- running thread is likely the same thread, allow thread to continue and move on when ready:
			self.target_branch = branch;
		else
			-- wasn't called in the same thread, safe to directly restart:
			self.thread:restart(branch);
		end;
	end;
end

function Sequencer:jump_to(branch, ...)
	-- doesn't get set to nil on close, this is intentional.
	self.current_branch = branch;
	self.target_branch = nil;

	while self.next_block_index < #branch.blocks do
		if not self.thread or self.thread.is_closed then
			return;
		end;

		self.next_block_index += 1;

		local block = branch.blocks[self.next_block_index];
		local shift_index = self.callback( self.next_block_index, block );

		-- Ignore shifting if target_branch is set (prevent rare bug)
		if shift_index and not self.target_branch then
			self.next_block_index = math.clamp(self.next_block_index + shift_index - 1, 0, #branch.blocks);
		end;

		self.previous_block_pointer = self.previous_block_pointer % MAX_PREVIOUS_BLOCKS_TRACE + 1;
		self.previous_block_stack[self.previous_block_pointer] = block;

		if self.target_branch then
			return self:jump_to(self.target_branch, ...);
		end;
	end;
end;

function Sequencer:close()
	if self.thread then
		self.thread:close();
	end
end

function Sequencer:stop()
	self.previous_block_pointer = 0;
	self.previous_block_size = 0;
	self.next_block_index = 0;

	table.clear(self.previous_block_stack);

	if self.thread then
		self.thread:close();
		self.thread = nil;
	end;

	self.target_branch = nil;
end;

function Sequencer:destroy()
	self:stop();
end;

table.freeze(Sequencer);

return Sequencer;