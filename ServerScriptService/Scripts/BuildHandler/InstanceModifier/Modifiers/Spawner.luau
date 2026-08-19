local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Unpacker = require( "../../Unpacker" );
local Serialise = require( "../../Serialise" );
local AI = require( "../../Npc" );

local Type = require( Unpacker.Packages.Type );
local Asset = require( Unpacker.Packages.Asset );

local LuaPlayerList = require( ServerScriptService.Scripts.Game.Modules.LuaPlayerList )
local LuaPlayer = require( ServerScriptService.Scripts.Game.Modules.Player )

local BaseCharacter = script:WaitForChild("BaseCharacter");

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Create a sentient boss";
TagModifier.icon = 16917184359;
TagModifier.color = Color3.fromRGB(89, 0, 0)
TagModifier.section = 3;
TagModifier.use_prompt = false;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	Description = {
		Order = 22,
		Default = nil;
		Type = Type.Instance();
		Hidden = true;
	};
	DescriptionId = {
		Order = 22,
		Default = 2;
		Hidden = true;
	};
	DescriptionType = {
		Order = 21,
		Default = "None",
		ValueList = { "None", "User", "Custom" };
		Shows = {
			["Description"] = { "Custom" };
			["DescriptionId"] = { "User" };
		};
	};
	Reference = {
		Order = 24,
		Default = nil;
		Type = Type.Instance();
	};
	Animated = {
		Order = 14;
		Default = false;
	};
	AutoRig = {
		Order = 13,
		Default = true;
	};
	Hurtable = {
		Order = 12,
		Default = true;
	};
	Nextbot = {
		Order = 9,
		Default = false;
		Shows = { "NextbotImage", "NextbotSize", "NextbotGlows" };
	};
	NextbotImage = {
		Order = 10,
		Default = "130257351593587";
		AssetType = Enum.AssetType.Decal;
		Hidden = true;
	};
	NextbotSize = {
		Order = 10,
		Default = 20;
		Hidden = true;
	};
	NextbotGlows = {
		Order = 10,
		Default = true;
		Hidden = true;
	};
	OnHit = {
		Order = 25,
		Default = nil;
		Type = Type.Instance();
	};
	CanAttack = {
		Order = 15;
		Default = true;
		Shows = { "AttackSpeed", "AttackRange", "AttackReplacer" };
	};
	AttackReplacer = {
		Default = "None";
		ValueList = "Skills";
		Order = 16,
		
		Shows = {
			["CustomAction"] = {"Custom"};
		};
		
		Validate = function(user_id, value)
			if (value == "Custom" or value == "Random" or value == "None") then
				return true;
			end;
			
			local player = LuaPlayerList.Get(user_id);
			
			if player then
				return player.Character.Combat:CanUseNamedAttack(value, {IncludeWorldEvents = true});
			else	
				return false;
			end;
		end,
		
		Hidden = true;
	};
	AttackSpeed = {
		Order = 18,
		Default = 0.5;
		Hidden = true;
	};
	AttackRange = {
		Order = 19,
		Default = 10;
		Hidden = true;
	};
	CustomAction = {
		Order = 17;
		Default = "",
		ValueList = "CustomSkill";
		Hidden = true;
	};
	_CustomActionSerialised = {
		Default = "";
		Hidden = true;
	};
	_CustomActionUserId = {
		Default = "",
		Hidden = true;
	};
	StandRange = {
		Order = 3,
		Default = 3;
	};
	SearchRange = {
		Order = 4,
		Default = 500;
	};
	WalkSpeed = {
		Order = 5,
		Default = 16;
	};
	MaxHealth = {
		Order = 6,
		Default = 100;
	};
	DeathCleanup = {
		Order = 7,
		Default = 2;
	};
};

-------------------------------------------------------------------------------------------

local function get_user_id(self): number?
	return self.interest_id or self.attributes:get("_CustomActionUserId");
end;

local function get_sequence_data(self)
	return self.build_handler.skill_builder:get_sequence_data_for_action(get_user_id(self), self.attributes:get("CustomAction"));
end

local function create_sequence(self)
	return self.build_handler.skill_builder:create_sequence_primitive(get_user_id(self), self.attributes:get("CustomAction"), self.attributes:get("_CustomActionSerialised"));
end

-------------------------------------------------------------------------------------------

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.entities = {};
	
	return self;
end

local function copy_attachments_into(copy_limb: BasePart, target_limb: BasePart): ()
	for _, child in copy_limb:GetChildren() do
		if child:IsA("Attachment") and not target_limb:FindFirstChild(child.Name) then
			child:Clone().Parent = target_limb;
		end;
	end;
end;

