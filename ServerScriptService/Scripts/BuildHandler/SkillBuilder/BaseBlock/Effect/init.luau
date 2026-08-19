local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Unpacker = require( "../../Unpacker" );
local Instances = require( ReplicatedStorage.Packages.Instances )
local Table = require( ReplicatedStorage.Packages.Table )

local VFX_Path = ReplicatedStorage.Modules.Player.Replication.VFX;
local Effects_Path = ReplicatedStorage.BuildTools.Effects;

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(62, 255, 75)
DerivedBlock.icon = "93438777054599"
DerivedBlock.description = "Animates a visual effect"
DerivedBlock.help_description = require(script.Description);
DerivedBlock.order = 5;
DerivedBlock.properties = { 
	Effect = {
		Described = true;
		Order = 1,
		Default = "None";
		Filtered = false;
		ViewingHelper = {
			Type = "ValueList",
			Getter = "Effects",
			Scale = 0.75;
		};
	};
	Tint = {
		Order = 2,
		Grayboxed = true;
		Default = Color3.new(1, 1, 1);
	};
	Scale = {
		Order = 3,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 2);
			Increment = 0.025;
		};
	};
	Volume = {
		Order = 4,
		Default = 1,
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 2);
			Increment = 0.025;
		};
	};
	Density = {
		Order = 5;
		Default = 1;
		Format = {
			Type = "Slider",
			Range = NumberRange.new(0, 2);
			Increment = 0.025;
		};
	};
	Position = {
		Order = 6,
		Default = Vector3.new(0, 0, 0),
	};
	Orientation = {
		Order = 7,
		Default = Vector3.new(0, 0, 0),
	};
	AttachTo = {
		Order = 110,
		Default = "Root Attachment";
		ValueList = {
			"Root Attachment",
			"Root Part",
			"Torso",
			"Head",
			"Right Arm",
			"Left Arm",
			"Right Leg",
			"Left Leg",
			"Terrain",
		};
	};
	LockToPart = {
		Order = 115,
		Default = true,
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

	return self;
end;

-------------------------------------------------------------------------

function DerivedBlock:initialise_cache(cache: Configuration)
	local data = self:get_values();
	local rot = self.values.Orientation / 180 * math.pi; -- Convert to Radians (from Degrees)
	
	self.cache_setting = Instance.new("Configuration");
	self.cache_setting.Name = self:get_internal_name();
	
	for attribute, value in 
		{
			Scale = data.Scale, 
			Volume = data.Volume,
			Density = data.Density,
			Tint = if not self.data.Tint.Gray then data.Tint else nil,
			Offset = CFrame.new(self.values.Position) * CFrame.Angles(rot.X, rot.Y, rot.Z);
		} 
	do
		self.cache_setting:SetAttribute(attribute, value);
	end
	
	self.cache_setting.Parent = cache;
end

local find_list = Table.bool_map(DerivedBlock.properties.AttachTo.ValueList);

function DerivedBlock:activate(sequencer, combat)
	local effect = Instances.find_directory(Effects_Path, self.values.Effect, "/") or Instances.find_directory(VFX_Path, self.values.Effect, "/");
	
	if effect then
		local attach_to = self.values.AttachTo;
		local character = combat.LuaCharacter;
		local part: Instance;
		
		if attach_to == "Terrain" then
			part = workspace.Terrain;
			
		elseif find_list[attach_to] then
			part = character[ string.gsub(attach_to :: string, " ", "") ];
		end
		
		if part then
			self.sequence_skill.skill_builder.build_handler:spawn_effects(effect, part, self.cache_setting);
		else
			self:get_combat():notify_builder("warning", "[Skill Debug] 'Attach To' property of Effect block is invalid", 8)
		end
	end;
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;