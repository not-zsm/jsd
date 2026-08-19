local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Debris = game:GetService("Debris")

-------------------------------------------------------------------------

local BaseBlock = require(script.Parent);
local Asset = require( ReplicatedStorage.Packages.Asset )

-------------------------------------------------------------------------

local DerivedBlock = setmetatable({}, BaseBlock);
DerivedBlock.__index = DerivedBlock;
DerivedBlock.name = script.Name;
DerivedBlock.color = Color3.fromRGB(29, 43, 7)
DerivedBlock.icon = "12695105591"
DerivedBlock.description = "Creates a crater at the target"
DerivedBlock.order = 31;
DerivedBlock.properties = {
	CraterType = {
		Order = 0,
		Default = "Crater",
		ValueList = {"Crater", "Cone", "Rubble", "Splash"},
	};
	Position = {
		Order = 10,
		Default = Vector3.zero,
		Described = true;
	};
	Orientation = {
		Order = 20,
		Default = Vector3.zero,
	};
	Lifetime = {
		Order = 30,
		Default = 10,
	};
	Count = {
		Order = 40,
		Default = NumberRange.new(10),
	};
	Size = {
		Order = 50,
		Default = Vector3.one,
	};
	RotationX = {
		Order = 60,
		Default = NumberRange.new(0),
	},
	RotationY = {
		Order = 70,
		Default = NumberRange.new(0),
	},
	Variance = {
		Order = 80;
		Default = 0,
	};
	PointVariance = {
		Order = 90;
		Default = 0,
	};
	Rate = {
		Order = 100;
		Default = 20,
	};
	Radius = {
		Order = 100;
		Default = 20,
	};
	Depth = {
		Order = 100;
		Default = 0,
	};
	Angle = {
		Order = 110;
		Default = NumberRange.new(15),
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
	data.Orientation = nil;
	data.Position = nil;
	
	self.cache_setting = Instance.new("Configuration");
	self.cache_setting.Name = self:get_internal_name();

	for attribute, value in data do
		self.cache_setting:SetAttribute(attribute, value);
	end
	
	self.cache_setting.Parent = cache;
end

function DerivedBlock:activate(sequencer, combat)
	local rot = self.values.Orientation / 180 * math.pi;
	local offset = CFrame.new( self.values.Position ) * CFrame.Angles(rot.X, rot.Y, rot.Z);
	local coordinate = combat:GetSimulatedRoot().CFrame * offset;
	
	ReplicatedStorage.BuildTools.Remotes.Effects.SpawnCrater:FireAllClients(coordinate, self.cache_setting);
end

-------------------------------------------------------------------------

table.freeze(DerivedBlock);

return DerivedBlock;