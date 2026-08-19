local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-----------------------------------------------------------------------------------------------

local Unpacker = require( "../../Unpacker" );
local Type = require( Unpacker.Packages.Type );
local Asset = require( Unpacker.Packages.Asset );
local Maid = require( Unpacker.Packages.Maid );
local Instances = require( Unpacker.Packages.Instances );

-----------------------------------------------------------------------------------------------

local InterfaceRemote = Unpacker.Remotes.Effects.ScreenInterface;

-----------------------------------------------------------------------------------------------

local InstanceModifier = require( script.Parent .Parent );
local TagModifier = setmetatable({}, InstanceModifier);

local ModifierEvents = {"OnEquipped", "OnUnequipped", "OnActivate", "OnDeactivate"};
local AnimationValueList = {};

for _, animation in script.Animations:GetChildren() do
	table.insert( AnimationValueList, animation.Name );
end;

TagModifier.__index = TagModifier;
TagModifier.name = string.lower(script.Name);
TagModifier.description = "Create custom items";
TagModifier.icon = 12392897830;
TagModifier.color = Color3.fromRGB(70, 255, 29)
TagModifier.section = 3;
TagModifier.attribute_updates = {};
TagModifier.properties = {
	OnActivate = {
		Order = 20,
		Default = nil,
		Type = Type.Instance();
	};
	OnDeactivate = {
		Order = 21,
		Default = nil,
		Type = Type.Instance();
	};
	OnEquipped = {
		Order = 22,
		Default = nil,
		Type = Type.Instance();
	};
	OnUnequipped = {
		Order = 23,
		Default = nil,
		Type = Type.Instance();
	};
	Handle = {
		Order = 1,
		Default = nil,
		Type = Type.Instance();
	};
	GripPosition = {
		Order = 2,
		Default = Vector3.zero;
	};
	GripOrientation = {
		Order = 3,
		Default = Vector3.zero;
	};
	HoldBased = {
		Order = 5,
		Default = false,
	};
	Hardlinking = {
		Order = 6,
		Default = true;
	};
	ActivateSinked = {
		Order = 7,
		Default = true,
	};
	MaxUses = {
		Order = 8,
		Default = 0;
	};
	Debounce = {
		Order = 9,
		Default = 0;
	};
	HoldAnimation = {
		Order = 4,
		Default = "None",
		ValueList = AnimationValueList;
	};
	Icon = {
		Order = 9,
		Default = "10755551053",
		AssetType = Enum.AssetType.Decal;
	};
};

-----------------------------------------------------------------------------------------------

local function get_player(tool: Tool): Player?
	local character = tool:FindFirstAncestorOfClass("Model");
	
	return if character then Players:GetPlayerFromCharacter(character) else nil;
end;

local function get_humanoid(tool: Tool): Humanoid?
	local character = tool:FindFirstAncestorOfClass("Model");

	return if character then character:FindFirstChildOfClass("Humanoid") else nil;
end;

local function trigger_output_tool(self, output: Instance, tool: Tool): ()
	if not output then
		return;
	end;
	
	local player = get_player(tool);
	
	if player then
		local list = InstanceModifier.get_modifiers(output);
		local signal = self.modifier:create_pulse{ self.modifier:get_combat(player) };
		
		for _, modifier in list do
			if modifier == self.modifier then
				continue;
			end;
			
			modifier:pulse(signal);
		end;
	end;
end;

local function sandbox_modifiers(self, instance: Instance, handle: Instance?)
	if not instance then
		return nil;
	end;
	
	local target_instance = instance;
	
	-- Is not the handle or a descendant of the handle, then create a copy.
	if not ( handle and ( instance == handle or instance:IsDescendantOf(handle) ) ) then
		target_instance = instance:Clone();
	end;
	
	self.modifier.build_handler:load_modifiers(target_instance);
	
	return target_instance;
end;

local CustomItem = {};
CustomItem.__index = CustomItem;

