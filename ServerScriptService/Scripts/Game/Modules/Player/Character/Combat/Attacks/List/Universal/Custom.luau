local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

----------------------------------------------------------------------------------

local Signal = require( ReplicatedStorage.Packages.Signal )
local Table = require( ReplicatedStorage.Packages.Table )

----------------------------------------------------------------------------------

local AllowedAttackFormatting = {UsesLeft = true, Name = true};

local BaseAttack = require( ServerScriptService.Scripts.Game.Modules.Player.Character.Combat.Attacks.BaseAttack )

local Attack = {}
Attack.__index = Attack

setmetatable(Attack, BaseAttack)

----------------------------------------------------------------------------------

function Attack:ConditionToActivate(State) : boolean
	return self.Enabled and self:BasicConditions() and not self.Combat:GetState("Blocking")
end;

function Attack:Pretrigger()
	self.OnVariant:Fire(); -- 🥀
	self.LastPretrigger = tick();
end

function Attack:Activate()
	assert(self.Sequencer, "No Sequencer?");

	if self.UsesLeft >= 1 then
		self.UsesLeft -= 1;
	end;
	
	local Walkspeed: number = self.Sequencer:get_value("WalkspeedDivider") or 3;
	
	self.Combat:StackState("Attacking", true);
	self.Combat:DivideSpeed(Walkspeed);
	
	self.Thread.OnClosed:Once(function(reason)
		self.Sequencer:stop();
	
		self.Combat:TimesSpeed(Walkspeed);
		self.Combat:StackState("Attacking", false);
		
		self:AddCooldown( self.Sequencer:get_current_cooldown() );
	
		if self.Thread.Cancelled then
			self.Sequencer:cancel_all();
		else
			self.Sequencer:close_all();
		end;
		
		if self.Sequencer:get_value("ResetUIState") then
			self:ResetUIState();
		end;
		
		self:UpdateBranchState();
		
		if self.UsesLeft == 0 then
			self.Combat:RemoveAttack(self.Name);
		end;
	end);
	
	local function block_iterate(index, block)
		return block:trigger( self.Sequencer.main_sequencer, self.Combat );
	end;
	
	self.Thread.OnClosed:Once(function()
		self.Sequencer.main_sequencer:close();
	end);
	
	local variant_interest = self.Sequencer.variant_interest;
	
	self:UpdateBranchState();
	self.Sequencer:start(block_iterate, self.PrimaryBranch);
	
	if variant_interest and self.Sequencer.variant_interest == variant_interest then
		variant_interest:cancel();
		self.Sequencer:set_variant_interest(nil);
	end
	
	self.Sequencer:wait();
	
	self:Close();
end;

function Attack:Close(...)
	self.Sequencer:stop();
	self.Sequencer:close_all();
	
	BaseAttack.Close(self, ...);
end;

function Attack:Cancel(...)
	self.Sequencer:cancel_all();
	
	BaseAttack.Cancel(self, ...);
end

function Attack:AddCooldown(Cooldown: number, ...)
	local variant_interest = self.Sequencer.variant_interest;
	
	if variant_interest and variant_interest.values.PreventCooldown then
		return;
	end;
	
	return BaseAttack.AddCooldown(self, Cooldown, ...)
end

function Attack:ApplyContextFormatting(Text: string): string
	local sequencer = self.Sequencer;
	local branch = sequencer.current_branch or sequencer.branches[1];
	
	if not branch then
		return Text;
	end;
	
	-- my heart goes out to this function 💖 its so beautiful
	local new_text = string.gsub(Text, "%b{}", function(substring)
		local value = string.sub(substring, 2, -2);
		
		if AllowedAttackFormatting[value] then
			return tostring( self[value] );
	
		elseif branch.data[value] then
			return tostring( branch.data[value].Value );
			
		elseif sequencer.data[value] then
			return tostring( sequencer.data[value].Value );
		end;
	end)
	
	return new_text;
