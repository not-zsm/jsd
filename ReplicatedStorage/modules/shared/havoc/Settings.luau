local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Utility = require( ReplicatedStorage.modules.shared.Utilities.Utility )

local HavocFolder = workspace:WaitForChild("Havoc", 5);
assert(HavocFolder, "No Havoc Folder?");

local Map = workspace.Map
local Havocs = Map and Map:FindFirstChild("Destructible")

local StaticServer = HavocFolder:FindFirstChild("StaticServer")
local DynamicServer = HavocFolder:FindFirstChild("DynamicServer")

local DefaultBreakOverlap = OverlapParams.new();
DefaultBreakOverlap.FilterDescendantsInstances = { HavocFolder.Static };
DefaultBreakOverlap.FilterType = Enum.RaycastFilterType.Include;

local DefaultPushOverlap = OverlapParams.new();
DefaultPushOverlap.FilterDescendantsInstances = {  };
DefaultPushOverlap.FilterType = Enum.RaycastFilterType.Include;

if StaticServer then
	DefaultBreakOverlap:AddToFilter(StaticServer)
end;

if DynamicServer then
	DefaultPushOverlap:AddToFilter(DynamicServer);
end;

if Havocs then
	DefaultBreakOverlap:AddToFilter(Havocs)
end

return {
	UsePartCache = true;
	
	-- If enabled, slice subdivision will use k-d tree partitioning, otherwise quadtree partitioning will be used.
	UseSimpleSubdivde = false;
	SubdivideRectangleThreshold = 1.33; -- Maximum difference between largest axis and smallest axis. 
	TimeToReset = Utility.DestructionRespawnTime;
	
	EffectsLifetime = 10; -- Maximum lifetime of effects created with Destruction:create_effects()
	
	DefaultParameters = table.freeze {
		origin = CFrame.identity;
		radius = 10;
		size = Vector3.zero * 10;
		block_size = 4.50;
		shape = "Box";
		overlap = DefaultBreakOverlap;
		auto_overlap = true;
		greedy_meshing = true;
		greedy_batch_size = 75;
		greedy_opportunistic_batch_size = 200;
		seperate_islands = false;
	};
	
	DefaultBreakOverlap = DefaultBreakOverlap;
	DefaultDebrisOverlap = DefaultPushOverlap;
	
	TagToHavoc = "CanHavoc"; -- If an instance contains this tag, it and its descendants will be added to the overlap automatically.
	AttributeDestructed = "HasHavoc", -- The attribute signaling whether a part is currently destructed.
	UseAttributeDestructed = false; -- If the attribute for destruction is used, can help reduce network received in replication.
	
	DestructAsWholeUnit = true; -- Whether all the parts of a DestructUnit (Parent/Model) will restore at the same time in sync.
	
	--[[ 
		Describes what ancestor is meant by whole unit (DestructAsWholeUnit)
		Valid types are:
			'Parent' - Use the part's parent.
			'AncestorModel' - Use the first ancestor which is a model.
			'AncestorTagged' - Use the first ancestor which has the tag (Setting.WholeUnitTag)
	]]
	WholeUnitType = "Parent";
	WholeUnitTag = "DestructionUnit"; -- The tag used when WholeUnitType is set to 'AncestorTagged'
	
	SetPropertiesOfDestructedPart = {
		Immediate = {
			CanQuery = false,
			CanCollide = false, 
			Transparency = 1,
		},
		Deferred = {},
	};
	
	ReplicationSettings = {
		DebrisSleepAfterIdle = 2;
		UpdateDebrisFrequency = 1 / 15;
		
		-- Three settings below are requirements before client mimics are used to save server performance.
		MinimumServerBeforeClientMimic = 8; -- Mimimum of server debris before client debris can be considered (two settings below).
		SmallestSurfaceForClientMimic = 4; -- Smaller than the multiplication of the two largest axes to be accepted.
		GreatestSizeForClientMimic = 1.50; -- Smaller than the magnitude of the size to be accepted.
		
		--[[
			🧱 = Create Debris.
			🆙 = Update Debris.
		]]
		ClientByteDebugPrint = false;
		ClientMimicDebrisUpdateFrequency = 1 / 60;
		MaxClientTweenBeforeDropoff = 500; -- Maximum number of tweens per update, if greater - then a linear dropoff is used and if x2 the threshold, no tweens will be made.
	};
};