local function create_missing_bodypart(model: Model, parent: Instance, copy_joint: Motor6D, reversed: boolean?): ()
	assert(copy_joint.Part0 and copy_joint.Part1, "Joint is not connected");

	local part0: BasePart, part1: BasePart;

	if reversed then
		part0, part1 = copy_joint.Part1, copy_joint.Part0;
	else
		part0, part1 = copy_joint.Part0, copy_joint.Part1;
	end

	local part1_limb = model:FindFirstChild(part1.Name);
	local part0_limb = model:FindFirstChild(part0.Name);

	if not part1_limb then
		part1_limb = part1:Clone();
		part1_limb.Transparency = 1;
		part1_limb.Parent = model;
	else
		copy_attachments_into(part0, part0_limb);
		copy_attachments_into(part1, part1_limb);
	end;

	local new_joint = parent:FindFirstChild(copy_joint.Name);

	if not new_joint then
		new_joint = copy_joint:Clone();
		
		if reversed then
			new_joint.Part0 = parent
			new_joint.Part1 = part0_limb or part1_limb;
		else
			new_joint.Part0 = parent;
			new_joint.Part1 = part1_limb;
		end;
		
		new_joint.Parent = parent;
	end;
end

-- The method to fix the mistakes we made along the way 💔
-- Basically create rig with whatever slop the user made, minimally as a model with a part inside.
local function create_enemy(self, model: Model)
	assert(model:IsA("Model"), "Reference is not of class Model");
	
	local humanoid = model:FindFirstChildOfClass("Humanoid");
	local root_part = model:FindFirstChild("HumanoidRootPart");
	
	if not humanoid then
		humanoid = Instance.new("Humanoid");
		humanoid.HipHeight = 2.50;
	end;
	
	humanoid.RequiresNeck = false;
	humanoid.BreakJointsOnDeath = false;
	
	local animator = humanoid:FindFirstChildOfClass("Animator");
	
	if not animator then
		animator = Instance.new("Animator", humanoid);
	end
	
	if not root_part then
		local part = model:FindFirstChildWhichIsA("BasePart");
		
		assert(part, "No parts exist in model");
		
		root_part = part.AssemblyRootPart or part;
		root_part.Name = "HumanoidRootPart";
		root_part.CanCollide = false;
		root_part.Anchored = false;
		root_part.Parent = model;
	end;
	
	root_part.RootPriority = 127;
	model.PrimaryPart = root_part;
	
	local torso = model:FindFirstChild("Torso");
	
	if not torso then
		torso = Instance.fromExisting(BaseCharacter.Torso);
		torso.Transparency = 1;
		torso.Parent = model;
	end;
	
	create_missing_bodypart(model, root_part, BaseCharacter.HumanoidRootPart.RootJoint, true);
	
	local is_r15 = humanoid.RigType == Enum.HumanoidRigType.R15;
	
	for _, joint in BaseCharacter.Torso:GetChildren() do
		if joint:IsA("Motor6D") then
			-- Fixes disjointed necks on valid R15 rigs.
			if is_r15 and joint.Name == "Neck" then
				continue;
			end;
			
			create_missing_bodypart(model, torso, joint, false);
		end;
	end;
	
	if self.attributes:get("Nextbot") then
		local size = self.attributes:get("NextbotSize");
		local image = self.attributes:get("NextbotImage");
		
		local gui = script.Nextbot:Clone();
		gui.Icon.Image = Asset.get_decal_id(image);
		gui.Size = UDim2.fromScale(size, size);
		
		if self.attributes:get("NextbotGlows") then
			gui.LightInfluence = 0;
			gui.Brightness = 1;
		end;
		
		gui.Parent = root_part;
		
		root_part.Transparency = 1;
		torso.Transparency = 1;
	end
	
	local instances = model:GetDescendants();
	
	for _, instance in instances do
		if instance:IsA("Sound") and instance.Name == "Music" then
			instance:Play();
			
		elseif instance:IsA("BasePart") then
			instance.Anchored = false;
		end;
	end;
	
	humanoid.Parent = model;
	
	return model, humanoid;
end

local function notify_builders(combats, ...)
	for _, combat in combats do
		combat:notify_builder(...);
	end;
end;

function TagModifier.attribute_updates:CustomAction(value, was_init)
	if was_init then return end;

	-- We need to serialise the data incase the player who set the custom action is no longer in-game, it it can still give players the custom skill.
	local data = get_sequence_data(self);

	if data then
		local skill_builder = self.build_handler.skill_builder;
		local success, exported = pcall( skill_builder.export, skill_builder, data );

		if success then
			self.attributes:set("_CustomActionSerialised", exported);
			self.attributes:set("_CustomActionUserId", self.interest_id);
		else
			warn("Unable to export:", exported);
		end;
	else
		warn("No sequence data?")
	end;
end;