end;

function Attack:ResetUIState()
	local Display = self:GetCurrentDisplayUI();

	self:ChangeAttackDisplayWithFormatting( Display.DisplayName, Display.Settings );
end

function Attack:ChangeAttackDisplayWithFormatting(DisplayName, Settings)
	if Settings and Settings.Tip then
		Settings.Tip = self:ApplyContextFormatting(Settings.Tip);
	end;
	
	self.Combat:ChangeAttackDisplay(self.Name, self:ApplyContextFormatting(DisplayName), Settings or {});
end;

function Attack:GetCurrentDisplayUI()
	if not self.CurrentDisplay then
		self.CurrentDisplay = self:GetBaseDisplayUI();
	end;
	
	return self.CurrentDisplay;
end

function Attack:GetBaseDisplayUI()
	local display_name = self.Sequencer.values.DisplayName;
	local tool_tip = self.Sequencer.values.ToolTip;
	
	return { DisplayName = display_name, Settings = { Tip = tool_tip } }
end

function Attack:GetCurrentBranchInfo()
	assert(self.Sequencer, "No Sequencer");
	
	local source_branches = self.Sequencer.branches;
	local branches = table.move(source_branches, 2, #source_branches, 1, {});
	
	-- Move the Trivial branch (default) at the end
	table.insert(branches, source_branches[1]);
	
	local info = { 
		branch = source_branches[1], 
		display = self:GetBaseDisplayUI();
	};
	
	if self.Sequencer.variant_interest then
		local ChangeDisplay = require( ServerScriptService.Scripts.BuildHandler.SkillBuilder.BaseBlock.ChangeDisplay )
		ChangeDisplay.flash_display(self.Sequencer.variant_interest.data, info.display);
		
		local branch = self.Sequencer:get_branch(self.Sequencer.variant_interest.values.BranchTo);
		
		if branch then
			info.branch = branch;
		end;
		
		return info;
	end

	for index, branch in branches do
		local should_use = branch:test_conditions();

		if should_use and branch:get_value("AutoBranchOnConditionsMet") then
			branch:apply_display(info.display);
			info.branch = branch;
			break;
		end;
	end;
	
	return info;
end;

function Attack:UpdateBranchState()
	local info, variant = self:GetCurrentBranchInfo();
	local current_display = self:GetCurrentDisplayUI()
	local current_branch = self.PrimaryBranch;
	
	-- Check if the UI display changed.
	if not Table.same_content(current_display, info.display) then
		self.CurrentDisplay = info.display;
		
		if not self.Thread or self.Thread.Closed then
			self:ChangeAttackDisplayWithFormatting(self.CurrentDisplay.DisplayName, self.CurrentDisplay.Settings);
		end;
	end;
	
	if current_branch ~= info.branch then
		self.PrimaryBranch = info.branch;
	end;
	
	self:UpdateDisplayShown();
end;

function Attack:SetCustomSequence(Sequencer)
	local Combat = self.Combat;
	local MaxUses = tonumber(Sequencer.values.MaximumUses) or 0;
	
	self.Sequencer = Sequencer;
	self.UsesLeft = if MaxUses > 0 then MaxUses else -1;
	self.DisplayName = Sequencer.values.SkillName;
	self.Name = Sequencer.values.SkillName;
	
	for block, hidden_attack in self.SequenceAttacks do
		hidden_attack:Destroy();
	end;
	
	table.clear(self.SequenceAttacks);
	
	local use_settings = { IncludeWorldEvents = true, RespectSkillBuilder = true };
	
	for _, branch in Sequencer.branches do
		for index, block in branch.blocks do
			if block.name ~= "Skill" then
				continue;
			end;
			
			local attack_name = block.values.Skill;
			
			if not attack_name then
				warn(`Skill does not exist :(`);
				continue;
			end;
			
			if not Combat:CanUseNamedAttack(block.values.Skill, use_settings) then
				warn(`Player {Combat.LuaPlayer.Player.Name} cannot use the attack {attack_name}`);
				continue;
			end;
			
			local hidden_attack = Combat:CreateGhostAttack(attack_name);
			
			if hidden_attack then
				block:set_attack( hidden_attack );
			end;
		end;
	end;
	
	local function UpdateBranchState()
		self:UpdateBranchState();
	end;
	
	self.Job:Task(self.Combat.OnAttackChanged:Connect(function(Attack)
		self:UpdateForUltimate();
		
		if self.Sequencer:get_value("PreventOverride") and self ~= Attack and Attack.Key == self.Key then
			task.defer(self.Combat.RemoveAttack, self.Combat, Attack.Name);
		end;
	end));
	
	self.Job:Task(self.LuaCharacter.Items.OnEquipChanged:Connect(UpdateBranchState));
	self.Job:Task(self.Combat.OnAirStateChanged:Connect(UpdateBranchState))
	self.Job:Task(self.Combat.OnSpaceStateChanged:Connect(UpdateBranchState))
	
	local Display = self:GetBaseDisplayUI();

	self:ChangeAttackDisplayWithFormatting( Display.DisplayName, Display.Settings );
	self:UpdateForUltimate();
	self:UpdateBranchState();
end;

function Attack:UpdateDisplayShown()	
	local Visible = true;
	
	if not self.Sequencer.data.AllowedForItemsOnly.Gray and not self.LuaCharacter.Items:HasEquipped(self.Sequencer.values.AllowedForItemsOnly) then
		Visible = false;
	end;
	
	if self.CurrentUltimate then 
		if self.CurrentUltimate.InUltimate and not self.Sequencer:get_value("AllowedInAwakening") then
			Visible = false;

		elseif not self.CurrentUltimate.InUltimate and not self.Sequencer:get_value("AllowedInBase") then
			Visible = false;
		end;
	end;
	
	if Visible and not self.Enabled then
		self:ShowDisplay();
		self.Enabled = true;
		
	elseif not Visible and self.Enabled then
		self:HideDisplay();
		self.Enabled = false;
	end;
end;

function Attack:UpdateForUltimate()
	local NewUltimate = self.Combat:MatchAttack("Ultimate", Enum.KeyCode.G);

	if self.CurrentUltimate ~= NewUltimate then
		self.CurrentUltimate = NewUltimate;
		self.UltimateJob:Clean();
		
		if NewUltimate then
			local AwakeningState = NewUltimate.InUltimate;
			
			local function Update()
				if self.Sequencer:get_value("RemoveOnMovesetSwitch") and NewUltimate.InUltimate ~= AwakeningState then
					return self.Combat:RemoveAttack(self.Name);
				end;
				
				self:UpdateBranchState();
			end;
			
			self.UltimateJob:Task(NewUltimate.OnUltimateBegan:Connect(Update));
			self.UltimateJob:Task(NewUltimate.OnUltimateEnded:Connect(Update));
			self.UltimateJob:Task(NewUltimate.OnUltimateReached:Connect(Update));
		end;
	end;
end;

function Attack:Destroy(...)
	self.Sequencer:destroy();
	self.CurrentUltimate = nil;
	
	BaseAttack.Destroy(self, ...)
end

function Attack.new(...)
	local self = setmetatable(BaseAttack.new(...), Attack)
	
	self.TryToCancelMoves = true;
	self.ActivateOnInputEnded = false;
	self.CooldownEnabled = true;
	self.CustomAttack = true;
	self.RemoveOnSpawn = true;
	self.Uncancellable = false;
	self.Enabled = true;
	self.LastPretrigger = -1;
	self.UsesLeft = -1;
	self.SequenceAttacks = {};
	
	self.UltimateJob = self.Job:Extend();
	self.OnVariant = self.Job:Task(Signal.new());
	
	self:_Init();

	return self
end;

----------------------------------------------------------------------------------

table.freeze(Attack)

return Attack