function CustomItem.new(modifier, original_owner)
	local maid = Maid.new();
	local data = modifier.attributes:all();
	
	local self = setmetatable(
		{
			combat = original_owner;
			
			maid = maid;
			modifier = modifier;
			data = data;
			links = data;
			
			modifier_links = {};
			powered_modifiers = {};
			animations = {};
			
			tool = Instance.new("Tool");
			uses = 0;
			enabled = true;
			debounce = false;
			equipped_humanoid = nil;
		},
		CustomItem);
	
	return self;
end;

function CustomItem:create_handle(origin_handle: Instance, parent: Instance?)
	if origin_handle.Name ~= "Handle" then
		self.tool.Name = origin_handle.Name;
	end;
	
	local handle = origin_handle:Clone();
	local origin_part_handle = origin_handle;
	local unpacking = false;
	
	if handle:IsA("BasePart") then
		handle.Anchored = false;
		handle.Name = "Handle";
	else
		origin_part_handle = origin_handle:FindFirstChild("Handle");
		
		if not origin_part_handle or not origin_part_handle:IsA("BasePart") then
			origin_part_handle = nil;
			self.combat:notify_builder("warning", "[Item Debug] Unable to find a part named Handle", 8);
		else
			unpacking = true;
		end;
	end;
	
	if origin_part_handle then
		local connected_parts: {BasePart} = origin_part_handle:GetConnectedParts()

		for _, part in connected_parts do
			if not part:IsDescendantOf(origin_handle) and part ~= origin_part_handle then
				self.combat:notify_builder("warning", "[Item Debug] Handle is jointed to another part that was not cloned", 8);
				self.combat:notify_builder("info", "Parent this part to your Handle to fix", 8);
				break;
			end;
		end;
	end;
	
	-- This Hardlinking feature allows automatic re-routing of 'Output' instance references to anything thats a descendant of the tool's handle.
	-- allowing modifiers to be triggered on the tool itself (and not the original output). 
	if self.data.Hardlinking then
		local map_descendants = Instances.get_mirrored_map(origin_handle, handle);
		
		for _, name in ModifierEvents do
			local link = self.data[name];
			
			if not link then
				continue;
			
			elseif link == origin_handle or link:IsDescendantOf(origin_handle) then
				self.links[name] = map_descendants[link];
			end;
		end;
	end;
	
	local children = handle:GetChildren();
	
	for _, part in children do
		if part:IsA("BasePart") then
			part.Anchored = false;
		end;
	end;
	
	if unpacking then
		for _, part in children do
			part.Parent = parent;
		end;
		
		handle:Destroy();
	else
		handle.Parent = parent;
	end;
	
	return handle;
end;

local function add_custom_item_icon(self)
	self.tool.TextureId = Asset.get_decal_id( tostring(self.data.Icon) );
end;

function CustomItem:initialise()
	if self.modifier.tool_icon then
		self.tool.TextureId = self.modifier.tool_icon;
	else
		task.spawn(add_custom_item_icon, self);
	end;
	
	self.tool.RequiresHandle = false;
	self.tool.CanBeDropped = true;
	self.tool.Name = "Custom Tool";
	
	if not self.data.ActivateSinked then
		self.tool:SetAttribute("DoNotSink", true);
	end;
	
	self.tool.Grip = CFrame.new(self.data.GripPosition) * CFrame.Angles( 
		math.rad(self.data.GripOrientation.X), 
		math.rad(self.data.GripOrientation.Y), 
		math.rad(self.data.GripOrientation.Z) 
	)

	local handle = self.data.Handle;

	if handle then
		handle = self:create_handle(handle, self.tool);
	end;
	
	self.modifier_links.equipped = sandbox_modifiers(self, self.links.OnEquipped, handle);
	self.modifier_links.unequipped = sandbox_modifiers(self, self.links.OnUnequipped, handle);
	self.modifier_links.activate = sandbox_modifiers(self, self.links.OnActivate, handle);
	self.modifier_links.deactivate = sandbox_modifiers(self, self.links.OnDeactivate, handle);
	
	self.maid:add(self.tool.AncestryChanged:Connect(function(_, parent)
		if not parent then
			self:destroy();
		end;
	end));
	
	self.maid:add(self.tool.Equipped:Connect(function()
		self:equipped();
	end))

	self.maid:add(self.tool.Unequipped:Connect(function()
		self:unequipped();
	end))

	self.maid:add(self.tool.Activated:Connect(function()
		self:activate();
	end));

	self.maid:add(self.tool.Deactivated:Connect(function()
		self:deactivate();
	end))