function TagModifier:pulse(signal)
	if not self.entities then return end;
	
	local clone_enemy, entity;
	local data = self.attributes:all();
	local combats = signal:get_combats();
	
	if data.Reference and not data.Reference:IsDescendantOf(workspace.Builds) then
		return notify_builders(combats, 1, `Unable to spawn: Reference is invalid`);
	end;
	
	if data.Hurtable and not data.AutoRig then
		return notify_builders(combats, 1, `Unable to spawn: Auto Rig is required when you are using property Hurtable.`);
	end;
	
	local reference = data.Reference or Unpacker.Shared.Assets.Build.Inventory.All.Miscellaneous.CharacterR6;
	local clone_model = reference:Clone();
	
	if data.AutoRig then
		local success, result, humanoid = pcall(create_enemy, self, clone_model);
		
		if success then
			clone_enemy = result;
		else
			clone_model:Destroy();
			return notify_builders(combats, 1, `Unable to spawn: {string.match(result, "%d+: *(.-)$")}`);
		end;
		
		entity = AI.new(humanoid);
		entity.death_cleanup = data.DeathCleanup;
		entity.range = data.SearchRange;
		entity.attack_range = data.AttackRange;
		entity.attack_speed = data.AttackSpeed;
		entity.standback_range = data.StandRange;
		entity.on_attack:Connect(function()
			local on_hit_part = self.attributes:get("OnHit");
			
			if on_hit_part then
				local combat = self:get_combat(entity.sensor.rig);
				
				if combat then
					local signal = self:create_pulse();
					signal.coordinate = clone_enemy:GetPivot();
					signal:add_humanoid(entity.sensor.humanoid);
					
					for _, instance_modifier in InstanceModifier.get_modifiers(on_hit_part) do
						instance_modifier:pulse(signal);
					end;
				end;
			end;
		end);
		
		humanoid.WalkSpeed = data.WalkSpeed;
		humanoid.MaxHealth = data.MaxHealth;
		humanoid.Health = data.MaxHealth;
		
		entity.maid:add(function()
			if self.entities then
				self.entities[clone_enemy] = nil;
			end;
		end);
		
		local NewLuaPlayer = LuaPlayer.new(clone_enemy)
		LuaPlayerList.Add(NewLuaPlayer)

		entity.lua_player = NewLuaPlayer
		entity.lua_character = NewLuaPlayer.Character
		entity.combat = NewLuaPlayer.Character.Combat;
		
		entity.maid:add(function()
			LuaPlayerList.Remove(NewLuaPlayer)
			NewLuaPlayer:Destroy()
		end)
		
		if not data.Hurtable then
			entity.combat:StackState("HitboxImmunity", true);
		end;
		
		if data.Animated then
			local RunAnimation : AnimationTrack = humanoid.Animator:LoadAnimation(ReplicatedStorage.Animations.Movement.Run)
			local RunSpeed = RunAnimation.Animation:GetAttribute("SpeedMultiplier") or 1;
			
			RunAnimation.Priority = Enum.AnimationPriority.Idle

			local Running = false

			local function TryRun(Speed: number)
				local IsRunning = Speed > 2;

				if not Running and entity.combat.Actions.CanRun and IsRunning then
					Running = true
					RunAnimation:Play(0.1, 1, RunSpeed)
					
				elseif Running and (not entity.combat.Actions.CanRun or not IsRunning) then
					Running = false
					RunAnimation:Stop()
				end
			end

			humanoid.Running:Connect(TryRun)
		end
			
		if data.AttackReplacer ~= "None" then
			local attack;
			
			if data.AttackReplacer == "Custom" then
				local sequence = create_sequence(self);
				
				attack = sequence:create_attack_for(entity.combat);
				
			elseif data.AttackReplacer == "Random" then
				
				local lua_player = LuaPlayerList.Get(self.interest_id);
				
				if not lua_player then
					local players = Players:GetPlayers()
					local random_player = players[math.random(1, #players)];
					
					lua_player = LuaPlayerList.Get(random_player);
				end;
				
				local attack_settings = { IncludeWorldEvents = true, RespectSkillBuilder = true };
				local attack_list = lua_player.Character.Combat:GetListOfAccessibleAttacks(attack_settings);
				local random = attack_list[math.random(1, #attack_list)];

				attack = entity.combat:CreateAttack(random, Enum.KeyCode.One);
			else
				attack = entity.combat:CreateAttack(data.AttackReplacer, Enum.KeyCode.One);
			end;
			
			entity.attack_replacer = attack;
		end;
	else
		clone_enemy = clone_model;
	end;
	
	clone_enemy:PivotTo(self:get_cframe());
	clone_enemy.Parent = workspace.Models;
	
	if data.DescriptionType ~= "None" then
		local humanoid_description: HumanoidDescription?;
		
		if data.DescriptionType == "Custom" then
			humanoid_description = data.Description;

			if data.Description and not data.Description:IsA("HumanoidDescription") then
				notify_builders(combats, 1, `Reference Description will not apply: isn't of instance type HumanoidDescription.`);
			end;

		elseif data.DescriptionType == "User" then
			local success, result = pcall(Players.GetHumanoidDescriptionFromUserId, Players, data.DescriptionId);

			if success then
				humanoid_description = result;
			end;
		end;

		if humanoid_description then
			entity.humanoid:ApplyDescriptionReset(humanoid_description);
		end;
	end;
	
	self.entities[clone_enemy] = true;
end

function TagModifier:destroy()
	for enemy in self.entities do
		enemy:Destroy();
	end;
	
	table.clear(self.entities);
	
	InstanceModifier.destroy(self);
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;