end

function CustomItem:deactivate()
	if self.data.HoldBased then
		for _, modifier in self.powered_modifiers do
			modifier:remove_humanoid_from_signal( self.equipped_humanoid );
			modifier:unpower_from_source( self.modifier );
		end
		
		table.clear(self.powered_modifiers);
	end
	
	if self.modifier_links.deactivate then
		trigger_output_tool(self, self.modifier_links.deactivate, self.tool);
	end;
end

function CustomItem:equipped()
	self.equipped_humanoid = get_humanoid(self.tool);

	if self.modifier_links.equipped then
		trigger_output_tool(self, self.modifier_links.equipped, self.tool);
	end;
	
	if self.data.HoldAnimation ~= "None" and self.equipped_humanoid then
		local animator = self.equipped_humanoid:FindFirstChildOfClass("Animator");
		
		if animator then
			local hold_animation = script.Animations:FindFirstChild(self.data.HoldAnimation);

			if hold_animation then
				self.animations.idle = animator:LoadAnimation(hold_animation);
				self.animations.idle.Looped = true;
				self.animations.idle.Priority = Enum.AnimationPriority.Action2;
				self.animations.idle:Play();
			end;
		end;
	end;
end;

function CustomItem:unequipped()
	self:deactivate();
	self.equipped_humanoid = nil;
	
	if self.modifier_links.unequipped then
		trigger_output_tool(self, self.modifier_links.unequipped, self.tool);
	end;
	
	self:clear_animations();
end;

function CustomItem:clear_animations()
	for name, animation in self.animations do
		animation:Stop();
		animation:Destroy();
	end;

	table.clear(self.animations);
end

function CustomItem:activate()
	if not self.enabled or self.debounce then return end;
	
	if self.data.Debounce > 0 then
		self.debounce = true;
		
		task.delay(self.data.Debounce, function()
			self.debounce = false;
		end);
	end;
	
	if self.data.HoldBased and self.modifier_links.activate then
		self.powered_modifiers = InstanceModifier.get_modifiers(self.modifier_links.activate);
		
		for _, modifier in self.powered_modifiers do
			modifier:add_humanoid_to_signal( self.equipped_humanoid );
			modifier:power_from_source( self.modifier );
			modifier:update_powered();
		end;
	else
		trigger_output_tool(self, self.modifier_links.activate, self.tool);
	end;
	
	if self.data.MaxUses > 0 then
		self.uses += 1;

		if self.uses >= self.data.MaxUses then
			self.enabled = false;
			
			self:deactivate();
			self:destroy();
		end;
	end;
end;

local function unparent_item(self)
	-- We can't parent to nil, modifier logic will automatically destroy.
	self.tool.Parent = script.DeadItems;

	-- We can't destroy it immediately (modifiers will also be destroyed, logic will not linger when intended which is bad)
	Debris:AddItem(self.tool, 120);
end;

function CustomItem:destroy()
	self.enabled = false;
	self.maid:destroy();
	
	pcall(unparent_item, self);
	
	self:clear_animations();
end;

table.freeze(CustomItem);

-----------------------------------------------------------------------------------------------

function TagModifier.new(instance_modifier, instance)
	local self = setmetatable(InstanceModifier.new(instance_modifier, instance), TagModifier);
	
	self.short_powered = true;
	self.phantom_powering = true;
	
	return self;
end;

function TagModifier.attribute_updates:Icon(value, was_init)
	self.tool_icon = Asset.get_decal_id( tostring(value) );
end;

function TagModifier:pulse(signal)
	
	for _, combat in signal:get_combats() do
		local player = combat.LuaPlayer.Player;
		
		local item = CustomItem.new(self, combat);
		item:initialise();
		
		combat.LuaPlayer.Character.Items:Give("Custom", item.tool);
		
		item.tool.Parent = player.Backpack;
	end;
end;

TagModifier:rebase();
table.freeze(TagModifier);

return TagModifier;